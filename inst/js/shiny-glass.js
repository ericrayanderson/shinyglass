(function () {
  "use strict";

  var TINT_THROTTLE_MS = 400;
  var tintTimer = null;
  var schemeMql = null;
  var schemeListener = null;

  function rootEl() {
    return document.documentElement;
  }

  function flagEnabled(name, defaultOn) {
    var v = rootEl().dataset[name];
    if (v === undefined || v === "") return defaultOn;
    return v === "true" || v === "1";
  }

  function tintEnabled() {
    if (window.__shinyglassDisableTint) return false;
    return flagEnabled("glassTint", true);
  }

  function specularEnabled() {
    return flagEnabled("glassSpecular", true);
  }

  function navMorphEnabled() {
    return flagEnabled("glassNavMorph", true);
  }

  function resolvePreset(mode) {
    mode = mode || rootEl().dataset.glassMode || "light";
    if (mode === "auto") {
      try {
        return window.matchMedia("(prefers-color-scheme: dark)").matches
          ? "dark"
          : "light";
      } catch (e) {
        return "light";
      }
    }
    return mode === "dark" ? "dark" : "light";
  }

  function detachSchemeListener() {
    if (schemeMql && schemeListener) {
      try {
        if (schemeMql.removeEventListener) {
          schemeMql.removeEventListener("change", schemeListener);
        } else if (schemeMql.removeListener) {
          schemeMql.removeListener(schemeListener);
        }
      } catch (e) {
        /* ignore */
      }
    }
    schemeMql = null;
    schemeListener = null;
  }

  function attachSchemeListener() {
    detachSchemeListener();
    try {
      schemeMql = window.matchMedia("(prefers-color-scheme: dark)");
      schemeListener = function () {
        if ((rootEl().dataset.glassMode || "") === "auto") {
          applyPreset("auto", { fromOs: true });
        }
      };
      if (schemeMql.addEventListener) {
        schemeMql.addEventListener("change", schemeListener);
      } else if (schemeMql.addListener) {
        schemeMql.addListener(schemeListener);
      }
    } catch (e) {
      /* ignore */
    }
  }

  function applyPreset(mode, opts) {
    opts = opts || {};
    var root = rootEl();
    if (mode === "light" || mode === "dark" || mode === "auto") {
      root.dataset.glassMode = mode;
    } else {
      mode = root.dataset.glassMode || "light";
    }

    var resolved = resolvePreset(mode);
    var prev = root.dataset.glassPreset;
    root.dataset.glassPreset = resolved;

    if (mode === "auto") {
      attachSchemeListener();
    } else {
      detachSchemeListener();
    }

    if (prev !== resolved) {
      clearTint();
      scheduleTintUpdate();
    }
    // Intensity endpoints differ by preset
    setIntensity(intensityState, { syncInputs: true });

    try {
      root.dispatchEvent(
        new CustomEvent("shinyglass:preset", {
          detail: { mode: mode, preset: resolved, fromOs: !!opts.fromOs },
        })
      );
    } catch (e) {
      /* IE / very old — ignore */
    }
  }

  function setTintEnabled(on) {
    rootEl().dataset.glassTint = on ? "true" : "false";
    if (!on) {
      clearTint();
    } else {
      scheduleTintUpdate();
    }
  }

  function parseCssColor(color) {
    if (color == null) return null;
    color = String(color).trim();
    var m = color.match(/^#([0-9a-f]{3}|[0-9a-f]{6})$/i);
    if (m) {
      var h = m[1];
      if (h.length === 3) {
        h = h.charAt(0) + h.charAt(0) + h.charAt(1) + h.charAt(1) + h.charAt(2) + h.charAt(2);
      }
      return {
        hex: "#" + h.toLowerCase(),
        r: parseInt(h.slice(0, 2), 16),
        g: parseInt(h.slice(2, 4), 16),
        b: parseInt(h.slice(4, 6), 16),
      };
    }
    m = color.match(/^rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)/i);
    if (m) {
      var r = parseInt(m[1], 10);
      var g = parseInt(m[2], 10);
      var b = parseInt(m[3], 10);
      function toHex(n) {
        var s = n.toString(16);
        return s.length === 1 ? "0" + s : s;
      }
      return { hex: "#" + toHex(r) + toHex(g) + toHex(b), r: r, g: g, b: b };
    }
    return null;
  }

  // Match glass-on() in glass.scss: light labels on saturated fills.
  function onColorForFill(r, g, b) {
    var y = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255;
    return y >= 0.55 ? "#1d1d1f" : "#ffffff";
  }


  // iOS 27 Liquid Glass intensity: 0 = Ultra Clear, 1 = Tinted
  var intensityState = 0.45;
  var intensityBaseBlurPx = null;
  // Last content-aware tint sample (so intensity can re-scale fills while tint is active)
  var lastTintRgb = null;

  function clamp01(t) {
    t = Number(t);
    if (!isFinite(t)) return 0.45;
    if (t < 0) return 0;
    if (t > 1) return 1;
    return t;
  }

  function lerp(a, b, t) {
    return a + (b - a) * t;
  }

  function rgba(r, g, b, a) {
    return "rgba(" + Math.round(r) + ", " + Math.round(g) + ", " + Math.round(b) + ", " + a.toFixed(4) + ")";
  }

  // Endpoint packs for Ultra Clear (0) vs Tinted (1), per preset.
  // iOS 27: clear stays readable via blur; tinted is denser fill + stronger edge.
  function intensityEndpoints(preset) {
    if (preset === "dark") {
      return {
        clear: {
          bgA: 0.07, bgHoverA: 0.12, contentA: 0.06, contentHoverA: 0.10,
          borderA: 0.20, rimA: 0.30, lipA: 0.35, highlightA: 0.22, specularA: 0.28,
          edgeSheenA: 0.16, innerGlowA: 0.07, menuA: 0.58, blurScale: 1.12
        },
        tinted: {
          bgA: 0.24, bgHoverA: 0.32, contentA: 0.20, contentHoverA: 0.28,
          borderA: 0.40, rimA: 0.52, lipA: 0.62, highlightA: 0.40, specularA: 0.44,
          edgeSheenA: 0.30, innerGlowA: 0.14, menuA: 0.90, blurScale: 1.22
        },
        fill: { r: 255, g: 255, b: 255 },
        menu: { r: 58, g: 58, b: 60 },
        lip: { r: 0, g: 0, b: 0 }
      };
    }
    return {
      clear: {
        bgA: 0.08, bgHoverA: 0.16, contentA: 0.14, contentHoverA: 0.22,
        borderA: 0.48, rimA: 0.70, lipA: 0.06, highlightA: 0.82, specularA: 0.58,
        edgeSheenA: 0.36, innerGlowA: 0.16, menuA: 0.64, blurScale: 1.12
      },
      tinted: {
        bgA: 0.50, bgHoverA: 0.64, contentA: 0.58, contentHoverA: 0.70,
        borderA: 0.82, rimA: 0.95, lipA: 0.15, highlightA: 0.98, specularA: 0.82,
        edgeSheenA: 0.62, innerGlowA: 0.32, menuA: 0.94, blurScale: 1.22
      },
      fill: { r: 255, g: 255, b: 255 },
      menu: { r: 255, g: 255, b: 255 },
      lip: { r: 0, g: 0, b: 0 }
    };
  }

  function readBaseBlurPx() {
    var root = rootEl();
    if (intensityBaseBlurPx != null) return intensityBaseBlurPx;
    var raw = getComputedStyle(root).getPropertyValue("--glass-blur-base").trim() ||
      getComputedStyle(root).getPropertyValue("--glass-blur").trim() ||
      "32px";
    var n = parseFloat(raw);
    if (!isFinite(n)) n = 32;
    intensityBaseBlurPx = n;
    root.style.setProperty("--glass-blur-base", n + "px");
    return n;
  }

  function setIntensity(t, opts) {
    opts = opts || {};
    t = clamp01(t);
    intensityState = t;
    var root = rootEl();
    root.dataset.glassIntensity = String(t);
    root.style.setProperty("--glass-intensity", String(t));

    // Accessibility: force fully tinted when reduced transparency is on
    try {
      if (window.matchMedia("(prefers-reduced-transparency: reduce)").matches) {
        t = 1;
      }
    } catch (e) { /* ignore */ }

    var preset = root.dataset.glassPreset || "light";
    var ep = intensityEndpoints(preset);
    var c = ep.clear;
    var d = ep.tinted;
    var fill = ep.fill;
    var menu = ep.menu;
    var lip = ep.lip;

    function A(key) {
      return lerp(c[key], d[key], t);
    }

    // Content-aware tint owns fill RGB; re-scale its alphas with intensity.
    // Neutral (no tint) path sets fills directly from intensity endpoints.
    if (!opts.fromTint && root.classList.contains("glass-tint-active") && lastTintRgb) {
      applyTintFills(lastTintRgb, t);
    } else if (!opts.fromTint && !root.classList.contains("glass-tint-active")) {
      root.style.setProperty("--glass-bg", rgba(fill.r, fill.g, fill.b, A("bgA")));
      root.style.setProperty("--glass-bg-hover", rgba(fill.r, fill.g, fill.b, A("bgHoverA")));
      root.style.setProperty("--glass-bg-content", rgba(fill.r, fill.g, fill.b, A("contentA")));
      root.style.setProperty("--glass-bg-content-hover", rgba(fill.r, fill.g, fill.b, A("contentHoverA")));
      root.style.setProperty("--glass-border", rgba(fill.r, fill.g, fill.b, A("borderA")));
      root.style.setProperty("--glass-rim", rgba(fill.r, fill.g, fill.b, A("rimA")));
      root.style.setProperty("--glass-menu-bg", rgba(menu.r, menu.g, menu.b, A("menuA")));
    }

    root.style.setProperty("--glass-lip", rgba(lip.r, lip.g, lip.b, A("lipA")));
    root.style.setProperty("--glass-highlight", rgba(255, 255, 255, A("highlightA")));
    root.style.setProperty("--glass-specular", rgba(255, 255, 255, A("specularA")));
    root.style.setProperty("--glass-edge-sheen", rgba(255, 255, 255, A("edgeSheenA")));
    root.style.setProperty("--glass-inner-glow", rgba(255, 255, 255, A("innerGlowA")));

    var blurPx = readBaseBlurPx() * A("blurScale");
    root.style.setProperty("--glass-blur", blurPx.toFixed(1) + "px");

    // Sync any intensity slider widgets
    document.querySelectorAll(".glass-intensity-slider").forEach(function (wrap) {
      wrap.style.setProperty("--glass-intensity", String(intensityState));
      var input = wrap.querySelector("input.glass-intensity-range");
      if (input && opts.syncInputs !== false) {
        var v = String(intensityState);
        if (input.value !== v) input.value = v;
      }
      var minL = wrap.querySelector(".glass-intensity-end--min");
      var maxL = wrap.querySelector(".glass-intensity-end--max");
      if (minL) minL.classList.toggle("is-active", intensityState < 0.35);
      if (maxL) maxL.classList.toggle("is-active", intensityState > 0.65);
    });

    try {
      root.dispatchEvent(
        new CustomEvent("shinyglass:intensity", { detail: { intensity: intensityState } })
      );
    } catch (e) { /* ignore */ }
  }

  function getIntensity() {
    return intensityState;
  }

  function setPrimary(color) {
    var parsed = parseCssColor(color);
    if (!parsed) return;
    var root = rootEl();
    root.dataset.glassPrimary = parsed.hex;
    var onPrimary = onColorForFill(parsed.r, parsed.g, parsed.b);
    // Own accent token (Bootstrap also maps --bs-primary; some builds
    // re-declare --bs-primary on :root later — --glass-accent stays ours.)
    // Set on both html and body so [data-bs-theme] packs can't shadow accent.
    var targets = [root];
    if (document.body) targets.push(document.body);
    for (var i = 0; i < targets.length; i++) {
      var el = targets[i];
      el.style.setProperty("--glass-accent", parsed.hex);
      el.style.setProperty("--bs-primary", parsed.hex);
      el.style.setProperty("--glass-primary", parsed.hex);
      el.style.setProperty("--glass-on-primary", onPrimary);
      el.style.setProperty(
        "--bs-primary-rgb",
        parsed.r + ", " + parsed.g + ", " + parsed.b
      );
      el.style.setProperty(
        "--bs-primary-bg-subtle",
        "rgba(" + parsed.r + ", " + parsed.g + ", " + parsed.b + ", 0.14)"
      );
      el.style.setProperty(
        "--bs-primary-border-subtle",
        "rgba(" + parsed.r + ", " + parsed.g + ", " + parsed.b + ", 0.42)"
      );
      el.style.setProperty("--bs-link-color", parsed.hex);
      el.style.setProperty(
        "--bs-link-color-rgb",
        parsed.r + ", " + parsed.g + ", " + parsed.b
      );
      el.style.setProperty(
        "--bs-focus-ring-color",
        "rgba(" + parsed.r + ", " + parsed.g + ", " + parsed.b + ", 0.25)"
      );
    }
    try {
      root.dispatchEvent(
        new CustomEvent("shinyglass:primary", {
          detail: { primary: parsed.hex, rgb: parsed },
        })
      );
    } catch (e) {
      /* ignore */
    }
  }

  function blend(a, b, t) {
    return Math.round(a + (b - a) * t);
  }

  function shiftHue(rgb) {
    return {
      r: blend(rgb.r, 175, 0.35),
      g: blend(rgb.g, 82, 0.35),
      b: blend(rgb.b, 222, 0.35),
    };
  }

  function shiftWarm(rgb) {
    return {
      r: blend(rgb.r, 255, 0.35),
      g: blend(rgb.g, 149, 0.35),
      b: blend(rgb.b, 10, 0.35),
    };
  }

  function samplePixels(ctx, w, h) {
    var data = ctx.getImageData(0, 0, w, h).data;
    var rs = 0;
    var gs = 0;
    var bs = 0;
    var weight = 0;

    for (var i = 0; i < data.length; i += 4) {
      var r = data[i];
      var g = data[i + 1];
      var b = data[i + 2];
      var a = data[i + 3];
      if (a < 100) continue;

      var max = Math.max(r, g, b);
      var min = Math.min(r, g, b);
      var sat = max - min;

      // Skip near-neutral backgrounds so plots read through
      if (sat < 18 && max > 190) continue;

      var wgt = sat / 255 + 0.15;
      rs += r * wgt;
      gs += g * wgt;
      bs += b * wgt;
      weight += wgt;
    }

    if (weight === 0) return null;
    return {
      r: Math.round(rs / weight),
      g: Math.round(gs / weight),
      b: Math.round(bs / weight),
    };
  }

  function sampleImage(img) {
    if (!img || !img.complete) return null;
    var nw = img.naturalWidth || img.width;
    var nh = img.naturalHeight || img.height;
    if (!nw || !nh) return null;

    var canvas = document.createElement("canvas");
    var w = Math.min(nw, 72);
    var h = Math.min(nh, 72);
    canvas.width = w;
    canvas.height = h;

    try {
      var ctx = canvas.getContext("2d", { willReadFrequently: true });
      ctx.drawImage(img, 0, 0, w, h);
      return samplePixels(ctx, w, h);
    } catch (e) {
      return null;
    }
  }

  function sampleCanvas(canvas) {
    if (!canvas || !canvas.width || !canvas.height) return null;
    try {
      var ctx = canvas.getContext("2d", { willReadFrequently: true });
      var w = Math.min(canvas.width, 72);
      var h = Math.min(canvas.height, 72);
      var scratch = document.createElement("canvas");
      scratch.width = w;
      scratch.height = h;
      scratch.getContext("2d").drawImage(canvas, 0, 0, w, h);
      return samplePixels(scratch.getContext("2d"), w, h);
    } catch (e) {
      return null;
    }
  }

  function collectSamples() {
    var samples = [];

    document
      .querySelectorAll(".shiny-plot-output img, .shiny-image-output img, .glass-content-hero img")
      .forEach(function (img) {
        var s = sampleImage(img);
        if (s) samples.push(s);
      });

    document.querySelectorAll("canvas").forEach(function (canvas) {
      var s = sampleCanvas(canvas);
      if (s) samples.push(s);
    });

    return samples;
  }

  function averageSamples(samples) {
    if (!samples.length) return null;
    var rs = 0;
    var gs = 0;
    var bs = 0;
    samples.forEach(function (s) {
      rs += s.r;
      gs += s.g;
      bs += s.b;
    });
    var n = samples.length;
    return { r: Math.round(rs / n), g: Math.round(gs / n), b: Math.round(bs / n) };
  }

  function clearTint() {
    var root = rootEl();
    lastTintRgb = null;
    root.classList.remove("glass-tint-active");
    root.style.removeProperty("--glass-tint-strength");
    [
      "--glass-bg",
      "--glass-bg-hover",
      "--glass-bg-content",
      "--glass-bg-content-hover",
      "--glass-border",
      "--glass-rim",
      "--glass-orb-tint-1",
      "--glass-orb-tint-2",
      "--glass-orb-tint-3",
    ].forEach(function (prop) {
      root.style.removeProperty(prop);
    });
    setIntensity(intensityState, { syncInputs: true });
  }

  // Apply content-sampled tint RGB with intensity-scaled alphas (Ultra Clear → Tinted).
  // Without this, intensity only tweaked blur while tint freezes fill opacity.
  function applyTintFills(rgb, t) {
    if (!rgb) return;
    t = clamp01(t != null ? t : intensityState);
    try {
      if (window.matchMedia("(prefers-reduced-transparency: reduce)").matches) {
        t = 1;
      }
    } catch (e) { /* ignore */ }

    var root = rootEl();
    var preset = root.dataset.glassPreset || "light";
    var ep = intensityEndpoints(preset);
    var c = ep.clear;
    var d = ep.tinted;
    function A(key) {
      return lerp(c[key], d[key], t);
    }

    // Strength softens toward Ultra Clear so tint hue still reads but fill thins
    var baseStrength = preset === "dark" ? 0.48 : 0.55;
    var strength = baseStrength * lerp(0.45, 1, t);
    root.style.setProperty("--glass-tint-r", String(rgb.r));
    root.style.setProperty("--glass-tint-g", String(rgb.g));
    root.style.setProperty("--glass-tint-b", String(rgb.b));
    root.style.setProperty("--glass-tint-strength", String(strength.toFixed(4)));

    if (preset === "dark") {
      root.style.setProperty("--glass-bg", rgba(rgb.r, rgb.g, rgb.b, A("bgA")));
      root.style.setProperty("--glass-bg-hover", rgba(rgb.r, rgb.g, rgb.b, A("bgHoverA")));
      root.style.setProperty("--glass-bg-content", rgba(rgb.r, rgb.g, rgb.b, A("contentA")));
      root.style.setProperty(
        "--glass-bg-content-hover",
        rgba(rgb.r, rgb.g, rgb.b, A("contentHoverA"))
      );
      root.style.setProperty(
        "--glass-border",
        rgba(blend(rgb.r, 255, 0.42), blend(rgb.g, 255, 0.42), blend(rgb.b, 255, 0.42), A("borderA"))
      );
      root.style.setProperty(
        "--glass-rim",
        rgba(blend(rgb.r, 255, 0.55), blend(rgb.g, 255, 0.55), blend(rgb.b, 255, 0.55), A("rimA"))
      );
    } else {
      // Light: keep a white mix so text stays readable, but scale alpha with intensity
      var mixBg = lerp(0.12, 0.28, t);
      var mixHover = lerp(0.18, 0.36, t);
      var mixBorder = lerp(0.30, 0.50, t);
      root.style.setProperty(
        "--glass-bg",
        rgba(blend(255, rgb.r, mixBg), blend(255, rgb.g, mixBg), blend(255, rgb.b, mixBg), A("bgA"))
      );
      root.style.setProperty(
        "--glass-bg-hover",
        rgba(
          blend(255, rgb.r, mixHover),
          blend(255, rgb.g, mixHover),
          blend(255, rgb.b, mixHover),
          A("bgHoverA")
        )
      );
      root.style.setProperty(
        "--glass-bg-content",
        rgba(blend(255, rgb.r, mixBg), blend(255, rgb.g, mixBg), blend(255, rgb.b, mixBg), A("contentA"))
      );
      root.style.setProperty(
        "--glass-bg-content-hover",
        rgba(
          blend(255, rgb.r, mixHover),
          blend(255, rgb.g, mixHover),
          blend(255, rgb.b, mixHover),
          A("contentHoverA")
        )
      );
      root.style.setProperty(
        "--glass-border",
        rgba(
          blend(255, rgb.r, mixBorder),
          blend(255, rgb.g, mixBorder),
          blend(255, rgb.b, mixBorder),
          A("borderA")
        )
      );
      root.style.setProperty(
        "--glass-rim",
        rgba(
          blend(255, rgb.r, mixBorder),
          blend(255, rgb.g, mixBorder),
          blend(255, rgb.b, mixBorder),
          A("rimA")
        )
      );
    }

    var secondary = shiftHue(rgb);
    var tertiary = shiftWarm(rgb);
    var orb1 = (preset === "dark" ? 0.34 : 0.30) * lerp(0.4, 1, t);
    var orb2 = (preset === "dark" ? 0.28 : 0.24) * lerp(0.4, 1, t);
    var orb3 = (preset === "dark" ? 0.22 : 0.18) * lerp(0.4, 1, t);

    root.style.setProperty(
      "--glass-orb-tint-1",
      rgba(rgb.r, rgb.g, rgb.b, orb1)
    );
    root.style.setProperty(
      "--glass-orb-tint-2",
      rgba(secondary.r, secondary.g, secondary.b, orb2)
    );
    root.style.setProperty(
      "--glass-orb-tint-3",
      rgba(tertiary.r, tertiary.g, tertiary.b, orb3)
    );
  }

  function applyTint(rgb) {
    if (!rgb) {
      clearTint();
      return;
    }

    lastTintRgb = { r: rgb.r, g: rgb.g, b: rgb.b };
    var root = rootEl();
    root.classList.add("glass-tint-active");
    applyTintFills(lastTintRgb, intensityState);
    // Scale edge/blur/highlights with intensity (fills already set above)
    setIntensity(intensityState, { fromTint: true, syncInputs: true });
  }

  function updateContentTint() {
    if (!tintEnabled()) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    var rgb = averageSamples(collectSamples());
    applyTint(rgb);
  }

  function scheduleTintUpdate() {
    if (!tintEnabled()) return;
    if (tintTimer) clearTimeout(tintTimer);
    tintTimer = setTimeout(updateContentTint, TINT_THROTTLE_MS);
  }

  // Public API for advanced users / tests
  window.shinyglass = window.shinyglass || {};
  window.shinyglass.setPreset = function (mode) {
    applyPreset(mode);
  };
  window.shinyglass.getPreset = function () {
    return rootEl().dataset.glassPreset || "light";
  };
  window.shinyglass.getMode = function () {
    return rootEl().dataset.glassMode || "light";
  };
  window.shinyglass.setTint = function (on) {
    setTintEnabled(!!on);
  };
  window.shinyglass.setPrimary = function (color) {
    setPrimary(color);
  };
  window.shinyglass.getPrimary = function () {
    return rootEl().dataset.glassPrimary || rootEl().style.getPropertyValue("--bs-primary") || "";
  };
  window.shinyglass.setIntensity = function (t) {
    setIntensity(t, { syncInputs: true });
  };
  window.shinyglass.getIntensity = function () {
    return getIntensity();
  };

  // raise native <select> above later card content
  $(document).on("focus mousedown", ".card .form-select, form.well .form-select", function () {
    var container = $(this).closest(".shiny-input-container");
    container.addClass("glass-select-open");
    container.siblings(".shiny-input-container").removeClass("glass-select-open");
  });

  $(document).on("blur change", ".card .form-select, form.well .form-select", function () {
    var container = $(this).closest(".shiny-input-container");
    setTimeout(function () {
      if (!container.find(".form-select").is(":focus")) {
        container.removeClass("glass-select-open");
      }
    }, 150);
  });

  // compact navbar on scroll down; expand on scroll up
  // Note: htmlDependency scripts often load in <head> before <body> exists —
  // never touch document.body until DOM is ready.
  (function () {
    var threshold = 56;
    var lastScrollY = window.scrollY || 0;
    var ticking = false;

    function updateNavMorph() {
      var body = document.body;
      if (!body) return;

      if (
        !navMorphEnabled() ||
        window.matchMedia("(prefers-reduced-motion: reduce)").matches
      ) {
        body.classList.remove("glass-nav-compact", "glass-nav-expanded");
        ticking = false;
        return;
      }

      var y = Math.max(0, window.scrollY);
      var scrollingDown = y > lastScrollY + 2;
      var scrollingUp = y < lastScrollY - 2;

      if (y <= threshold) {
        body.classList.remove("glass-nav-compact");
        body.classList.add("glass-nav-expanded");
      } else if (scrollingDown) {
        body.classList.add("glass-nav-compact");
        body.classList.remove("glass-nav-expanded");
      } else if (scrollingUp) {
        body.classList.remove("glass-nav-compact");
        body.classList.add("glass-nav-expanded");
      }

      lastScrollY = y;
      ticking = false;
    }

    window.addEventListener(
      "scroll",
      function () {
        if (!ticking) {
          window.requestAnimationFrame(updateNavMorph);
          ticking = true;
        }
      },
      { passive: true }
    );

    if (document.body) {
      updateNavMorph();
    } else if (document.addEventListener) {
      document.addEventListener("DOMContentLoaded", updateNavMorph);
    }
  })();

  // force glass colors past inline widget styles
  function applyWidgetGlassOverrides() {
    document.querySelectorAll(".stati").forEach(function (el) {
      el.style.setProperty("background", "var(--glass-bg)", "important");
      el.style.setProperty("background-color", "var(--glass-bg)", "important");
      el.style.setProperty("color", "inherit", "important");
      el.style.setProperty(
        "box-shadow",
        "0 8px 32px var(--glass-shadow), inset 0 1px 0 var(--glass-highlight)",
        "important"
      );
      el.querySelectorAll(".stati-value, .stati-subtitle, i, svg").forEach(function (child) {
        child.style.setProperty("color", "inherit", "important");
        child.style.removeProperty("fill");
      });
    });

    document.querySelectorAll(".Reactable").forEach(function (el) {
      el.style.setProperty("background-color", "var(--glass-bg)", "important");
      el.style.setProperty("color", "inherit", "important");
    });
  }

  $(document).on("shiny:connected shiny:value shiny:visualchange", applyWidgetGlassOverrides);

  // --glass-specular-x/y from pointer
  (function () {
    var specularSelector =
      ".card, form.well, .col-sm-4.well, .bslib-sidebar-layout > .sidebar, .bslib-page-sidebar > .navbar, .navbar.navbar-static-top, .navbar.navbar-default, .tabbable > .nav-tabs, .dataTables_wrapper, .stati, .box, .small-box, .info-box, .reactable, .Reactable, .value-box";

    var pointerActiveTimer = null;
    document.addEventListener(
      "mousemove",
      function (e) {
        if (!specularEnabled()) return;
        if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
        var el = e.target.closest(specularSelector);
        if (!el) {
          rootEl().classList.remove("glass-pointer-active");
          return;
        }
        var rect = el.getBoundingClientRect();
        if (!rect.width || !rect.height) return;
        var x = ((e.clientX - rect.left) / rect.width) * 100;
        var y = ((e.clientY - rect.top) / rect.height) * 100;
        // Pause ambient drift while pointer drives specular
        rootEl().classList.add("glass-pointer-active");
        if (pointerActiveTimer) clearTimeout(pointerActiveTimer);
        pointerActiveTimer = setTimeout(function () {
          rootEl().classList.remove("glass-pointer-active");
        }, 1400);
        el.style.setProperty("--glass-specular-x", x + "%");
        el.style.setProperty("--glass-specular-y", y + "%");
      },
      { passive: true }
    );
  })();

  // selectize open/close class for z-index
  $(document).on("focus mousedown", ".selectize-control .selectize-input", function () {
    $(this).closest(".shiny-input-container").addClass("glass-select-open");
  });

  $(document).on("blur", ".selectize-control .selectize-input", function () {
    var container = $(this).closest(".shiny-input-container");
    setTimeout(function () {
      if (!container.find(".selectize-input").is(":focus")) {
        container.removeClass("glass-select-open");
      }
    }, 200);
  });

  $(document).on("change", ".selectize-control", function () {
    $(this).closest(".shiny-input-container").removeClass("glass-select-open");
  });

  function handleShinyglassMessage(msg) {
    if (msg == null) return;
    // Legacy: glassPreset sent a bare string
    if (typeof msg === "string") {
      applyPreset(msg);
      return;
    }
    if (typeof msg === "object") {
      if (msg.preset != null) applyPreset(msg.preset);
      if (msg.tint != null) setTintEnabled(!!msg.tint);
      if (msg.primary != null) setPrimary(msg.primary);
      if (msg.intensity != null) setIntensity(msg.intensity, { syncInputs: true });
    }
  }

  // Apply glass custom messages whether they arrive via the normal Shiny
  // handler map or via a host that overwrites Shiny.oncustommessage
  // (shinyapps.io does this and drops registered handlers).
  function consumeCustomEnvelope(envelope) {
    if (!envelope || typeof envelope !== "object") return;
    if (envelope.shinyglass != null) {
      handleShinyglassMessage(envelope.shinyglass);
    }
    if (envelope.glassPreset != null) {
      applyPreset(envelope.glassPreset || "light");
    }
  }

  function installOnCustomMessageHook() {
    if (typeof Shiny === "undefined" || !Shiny) return;
    var prev = Shiny.oncustommessage;
    // Already our hook and still installed
    if (prev && prev.__shinyglassHooked) return;
    var hooked = function (message) {
      try {
        consumeCustomEnvelope(message);
      } catch (e1) {
        /* ignore */
      }
      if (typeof prev === "function" && !prev.__shinyglassHooked) {
        try {
          return prev.apply(this, arguments);
        } catch (e2) {
          /* ignore host handler errors */
        }
      }
    };
    hooked.__shinyglassHooked = true;
    // Keep reference to whatever we wrapped so we can re-chain if host
    // overwrites us again.
    hooked.__shinyglassPrev = prev;
    Shiny.oncustommessage = hooked;
  }

  // --- Message routing (order matters: never throw before jQuery binds) ---

  // 1) shiny:message — fires for every server payload (most reliable)
  $(document).on("shiny:message.shinyglass", function (event) {
    try {
      var msg = event && event.message;
      if (!msg) return;
      if (msg.custom) consumeCustomEnvelope(msg.custom);
      consumeCustomEnvelope(msg);
    } catch (e) {
      /* ignore */
    }
  });

  // 2) tint / widget updates
  $(document).on("shiny:value.shinyglass shiny:visualchange.shinyglass", scheduleTintUpdate);

  // 3) Re-install host hooks when session connects
  $(document).on("shiny:connected.shinyglass", function () {
    try {
      installOnCustomMessageHook();
      if (typeof Shiny !== "undefined" && Shiny.addCustomMessageHandler) {
        Shiny.addCustomMessageHandler("shinyglass", handleShinyglassMessage);
        Shiny.addCustomMessageHandler("glassPreset", function (preset) {
          applyPreset(preset || "light");
        });
      }
    } catch (e) {
      /* ignore */
    }
    scheduleTintUpdate();
  });

  // 4) Standard Shiny handler map + oncustommessage wrap (best-effort)
  try {
    if (typeof Shiny !== "undefined" && Shiny.addCustomMessageHandler) {
      Shiny.addCustomMessageHandler("shinyglass", handleShinyglassMessage);
      Shiny.addCustomMessageHandler("glassPreset", function (preset) {
        applyPreset(preset || "light");
      });
    }
    installOnCustomMessageHook();
  } catch (e) {
    /* ignore — jQuery shiny:message path still works */
  }

  // 5) shinyapps.io may overwrite oncustommessage after our script; re-hook
  setTimeout(installOnCustomMessageHook, 0);
  setTimeout(installOnCustomMessageHook, 250);
  setTimeout(installOnCustomMessageHook, 1000);
  setTimeout(installOnCustomMessageHook, 3000);
  // Keep watching for a short window after load (host scripts race)
  var hookAttempts = 0;
  var hookTimer = setInterval(function () {
    installOnCustomMessageHook();
    hookAttempts += 1;
    if (hookAttempts >= 20) clearInterval(hookTimer);
  }, 500);


  function bindIntensitySliders() {
    document.querySelectorAll(".glass-intensity-slider").forEach(function (wrap) {
      if (wrap.__glassIntensityBound) return;
      wrap.__glassIntensityBound = true;
      var input = wrap.querySelector("input.glass-intensity-range");
      if (!input) return;

      function applyFromInput(ev) {
        var t = clamp01(input.value);
        wrap.classList.toggle("is-dragging", !!(ev && ev.type === "input"));
        setIntensity(t, { syncInputs: false });
        wrap.style.setProperty("--glass-intensity", String(t));
      }

      input.addEventListener("input", applyFromInput);
      input.addEventListener("change", function (ev) {
        applyFromInput(ev);
        wrap.classList.remove("is-dragging");
      });
      input.value = String(getIntensity());
      wrap.style.setProperty("--glass-intensity", String(getIntensity()));
    });
  }

  if (typeof Shiny !== "undefined" && Shiny.InputBinding) {
    var intensityBinding = new Shiny.InputBinding();
    $.extend(intensityBinding, {
      find: function (scope) {
        return $(scope).find(".glass-intensity-slider input.glass-intensity-range");
      },
      getId: function (el) {
        return el.id;
      },
      getValue: function (el) {
        return clamp01(el.value);
      },
      setValue: function (el, value) {
        el.value = clamp01(value);
        setIntensity(el.value, { syncInputs: false });
        var wrap = el.closest(".glass-intensity-slider");
        if (wrap) wrap.style.setProperty("--glass-intensity", String(clamp01(value)));
      },
      subscribe: function (el, callback) {
        $(el).on("input.glassIntensity change.glassIntensity", function () {
          callback(true);
        });
      },
      unsubscribe: function (el) {
        $(el).off(".glassIntensity");
      },
      receiveMessage: function (el, data) {
        if (data && data.value != null) {
          this.setValue(el, data.value);
          $(el).trigger("change");
        }
      },
      getRatePolicy: function () {
        return { policy: "debounce", delay: 100 };
      },
    });
    Shiny.inputBindings.register(intensityBinding, "shinyglass.intensity");
  }

  $(document).on("shiny:connected.shinyglassIntensity", function () {
    bindIntensitySliders();
  });

  $(function () {
    // Ensure mode/preset are coherent if head script ran or was skipped
    var mode = rootEl().dataset.glassMode || rootEl().dataset.glassPreset || "light";
    applyPreset(mode);

    // Re-apply primary from head/data if present
    if (rootEl().dataset.glassPrimary) {
      setPrimary(rootEl().dataset.glassPrimary);
    }

    // iOS 27 intensity (0 Ultra Clear → 1 Tinted)
    var initI = rootEl().dataset.glassIntensity;
    if (initI != null && initI !== "") {
      setIntensity(initI, { syncInputs: true });
    } else {
      setIntensity(0.45, { syncInputs: true });
    }

    scheduleTintUpdate();
    applyWidgetGlassOverrides();
    bindIntensitySliders();

    if (typeof MutationObserver !== "undefined") {
      var observer = new MutationObserver(function (mutations) {
        var needsTint = false;
        var needsWidgetGlass = false;

        for (var i = 0; i < mutations.length; i++) {
          var t = mutations[i].target;
          if (
            t.matches &&
            (t.matches(".shiny-plot-output img") ||
              t.matches(".shiny-image-output img") ||
              t.matches("canvas"))
          ) {
            needsTint = true;
          } else if (
            t.matches &&
            (t.matches(".stati") || t.matches(".Reactable") || t.closest(".stati, .Reactable"))
          ) {
            needsWidgetGlass = true;
          }

          if (t.querySelector) {
            if (t.querySelector(".shiny-plot-output img, canvas")) needsTint = true;
            if (t.querySelector(".stati, .Reactable")) needsWidgetGlass = true;
          }
        }

        if (needsTint) scheduleTintUpdate();
        if (needsWidgetGlass) applyWidgetGlassOverrides();
      });
      observer.observe(document.body, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: ["src", "style", "class"],
      });
    }
  });
})();
