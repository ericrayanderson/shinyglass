// shinyglass — Apple Liquid Glass behaviors for Shiny (web)

(function () {
  "use strict";

  var TINT_THROTTLE_MS = 400;
  var tintTimer = null;

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
    var root = document.documentElement;
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

    var root = document.documentElement;
    var preset = root.dataset.glassPreset || "light";
    var strength = 0.55;
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
        "rgba(" + rgb.r + ", " + rgb.g + ", " + rgb.b + ", 0.10)"
      );
      root.style.setProperty(
        "--glass-bg-hover",
        "rgba(" + rgb.r + ", " + rgb.g + ", " + rgb.b + ", 0.16)"
      );
      root.style.setProperty(
        "--glass-border",
        "rgba(" + blend(rgb.r, 255, 0.35) + ", " + blend(rgb.g, 255, 0.35) + ", " + blend(rgb.b, 255, 0.35) + ", 0.22)"
      );
    } else {
      root.style.setProperty(
        "--glass-bg",
        "rgba(" + blend(255, rgb.r, 0.22) + ", " + blend(255, rgb.g, 0.22) + ", " + blend(255, rgb.b, 0.22) + ", 0.30)"
      );
      root.style.setProperty(
        "--glass-bg-hover",
        "rgba(" + blend(255, rgb.r, 0.30) + ", " + blend(255, rgb.g, 0.30) + ", " + blend(255, rgb.b, 0.30) + ", 0.42)"
      );
      root.style.setProperty(
        "--glass-border",
        "rgba(" + blend(255, rgb.r, 0.45) + ", " + blend(255, rgb.g, 0.45) + ", " + blend(255, rgb.b, 0.45) + ", 0.58)"
      );
    }

    root.style.setProperty(
      "--glass-orb-tint-1",
      "rgba(" + rgb.r + ", " + rgb.g + ", " + rgb.b + ", 0.30)"
    );
    root.style.setProperty(
      "--glass-orb-tint-2",
      "rgba(" + secondary.r + ", " + secondary.g + ", " + secondary.b + ", 0.24)"
    );
    root.style.setProperty(
      "--glass-orb-tint-3",
      "rgba(" + tertiary.r + ", " + tertiary.g + ", " + tertiary.b + ", 0.18)"
    );
  }

  function updateContentTint() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    var rgb = averageSamples(collectSamples());
    applyTint(rgb);
  }

  function scheduleTintUpdate() {
    if (tintTimer) clearTimeout(tintTimer);
    tintTimer = setTimeout(updateContentTint, TINT_THROTTLE_MS);
  }

  // Native <select> stacking inside cards
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

  // Compact floating navigation on scroll
  (function () {
    var threshold = 48;
    var ticking = false;

    function updateNavCompact() {
      document.body.classList.toggle("glass-nav-compact", window.scrollY > threshold);
      ticking = false;
    }

    window.addEventListener(
      "scroll",
      function () {
        if (!ticking) {
          window.requestAnimationFrame(updateNavCompact);
          ticking = true;
        }
      },
      { passive: true }
    );

    updateNavCompact();
  })();

  // Content-aware tinting (Apple: color informed by surroundings)
  $(document).on("shiny:connected", scheduleTintUpdate);
  $(document).on("shiny:value shiny:visualchange", scheduleTintUpdate);

  $(function () {
    scheduleTintUpdate();

    if (typeof MutationObserver !== "undefined") {
      var observer = new MutationObserver(function (mutations) {
        for (var i = 0; i < mutations.length; i++) {
          var t = mutations[i].target;
          if (
            t.matches &&
            (t.matches(".shiny-plot-output img") ||
              t.matches(".shiny-image-output img") ||
              t.matches("canvas"))
          ) {
            scheduleTintUpdate();
            return;
          }
          if (t.querySelector && t.querySelector(".shiny-plot-output img, canvas")) {
            scheduleTintUpdate();
            return;
          }
        }
      });
      observer.observe(document.body, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: ["src", "style"],
      });
    }
  });
})();