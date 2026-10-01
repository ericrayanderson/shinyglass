const {
  React,
  ReactDOM,
  useShinyInput,
  useShinyOutputValue,
  useShinyInitialized,
  ShinyOutput,
} = window.shinyreact;

const {
  useGlassTheme,
  GlassPage,
  GlassMain,
  GlassSidebar,
  GlassSurface,
  GlassStack,
  GlassButton,
  GlassTitle,
  GlassMuted,
  GlassRange,
} = window.shinyglass;

const h = React.createElement;

const SCENES = ["tahoe", "dusk", "mesh", "aurora", "harbor", "grove"];
const MODES = ["light", "dark", "auto"];

function ShadowNote() {
  const ref = React.useRef(null);
  React.useEffect(() => {
    const host = ref.current;
    if (!host || host.shadowRoot) return;
    const shadow = host.attachShadow({ mode: "open" });
    if (window.shinyglass && window.shinyglass.adoptShadow) {
      window.shinyglass.adoptShadow(shadow);
    }
    const card = document.createElement("p");
    card.className = "glass-surface";
    card.id = "shadow-card";
    card.textContent = "This panel is inside an open shadow root.";
    shadow.appendChild(card);
  }, []);
  return h("div", { id: "shadow-host", ref: ref });
}

function App() {
  const ready = useShinyInitialized();
  const theme = useGlassTheme();
  const [bins, setBins] = useShinyInput("bins", 20);
  const [showExtra, setShowExtra] = useShinyInput("show_extra", false);
  const caption = useShinyOutputValue("caption", null);
  const extra = useShinyOutputValue("extra", null);

  if (!ready) {
    return h(GlassMuted, { id: "booting" }, "Connecting…");
  }

  return h(
    GlassPage,
    { id: "app" },
    h(
      GlassSidebar,
      { id: "controls" },
      h(GlassTitle, { id: "title" }, "Liquid Glass"),
      h("label", { htmlFor: "bins" }, "Number of bins"),
      h(
        GlassStack,
        null,
        h(GlassRange, {
          id: "bins",
          min: 5,
          max: 40,
          value: bins,
          onChange: (e) => setBins(Number(e.target.value)),
        }),
        h("output", { id: "bins-value", htmlFor: "bins" }, String(bins))
      ),
      h(GlassMuted, { id: "caption" }, caption || "Waiting for the server…"),
      h(
        GlassStack,
        { id: "presets" },
        MODES.map((mode) =>
          h(
            GlassButton,
            {
              key: mode,
              id: "preset-" + mode,
              variant: theme.mode === mode ? "primary" : "secondary",
              pressed: theme.mode === mode,
              onClick: () => theme.setMode(mode),
            },
            mode
          )
        )
      ),
      h(
        GlassStack,
        { id: "scenes" },
        SCENES.map((name) =>
          h(
            GlassButton,
            {
              key: name,
              id: "scene-" + name,
              variant: "secondary",
              pressed: theme.scene === name,
              onClick: () => theme.setScene(name),
            },
            name
          )
        )
      ),
      h(
        GlassButton,
        {
          id: "toggle-extra",
          variant: "secondary",
          onClick: () => setShowExtra(!showExtra),
        },
        showExtra ? "Hide dynamic region" : "Show dynamic region"
      ),
      showExtra ? h(GlassMuted, { id: "extra" }, extra || "Asking the server…") : null,
      h(
        GlassMuted,
        { id: "preset-readout" },
        "mode " +
          theme.mode +
          ", resolved " +
          theme.preset +
          ", scene " +
          theme.scene +
          ", material " +
          theme.material +
          ", intensity " +
          Number(theme.intensity).toFixed(2)
      )
    ),
    h(
      GlassMain,
      null,
      h(
        GlassSurface,
        { id: "plot-card" },
        h(ShinyOutput, {
          id: "dist",
          className: "shiny-plot-output glass-plot",
        })
      ),
      h(ShadowNote)
    )
  );
}

const root = ReactDOM.createRoot(
  document.body.appendChild(document.createElement("div"))
);
root.render(h(App));
