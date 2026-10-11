# Changelog

## shinyglass 0.5.0

CRAN release: 2026-10-11

### Mobile-ready

- On a coarse pointer, the controls Playwright measures are at least
  44px. That set is the theme toggle, the sidebar collapse toggle, nav
  tabs, modal close, text inputs, selects and selectize, the file Browse
  button, DataTables and reactable pagination, popover triggers, card
  expand, and the hit area on
  [`actionLink()`](https://rdrr.io/pkg/shiny/man/actionButton.html) and
  [`downloadLink()`](https://rdrr.io/pkg/shiny/man/downloadButton.html).
  Checkbox and radio rows are at least 44px tall; the marks stay about
  18px. Slider thumbs keep their size and use a 44px hit area. Harbor
  notes also checks the send button, edit button, composer, sidebar
  toggle, sources button, history row, scroll-to-bottom, the thinking
  disclosure, source-pill hit area, and the sources close button.
- A popover on a coarse pointer at 393x852 closes on a second tap of its
  trigger and on a tap outside. On a 390x852 touch viewport, the Harbor
  notes sidebar toggle and close button both respond. The sources
  offcanvas opens from its button and closes from its close button; on a
  coarse pointer that button is at least 44px.
- Phone widths do not add a horizontal page scroll bar. Harbor notes
  stays within 2px at 390x844 and 393x852. The dashboard and Olympics
  fixtures at 480px stay within 1px. `html` and `body` use
  `overflow-x: clip`.
- Playwright runs these checks at iPhone sizes (393x852 and 390x852,
  with touch). The five hosted demos are also opened with the iPhone 16
  profile at 393x852. That run expects no preview toggle, no embedded
  frame, and one Shiny session.

### Breaking changes

- The default intensity is `0.5`, Apple’s midpoint between Ultra Clear
  and Tinted (previously `0.45`). Apps that do not set `intensity` look
  slightly more tinted, with a stronger rim, lip, and edge and a
  narrower, more even blur range. Colored edge tokens
  (`--glass-refract-a`, `--glass-refract-b`) and the backdrop brightness
  and contrast boosts scale with intensity.
- Specular highlights are static top and bottom bands. Pointer tracking
  and the ambient specular drift are gone. `specular = TRUE` still
  paints the highlights. `specular = FALSE` hides them. iOS 27 does not
  tilt glass. Pointer tracking is not available in 0.5.0.
- In dark mode the top highlight is a 1px rim plus a short sheen (about
  8–12px). A tall sidebar or card no longer grows a white band over its
  title.
- Dark value boxes use an opaque plate, and a Leaflet map clips its
  tiles, so a bright neighbor cannot wash out the number.
- Dark table headers use a near-black backing so a light-grey header
  label stays readable. ApexCharts axis text and gridlines follow the
  dark ink.
- On a coarse pointer, the Light / Dark / Auto segmented control stays
  one row, 44px tall, at its normal width.
- Glass edges are darker, and diffusion is more even across chrome and
  content. Fill alphas are unchanged.
- Chromium bends the backdrop through a convex squircle lens (index of
  refraction about 1.5, flat interior, bend concentrated at the rim,
  subtle chromatic dispersion). Safari and Firefox keep blur and tint.
  `refraction = FALSE` turns the lens off. Reduced transparency,
  increased contrast, forced colors, and flatten mode do the same.
- Nav pills, tabs, button groups, and the theme toggle get a
  non-interactive indicator that springs between the active item. Menus
  and popovers scale out of their trigger. `morph = FALSE` disables
  that. Click targets stay on the original controls.
- Buttons and nav links scale and rotate slightly while pressed, then
  spring back (`press = TRUE`). Reduced motion skips the spring.
- Tab bars and nav pills shrink while scrolling down and expand on
  scroll up or interaction (`minimize_tabs = TRUE`). Reduced motion
  keeps them full size. Navbar compact-on-scroll is still `nav_morph`.
- Icons in nav bars, tab bars, and non-primary buttons use monochrome
  clear-glass ink (`icon_style = "clear"`). Light mode uses `#1d1d1f` so
  the glyph stays above the contrast floor. Dark mode uses near-white.
  Primary buttons keep their own ink. `"color"` leaves author colors.
  `"all"` also restyles icons inside cards.
- `material = "clear"` is deprecated. Pass `intensity` instead. Existing
  calls still work: when `intensity` is omitted they map to `0.12`,
  warn, and stay clearer than the midpoint.
  `update_glass_theme(material = "clear")` and `setMaterial("clear")` do
  the same.
- These defaults load in existing apps. Layout, inputs, and click
  targets keep working. The iPadOS 26 detached sidebar is opt-in
  (`floating_sidebar = TRUE`) and off by default.
- [`vignette("migrating")`](https://ericrayanderson.github.io/shinyglass/articles/migrating.md)
  lists the visual and API changes and shows how to approximate the
  0.4.0 look.

### New features

- The installed help page `shinyglass` (also `shinyglass-package`) is
  the usage guide: a minimal app, how to add glass to an existing bslib
  or [`fluidPage()`](https://rdrr.io/pkg/shiny/man/fluidPage.html) app,
  key options, the 0.5.0 migration, and common pitfalls with their
  fixes.
  [`vignette("shinyglass")`](https://ericrayanderson.github.io/shinyglass/articles/shinyglass.md)
  is that same guide and is what `browseVignettes("shinyglass")` lists.
  Help pages state types, defaults, and minimal examples, and they
  cross-link by topic. Argument errors name the argument and the value
  to pass.
- [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md),
  [`glass_page()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page.md),
  and
  [`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)
  take `refraction`, `morph`, `press`, `scroll_edge`, `minimize_tabs`,
  `icon_style`, and `floating_sidebar`. Tokens include `--glass-ior`,
  `--glass-refraction-scale`, `--glass-dispersion`, `--glass-diffusion`,
  `--glass-specular-top`, `--glass-specular-bottom`, `--glass-edge`,
  `--glass-press-scale`, `--glass-scroll-edge-fade`,
  `--glass-minimize-scale`, and `--glass-icon-clear`.
- Scroll edge fades a uniform toolbar backing when content sits under
  floating bars (`scroll_edge = TRUE`). This is the 0.4.0 scroll-edge
  toolbar, now a theme argument.
- First-class shinyreact components.
  [`glass_page_react()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page_react.md)
  and
  [`glass_theme_dependencies()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme_dependencies.md)
  attach `inst/js/shinyglass-react.js`, an ES module (html dependency
  `shinyglass-react`) that registers `useGlassTheme`, `GlassPage`,
  `GlassSidebar`, `GlassSurface`, `GlassCard`, `GlassButton`, and the
  small layout helpers on `window.shinyglass` and as named exports. The
  module uses `window.shinyreact.React` (it does not ship a second React
  or an npm package). Paint stays on the existing `--glass-*` tokens via
  `.glass-page`, `.glass-sidebar`, `.glass-button`, and
  `.glass-surface`. `useGlassTheme()` follows mode, resolved preset,
  scene, material, and intensity, and reports `reducedTransparency`,
  `increasedContrast`, and `forcedColors`, plus refraction, morph,
  press, scroll edge, tab minimize, icon style, and floating sidebar.
  `GlassIntensitySlider` runs from Ultra Clear to Tinted (default
  `0.5`). `GlassSidebar` floats when `floating` is set or the theme opts
  in. See
  [`vignette("shinyreact")`](https://ericrayanderson.github.io/shinyglass/articles/shinyreact.md).
- shinyreact interop.
  [`glass_page_react()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page_react.md)
  passes
  [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
  as `theme` so Liquid Glass CSS is not stripped (an unnamed theme hits
  shinyreact’s no-Bootstrap page and drops the compiled stylesheet).
  [`glass_theme_dependencies()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme_dependencies.md)
  is the same asset list for `page_react_html(extra_deps = )`. Opt-in
  `.glass-surface` / `.glass-muted` follow the live light/dark packs.
  Document class rules do not cross a shadow root; `--glass-*` custom
  properties do, and `window.shinyglass.adoptShadow()` injects a
  `.glass-surface` rule into a root the client created. Example:
  `system.file("examples/shinyreact-glass", package = "shinyglass")`.
- Displacement maps are generated in `inst/js/glass-ios27.js` (not
  copied from the reference projects). The approach follows public
  `backdrop-filter: url()` lens work: Surdeddd/liquidglassjs,
  nikdelvin/liquid-glass, and archisvaze/liquid-glass.
- Compatibility fixture `inst/examples/compat-glass.R` with Playwright
  coverage in `inst/scripts/browser/compat.spec.js`. It checks common
  inputs, DT, reactable, plotly, leaflet, ggplot2, echarts4r,
  shinyWidgets, modals, tooltips, modules, dynamic UI, dark mode,
  scroll, and print under the iOS 27 defaults and with refraction
  fallback.
- Harbor notes (`inst/examples/shinychat-glass`) joins the five-app demo
  set with basics, dashboard, inputs, and Olympics. plotly + gt stays a
  local example (`inst/examples/plotly-gt-demo.R`) and stays in the
  deploy catalog, outside that five-app set. Harbor notes uses the dusk
  wallpaper, streams a local script (thinking, a tool card, and a
  citation) with no API key, and uses
  [`ellmer::chat_google_gemini()`](https://ellmer.tidyverse.org/reference/chat_google_gemini.html)
  (Gemini Flash) when `GEMINI_API_KEY` or `GOOGLE_API_KEY` is set. Each
  visitor gets 8 messages of at most 400 characters, shared with the
  phone preview. Quota and other API errors fall back to the local
  script. Live Harbor notes replies stay specific to shinyglass
  ([`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md),
  [`glass_page()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page.md),
  the intensity slider, the physics, and shinychat). Deploy key `chat`
  (`shinyglass-chat`). When `GEMINI_API_KEY` is present in the deploy
  environment, the chat bundle gets a temporary `.Renviron`.
  shinyapps.io does not accept rsconnect `envVars`. The value is not
  logged. Hosted app: [Harbor
  notes](https://ericrayanderson.shinyapps.io/shinyglass-chat/).
- shinychat 0.5
  [`page_chat()`](https://posit-dev.github.io/shinychat/r/reference/page_chat.html)
  and
  [`chat_ui()`](https://posit-dev.github.io/shinychat/r/reference/chat_ui.html)
  pick up the glass pack: full-window header and history sidebar,
  message bubbles, a floating composer, thinking panels, tool rows,
  citation chips, artifact previews, toolbars, and the slash-command
  menu. Chat replies use a neutral glass bubble, including while the
  reply is streaming. User bubbles stay the tinted pill. A scrolled
  transcript fades under the header and the composer instead of clipping
  on the bar. On a coarse pointer the send button, edit button, and
  composer are at least 44px, and the footer keeps the bottom safe-area
  inset. The typed “/” in the composer stays visible when the slash menu
  opens. Refraction, morph, press, and the scroll edge stay on. Example:
  `inst/examples/shinychat-glass` (local echo, no API key). Harbor notes
  shows a Live (Gemini) or Demo replies chip, lists citations from the
  scripted reply (and from Gemini when grounding is present), and keeps
  the theme and the conversation in the browser.
- bslib 0.12
  [`offcanvas()`](https://rstudio.github.io/bslib/reference/offcanvas.html)
  panels use the glass material, scale in from the trigger, and show a
  scroll edge on the header. Bootstrap still owns the slide.

### Demos

- The five hosted demos have a desktop phone preview (`?frame=0`, coarse
  pointer) on a wide fine-pointer screen. A phone never gets the
  control.

### Bug fixes

- On a phone, a collapsible
  [`page_sidebar()`](https://rstudio.github.io/bslib/reference/page_sidebar.html)
  or
  [`layout_sidebar()`](https://rstudio.github.io/bslib/reference/sidebar.html)
  opens as a full-height overlay. The collapse toggle stays above the
  panel and closes it, and a tap outside the panel closes it too. The
  open panel no longer wears a white band across the top in dark mode.
- A page that scrolls the window no longer flickers between the compact
  and full navbar near the scroll threshold. The height change from
  compacting moved the scroll position, which read as a scroll the other
  way. That shift is now ignored, and compacting starts 16px past the
  threshold.
- Settings menus and popovers close on a click or tap outside, and they
  have a 44px close button. Escape closes them too and returns focus to
  the control that opened them. The shinychat app menu closes on a tap
  outside the sidebar.
- Coarse pointers get a 44px hit area on glass controls, and fine
  pointers stay at least 32px. That covers buttons, the Light/Dark/Auto
  toggle, the sidebar toggle, card expand, nav tabs, modal close,
  selects, pagination, popover triggers, and
  [`actionLink()`](https://rdrr.io/pkg/shiny/man/actionButton.html) /
  [`downloadLink()`](https://rdrr.io/pkg/shiny/man/downloadButton.html).
  Those links keep their text size. Nav tabs do not scale when pressed.
- On a coarse pointer, wrapped rows of Harbor notes citation pills sit
  12px apart, so each pill keeps a 44px tap target.
- Light-mode chat replies use a thin rim and a bright top highlight, in
  the same family as the user bubble and the composer.
- Ultra Clear (intensity 0) keeps a hairline and a top specular
  highlight, including the settings strip on
  [`glass_page()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page.md).
- A card opened full screen fills the overlay. Plots and tables use the
  card, DataTables pagination sits at the bottom, and the overlay is
  frosted glass.
- Tables on glass keep an opaque body behind striped cells, including
  dark mode with `plot_surface = "clear"`, so the text does not sit on
  the wallpaper.
- [`verbatimTextOutput()`](https://rdrr.io/pkg/shiny/man/textOutput.html)
  inside a card uses the card surface, so a live values panel matches
  the cards next to it.
- shinyWidgets drop menus and bslib popovers close on a second tap and
  when you tap outside, including on touch. The Virtual Select mobile
  close button sits inside the dropdown.
- A closed single selectize field uses the whole visible control as its
  hit target.
- Accessibility overrides now win over the inline `--glass-*` values the
  intensity script writes. Reduce Transparency uses opaque fills and no
  backdrop blur (the same idea as flatten mode). Increase Contrast and
  forced colors are watched live. The page sets `data-glass-contrast`,
  `data-glass-forced-colors`, and `data-glass-reduced-transparency` on
  `<html>`, and matching CSS rules use `!important`.
- [`bslib::input_dark_mode()`](https://rstudio.github.io/bslib/reference/input_dark_mode.html)
  switches the glass pack when it writes `data-bs-theme`.
- Leaflet popups are not clipped by the map frame, and plotly hover
  stays above the card sheen.
- shinyWidgets `materialSwitch()` gets a 24px hit target so the knob
  stays inside glass cards and accepts clicks.
- Tooltips do not capture pointer events, so a hint over the next
  control does not block the click.

## shinyglass 0.4.0

CRAN release: 2026-09-21

### New features

- `glass_theme(plot_surface = "opaque")` densifies plot, plotly, gt, and
  DT hosts (~94% panel fill, readable ink) while chrome stays Liquid
  Glass. Default `"clear"` keeps wallpaper show-through. Toggle live
  with
  [`glass_plot_surface_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_surface_input.md),
  `update_glass_theme(plot_surface = )`,
  `window.shinyglass.setPlotSurface()`, or `.glass-plot-surface-opaque`.
  [`theme_glass()`](https://ericrayanderson.github.io/shinyglass/reference/theme_glass.md),
  [`plotly_glass()`](https://ericrayanderson.github.io/shinyglass/reference/plotly_glass.md),
  and
  [`gt_theme_glass()`](https://ericrayanderson.github.io/shinyglass/reference/gt_theme_glass.md)
  accept `surface = "opaque"`.
  [`dt_options_glass()`](https://ericrayanderson.github.io/shinyglass/reference/dt_options_glass.md)
  is an optional DT helper.
- Named wallpaper scenes `aurora`, `harbor`, and `grove` join `tahoe` /
  `dusk` / `mesh`.
  [`glass_scenes()`](https://ericrayanderson.github.io/shinyglass/reference/glass_scenes.md)
  /
  [`glass_scene_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_scene_input.md)
  list and switch them. User `wallpaper=` photos are blurred and washed
  (`--glass-wallpaper-wash`) so body ink stays above the contrast floor
  (4.5:1 text / 3:1 large chrome).
- Flatten mode for print, PDF, chromote, and screenshots:
  [`glass_flatten()`](https://ericrayanderson.github.io/shinyglass/reference/glass_flatten.md),
  `glass_theme(flatten = )`,
  [`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md),
  `window.shinyglass.setFlatten()` / `.enterFlatten()` /
  `.exitFlatten()`, and `?glass_flatten=1`. `@media print` does the same
  automatically.
- Public `--glass-*` tokens:
  [`glass_css_tokens()`](https://ericrayanderson.github.io/shinyglass/reference/glass_css_tokens.md),
  [`glass_token_pack()`](https://ericrayanderson.github.io/shinyglass/reference/glass_token_pack.md),
  [`glass_add_tokens()`](https://ericrayanderson.github.io/shinyglass/reference/glass_add_tokens.md),
  `glass_theme(tokens = )`, and `update_glass_theme(tokens = )` /
  `window.shinyglass.setTokens()`.

### Improvements

- Closer to shipping iOS 27 Liquid Glass: darker outer lip / side stroke
  and a slightly stronger border, brighter rim and specular, unchanged
  fill alphas and default intensity (`0.45`). Dark bslib sidebars keep
  rim/lip/side-stroke edges instead of a shadow-only look.
- Stronger scroll-edge toolbar (`body.glass-scroll-edge`) when content
  sits under floating nav. Contrast-only: stays on under
  `prefers-reduced-motion`; `prefers-reduced-transparency` still forces
  Tinted.
- Deeper bslib Liquid Glass for `page_navbar` / navsets, nested cards
  and value boxes, sidebars, accordion, tooltips/popovers, and modals.
  Focus-visible rings and overlay stacking (tooltip 1090, popover 1085,
  menus 1080) apply to every
  [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
  app.
- Layout polish: page-level horizontal overflow is clipped so wide DT /
  gt / plotly hosts scroll inside the card; DT tables use fixed layout
  and wrapping headers at ~1280px; theme switches hide stale ggplot ink
  and snap plotly axis text to the live pack.
- Overlay menus escape glass containment: shinyWidgets Virtual Select
  defaults to a body portal (`zIndex = 1080`) unless the app sets those
  options.
- Narrow (≤480px) CSS for stacked controls, wrapping nav, full-width
  value boxes, and core demo containment.
- In-app intensity control is documented as the web stand-in for iOS 27
  Settings → Appearance → Liquid Glass (browsers cannot read the OS
  slider).
- Experimental Python package (not in the CRAN tarball) now takes
  intensity, `plot_surface`, scenes, flatten, persist, and JS knobs on
  [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md).

### Bug fixes

- [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
  no longer errors when `scene` is the default name vector (R 4.4+ `&&`
  length check) or a subset of scene names.
- User `tokens=` stay distinct from the compiled Sass pack (empty
  overrides no longer inject `glass_bg` as a public CSS token).

## shinyglass 0.3.0

CRAN release: 2026-09-09

### New features

- Remember glass: `glass_theme(persist = TRUE)` stores preset,
  intensity, accent, material, and scene in `localStorage` per app path.
- [`theme_glass()`](https://ericrayanderson.github.io/shinyglass/reference/theme_glass.md),
  [`plotly_glass()`](https://ericrayanderson.github.io/shinyglass/reference/plotly_glass.md),
  and
  [`gt_theme_glass()`](https://ericrayanderson.github.io/shinyglass/reference/gt_theme_glass.md)
  match plot and table ink to the resolved light/dark pack.
  [`glass_plot_colors()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_colors.md)
  exposes the palette.
- iOS-style
  [`glass_accent_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_accent_input.md)
  wells (blue / purple / pink / orange / green / teal). Named colors
  like `primary = "purple"` are accepted.
- [`glass_page()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page.md)
  /
  [`observe_glass()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass.md)
  assemble theme + toggle + intensity + accent in one call. Persistence
  defaults to on.
- Named wallpaper scenes (`tahoe`, `dusk`, `mesh`) and optional photo
  `wallpaper =`.
  [`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)
  can change `material`, `ambient_motion`, and `scene` live.
- `glass_theme(ambient_motion = FALSE)` disables decorative ambient
  animation independently of pointer highlights and navbar motion.

### Improvements

- Golden Gate material: 90° top highlight, light top/bottom strokes with
  darker side edges, richer wallpaper orbs, and denser chrome when
  content scrolls underneath.
- High-contrast (`prefers-contrast: more`) and Windows forced-colors
  surfaces. Reduced-motion and reduced-transparency follow the OS live.
- Intensity sliders validate bounds and steps; multiple controls
  synchronize, including dynamically inserted and module-namespaced
  inputs.
- Visible focus rings and slider value announcements when the label is
  hidden.
- Faster client updates: inspect changed DOM subtrees, coalesce widget
  styling, cache unchanged image tint samples, skip unrelated text
  outputs, and cap pointer highlights at one per frame.

### Bug fixes

- Olympics subtitle no longer shows raw HTML; favicon points at the
  shipped `rings.jpg`.
- Auto mode tracks OS theme from the first paint; dynamically inserted
  intensity sliders bind correctly.
- [`theme_glass()`](https://ericrayanderson.github.io/shinyglass/reference/theme_glass.md)
  uses grid-safe colors (ggplot2 cannot paint CSS `rgba()`).

## shinyglass 0.2.0

CRAN release: 2026-08-21

### Breaking changes

- Light and dark glass surfaces are now dual **CSS custom-property
  packs** on `[data-glass-preset]`. Switching preset no longer requires
  recompiling Sass or reloading the page. Apps that overrode Sass-only
  `$glass-*` tokens should target `--glass-*` CSS variables (or
  `[data-glass-preset="dark"]`) instead.
- [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
  always builds on the Bootstrap 5 base theme (not Bootswatch `darkly`
  for dark). Dark appearance comes from the CSS variable pack so
  light↔︎dark can toggle live. Visuals should match 0.1.x closely; if you
  relied on darkly-specific chrome outside glass surfaces, re-check dark
  mode.
- Private escape hatch `window.__shinyglassDisableTint` still works, but
  the supported API is `glass_theme(tint = FALSE)` /
  `update_glass_theme(tint = …)`.

### New features

- Light / Dark / Auto is an iOS-style segmented control: theme-aware
  glass thumb (changes in light vs dark), body ink on every chip, and a
  delegated click so Auto applies even when host pages rewrite inline
  handlers.

- Theme toggle applies the preset once (no inline handler + server echo
  storm), so plots no longer flicker when switching Light / Dark.

- Default
  [`actionButton()`](https://rdrr.io/pkg/shiny/man/actionButton.html) /
  `.btn-link` ink follows theme tokens (`--glass-body-color` /
  `--glass-accent`) instead of compiled `$primary`.

- \[glass_resolved_preset()\] reports the resolved light/dark appearance
  so plots do not stay light-inked when the user picks Auto.

- Dark pack no longer re-locks default / outline / download labels to
  compiled `$primary`. Download links and ghost focus rings follow
  `--glass-accent`. Accent `<select id="accent">` applies `setPrimary`
  immediately.

- \[glass_intensity_slider()\] / \[observe_glass_intensity()\]: iOS
  27-style **Ultra Clear → Tinted** control. `glass_theme(intensity = )`
  sets the starting value (`0`–`1`, default `0.45`);
  \[update_glass_theme()\] and `window.shinyglass.setIntensity()` update
  it live.

- \[glass_preset_input()\] / \[observe_glass_preset_input()\]:
  client-first Light/Dark/Auto select (applies `setPreset` immediately;
  server sync is optional). Prefer this over a bare
  [`selectInput()`](https://rdrr.io/pkg/shiny/man/selectInput.html) +
  [`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)
  alone on hosts that rewrite custom messages.

- Theme delivery is dual-channel (`shinyglass` + legacy `glassPreset`)
  with a self-healing `oncustommessage` proxy so
  preset/intensity/showModal survive host message rewrites
  (e.g. shinyapps.io).

- Demo app `intensity-slider-demo.R`; live
  [shinyglass-demo](https://ericrayanderson.shinyapps.io/shinyglass-demo/)
  and
  [shinyglass-dashboard](https://ericrayanderson.shinyapps.io/shinyglass-dashboard/)
  ship
  [`glass_intensity_slider()`](https://ericrayanderson.github.io/shinyglass/reference/glass_intensity_slider.md)
  in the UI.

- iOS 27 material polish: stronger darkened edges, brighter specular
  highlights, intensity-scaled fill/blur for clearer layer separation
  and readability.

- Dark-mode nav tab ink keeps WCAG UI 3:1 on glass (inactive tabs).

- Closer iOS 27 Liquid Glass: defined borders (not shadow-only),
  chromatic edge refraction cues, lighter dark-mode glass, thicker
  elevated chrome, ambient specular drift + pointer override, stronger
  diffusion blur defaults (`blur = 36`, `saturation = 200`).

- Runtime light/dark switching via
  `document.documentElement.dataset.glassPreset` without a full reload.

- `glass_theme(preset = "auto")` follows `prefers-color-scheme` and
  updates when the OS theme changes.

- \[update_glass_theme()\] to change `preset`, `tint`, and **`primary`**
  (live accent via `--glass-accent` / `--bs-primary`) from the server.
  Recolors primary buttons, Shiny
  [`checkboxInput()`](https://rdrr.io/pkg/shiny/man/checkboxInput.html)
  / radios / switches, ion.rangeSlider bars, value chips, and active
  nav/list items without a Sass recompile.

- \[glass_theme_toggle()\] / \[observe_glass_theme_toggle()\] drop-in
  Light / Dark / Auto buttons.

- Behavior knobs on \[glass_theme()\]: `tint`, `specular`, and
  `nav_morph` (all default `TRUE`, matching 0.1.x JS behavior).

- Client helpers: `window.shinyglass.setPreset()` / `.getPreset()` /
  `.setTint()` / `.setPrimary()` / `.getPrimary()`.

### Improvements

- Liquid Glass material fidelity (Tahoe / iOS 26 inspired): multi-layer
  surfaces (illumination fill, dual-edge rim/lip, ambient + pointer
  specular), chrome vs content hierarchy (less glass-on-glass), softer
  wallpaper orbs, larger concentric radii, capsule-leaning controls.

- New `glass_theme(material = "regular"|"clear")`. Clear is more
  transparent for media-rich layouts. Defaults: `blur = 36`,
  `radius = "1.5rem"`, `saturation = 200`.

- Value boxes are tinted glass (theme-color wash + body ink), not solid
  `.bg-*` slabs. Plots and DT/gt hosts inside cards drop the extra glass
  frame so page orbs show through (`renderPlot(bg = "transparent")` in
  bundled demos).

- DataTables / Bootstrap pagination chips: style the visible
  `.page-link` surface (DT uses `<li.paginate_button><a.page-link>`).
  Fixes solid black page numbers and light-grey ellipsis chips in dark
  mode on the dashboard demo / README screenshots.

- Overlay chrome (datepicker popup, Shiny notification types, generic
  accordion, Bootstrap tooltip/popover/toast, `.btn-close`, file Browse
  chip) now uses the glass menu pack so dark mode is not leftover
  Bootstrap light hex. Datepicker is hoisted to `document.body` (Shiny
  1.14 `bsDatepicker`) so card/navbar `backdrop-filter` no longer clips
  the calendar. Navbar overflow is visible so `nav_menu` dropdowns
  escape the glass bar. Kitchen-sink example: `chrome-kitchen-sink.R`
  (`page_navbar`, `nav_menu`,
  [`showModal()`](https://rdrr.io/pkg/shiny/man/showModal.html), all
  four
  [`showNotification()`](https://rdrr.io/pkg/shiny/man/showNotification.html)
  types).

- Visual QA harness: `inst/scripts/audit-glass-contrast.R` (+ `.js`)
  runs a dual-theme computed-style audit (low contrast, solid-black
  chips, Bootstrap light greys in dark, dark ink on accent, DT
  pagination structure) across demo / dashboard / inputs-gallery /
  chrome kitchen-sink. Opens datepicker, navbar menu, notifications,
  accordion, tooltip/popover, and server modal before sampling.
  Checklist and definition of done in `inst/scripts/VISUAL-QA.md`.

- Selectize fields: force body/menu ink on inputs and multi-select tags
  (selectize default near-black item text failed dark mode); opaque
  `--glass-menu-bg` fills in dark; dropdown options use menu colors.

- Ecosystem chrome: **plotly** modebar + frame, **gt** tables,
  **waiter** / shinybusy overlays, **shinyalert**/SweetAlert2 popups,
  denser **shinydashboardPlus** controlbar/dropdowns/user menu, light
  **rhandsontable** / echarts/highcharter hosts. Examples:
  `plotly-gt-demo.R`, `shinydashboardPlus-glass-demo.R`.

- plotly + gt stays a local example (`plotly-gt-demo.R`). README
  light/dark screenshots for plotly+gt. The hosted copy is archived.

- CI workflow `visual-qa` (testthat + dual-theme contrast audit) and
  committed `inst/scripts/audit-baseline.json`.

- Navbar brand / page title ink uses `--glass-body-color` (no more white
  brand on light glass). Plotly hosts no longer clip x-axis titles.

- Active-on-accent contrast: lower Bootstrap `$min-contrast-ratio` to
  **3** so `color-contrast()` picks white on brand blues/purples (white
  on `#007AFF` is ~4.02:1 and failed the old 4.5 gate). Solid `.bg-*` /
  `.text-bg-*` fills (including `bslib::value_box(theme=)`) get
  luminance-based ink via `glass-on()` / `--glass-on-*`, not body color
  on solid primary. Safety nets remain for checks, radios, switches,
  pagination, and list-group active.

- Accent rules target Shiny markup (`.shiny-input-checkbox`) as well as
  Bootstrap `.form-check-input`.

- Plot / image outputs get a softer glass frame (lighter nesting inside
  cards).

- `prefers-reduced-motion: reduce` disables nav morph, specular, tint
  sampling, and decorative transitions (JS + CSS).

- Demo and bslib dashboard examples: theme toggle helper; dashboard
  accent select calls `update_glass_theme(primary = …)`.

- Vignettes cover migration, primary updates, toggle helper, and reduced
  motion.

- Unit tests cover dual CSS packs, head script knobs, active-color vars,
  and
  [`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)
  messaging.

### Bug fixes

- Demo app “Show smooth” draws a density curve (checkbox was previously
  ignored).
- Theme message routing hardened for hosts that rewrite Shiny custom
  messages (e.g. shinyapps.io).
- `shiny-glass.js` no longer crashes when the script loads in `<head>`
  before `document.body` exists.

## shinyglass 0.1.1

CRAN release: 2026-08-02

- Fix:
  [`bslib::sidebar()`](https://rstudio.github.io/bslib/reference/sidebar.html)
  /
  [`page_sidebar()`](https://rstudio.github.io/bslib/reference/page_sidebar.html)
  layout no longer collapses to a full-width stack. Glass
  floating-sidebar rules now win over bslib’s later `position`/`width`
  cascade, and open sidebars reserve space in main so value boxes and
  cards stay fully visible beside the chrome (not under it).
- Fix: nested
  [`layout_sidebar()`](https://rstudio.github.io/bslib/reference/sidebar.html)
  no longer double-floats. Inner sidebars keep glass styling but use
  bslib’s in-flow grid so content is not pushed into a large empty
  gutter beside a second absolute panel.
- Improve: AdminLTE chrome (classic `shinydashboard` and `bs4Dash`) gets
  stronger glass overlay: translucent header/sidebar, soft-tinted
  value/info boxes, and clearer menu active states, without breaking
  AdminLTE layout.

## shinyglass 0.1.0

CRAN release: 2026-07-28

- Initial release.
- [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
  returns a [bslib](https://rstudio.github.io/bslib/) theme with Liquid
  Glass styling for [shiny](https://shiny.posit.co/) apps: translucent
  surfaces, backdrop blur, soft depth, and system typography.
- Light and dark presets, with options for accent color, blur,
  saturation, and corner radius.
- Works with
  [`fluidPage()`](https://rdrr.io/pkg/shiny/man/fluidPage.html),
  [`navbarPage()`](https://rdrr.io/pkg/shiny/man/navbarPage.html),
  [`bslib::page_sidebar()`](https://rstudio.github.io/bslib/reference/page_sidebar.html),
  and other page functions that accept a bslib theme. Pass the theme via
  `theme = glass_theme()`, or for
  [teal](https://insightsengineering.github.io/teal/) apps via
  `options(teal.bs_theme = glass_theme())`.
- Styles common Bootstrap and Shiny surfaces (cards, navbars, sidebars,
  inputs, tables, plots, modals) and holds up on denser UIs such as
  leaflet maps, DT, shinyWidgets, bs4Dash, and teal filter panels.
