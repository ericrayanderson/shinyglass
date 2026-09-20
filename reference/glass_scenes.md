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
glass_theme(scene = "aurora")
#> /* Sass Bundle: _utilities, _root, _reboot, _type, _images, _containers, _grid, _tables, _forms, _buttons, _transitions, _dropdown, _button-group, _nav, _navbar, _card, _accordion, _breadcrumb, _pagination, _badge, _alert, _progress, _list-group, _close, _toasts, _modal, _tooltip, _popover, _carousel, _spinners, _offcanvas, _placeholders, _helpers, _api, bs3compat */
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_functions.scss";
#> @import "/home/runner/work/_temp/Library/bslib/bslib-scss/functions.scss";
#> $glass-bg: rgba(255, 255, 255, 0.22) !default;
#> $glass-bg-hover: rgba(255, 255, 255, 0.36) !default;
#> $glass-border: rgba(255, 255, 255, 0.62) !default;
#> $glass-shadow: rgba(0, 0, 0, 0.10) !default;
#> $glass-elevated-shadow: rgba(0, 0, 0, 0.16) !default;
#> $glass-blur: 36px !default;
#> $glass-saturate: 200% !default;
#> $glass-radius: 1.5rem !default;
#> $glass-highlight: rgba(255, 255, 255, 0.88) !default;
#> $glass-specular: rgba(255, 255, 255, 0.55) !default;
#> $glass-menu-bg: rgba(255, 255, 255, 0.86) !default;
#> $glass-menu-color: #1d1d1f !default;
#> $glass-page-bg: linear-gradient(160deg, #eef1f8 0%, #f5f5f7 42%, #ebe8f4 78%, #e6eef8 100%) !default;
#> $glass-orb-1: rgba(0, 122, 255, 0.18) !default;
#> $glass-orb-2: rgba(175, 82, 222, 0.12) !default;
#> $glass-orb-3: rgba(90, 200, 250, 0.14) !default;
#> $body-bg: #f2f2f7 !default;
#> $body-color: #1d1d1f !default;
#> $font-family-sans-serif: -apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Segoe UI", Roboto, Helvetica, Arial, sans-serif !default;
#> $border-radius: 1.1rem !default;
#> $border-radius-lg: 1.5rem !default;
#> $border-radius-sm: 0.85rem !default;
#> $card-border-width: 1px !default;
#> $card-border-color: rgba(255, 255, 255, 0.62) !default;
#> $input-border-color: rgba(255, 255, 255, 0.62) !default;
#> $navbar-padding-y: 0.75rem !default;
#> $btn-font-weight: 600 !default;
#> $btn-font-size: 0.9375rem !default;
#> $btn-line-height: 1.2 !default;
#> $btn-padding-y: .55rem !default;
#> $btn-padding-x: 1.2rem !default;
#> $btn-border-width: 1px !default;
#> $min-contrast-ratio: 3 !default;
#> $component-active-color: #ffffff !default;
#> $form-check-input-checked-color: #ffffff !default;
#> $form-check-input-indeterminate-color: #ffffff !default;
#> $form-switch-checked-color: #ffffff !default;
#> $pagination-active-color: #ffffff !default;
#> 
#> $primary: #007AFF !default;
#> $enable-cssgrid: true !default;
#> @import "/home/runner/work/_temp/Library/bslib/bs3compat/_defaults.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_variables.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_variables-dark.scss";
#> $bootstrap-version: 5;
#> $bslib-preset-name: null !default;
#> $bslib-preset-type: null !default;
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_maps.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_mixins.scss";
#> @import "/home/runner/work/_temp/Library/bslib/bs3compat/_declarations.scss";
#> :root {
#> --bslib-bootstrap-version: #{$bootstrap-version};
#> --bslib-preset-name: #{$bslib-preset-name};
#> --bslib-preset-type: #{$bslib-preset-type};
#> }
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/mixins/_banner.scss";
#> @include bsBanner('')
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_utilities.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_root.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_reboot.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_type.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_images.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_containers.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_grid.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_tables.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_forms.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_buttons.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_transitions.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_dropdown.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_button-group.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_nav.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_navbar.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_card.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_accordion.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_breadcrumb.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_pagination.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_badge.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_alert.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_progress.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_list-group.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_close.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_toasts.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_modal.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_tooltip.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_popover.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_carousel.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_spinners.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_offcanvas.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_placeholders.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/_helpers.scss";
#> @import "/home/runner/work/_temp/Library/bslib/lib/bs5/scss/utilities/_api.scss";
#> .table th[align=left] { text-align: left; }
#> .table th[align=right] { text-align: right; }
#> .table th[align=center] { text-align: center; }
#> @import "/home/runner/work/_temp/Library/bslib/bs3compat/_rules.scss";
#> @import "/home/runner/work/_temp/Library/bslib/bslib-scss/bslib.scss";
#> @import "/home/runner/work/_temp/Library/shinyglass/scss/glass.scss";
#> /* *** */
#> 
#> Other Sass Bundle information:
#> List of 2
#>  $ html_deps       :List of 3
#>   ..$ :List of 10
#>   .. ..$ name      : chr "bs3compat"
#>   .. ..$ version   : chr "0.12.0"
#>   .. ..$ src       :List of 1
#>   .. .. ..$ file: chr "bs3compat/js"
#>   .. ..$ meta      : NULL
#>   .. ..$ script    : chr [1:3] "transition.js" "tabs.js" "bs3compat.js"
#>   .. ..$ stylesheet: NULL
#>   .. ..$ head      : NULL
#>   .. ..$ attachment: NULL
#>   .. ..$ package   : chr "bslib"
#>   .. ..$ all_files : logi TRUE
#>   .. ..- attr(*, "class")= chr "html_dependency"
#>   ..$ :List of 10
#>   .. ..$ name      : chr "shinyglass-preset"
#>   .. ..$ version   : chr "0.3.0.9000"
#>   .. ..$ src       :List of 1
#>   .. .. ..$ file: chr "/home/runner/work/_temp/Library/shinyglass/js"
#>   .. ..$ meta      : NULL
#>   .. ..$ script    : NULL
#>   .. ..$ stylesheet: NULL
#>   .. ..$ head      : chr "<script>(function(){var p=\"light\";var intensity=0.4500;var prim=\"#007AFF\";var material=\"regular\";var plot"| __truncated__
#>   .. ..$ attachment: NULL
#>   .. ..$ package   : NULL
#>   .. ..$ all_files : logi FALSE
#>   .. ..- attr(*, "class")= chr "html_dependency"
#>   ..$ :List of 10
#>   .. ..$ name      : chr "shinyglass"
#>   .. ..$ version   : chr "0.3.0.9000"
#>   .. ..$ src       :List of 1
#>   .. .. ..$ file: chr "/home/runner/work/_temp/Library/shinyglass/js"
#>   .. ..$ meta      : NULL
#>   .. ..$ script    : chr "shiny-glass.js"
#>   .. ..$ stylesheet: NULL
#>   .. ..$ head      : NULL
#>   .. ..$ attachment: NULL
#>   .. ..$ package   : NULL
#>   .. ..$ all_files : logi FALSE
#>   .. ..- attr(*, "class")= chr "html_dependency"
#>  $ file_attachments: Named chr "/home/runner/work/_temp/Library/bslib/lib/bs3/assets/fonts"
#>   ..- attr(*, "names")= chr "fonts"
```
