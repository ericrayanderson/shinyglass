// Liquid Glass components for shinyreact.
//
// ES module on purpose: shinyreact serves www/ui.js as type=module, and this
// file is an htmlDependency script of the same type so it can also be
// imported. It does not import "react". shinyreact's no-build client has one
// React, at window.shinyreact.React. A second copy would break hooks.
//
// Do not read window.shinyreact at module top level. glass_page_react()
// places this file in the theme dependency list, which is before shinyreact's
// deferred script. Components look up React when they render, which is after
// that script has run. www/ui.js can still read window.shinyglass.* at the
// top of the module, because this file is earlier in the document.

const api = (window.shinyglass = window.shinyglass || {});

function reactLib() {
  const React = window.shinyreact && window.shinyreact.React;
  if (!React) {
    throw new Error(
      "shinyglass React components need window.shinyreact.React. " +
        "Render them from a shinyreact page (glass_page_react())."
    );
  }
  return React;
}

function cx(...parts) {
  return parts.filter(Boolean).join(" ");
}

function omit(props, keys) {
  const out = {};
  if (!props) return out;
  for (const key of Object.keys(props)) {
    if (keys.indexOf(key) === -1) out[key] = props[key];
  }
  return out;
}

const THEME_ATTRS = [
  "data-glass-mode",
  "data-glass-preset",
  "data-glass-scene",
  "data-glass-material",
  "data-glass-intensity",
];

function readTheme() {
  const ds = document.documentElement.dataset;
  const intensity = parseFloat(ds.glassIntensity);
  return {
    mode: ds.glassMode || "light",
    preset: ds.glassPreset || "light",
    scene: ds.glassScene || "default",
    material: ds.glassMaterial || "regular",
    intensity: Number.isFinite(intensity) ? intensity : 0.45,
  };
}

function callGlass(name, value) {
  const fn = window.shinyglass && window.shinyglass[name];
  if (typeof fn === "function") fn(value);
}

export function useGlassTheme() {
  const React = reactLib();
  const [theme, setTheme] = React.useState(readTheme);
  React.useEffect(function () {
    const el = document.documentElement;
    const obs = new MutationObserver(function () {
      setTheme(readTheme());
    });
    obs.observe(el, { attributes: true, attributeFilter: THEME_ATTRS });
    setTheme(readTheme());
    return function () {
      obs.disconnect();
    };
  }, []);
  return {
    mode: theme.mode,
    preset: theme.preset,
    scene: theme.scene,
    material: theme.material,
    intensity: theme.intensity,
    setMode: function (mode) {
      callGlass("setPreset", mode);
    },
    setScene: function (name) {
      callGlass("setScene", name);
    },
    setMaterial: function (name) {
      callGlass("setMaterial", name);
    },
    setIntensity: function (value) {
      callGlass("setIntensity", value);
    },
  };
}

export function GlassPage(props) {
  const React = reactLib();
  const dom = omit(props, ["children", "className"]);
  dom.className = cx("glass-page", props && props.className);
  return React.createElement("main", dom, props && props.children);
}

export function GlassMain(props) {
  const React = reactLib();
  const dom = omit(props, ["children", "className"]);
  dom.className = cx("glass-main", props && props.className);
  return React.createElement("div", dom, props && props.children);
}

export function GlassSidebar(props) {
  const React = reactLib();
  const dom = omit(props, ["children", "className"]);
  dom.className = cx("glass-sidebar", props && props.className);
  return React.createElement("aside", dom, props && props.children);
}

export function GlassSurface(props) {
  const React = reactLib();
  const dom = omit(props, ["children", "className"]);
  dom.className = cx("glass-surface", props && props.className);
  return React.createElement("section", dom, props && props.children);
}

export function GlassCard(props) {
  const React = reactLib();
  const dom = omit(props, ["children", "className"]);
  dom.className = cx("glass-surface", "glass-card", props && props.className);
  return React.createElement("section", dom, props && props.children);
}

export function GlassStack(props) {
  const React = reactLib();
  const dom = omit(props, ["children", "className"]);
  dom.className = cx("glass-stack", props && props.className);
  return React.createElement("div", dom, props && props.children);
}

export function GlassTitle(props) {
  const React = reactLib();
  const dom = omit(props, ["children", "className"]);
  dom.className = cx("glass-title", props && props.className);
  return React.createElement("h1", dom, props && props.children);
}

export function GlassMuted(props) {
  const React = reactLib();
  const dom = omit(props, ["children", "className"]);
  dom.className = cx("glass-muted", props && props.className);
  return React.createElement("p", dom, props && props.children);
}

export function GlassButton(props) {
  const React = reactLib();
  const variant = props && props.variant === "primary" ? "primary" : "secondary";
  const pressed = props && props.pressed;
  const dom = omit(props, ["children", "className", "variant", "pressed"]);
  if (!dom.type) dom.type = "button";
  dom.className = cx(
    "glass-button",
    variant === "primary" ? "glass-button-primary" : "glass-button-secondary",
    pressed ? "is-pressed" : null,
    props && props.className
  );
  if (pressed === true) dom["aria-pressed"] = "true";
  else if (pressed === false) dom["aria-pressed"] = "false";
  return React.createElement("button", dom, props && props.children);
}

export function GlassRange(props) {
  const React = reactLib();
  const dom = omit(props, ["className"]);
  dom.type = "range";
  dom.className = cx("glass-range", props && props.className);
  return React.createElement("input", dom);
}

api.useGlassTheme = useGlassTheme;
api.GlassPage = GlassPage;
api.GlassMain = GlassMain;
api.GlassSidebar = GlassSidebar;
api.GlassSurface = GlassSurface;
api.GlassCard = GlassCard;
api.GlassStack = GlassStack;
api.GlassTitle = GlassTitle;
api.GlassMuted = GlassMuted;
api.GlassButton = GlassButton;
api.GlassRange = GlassRange;
