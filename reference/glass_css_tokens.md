# Stable Liquid Glass CSS tokens

Catalog of public `--glass-*` custom properties. Override them with
[`glass_add_tokens()`](https://ericrayanderson.github.io/shinyglass/reference/glass_add_tokens.md)
or
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
`tokens=` without forking `inst/scss/glass.scss`. Light/dark packs
already ship as dual `[data-glass-preset]` rules; prefer these variables
over Sass `$glass-*`.

## Usage

``` r
glass_css_tokens()
```

## Value

A data frame with `token`, `css_var`, `category`, and `description`.

## Details

Contrast floor (wallpaper / scenes): body ink is `#1d1d1f` (light) or
`#f5f5f7` (dark). User wallpapers are blurred and washed
(`--glass-wallpaper-wash`) so text sits on glass or a dimmed photo, not
raw imagery. Overlay menus use `--glass-menu-bg` (~86% light / ~88%
dark). Target 4.5:1 for body text and 3:1 for large UI chrome.

## Examples

``` r
head(glass_css_tokens())
#>       token           css_var category                        description
#> 1      blur      --glass-blur material Backdrop blur radius (CSS length).
#> 2  saturate  --glass-saturate material               Backdrop saturation.
#> 3    radius    --glass-radius material  Corner radius for glass surfaces.
#> 4 intensity --glass-intensity material     Ultra Clear (0) to Tinted (1).
#> 5        bg        --glass-bg  surface                Primary glass fill.
#> 6  bg-hover  --glass-bg-hover  surface         Hover / active glass fill.
glass_css_tokens()$css_var
#>  [1] "--glass-blur"            "--glass-saturate"       
#>  [3] "--glass-radius"          "--glass-intensity"      
#>  [5] "--glass-bg"              "--glass-bg-hover"       
#>  [7] "--glass-bg-content"      "--glass-border"         
#>  [9] "--glass-border-outer"    "--glass-shadow"         
#> [11] "--glass-elevated-shadow" "--glass-highlight"      
#> [13] "--glass-specular"        "--glass-lip"            
#> [15] "--glass-stroke-side"     "--glass-body-bg"        
#> [17] "--glass-body-color"      "--glass-menu-bg"        
#> [19] "--glass-menu-color"      "--glass-page-bg"        
#> [21] "--glass-orb-1"           "--glass-orb-2"          
#> [23] "--glass-orb-3"           "--glass-wallpaper"      
#> [25] "--glass-wallpaper-wash"  "--glass-plot-panel"     
#> [27] "--glass-primary"         "--glass-accent"         
#> [29] "--glass-on-primary"     
```
