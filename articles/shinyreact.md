# Using shinyglass with shinyreact

shinyreact apps do not render Shiny’s tag UI. The client is `www/ui.js`,
and
[`shinyreact::page_react()`](https://posit-dev.github.io/shinyreact/r/reference/page_react.html)
drops Bootstrap unless you pass `theme`.
[`glass_page_react()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page_react.md)
does that, and it also loads the Liquid Glass React components so the
client does not need its own glass CSS.

``` r

library(shiny)
library(shinyreact)
library(shinyglass)

ui <- glass_page_react(
  theme = glass_theme(preset = "auto", scene = "tahoe"),
  title = "Liquid Glass"
)

server <- function(input, output, session) {
  output$dist <- renderPlot({
    pal <- glass_plot_colors(input = input)
    hist(faithful$waiting, col = pal$fill, border = NA)
  }, bg = "transparent")
}

shinyApp(ui, server)
```

The matching `www/ui.js` reads the components from the same global
shinyreact already uses:

``` js
const { ReactDOM, useShinyInitialized, ShinyOutput } = window.shinyreact;
const {
  useGlassTheme,
  GlassPage,
  GlassSidebar,
  GlassSurface,
  GlassButton
} = window.shinyglass;

const h = React.createElement;

function App() {
  const ready = useShinyInitialized();
  const theme = useGlassTheme();
  if (!ready) return null;
  return h(
    GlassPage,
    null,
    h(
      GlassSidebar,
      null,
      h(
        GlassButton,
        {
          variant: theme.mode === "dark" ? "primary" : "secondary",
          pressed: theme.mode === "dark",
          onClick: () => theme.setMode(theme.mode === "dark" ? "light" : "dark")
        },
        theme.mode
      )
    ),
    h(GlassSurface, null, h(ShinyOutput, { id: "dist", className: "shiny-plot-output glass-plot" }))
  );
}

ReactDOM.createRoot(document.body.appendChild(document.createElement("div"))).render(h(App));
```

A full app ships at
`system.file("examples/shinyreact-glass", package = "shinyglass")`. It
has no `www/ui.css`.

## Components

| Name | Element | Class |
|----|----|----|
| `GlassPage` | `main` | `.glass-page` |
| `GlassMain` | `div` | `.glass-main` |
| `GlassSidebar` | `aside` | `.glass-sidebar` |
| `GlassSurface` | `section` | `.glass-surface` |
| `GlassCard` | `section` | `.glass-surface.glass-card` |
| `GlassStack` | `div` | `.glass-stack` |
| `GlassButton` | `button` | `.glass-button-primary` or `.glass-button-secondary` |
| `GlassTitle` | `h1` | `.glass-title` |
| `GlassMuted` | `p` | `.glass-muted` |
| `GlassRange` | `input` | `.glass-range` |

`GlassButton` takes `variant` (`"primary"` or `"secondary"`) and
`pressed`. Primary fill follows `--glass-accent` / `--glass-on-primary`.
Secondary label ink follows `--glass-body-color`. Sidebar, card, and
page chrome use the same surface tokens as bslib cards (blur, border,
radius, shadow). Light and dark packs swap those variables, so a button
or panel written this way tracks `setPreset` without a client
stylesheet.

Plot and table hosts inside `.glass-surface`, `.glass-card`, and
`.glass-sidebar` stay transparent, same as a plot inside `.card`. Ink
for a base or ggplot graphic is still drawn on the server. Use
`glass_plot_colors(input = input)` or `glass_resolved_preset(input)` so
the R graphic follows the resolved pack. CSS variables are not available
to the graphics device.

## useGlassTheme()

The hook reads `document.documentElement` and subscribes with a
`MutationObserver`, so it sees the head script, `setPreset`, and any
other writer of the dataset.

| Field       | Meaning                                   |
|-------------|-------------------------------------------|
| `mode`      | `"light"`, `"dark"`, or `"auto"`          |
| `preset`    | Resolved pack, `"light"` or `"dark"`      |
| `scene`     | Wallpaper scene                           |
| `material`  | `"regular"` or `"clear"`                  |
| `intensity` | Number from 0 (ultra clear) to 1 (tinted) |

`setMode`, `setScene`, `setMaterial`, and `setIntensity` call the
existing `window.shinyglass` mutators. `setMode("dark")` is
`setPreset("dark")`.

## Where the module comes from

`inst/js/shinyglass-react.js` is an ES module attached as the html
dependency `shinyglass-react` (see
[`glass_react_dependency()`](https://ericrayanderson.github.io/shinyglass/reference/glass_react_dependency.md)).
[`glass_page_react()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page_react.md)
bundles it into the theme.
[`bootstrapPage()`](https://rdrr.io/pkg/shiny/man/bootstrapPage.html)
emits theme dependencies before `www/ui.js`, so the app module can
destructure `window.shinyglass` at top level. The file does not touch
`window.shinyreact` until a component renders, because the theme module
is earlier in the document than shinyreact’s deferred script.

[`glass_theme_dependencies()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme_dependencies.md)
appends the same dependency for `page_react_html(extra_deps = )`. A
plain
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
does not load it, so classic Shiny pages do not download the React file.
`page_react(theme = glass_theme())` still gets the CSS and
`shiny-glass.js`. Use
[`glass_page_react()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page_react.md),
or pass
[`glass_theme_dependencies()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme_dependencies.md),
when you want the components.

This is not published as an npm package. shinyreact’s default app has no
build, and hooks must use the single React already on
`window.shinyreact`. A package that imported `react` would load a second
copy unless every app externalized it. htmltools also serves the file at
a versioned path, so a hardcoded import in `www/ui.js` would break on
each shinyglass release. Named `export`s are there for a bundler that
can resolve the file itself. The supported no-build path is the global,
same as `window.shinyreact`.

## Shadow roots

Document class rules do not cross a shadow root. `--glass-*` custom
properties do. Call `window.shinyglass.adoptShadow(shadowRoot)` from the
component that created the root. The example does this for a note inside
the page.
