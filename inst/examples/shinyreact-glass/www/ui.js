const {
  React,
  ReactDOM,
  useShinyInput,
  useShinyOutputValue,
  useShinyInitialized,
  ShinyOutput,
} = window.shinyreact;

const h = React.createElement;

function setPreset(mode) {
  if (window.shinyglass && window.shinyglass.setPreset) {
    window.shinyglass.setPreset(mode);
  }
}

function setScene(name) {
  if (window.shinyglass && window.shinyglass.setScene) {
    window.shinyglass.setScene(name);
  }
}

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
  const [bins, setBins] = useShinyInput("bins", 20);
  const [showExtra, setShowExtra] = useShinyInput("show_extra", false);
  const caption = useShinyOutputValue("caption", null);
  const extra = useShinyOutputValue("extra", null);
  const [preset, setPresetState] = React.useState("auto");

  if (!ready) {
    return h("p", { id: "booting" }, "Connecting…");
  }

  const scenes = ["tahoe", "dusk", "mesh", "aurora", "harbor", "grove"];

  return h(
    "main",
    { className: "layout", id: "app" },
    h("h1", { id: "title" }, "Liquid Glass, React client"),
    h(
      "section",
      { className: "glass-surface", id: "controls" },
      h("label", { htmlFor: "bins" }, "Number of bins"),
      h(
        "div",
        { className: "row" },
        h("input", {
          id: "bins",
          type: "range",
          min: 5,
          max: 40,
          value: bins,
          onChange: (e) => setBins(Number(e.target.value)),
        }),
        h("output", { id: "bins-value", htmlFor: "bins" }, String(bins))
      ),
      h("p", { id: "caption", className: "glass-muted" }, caption || "Waiting for the server…"),
      h(
        "div",
        { className: "row", id: "presets" },
        ["light", "dark", "auto"].map((mode) =>
          h(
            "button",
            {
              key: mode,
              type: "button",
              className: "btn btn-primary",
              id: "preset-" + mode,
              onClick: () => {
                setPreset(mode);
                setPresetState(mode);
              },
            },
            mode
          )
        )
      ),
      h(
        "div",
        { className: "row", id: "scenes" },
        scenes.map((name) =>
          h(
            "button",
            {
              key: name,
              type: "button",
              className: "btn btn-secondary",
              id: "scene-" + name,
              onClick: () => setScene(name),
            },
            name
          )
        )
      ),
      h(
        "button",
        {
          id: "toggle-extra",
          type: "button",
          className: "btn btn-secondary",
          onClick: () => setShowExtra(!showExtra),
        },
        showExtra ? "Hide dynamic region" : "Show dynamic region"
      ),
      showExtra
        ? h("p", { id: "extra" }, extra || "Asking the server…")
        : null,
      h("p", { id: "preset-readout", className: "glass-muted" }, "Preset control: " + preset)
    ),
    h(
      "section",
      { className: "glass-surface", id: "plot-card" },
      h(ShinyOutput, {
        id: "dist",
        className: "shiny-plot-output plot-host",
      })
    ),
    h(ShadowNote)
  );
}

const root = ReactDOM.createRoot(
  document.body.appendChild(document.createElement("div"))
);
root.render(h(App));
