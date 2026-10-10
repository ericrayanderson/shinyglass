# Default CSS variable pack for a preset

Values that
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
compiles into `[data-glass-preset]`. Use as a starting point for
[`glass_add_tokens()`](https://ericrayanderson.github.io/shinyglass/reference/glass_add_tokens.md)
overrides.

## Usage

``` r
glass_token_pack(preset = c("light", "dark"))
```

## Arguments

- preset:

  `"light"` or `"dark"`.

## Value

A named list of CSS custom properties (names include `--`).

## See also

[`glass_css_tokens()`](https://ericrayanderson.github.io/shinyglass/reference/glass_css_tokens.md),
[`glass_add_tokens()`](https://ericrayanderson.github.io/shinyglass/reference/glass_add_tokens.md)

Other glass tokens:
[`glass_add_tokens()`](https://ericrayanderson.github.io/shinyglass/reference/glass_add_tokens.md),
[`glass_css_tokens()`](https://ericrayanderson.github.io/shinyglass/reference/glass_css_tokens.md),
[`glass_scenes()`](https://ericrayanderson.github.io/shinyglass/reference/glass_scenes.md)

## Examples

``` r
names(glass_token_pack("light"))
#>  [1] "--glass-bg"                 "--glass-bg-hover"          
#>  [3] "--glass-border"             "--glass-shadow"            
#>  [5] "--glass-elevated-shadow"    "--glass-highlight"         
#>  [7] "--glass-specular"           "--glass-menu-bg"           
#>  [9] "--glass-menu-color"         "--glass-page-bg"           
#> [11] "--glass-orb-1"              "--glass-orb-2"             
#> [13] "--glass-orb-3"              "--glass-body-bg"           
#> [15] "--glass-body-color"         "--glass-blur"              
#> [17] "--glass-saturate"           "--glass-radius"            
#> [19] "--glass-intensity"          "--glass-refract-a"         
#> [21] "--glass-refract-b"          "--glass-refract-brightness"
#> [23] "--glass-refract-contrast"   "--glass-ior"               
#> [25] "--glass-refraction-scale"   "--glass-dispersion"        
#> [27] "--glass-diffusion"          "--glass-specular-top"      
#> [29] "--glass-specular-bottom"    "--glass-edge"              
#> [31] "--glass-press-scale"        "--glass-scroll-edge-fade"  
#> [33] "--glass-minimize-scale"     "--glass-icon-clear"        
#> [35] "--glass-wallpaper-wash"     "--glass-plot-panel"        
glass_token_pack("dark")[["--glass-body-color"]]
#> [1] "#f5f5f7"
```
