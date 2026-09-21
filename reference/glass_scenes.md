# Named wallpaper scenes

Curated page backgrounds for
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
`scene=`. Each name ships light and dark gradient/orb packs. Pair with
`wallpaper=` for a user photo; the photo is blurred and washed so body
ink stays above the contrast floor documented in
[`glass_css_tokens()`](https://ericrayanderson.github.io/shinyglass/reference/glass_css_tokens.md).

## Usage

``` r
glass_scenes()
```

## Value

A named character vector: names are scene ids, values are labels.

## Examples

``` r
names(glass_scenes())
#> [1] "default" "tahoe"   "dusk"    "mesh"    "aurora"  "harbor"  "grove"  
glass_scenes()[["aurora"]]
#> [1] "Aurora veil"
```
