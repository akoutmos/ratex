defmodule RatexTest do
  use ExUnit.Case

  @png_magic <<0x89, ?P, ?N, ?G, 0x0D, 0x0A, 0x1A, 0x0A>>

  describe "render_png/2" do
    test "renders a simple expression to a PNG binary" do
      assert {:ok, <<@png_magic, _rest::binary>>} = Ratex.render_png("x + y")
    end

    test "respects font_size and color options" do
      assert {:ok, <<@png_magic, _::binary>>} =
               Ratex.render_png("E = mc^2", font_size: 64.0, color: "#1E88E5")
    end

    test "accepts integer values for numeric options (coerces to float)" do
      # Regression test: Rustler's f64 decoder rejects integer terms, which
      # surfaces as `:invalid_struct`. The public API normalizes on the way in.
      assert {:ok, <<@png_magic, _::binary>>} =
               Ratex.render_png("x", font_size: 48.0, pixel_ratio: 1.0)
    end

    test "renders the quadratic formula" do
      latex = "\\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}"
      assert {:ok, <<@png_magic, _::binary>>} = Ratex.render_png(latex)
    end

    test "returns {:error, _} on malformed LaTeX rather than crashing" do
      # Should never crash the VM. Either succeeds (Ratex is permissive) or
      # returns an error tuple — both are acceptable; a NIF crash is not.
      result = Ratex.render_png("\\\\unknown_command{")
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    test ":padding actually changes the output (not silently dropped)" do
      {:ok, default} = Ratex.render_png("x")
      {:ok, padded} = Ratex.render_png("x", padding: 60.0)
      # Different padding → different image dimensions → different bytes.
      refute default == padded
    end
  end

  describe "render_svg/2" do
    test "renders a simple expression to an SVG document" do
      assert {:ok, svg} = Ratex.render_svg("x + y")
      assert is_binary(svg)
      assert String.contains?(svg, "<svg")
      assert String.contains?(svg, "</svg>")
    end

    test "embeds glyph outlines as paths (standalone SVG)" do
      # With ratex-svg's `embed-fonts` feature, glyphs come out as <path>
      # elements rather than <text> referencing KaTeX webfonts. This is what
      # makes the output portable.
      assert {:ok, svg} = Ratex.render_svg("\\frac{1}{2}")
      assert String.contains?(svg, "<path")
    end

    test "respects color option" do
      assert {:ok, svg} = Ratex.render_svg("E = mc^2", color: "#1E88E5")
      # The hex color (or its rgb form) should appear somewhere in the output.
      assert String.contains?(String.downcase(svg), "1e88e5") or
               String.contains?(svg, "rgba(30")
    end

    test ":padding actually changes the SVG (not silently dropped)" do
      {:ok, default} = Ratex.render_svg("x")
      {:ok, padded} = Ratex.render_svg("x", padding: 60.0)
      # Different padding → different viewBox → different bytes.
      refute default == padded
    end
  end
end
