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
#>       token           css_var category
#> 1      blur      --glass-blur material
#> 2  saturate  --glass-saturate material
#> 3    radius    --glass-radius material
#> 4 intensity --glass-intensity material
#> 5 refract-a --glass-refract-a material
#> 6 refract-b --glass-refract-b material
#>                                                           description
#> 1                                  Backdrop blur radius (CSS length).
#> 2                                                Backdrop saturation.
#> 3                                   Corner radius for glass surfaces.
#> 4                         Ultra Clear (0) to Tinted (1). Default 0.5.
#> 5  Coloured leading-edge refraction cue. Alpha scales with intensity.
#> 6 Coloured trailing-edge refraction cue. Alpha scales with intensity.
glass_css_tokens()$css_var
#>  [1] "--glass-blur"               "--glass-saturate"          
#>  [3] "--glass-radius"             "--glass-intensity"         
#>  [5] "--glass-refract-a"          "--glass-refract-b"         
#>  [7] "--glass-refract-brightness" "--glass-refract-contrast"  
#>  [9] "--glass-bg"                 "--glass-bg-hover"          
#> [11] "--glass-bg-content"         "--glass-border"            
#> [13] "--glass-border-outer"       "--glass-shadow"            
#> [15] "--glass-elevated-shadow"    "--glass-highlight"         
#> [17] "--glass-specular"           "--glass-lip"               
#> [19] "--glass-stroke-side"        "--glass-body-bg"           
#> [21] "--glass-body-color"         "--glass-menu-bg"           
#> [23] "--glass-menu-color"         "--glass-page-bg"           
#> [25] "--glass-orb-1"              "--glass-orb-2"             
#> [27] "--glass-orb-3"              "--glass-wallpaper"         
#> [29] "--glass-wallpaper-wash"     "--glass-plot-panel"        
#> [31] "--glass-primary"            "--glass-accent"            
#> [33] "--glass-on-primary"         "--glass-ior"               
#> [35] "--glass-refraction-scale"   "--glass-dispersion"        
#> [37] "--glass-diffusion"          "--glass-specular-top"      
#> [39] "--glass-specular-bottom"    "--glass-edge"              
#> [41] "--glass-press-scale"        "--glass-scroll-edge-fade"  
#> [43] "--glass-minimize-scale"     "--glass-icon-clear"        
```
