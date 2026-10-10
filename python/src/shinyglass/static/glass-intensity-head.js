/* Concatenated into the preset head script. Uses in-scope `root` and `intensity`.
   Keep this free of closing script tags. Endpoint numbers match shiny-glass.js. */
try {
  if (window.matchMedia("(prefers-reduced-transparency: reduce)").matches) {
    root.dataset.glassReducedTransparency = "reduce";
  }
  if (window.matchMedia("(prefers-contrast: more)").matches) {
    root.dataset.glassContrast = "more";
  }
  if (window.matchMedia("(forced-colors: active)").matches) {
    root.dataset.glassForcedColors = "active";
  }
} catch (e) {}
(function (root, t) {
  var preset = root.dataset.glassPreset || "light";
  var light = preset !== "dark";
  var c = light
    ? {bgA:0.12,bgHoverA:0.20,contentA:0.18,contentHoverA:0.26,borderA:0.72,rimA:0.94,lipA:0.24,highlightA:1,specularA:0.90,edgeSheenA:0.62,innerGlowA:0.28,menuA:0.74,blurScale:1.08,refractA:0.10,refractB:0.06,brightness:1.02,contrast:1.02}
    : {bgA:0.08,bgHoverA:0.14,contentA:0.08,contentHoverA:0.12,borderA:0.42,rimA:0.60,lipA:0.64,highlightA:0.48,specularA:0.56,edgeSheenA:0.34,innerGlowA:0.16,menuA:0.66,blurScale:1.08,refractA:0.08,refractB:0.06,brightness:1.02,contrast:1.02};
  var d = light
    ? {bgA:0.48,bgHoverA:0.62,contentA:0.56,contentHoverA:0.68,borderA:0.98,rimA:1,lipA:0.42,highlightA:1,specularA:1,edgeSheenA:0.88,innerGlowA:0.48,menuA:0.94,blurScale:1.14,refractA:0.28,refractB:0.18,brightness:1.06,contrast:1.06}
    : {bgA:0.24,bgHoverA:0.32,contentA:0.20,contentHoverA:0.28,borderA:0.68,rimA:0.86,lipA:0.92,highlightA:0.72,specularA:0.82,edgeSheenA:0.52,innerGlowA:0.26,menuA:0.92,blurScale:1.14,refractA:0.22,refractB:0.16,brightness:1.06,contrast:1.06};
  function L(k) { return c[k] + (d[k] - c[k]) * t; }
  function rgba(r, g, b, a) {
    return "rgba(" + Math.round(r) + ", " + Math.round(g) + ", " + Math.round(b) + ", " + a.toFixed(4) + ")";
  }
  var menu = light ? {r:255,g:255,b:255} : {r:58,g:58,b:60};
  var ra = light ? {r:120,g:200,b:255} : {r:100,g:200,b:255};
  var rb = light ? {r:255,g:140,b:200} : {r:220,g:140,b:255};
  root.style.setProperty("--glass-bg", rgba(255, 255, 255, L("bgA")));
  root.style.setProperty("--glass-bg-hover", rgba(255, 255, 255, L("bgHoverA")));
  root.style.setProperty("--glass-bg-content", rgba(255, 255, 255, L("contentA")));
  root.style.setProperty("--glass-bg-content-hover", rgba(255, 255, 255, L("contentHoverA")));
  root.style.setProperty("--glass-border", rgba(255, 255, 255, L("borderA")));
  root.style.setProperty("--glass-rim", rgba(255, 255, 255, L("rimA")));
  root.style.setProperty("--glass-lip", rgba(0, 0, 0, L("lipA")));
  root.style.setProperty("--glass-highlight", rgba(255, 255, 255, L("highlightA")));
  root.style.setProperty("--glass-specular", rgba(255, 255, 255, L("specularA")));
  root.style.setProperty("--glass-edge-sheen", rgba(255, 255, 255, L("edgeSheenA")));
  root.style.setProperty("--glass-inner-glow", rgba(255, 255, 255, L("innerGlowA")));
  root.style.setProperty("--glass-menu-bg", rgba(menu.r, menu.g, menu.b, L("menuA")));
  root.style.setProperty("--glass-refract-a", rgba(ra.r, ra.g, ra.b, L("refractA")));
  root.style.setProperty("--glass-refract-b", rgba(rb.r, rb.g, rb.b, L("refractB")));
  root.style.setProperty("--glass-refract-brightness", L("brightness").toFixed(4));
  root.style.setProperty("--glass-refract-contrast", L("contrast").toFixed(4));
  root.style.setProperty("--glass-blur", "calc(var(--glass-blur-base, 36px) * " + L("blurScale").toFixed(4) + ")");
})(root, intensity);
