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
    root.classList.remove("glass-tint-active");
    root.style.removeProperty("--glass-tint-strength");
    [
      "--glass-bg",
      "--glass-bg-hover",
      "--glass-border",
      "--glass-orb-tint-1",
      "--glass-orb-tint-2",
      "--glass-orb-tint-3",
    ].forEach(function (prop) {
      root.style.removeProperty(prop);
    });
  }

  function applyTint(rgb) {
    if (!rgb) {
      clearTint();
      return;
    }

    var root = rootEl();
    var preset = root.dataset.glassPreset || "light";
    var strength = preset === "dark" ? 0.48 : 0.55;
    var secondary = shiftHue(rgb);
    var tertiary = shiftWarm(rgb);

    root.classList.add("glass-tint-active");
    root.style.setProperty("--glass-tint-r", String(rgb.r));
    root.style.setProperty("--glass-tint-g", String(rgb.g));
    root.style.setProperty("--glass-tint-b", String(rgb.b));
    root.style.setProperty("--glass-tint-strength", String(strength));

    if (preset === "dark") {
      root.style.setProperty(
        "--glass-bg",
        "rgba(" + rgb.r + ", " + rgb.g + ", " + rgb.b + ", 0.12)"
      );
      root.style.setProperty(
        "--glass-bg-hover",
        "rgba(" + rgb.r + ", " + rgb.g + ", " + rgb.b + ", 0.20)"
      );
      root.style.setProperty(
        "--glass-border",
        "rgba(" +
          blend(rgb.r, 255, 0.42) +
          ", " +
          blend(rgb.g, 255, 0.42) +
          ", " +
          blend(rgb.b, 255, 0.42) +
          ", 0.28)"
      );
    } else {
      root.style.setProperty(
        "--glass-bg",
        "rgba(" +
          blend(255, rgb.r, 0.22) +
          ", " +
          blend(255, rgb.g, 0.22) +
          ", " +
          blend(255, rgb.b, 0.22) +
          ", 0.30)"
      );
      root.style.setProperty(
        "--glass-bg-hover",
        "rgba(" +
          blend(255, rgb.r, 0.30) +
          ", " +
          blend(255, rgb.g, 0.30) +
          ", " +
          blend(255, rgb.b, 0.30) +
          ", 0.42)"
      );
      root.style.setProperty(
        "--glass-border",
        "rgba(" +
          blend(255, rgb.r, 0.45) +
          ", " +
          blend(255, rgb.g, 0.45) +
          ", " +
          blend(255, rgb.b, 0.45) +
          ", 0.58)"
      );
    }

    var orb1 = preset === "dark" ? 0.34 : 0.30;
    var orb2 = preset === "dark" ? 0.28 : 0.24;
    var orb3 = preset === "dark" ? 0.22 : 0.18;

    root.style.setProperty(
      "--glass-orb-tint-1",
      "rgba(" + rgb.r + ", " + rgb.g + ", " + rgb.b + ", " + orb1 + ")"
    );
    root.style.setProperty(
      "--glass-orb-tint-2",
      "rgba(" + secondary.r + ", " + secondary.g + ", " + secondary.b + ", " + orb2 + ")"
    );
    root.style.setProperty(
      "--glass-orb-tint-3",
      "rgba(" + tertiary.r + ", " + tertiary.g + ", " + tertiary.b + ", " + orb3 + ")"
    );
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
  (function () {
    var threshold = 56;
    var lastScrollY = window.scrollY || 0;
    var ticking = false;

    function updateNavMorph() {
      if (
        !navMorphEnabled() ||
        window.matchMedia("(prefers-reduced-motion: reduce)").matches
      ) {
        document.body.classList.remove("glass-nav-compact", "glass-nav-expanded");
        ticking = false;
        return;
      }

      var y = Math.max(0, window.scrollY);
      var scrollingDown = y > lastScrollY + 2;
      var scrollingUp = y < lastScrollY - 2;
      var body = document.body;

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

    updateNavMorph();
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

    document.addEventListener(
      "mousemove",
      function (e) {
        if (!specularEnabled()) return;
        if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
        var el = e.target.closest(specularSelector);
        if (!el) return;
        var rect = el.getBoundingClientRect();
        if (!rect.width || !rect.height) return;
        var x = ((e.clientX - rect.left) / rect.width) * 100;
        var y = ((e.clientY - rect.top) / rect.height) * 100;
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
    }
  }

  // Apply glass custom messages whether they arrive via the normal Shiny
  // handler map or via a host that overwrites Shiny.oncustommessage
  // (shinyapps.io does this and drops registered handlers).
  function consumeCustomEnvelope(envelope) {
    if (!envelope || typeof envelope !== "object") return;
    if (Object.prototype.hasOwnProperty.call(envelope, "shinyglass")) {
      handleShinyglassMessage(envelope.shinyglass);
    }
    if (Object.prototype.hasOwnProperty.call(envelope, "glassPreset")) {
      applyPreset(envelope.glassPreset || "light");
    }
  }

  function installOnCustomMessageHook() {
    if (typeof Shiny === "undefined") return;
    var prev = Shiny.oncustommessage;
    if (prev && prev.__shinyglassHooked) return;
    var hooked = function (message) {
      try {
        consumeCustomEnvelope(message);
      } catch (e) {
        /* ignore */
      }
      if (typeof prev === "function" && !prev.__shinyglassHooked) {
        return prev.apply(this, arguments);
      }
    };
    hooked.__shinyglassHooked = true;
    Shiny.oncustommessage = hooked;
  }

  // Structured message from update_glass_theme()
  if (typeof Shiny !== "undefined") {
    Shiny.addCustomMessageHandler("shinyglass", handleShinyglassMessage);
    // Back-compat with older glassPreset handler name
    Shiny.addCustomMessageHandler("glassPreset", function (preset) {
      applyPreset(preset || "light");
    });
    installOnCustomMessageHook();
  }

  // shiny:message fires for every server message (including custom). This is
  // the most reliable path when hosts replace oncustommessage after load.
  $(document).on("shiny:message", function (event) {
    try {
      var msg = event && event.message;
      if (!msg) return;
      // Full websocket payload: { custom: { shinyglass: {...} }, ... }
      if (msg.custom) consumeCustomEnvelope(msg.custom);
      // Some paths may deliver the custom map directly
      consumeCustomEnvelope(msg);
    } catch (e) {
      /* ignore */
    }
  });

  // Re-install hook after other scripts (shinyapps client) may overwrite it
  $(document).on("shiny:connected", function () {
    installOnCustomMessageHook();
    scheduleTintUpdate();
  });
  setTimeout(installOnCustomMessageHook, 0);
  setTimeout(installOnCustomMessageHook, 250);
  setTimeout(installOnCustomMessageHook, 1500);

  $(document).on("shiny:value shiny:visualchange", scheduleTintUpdate);

  $(function () {
    // Ensure mode/preset are coherent if head script ran or was skipped
    var mode = rootEl().dataset.glassMode || rootEl().dataset.glassPreset || "light";
    applyPreset(mode);

    scheduleTintUpdate();
    applyWidgetGlassOverrides();

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
