<p align="center">
  <img align="center" width="50%" src="guides/images/logo.png" alt="MathJax Logo">
</p>

<p align="center">
  Generate SVGs and PNGs of mathematical expressions using <a href="https://www.mathjax.org/">MathJax</a>
</p>

<p align="center">
  <a href="https://hex.pm/packages/math_jax">
    <img alt="Hex.pm" src="https://img.shields.io/hexpm/v/math_jax?style=for-the-badge">
  </a>

  <a href="https://github.com/akoutmos/math_jax/actions">
    <img alt="GitHub Workflow Status (master)"
    src="https://img.shields.io/github/actions/workflow/status/akoutmos/math_jax/main.yml?label=Build%20Status&style=for-the-badge&branch=master">
  </a>

  <a href="https://coveralls.io/github/akoutmos/math_jax?branch=master">
    <img alt="Coveralls master branch" src="https://img.shields.io/coveralls/github/akoutmos/math_jax/master?style=for-the-badge">
  </a>

  <a href="https://github.com/sponsors/akoutmos">
    <img alt="Support the project" src="https://img.shields.io/badge/Support%20the%20project-%E2%9D%A4-lightblue?style=for-the-badge">
  </a>
</p>

<br>

# Contents

- [Installation](#installation)
- [Example Output](#example-output)
- [Supporting MathJax](#supporting-sqlfmt)
- [Attribution](#attribution)

## Installation

[Available in Hex](https://hex.pm/packages/math_jax), the package can be installed by adding `math_jax` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:math_jax, "~> 0.2.0"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/math_jax](https://hexdocs.pm/math_jax).

## Example Output

After setting up MathJax in your application you can use the MathJax functions in order to generate images of
mathematical expressions:

### Example 1

```elixir
MathJax.render!(~S"y = mx + b", :png)
```

<p align="center">
  <img align="center" src="guides/images/equation_1.png" alt="Equation 1">
</p>

### Example 2

```elixir
MathJax.render!(~S"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}", :png)
```

<p align="center">
  <img align="center" src="guides/images/equation_2.png" alt="Equation 2">
</p>

### Example 3

```elixir
MathJax.render!(~S"\frac{d}{dx}\left[\frac{x^2 \sin(x)}{e^x}\right] = \frac{e^x(2x\sin(x) + x^2\cos(x)) - x^2\sin(x)\,e^x}{e^{2x}}", :png)
```

<p align="center">
  <img align="center" src="guides/images/equation_3.png" alt="Equation 3">
</p>

### Example 4

```elixir
MathJax.render!(~S"\int_{0}^{\infty} \frac{\sqrt[3]{x}}{(1+x)^2} \, dx = \frac{2\pi}{3\sqrt{3}}", :png)
```

<p align="center">
  <img align="center" src="guides/images/equation_4.png" alt="Equation 4">
</p>

### Example 5

```elixir
MathJax.render!(~S"\nabla f(\mathbf{x}) = \sum_{k=1}^{n} \frac{\partial}{\partial x_k} \left[ \int_{0}^{x_k} e^{-t^2} \, dt \right] \hat{e}_k = \begin{pmatrix} e^{-x_1^2} \\ e^{-x_2^2} \\ \vdots \\ e^{-x_n^2} \end{pmatrix}", :png)
```

<p align="center">
  <img align="center" src="guides/images/equation_5.png" alt="Equation 5">
</p>

## Supporting MathJax

If you rely on this library help you debug your Ecto/SQL queries, it would much appreciated if you can give back
to the project in order to help ensure its continued development.

Checkout my [GitHub Sponsorship page](https://github.com/sponsors/akoutmos) if you want to help out!

### Gold Sponsors

<a href="https://github.com/sponsors/akoutmos/sponsorships?sponsor=akoutmos&tier_id=58083">
  <img align="center" height="175" src="guides/images/your_logo_here.png" alt="Support the project">
</a>

### Silver Sponsors

<a href="https://github.com/sponsors/akoutmos/sponsorships?sponsor=akoutmos&tier_id=58082">
  <img align="center" height="150" src="guides/images/your_logo_here.png" alt="Support the project">
</a>

### Bronze Sponsors

<a href="https://github.com/sponsors/akoutmos/sponsorships?sponsor=akoutmos&tier_id=17615">
  <img align="center" height="125" src="guides/images/your_logo_here.png" alt="Support the project">
</a>

## Attribution

- The MathJax library leans on the Rust library [mathjax_svg](https://github.com/gw31415/mathjax_svg) for compiling MathJax expressions.
