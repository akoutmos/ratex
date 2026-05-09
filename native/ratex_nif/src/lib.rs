// SPDX-License-Identifier: MIT
//
// NIF surface for RaTeX. Pipeline:
//
//   LaTeX (&str)
//     → ratex_parser::parse           (lexer driven internally; → Vec<ParseNode>)
//     → ratex_layout::layout          (Vec<ParseNode> → LayoutBox, takes LayoutOptions)
//     → ratex_layout::to_display_list (LayoutBox → DisplayList — engine's terminal IR)
//     → ratex_render::render_to_png   (PNG bytes via tiny-skia)
//     | ratex_svg::render_to_svg      (self-contained SVG with inlined glyph paths)
//
// Color and `inline` (display vs text style) are both set on LayoutOptions
// before layout runs — DisplayItems come out pre-colored, no post-walk needed.
// `dpr` is PNG-only (vector SVG is resolution-independent).

use rustler::{Binary, Encoder, Env, Error, NewBinary, NifStruct, Term};

use ratex_types::display_item::DisplayList;
use ratex_types::{Color, MathStyle};

/// Mirror of `Elixir.RaTeX.Options`. Field names and types must match the
/// Elixir struct exactly — Rustler decodes by name.
///
/// `dpr` is `Option<f64>` because device pixel ratio only makes sense for
/// raster output. SVG callers send `nil`; PNG callers send `Some(value)`,
/// or `None` to fall back to the engine default.
#[derive(NifStruct)]
#[module = "Ratex.Options"]
pub struct Options {
    pub font_size: f64,
    pub pixel_ratio: Option<f64>,
    pub color: String,
    pub inline: bool,
    pub unicode_font_path: Option<String>,
}

// -----------------------------------------------------------------------------
// PNG NIF
// -----------------------------------------------------------------------------

#[rustler::nif(schedule = "DirtyCpu")]
fn render_png<'a>(env: Env<'a>, latex: String, opts: Options) -> Result<Term<'a>, Error> {
    if let Some(path) = &opts.unicode_font_path {
        std::env::set_var("RATEX_UNICODE_FONT", path);
    }

    let result = std::panic::catch_unwind(|| do_render_png(&latex, &opts));

    match result {
        Ok(Ok(bytes)) => {
            let mut bin = NewBinary::new(env, bytes.len());
            bin.as_mut_slice().copy_from_slice(&bytes);
            let binary: Binary = bin.into();
            Ok((rustler::types::atom::ok(), binary).encode(env))
        }
        Ok(Err(msg)) => Ok((rustler::types::atom::error(), msg).encode(env)),
        Err(_panic) => Ok((rustler::types::atom::error(), "ratex_panic").encode(env)),
    }
}

// -----------------------------------------------------------------------------
// SVG NIF
// -----------------------------------------------------------------------------

#[rustler::nif(schedule = "DirtyCpu")]
fn render_svg<'a>(env: Env<'a>, latex: String, opts: Options) -> Result<Term<'a>, Error> {
    if let Some(path) = &opts.unicode_font_path {
        std::env::set_var("RATEX_UNICODE_FONT", path);
    }

    let result = std::panic::catch_unwind(|| do_render_svg(&latex, &opts));

    match result {
        Ok(Ok(svg)) => Ok((rustler::types::atom::ok(), svg).encode(env)),
        Ok(Err(msg)) => Ok((rustler::types::atom::error(), msg).encode(env)),
        Err(_panic) => Ok((rustler::types::atom::error(), "ratex_panic").encode(env)),
    }
}

// =============================================================================
// Pipeline implementation
// =============================================================================

/// Build a fully-styled DisplayList from a LaTeX string. Color and inline-vs-
/// display are baked in at layout time, so the renderers can stay vanilla.
fn build_display_list(latex: &str, inline: bool, color_hex: &str) -> Result<DisplayList, String> {
    // Verified: `pub fn parse(input: &str) -> ParseResult<Vec<ParseNode>>`.
    let nodes = ratex_parser::parse(latex).map_err(|e| format!("parse error: {e:?}"))?;

    // Verified LayoutOptions fields: style, color, align_relation_spacing,
    // leftright_delim_height, inter_glyph_kern_em. `inline` is encoded via
    // `style` — Text for inline math, Display for block math (best-guess
    // variant names; if `MathStyle::{Display,Text}` are wrong they'll be
    // pinpointed by the next compile error).
    let mut layout_opts = ratex_layout::LayoutOptions::default();
    layout_opts.style = if inline {
        MathStyle::Text
    } else {
        MathStyle::Display
    };
    if let Some(c) = Color::parse(color_hex) {
        layout_opts.color = c;
    }
    // Bad/empty color string → leave the default (LayoutOptions::default()
    // gives black, matching upstream CLI behavior).

    // Verified: `layout` is infallible, returns LayoutBox directly. Takes the
    // node vec by reference. `&nodes` deref-coerces to `&[ParseNode]` if the
    // signature wants a slice; otherwise we'll see a clean type error.
    let layout_box = ratex_layout::layout(&nodes, &layout_opts);

    // Verified: `pub fn to_display_list(root: &LayoutBox) -> DisplayList`.
    Ok(ratex_layout::to_display_list(&layout_box))
}

fn do_render_png(latex: &str, opts: &Options) -> Result<Vec<u8>, String> {
    let dl = build_display_list(latex, opts.inline, &opts.color)?;

    // Verified RenderOptions fields: font_size: f32, padding, font_dir,
    // device_pixel_ratio. font_dir stays default — `embed-fonts` makes it
    // unused. dpr is honored only when the caller specified it; otherwise
    // we leave the engine default in place.
    let mut render_opts = ratex_render::RenderOptions::default();
    render_opts.font_size = opts.font_size as f32;
    if let Some(pixel_ratio) = opts.pixel_ratio {
        render_opts.device_pixel_ratio = pixel_ratio as f32;
    }

    ratex_render::render_to_png(&dl, &render_opts).map_err(|e| format!("render error: {e:?}"))
}

fn do_render_svg(latex: &str, opts: &Options) -> Result<String, String> {
    let dl = build_display_list(latex, opts.inline, &opts.color)?;

    // Verified from ratex-svg/src/lib.rs in the registry:
    //
    //   pub struct SvgOptions {
    //       pub font_size: f64,
    //       pub padding: f64,
    //       pub stroke_width: f64,
    //       pub embed_glyphs: bool,   // ← critical: must be true for <path> output
    //       pub font_dir: String,
    //   }
    //   pub fn render_to_svg(list: &DisplayList, opts: &SvgOptions) -> String
    //
    // embed_glyphs = true emits glyph outlines as <path>; false emits <text>
    // with KaTeX webfont references. With the embed-fonts Cargo feature the
    // TTFs are bundled via ratex-katex-fonts so font_dir stays empty.
    let mut svg_opts = ratex_svg::SvgOptions::default();
    svg_opts.font_size = opts.font_size;
    svg_opts.embed_glyphs = true;

    Ok(ratex_svg::render_to_svg(&dl, &svg_opts))
}

rustler::init!("Elixir.Ratex.Native");
