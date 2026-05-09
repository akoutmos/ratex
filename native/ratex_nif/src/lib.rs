use rustler::{Binary, Encoder, Env, Error, NewBinary, NifStruct, Term};

use ratex_types::display_item::DisplayList;
use ratex_types::{Color, MathStyle};

#[derive(NifStruct)]
#[module = "Ratex.Options"]
pub struct Options {
    pub font_size: f64,
    pub pixel_ratio: Option<f64>,
    pub color: String,
    pub inline: bool,
    pub unicode_font_path: Option<String>,
}

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

fn build_display_list(latex: &str, inline: bool, color_hex: &str) -> Result<DisplayList, String> {
    let nodes = ratex_parser::parse(latex).map_err(|e| format!("parse error: {e:?}"))?;
    let mut layout_opts = ratex_layout::LayoutOptions::default();

    layout_opts.style = if inline {
        MathStyle::Text
    } else {
        MathStyle::Display
    };

    if let Some(c) = Color::parse(color_hex) {
        layout_opts.color = c;
    }

    let layout_box = ratex_layout::layout(&nodes, &layout_opts);

    Ok(ratex_layout::to_display_list(&layout_box))
}

fn do_render_png(latex: &str, opts: &Options) -> Result<Vec<u8>, String> {
    let dl = build_display_list(latex, opts.inline, &opts.color)?;
    let mut render_opts = ratex_render::RenderOptions::default();

    render_opts.font_size = opts.font_size as f32;

    if let Some(pixel_ratio) = opts.pixel_ratio {
        render_opts.device_pixel_ratio = pixel_ratio as f32;
    }

    ratex_render::render_to_png(&dl, &render_opts).map_err(|e| format!("render error: {e:?}"))
}

fn do_render_svg(latex: &str, opts: &Options) -> Result<String, String> {
    let dl = build_display_list(latex, opts.inline, &opts.color)?;
    let mut svg_opts = ratex_svg::SvgOptions::default();

    svg_opts.font_size = opts.font_size;
    svg_opts.embed_glyphs = true;

    Ok(ratex_svg::render_to_svg(&dl, &svg_opts))
}

rustler::init!("Elixir.Ratex.Native");
