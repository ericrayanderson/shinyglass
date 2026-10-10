/* iOS 27 motion and refraction. Loaded after shiny-glass.js.
   Displacement maps are generated here (squircle lens, rim-weighted Snell
   gain, SVG feDisplacementMap). Technique references, not copied sources:
   Surdeddd/liquidglassjs, nikdelvin/liquid-glass, archisvaze/liquid-glass.
   Safari and Firefox do not support backdrop-filter: url(), so they keep
   the blur and tint material. */
(function () {
  "use strict";

  var SVG_NS = "http://www.w3.org/2000/svg";
  var XLINK_NS = "http://www.w3.org/1999/xlink";
  var REFRACT_CAP = 8;
  var MAP_LONG_SIDE = 144;
  var MAP_CACHE_MAX = 24;
  var IOR_DESIGN = 1.5;
  var mapCache = new Map();
  var refractFrame = 0;
  var tabsHoldUntil = 0;
  var pressedEl = null;
  var ios27Started = false;
  var scrollScanAt = 0;

  var REFRACT_SELECTOR = [
    ".navbar",
    ".bslib-sidebar-layout > .sidebar",
    ".glass-sidebar",
    ".glass-surface",
    ".glass-card",
    ".card",
    ".modal-content",
    ".dropdown-menu",
    ".popover",
    "form.well",
    ".nav-pills",
    ".tabbable > .nav-tabs",
    ".glass-tabbar",
    ".offcanvas",
    ".shiny-chat-page-header",
    ".shiny-chat-page-sidebar",
    ".shiny-chat-input .tiptap",
    ".shiny-chat-slash-palette"
  ].join(",");

  var MORPH_SELECTOR = [
    ".nav-pills",
    ".btn-group",
    ".glass-theme-toggle",
    ".nav-tabs",
    "[role='tablist']"
  ].join(",");

  var PRESS_SELECTOR = [
    ".btn",
    ".nav-link",
    ".glass-button",
    ".glass-accent-well",
    ".paginate_button",
    "summary"
  ].join(",");

  function rootEl() {
    return document.documentElement;
  }

  function flagEnabled(name, defaultOn) {
    var v = rootEl().dataset[name];
    if (v === undefined || v === "") return defaultOn;
    return v === "true" || v === "1";
  }

  function reducedMotion() {
    try {
      return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    } catch (e) {
      return false;
    }
  }

  function readNumber(prop, fallback) {
    var raw = "";
    try {
      raw = getComputedStyle(rootEl()).getPropertyValue(prop);
    } catch (e) {
      raw = "";
    }
    var n = parseFloat(raw);
    return isFinite(n) ? n : fallback;
  }

  function refractionEnabled() {
    return flagEnabled("glassRefraction", true);
  }

  function morphEnabled() {
    return flagEnabled("glassMorph", true);
  }

  function pressEnabled() {
    return flagEnabled("glassPress", true);
  }

  function supportsDisplacementBackdrop() {
    if (window.__shinyglassForceRefractionSupport === false) return false;
    if (window.__shinyglassForceRefractionSupport === true) return true;
    try {
      return !!(window.CSS && CSS.supports && (
        CSS.supports("backdrop-filter", "url(#shinyglass-refract)") ||
        CSS.supports("-webkit-backdrop-filter", "url(#shinyglass-refract)")
      ));
    } catch (e) {
      return false;
    }
  }

  function isLowTierDevice() {
    if (window.__shinyglassForceLowTier === true) return true;
    if (window.__shinyglassForceLowTier === false) return false;
    try {
      var c = navigator.connection;
      if (c && c.saveData) return true;
    } catch (e) { /* ignore */ }
    var cores = navigator.hardwareConcurrency || 8;
    var mem = navigator.deviceMemory;
    if (cores <= 4) return true;
    if (mem && mem <= 4) return true;
    return false;
  }

  function dispersionEnabled() {
    if (window.__shinyglassForceDispersion === false) return false;
    if (window.__shinyglassForceDispersion === true) return true;
    return !isLowTierDevice();
  }

  function refractionBlocked() {
    var ds = rootEl().dataset;
    if (!refractionEnabled()) return true;
    if (ds.glassFlatten === "true") return true;
    if (ds.glassReducedTransparency === "reduce") return true;
    if (ds.glassContrast === "more") return true;
    if (ds.glassForcedColors === "active") return true;
    try {
      if (window.matchMedia("(prefers-reduced-transparency: reduce)").matches) return true;
      if (window.matchMedia("(prefers-contrast: more)").matches) return true;
      if (window.matchMedia("(forced-colors: active)").matches) return true;
    } catch (e) { /* ignore */ }
    if (!supportsDisplacementBackdrop()) return true;
    return false;
  }

  function markRefractionSupport() {
    rootEl().dataset.glassRefractionSupport = supportsDisplacementBackdrop() ? "true" : "false";
    rootEl().dataset.glassDispersion = dispersionEnabled() ? "true" : "false";
  }

  // Rounded-rect SDF with a superellipse (n = 4) warp so corners read as a
  // squircle. dist < 0 is inside.
  function squircleSdf(px, py, hw, hh, rad) {
    var nx = hw > 0 ? px / hw : 0;
    var ny = hh > 0 ? py / hh : 0;
    var ax = Math.abs(nx);
    var ay = Math.abs(ny);
    var circ = Math.hypot(nx, ny);
    var k = 1;
    if (circ > 1e-4) {
      var superR = Math.pow(Math.pow(ax, 4) + Math.pow(ay, 4), 0.25);
      k = superR / circ;
    }
    var sx = px * k;
    var sy = py * k;
    var qx = Math.abs(sx) - (hw - rad);
    var qy = Math.abs(sy) - (hh - rad);
    var ox = Math.max(qx, 0);
    var oy = Math.max(qy, 0);
    return Math.min(Math.max(qx, qy), 0) + Math.hypot(ox, oy) - rad;
  }

  function buildDisplacementMap(width, height, radius) {
    width = Math.max(8, Math.round(width));
    height = Math.max(8, Math.round(height));
    radius = Math.max(0, radius || 0);
    var longSide = Math.max(width, height);
    var mapW = Math.max(8, Math.round(width * Math.min(1, MAP_LONG_SIDE / longSide)));
    var mapH = Math.max(8, Math.round(height * Math.min(1, MAP_LONG_SIDE / longSide)));
    var canvas = document.createElement("canvas");
    canvas.width = mapW;
    canvas.height = mapH;
    var ctx = canvas.getContext("2d", { willReadFrequently: true });
    var img = ctx.createImageData(mapW, mapH);
    var data = img.data;
    var hw = width / 2;
    var hh = height / 2;
    var rad = Math.max(0, Math.min(radius, Math.min(hw, hh) - 0.5));
    var rimWidth = Math.max(6, Math.min(rad > 1 ? rad * 1.15 : Math.min(width, height) * 0.18, Math.min(width, height) * 0.28));
    var gain = 1 - 1 / IOR_DESIGN;
    var magPx = Math.min(width, height) * 0.012;
    var rimPx = rimWidth * 0.9 * gain / (1 - 1 / IOR_DESIGN);
    var scale = 42;
    var cSum = 0;
    var cN = 0;
    var rSum = 0;
    var rN = 0;
    var eps = 1.35;

    for (var y = 0; y < mapH; y++) {
      for (var x = 0; x < mapW; x++) {
        var px = ((x + 0.5) / mapW) * width - hw;
        var py = ((y + 0.5) / mapH) * height - hh;
        var dist = squircleSdf(px, py, hw, hh, rad);
        var distIn = -dist;
        var dx = 0;
        var dy = 0;
        if (distIn > 0.4) {
          var gx = squircleSdf(px + eps, py, hw, hh, rad) - squircleSdf(px - eps, py, hw, hh, rad);
          var gy = squircleSdf(px, py + eps, hw, hh, rad) - squircleSdf(px, py - eps, hw, hh, rad);
          var gl = Math.hypot(gx, gy) || 1;
          gx /= gl;
          gy /= gl;
          var plateau = Math.min(distIn / rimWidth, 1);
          var nx = hw > 0 ? px / hw : 0;
          var ny = hh > 0 ? py / hh : 0;
          // Optically flat interior: a small inward sample (slight magnification).
          dx = -nx * magPx * plateau;
          dy = -ny * magPx * plateau;
          // Rim-concentrated bend along the outward surface normal.
          var rim = Math.exp(-distIn / (rimWidth * 0.42));
          dx += gx * rim * rimPx;
          dy += gy * rim * rimPx;
          var mag = Math.hypot(dx, dy);
          if (distIn > rimWidth) {
            cSum += mag;
            cN++;
          } else if (distIn < rimWidth * 0.5) {
            rSum += mag;
            rN++;
          }
        }
        var rch = Math.max(0, Math.min(255, Math.round(128 + (dx / scale) * 127)));
        var gch = Math.max(0, Math.min(255, Math.round(128 + (dy / scale) * 127)));
        var i = (y * mapW + x) * 4;
        data[i] = rch;
        data[i + 1] = gch;
        data[i + 2] = 128;
        data[i + 3] = 255;
      }
    }
    ctx.putImageData(img, 0, 0);
    return {
      url: canvas.toDataURL("image/png"),
      scale: scale,
      centerDelta: cN ? cSum / cN : 0,
      rimDelta: rN ? rSum / rN : 0,
      width: mapW,
      height: mapH
    };
  }

  function cachedMap(width, height, radius) {
    var key = [
      Math.round(width / 4) * 4,
      Math.round(height / 4) * 4,
      Math.round(radius)
    ].join("x");
    if (mapCache.has(key)) {
      var hit = mapCache.get(key);
      mapCache.delete(key);
      mapCache.set(key, hit);
      return hit;
    }
    var built = buildDisplacementMap(
      Math.round(width / 4) * 4 || width,
      Math.round(height / 4) * 4 || height,
      radius
    );
    built.key = key;
    mapCache.set(key, built);
    while (mapCache.size > MAP_CACHE_MAX) {
      var oldest = mapCache.keys().next().value;
      mapCache.delete(oldest);
    }
    return built;
  }

  function ensureSvg() {
    var svg = document.getElementById("shinyglass-refract-svg");
    if (svg) return svg;
    svg = document.createElementNS(SVG_NS, "svg");
    svg.setAttribute("id", "shinyglass-refract-svg");
    svg.setAttribute("aria-hidden", "true");
    svg.setAttribute("width", "0");
    svg.setAttribute("height", "0");
    svg.style.cssText = "position:absolute;width:0;height:0;overflow:hidden;pointer-events:none";
    var defs = document.createElementNS(SVG_NS, "defs");
    svg.appendChild(defs);
    (document.body || document.documentElement).appendChild(svg);
    return svg;
  }

  function svgEl(name, attrs) {
    var node = document.createElementNS(SVG_NS, name);
    if (!attrs) return node;
    Object.keys(attrs).forEach(function (key) {
      if (key === "href") {
        node.setAttribute("href", attrs[key]);
        node.setAttributeNS(XLINK_NS, "href", attrs[key]);
      } else {
        node.setAttribute(key, attrs[key]);
      }
    });
    return node;
  }

  function writeFilter(filter, mapUrl, scale, disperse, dispersion, pixelW, pixelH) {
    while (filter.firstChild) filter.removeChild(filter.firstChild);
    filter.appendChild(svgEl("feImage", {
      href: mapUrl,
      result: "map",
      preserveAspectRatio: "none",
      x: "0",
      y: "0",
      width: String(Math.max(1, Math.round(pixelW))),
      height: String(Math.max(1, Math.round(pixelH)))
    }));
    if (!disperse) {
      filter.appendChild(svgEl("feDisplacementMap", {
        in: "SourceGraphic",
        in2: "map",
        scale: String(scale.toFixed(2)),
        xChannelSelector: "R",
        yChannelSelector: "G"
      }));
      return;
    }
    var spread = dispersion > 0 ? dispersion : 0.06;
    var scales = [scale * (1 - spread), scale, scale * (1 + spread)];
    var matrices = [
      "1 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 1 0",
      "0 0 0 0 0  0 1 0 0 0  0 0 0 0 0  0 0 0 1 0",
      "0 0 0 0 0  0 0 0 0 0  0 0 1 0 0  0 0 0 1 0"
    ];
    var results = ["chanR", "chanG", "chanB"];
    for (var i = 0; i < 3; i++) {
      filter.appendChild(svgEl("feDisplacementMap", {
        in: "SourceGraphic",
        in2: "map",
        scale: scales[i].toFixed(2),
        xChannelSelector: "R",
        yChannelSelector: "G",
        result: "disp" + i
      }));
      filter.appendChild(svgEl("feColorMatrix", {
        in: "disp" + i,
        type: "matrix",
        values: matrices[i],
        result: results[i]
      }));
    }
    filter.appendChild(svgEl("feComposite", {
      in: "chanR",
      in2: "chanG",
      operator: "arithmetic",
      k2: "1",
      k3: "1",
      result: "rg"
    }));
    filter.appendChild(svgEl("feComposite", {
      in: "rg",
      in2: "chanB",
      operator: "arithmetic",
      k2: "1",
      k3: "1"
    }));
  }

  function ensureFilter(index) {
    var svg = ensureSvg();
    var defs = svg.querySelector("defs");
    var id = "shinyglass-refract-" + index;
    var filter = document.getElementById(id);
    if (!filter) {
      filter = svgEl("filter", {
        id: id,
        x: "-0.12",
        y: "-0.12",
        width: "1.24",
        height: "1.24",
        filterUnits: "objectBoundingBox",
        primitiveUnits: "userSpaceOnUse",
        "color-interpolation-filters": "sRGB"
      });
      defs.appendChild(filter);
    }
    return filter;
  }

  function clearRefraction() {
    document.querySelectorAll(".glass-refract").forEach(function (el) {
      el.classList.remove("glass-refract");
      el.style.removeProperty("--glass-refract-filter");
    });
  }

  function readRadius(el) {
    var v = 16;
    try {
      v = parseFloat(getComputedStyle(el).borderTopLeftRadius);
    } catch (e) {
      v = 16;
    }
    if (!isFinite(v)) v = 16;
    return v;
  }

  function refractRank(el) {
    if (el.matches(".navbar, .bslib-sidebar-layout > .sidebar, .glass-sidebar, .nav-pills, .glass-tabbar, .tabbable > .nav-tabs, .offcanvas, .shiny-chat-page-header, .shiny-chat-page-sidebar, .shiny-chat-input .tiptap")) {
      return 3;
    }
    if (el.matches(".modal-content, .dropdown-menu, .popover, .shiny-chat-slash-palette")) return 2;
    return 1;
  }

  function syncRefraction() {
    markRefractionSupport();
    if (refractionBlocked() || !document.body) {
      clearRefraction();
      return;
    }
    var nodes = Array.prototype.slice.call(document.querySelectorAll(REFRACT_SELECTOR));
    var candidates = [];
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      if (el.closest("[data-glass-no-refract]")) continue;
      if (el.parentElement) {
        var parentHit = el.parentElement.closest(REFRACT_SELECTOR);
        if (parentHit) continue;
      }
      var rect = el.getBoundingClientRect();
      if (rect.width < 72 || rect.height < 32) continue;
      if (rect.bottom < -40 || rect.top > window.innerHeight + 40) continue;
      if (rect.right < -40 || rect.left > window.innerWidth + 40) continue;
      candidates.push({ el: el, rank: refractRank(el), area: rect.width * rect.height, rect: rect });
    }
    candidates.sort(function (a, b) {
      if (b.rank !== a.rank) return b.rank - a.rank;
      return b.area - a.area;
    });
    if (candidates.length > REFRACT_CAP) candidates = candidates.slice(0, REFRACT_CAP);
    var keep = new Set();
    var ior = readNumber("--glass-ior", IOR_DESIGN);
    if (ior < 1.01 || ior > 2.4) ior = IOR_DESIGN;
    var snell = (1 - 1 / ior) / (1 - 1 / IOR_DESIGN);
    var baseScale = readNumber("--glass-refraction-scale", 42);
    if (baseScale <= 0) baseScale = 42;
    var dispersion = readNumber("--glass-dispersion", 0.06);
    var disperse = dispersionEnabled() && dispersion > 0.001;
    candidates.forEach(function (item, index) {
      var el = item.el;
      keep.add(el);
      var radius = readRadius(el);
      var map = cachedMap(item.rect.width, item.rect.height, radius);
      var filter = ensureFilter(index);
      var scale = baseScale * snell * (map.scale / 42);
      var signature = [map.key, scale.toFixed(2), disperse ? "d" : "s", Math.round(item.rect.width), Math.round(item.rect.height)].join("|");
      if (el.dataset.glassRefractKey !== signature) {
        writeFilter(filter, map.url, scale, disperse, dispersion, item.rect.width, item.rect.height);
        el.dataset.glassRefractKey = signature;
      }
      var url = "url(#shinyglass-refract-" + index + ")";
      if (el.style.getPropertyValue("--glass-refract-filter") !== url) {
        el.style.setProperty("--glass-refract-filter", url);
      }
      el.classList.add("glass-refract");
    });
    document.querySelectorAll(".glass-refract").forEach(function (el) {
      if (!keep.has(el)) {
        el.classList.remove("glass-refract");
        el.style.removeProperty("--glass-refract-filter");
        delete el.dataset.glassRefractKey;
      }
    });
  }

  function activeInGroup(group) {
    return group.querySelector(
      ":scope > .active, :scope > .nav-item.active, :scope > li.active, :scope > .btn.active, :scope > .btn-primary, :scope > [aria-selected='true'], :scope > [aria-pressed='true'], :scope > .nav-link.active"
    ) || group.querySelector(".active, [aria-selected='true'], [aria-pressed='true'].btn");
  }

  function placeIndicator(group, active) {
    if (!active) return;
    var ind = group.querySelector(":scope > .glass-morph-indicator");
    if (!ind) {
      ind = document.createElement("span");
      ind.className = "glass-morph-indicator";
      ind.setAttribute("aria-hidden", "true");
      group.appendChild(ind);
    }
    if (getComputedStyle(group).position === "static") {
      group.style.position = "relative";
    }
    var gr = group.getBoundingClientRect();
    var ar = active.getBoundingClientRect();
    var left = ar.left - gr.left + group.scrollLeft;
    var top = ar.top - gr.top + group.scrollTop;
    var w = Math.max(0, ar.width);
    var h = Math.max(0, ar.height);
    var transform = "translate(" + left.toFixed(2) + "px, " + top.toFixed(2) + "px)";
    var width = w.toFixed(2) + "px";
    var height = h.toFixed(2) + "px";
    if (reducedMotion() || ind.dataset.ready !== "1") {
      ind.style.transition = "none";
    }
    if (ind.style.width !== width) ind.style.width = width;
    if (ind.style.height !== height) ind.style.height = height;
    if (ind.style.transform !== transform) ind.style.transform = transform;
    if (!reducedMotion() && ind.style.transition === "none" && ind.dataset.ready === "1") {
      ind.style.transition = "";
    }
    if (ind.dataset.ready !== "1" || reducedMotion()) {
      // Commit the jump before restoring the spring.
      void ind.offsetWidth;
      if (!reducedMotion()) ind.style.transition = "";
      ind.dataset.ready = "1";
    }
  }

  function syncMorph() {
    if (!document.body) return;
    var groups = Array.prototype.slice.call(document.querySelectorAll(MORPH_SELECTOR));
    groups.forEach(function (group) {
      if (!morphEnabled() || group.closest("[data-glass-no-morph]")) {
        group.classList.remove("glass-morph-group");
        var stale = group.querySelector(":scope > .glass-morph-indicator");
        if (stale) stale.remove();
        return;
      }
      var parentGroup = group.parentElement && group.parentElement.closest(MORPH_SELECTOR);
      if (parentGroup) return;
      var buttons = group.querySelectorAll(":scope > .btn, :scope > .nav-link, :scope > .nav-item, :scope > li, :scope > [role='tab']");
      if (buttons.length < 2 && !group.querySelector(".nav-link, .btn")) {
        return;
      }
      var active = activeInGroup(group);
      if (!active) return;
      group.classList.add("glass-morph-group");
      placeIndicator(group, active);
    });
  }

  function morphFromTrigger(panel, trigger) {
    if (!panel || !morphEnabled() || reducedMotion()) return;
    if (panel.dataset.glassMorphed === "1") return;
    panel.dataset.glassMorphed = "1";
    var origin = "50% 0%";
    try {
      if (trigger && panel.getBoundingClientRect) {
        var tr = trigger.getBoundingClientRect();
        var pr = panel.getBoundingClientRect();
        if (pr.width > 1 && pr.height > 1) {
          var x = ((tr.left + tr.width / 2) - pr.left) / pr.width * 100;
          var y = ((tr.top + tr.height / 2) - pr.top) / pr.height * 100;
          x = Math.max(0, Math.min(100, x));
          y = Math.max(0, Math.min(100, y));
          origin = x.toFixed(1) + "% " + y.toFixed(1) + "%";
        }
      }
    } catch (e) { /* ignore */ }
    panel.style.transformOrigin = origin;
    try {
      panel.animate(
        [
          { scale: "0.84", opacity: 0.42, filter: "blur(2px)" },
          { scale: "1", opacity: 1, filter: "blur(0px)" }
        ],
        { duration: 480, easing: "cubic-bezier(0.16, 1.18, 0.3, 1)" }
      );
    } catch (err) { /* ignore */ }
    window.setTimeout(function () {
      delete panel.dataset.glassMorphed;
    }, 520);
  }

  function bindMenuMorph() {
    document.addEventListener("shown.bs.dropdown", function (e) {
      var root = e.target;
      if (!root || !root.querySelector) return;
      var menu = root.querySelector(".dropdown-menu");
      var trigger = root.querySelector("[data-bs-toggle='dropdown'], .dropdown-toggle") || root;
      morphFromTrigger(menu, trigger);
    }, true);
    document.addEventListener("shown.bs.popover", function (e) {
      var tip = null;
      try {
        var Pop = window.bootstrap && window.bootstrap.Popover;
        var inst = Pop && Pop.getInstance(e.target);
        tip = inst && (inst.tip || inst._element && inst.tip);
      } catch (err) { /* ignore */ }
      if (!tip) tip = document.querySelector(".popover.show");
      morphFromTrigger(tip, e.target);
    }, true);
    // show fires before the slide. scale is separate from Bootstrap's
    // translate, so the panel still enters from its edge and grows from
    // the trigger when one is known.
    document.addEventListener("show.bs.offcanvas", function (e) {
      var panel = e.target;
      if (!panel || !panel.classList || !panel.classList.contains("offcanvas")) return;
      morphFromTrigger(panel, e.relatedTarget || null);
    }, true);
  }

  function syncChatMessages(scroller) {
    var top = scroller.scrollTop > 8;
    var gap = scroller.scrollHeight - scroller.scrollTop - scroller.clientHeight;
    var bottom = gap > 24;
    var page = scroller.closest ? scroller.closest("shiny-chat-page") : null;
    var root = scroller.closest ? scroller.closest("shiny-chat-container") : null;
    var header = page && page.querySelector(".shiny-chat-page-header");
    var composer = root && root.querySelector(".shiny-chat-composer, .shiny-chat-input");
    if (header) header.classList.toggle("glass-scroll-edge", top);
    if (composer) composer.classList.toggle("glass-scroll-edge", bottom);
    scroller.classList.toggle("glass-scroll-edge-top", top);
    scroller.classList.toggle("glass-scroll-edge-bottom", bottom);
  }

  function syncOffcanvasBody(body) {
    var overflowing = body.scrollHeight > body.clientHeight + 2;
    body.classList.toggle("glass-overflowing", overflowing);
    var host = body.closest ? body.closest(".offcanvas") : null;
    if (host) host.classList.toggle("glass-scroll-edge", body.scrollTop > 8);
  }

  function syncOpenScrollers() {
    if (!flagEnabled("glassScrollEdge", true)) return;
    var nodes = document.querySelectorAll(".shiny-chat-messages, .offcanvas-body");
    var i;
    for (i = 0; i < nodes.length; i++) {
      var t = nodes[i];
      if (t.classList.contains("shiny-chat-messages")) syncChatMessages(t);
      if (t.classList.contains("offcanvas-body")) syncOffcanvasBody(t);
    }
  }

  function bindScrollEdges() {
    var queued = false;
    function kick() {
      if (queued) return;
      queued = true;
      var raf = window.requestAnimationFrame || function (fn) { return window.setTimeout(fn, 16); };
      raf(function () {
        queued = false;
        syncOpenScrollers();
      });
    }
    document.addEventListener("scroll", function (e) {
      if (!flagEnabled("glassScrollEdge", true)) return;
      var t = e.target;
      if (!t || !t.classList) return;
      if (t.classList.contains("shiny-chat-messages")) {
        syncChatMessages(t);
        return;
      }
      if (t.classList.contains("offcanvas-body")) {
        syncOffcanvasBody(t);
        return;
      }
      // Page-level scroll (not the chat transcript, which lives on
      // .shiny-chat-messages) still fades a header that sits over it.
      if (t.classList.contains("shiny-chat-page-main") && t.scrollHeight > t.clientHeight + 2) {
        var host = t.closest ? t.closest("shiny-chat-page") : null;
        var bar = host && host.querySelector(".shiny-chat-page-header");
        if (bar) bar.classList.toggle("glass-scroll-edge", t.scrollTop > 8);
      }
    }, true);
    if (window.MutationObserver && document.documentElement) {
      var obs = new MutationObserver(kick);
      obs.observe(document.documentElement, { childList: true, subtree: true });
    }
    window.addEventListener("resize", kick);
    document.addEventListener("shown.bs.offcanvas", kick, true);
    kick();
  }

  function releasePress() {
    var el = pressedEl;
    pressedEl = null;
    if (!el) return;
    var rot = el.style.rotate || "0deg";
    el.style.scale = "";
    el.style.rotate = "";
    if (reducedMotion() || !pressEnabled()) return;
    try {
      el.animate(
        [
          { scale: "0.965", rotate: rot },
          { scale: "1.018", rotate: "0deg", offset: 0.62 },
          { scale: "1", rotate: "0deg" }
        ],
        { duration: 460, easing: "cubic-bezier(0.2, 0.85, 0.25, 1.12)" }
      );
    } catch (err) { /* ignore */ }
  }

  function coarsePointer() {
    try {
      return window.matchMedia("(pointer: coarse)").matches;
    } catch (e) {
      return false;
    }
  }

  function hideTippy(inst) {
    try {
      if (inst && inst.state && inst.state.isShown) inst.hide();
    } catch (e) { /* ignore */ }
  }

  function pointInRect(x, y, rect) {
    return x >= rect.left && x <= rect.right && y >= rect.top && y <= rect.bottom;
  }

  // Second tap on a Settings drop menu or bslib popover closes it. A tap
  // outside the panel closes it too. Desktop click toggle is left alone.
  function bindOverlayDismiss() {
    // Swallow only the click from the tap that closed the panel. A later
    // tap (its pointerdown is newer than that pointerup) still opens it,
    // even if the first click is delivered late.
    var arm = null;
    document.addEventListener("pointerdown", function (e) {
      if (arm && e.timeStamp > arm.upTs) arm.olderThan = e.timeStamp;
    }, true);
    document.addEventListener("pointerup", function (e) {
      if (!coarsePointer()) return;
      if (e.button != null && e.button !== 0) return;
      var target = e.target;
      if (!target || !target.closest) return;
      var x = e.clientX;
      var y = e.clientY;
      var closedOnTrigger = false;
      var menus = document.querySelectorAll(".drop-menu-input");
      var i;
      for (i = 0; i < menus.length; i++) {
        var id = menus[i].getAttribute("data-target");
        var trigger = id && document.getElementById(id);
        var inst = trigger && trigger._tippy;
        if (!inst || !inst.state || !inst.state.isShown) continue;
        var pop = inst.popper;
        var onTrigger = trigger.contains(target) || pointInRect(x, y, trigger.getBoundingClientRect());
        var onPop = pop && (pop === target || pop.contains(target));
        if (onTrigger) {
          hideTippy(inst);
          closedOnTrigger = true;
          continue;
        }
        if (!onPop) hideTippy(inst);
      }
      var pops = document.querySelectorAll(".popover.show");
      var j;
      for (j = 0; j < pops.length; j++) {
        var popEl = pops[j];
        if (popEl.contains(target)) continue;
        var pid = popEl.getAttribute("id");
        var trig = pid && document.querySelector('[aria-describedby="' + pid + '"]');
        var onTrig = false;
        if (trig) {
          onTrig = trig.contains(target) || pointInRect(x, y, trig.getBoundingClientRect());
        }
        try {
          var Pop = window.bootstrap && window.bootstrap.Popover;
          var pinst = Pop && trig && Pop.getInstance(trig);
          if (pinst) pinst.hide();
          else popEl.classList.remove("show");
        } catch (err) { /* ignore */ }
        if (onTrig) closedOnTrigger = true;
      }
      if (closedOnTrigger) {
        var stamp = e.timeStamp;
        arm = { upTs: stamp, olderThan: Infinity };
        window.setTimeout(function () {
          if (arm && arm.upTs === stamp) arm = null;
        }, 700);
      }
    }, true);
    document.addEventListener("click", function (e) {
      if (!arm) return;
      // Clicks from the closing tap are older than the next pointerdown.
      if (e.timeStamp + 1 < arm.olderThan) {
        e.preventDefault();
        e.stopPropagation();
      }
    }, true);
  }

  function bindPressPhysics() {
    document.addEventListener("pointerdown", function (e) {
      if (!pressEnabled() || reducedMotion()) return;
      if (e.button != null && e.button !== 0) return;
      var target = e.target;
      if (!target || !target.closest) return;
      var el = target.closest(PRESS_SELECTOR);
      if (!el) return;
      // Press scale on a popover or drop-menu trigger swallows the second tap
      // on touch, so the menu stays open.
      if (target.closest(".drop-menu-input, [data-bs-toggle='popover']")) return;
      if (el.disabled || el.getAttribute("aria-disabled") === "true" || el.classList.contains("disabled")) return;
      if (target.closest("input, textarea, select, .form-control")) return;
      var rect = el.getBoundingClientRect();
      var ox = ((e.clientX - (rect.left + rect.width / 2)) / (rect.width || 1));
      ox = Math.max(-1, Math.min(1, ox));
      pressedEl = el;
      el.style.scale = "0.965";
      el.style.rotate = (ox * -1.35).toFixed(3) + "deg";
    }, true);
    document.addEventListener("pointerup", releasePress, true);
    document.addEventListener("pointercancel", releasePress, true);
  }

  function noteTabInteraction() {
    tabsHoldUntil = Date.now() + 1400;
    if (document.body) document.body.classList.remove("glass-tabs-min");
  }

  function bindTabInteraction() {
    function hit(e) {
      if (!flagEnabled("glassMinimizeTabs", true)) return;
      var target = e.target;
      if (!target || !target.closest) return;
      if (!target.closest(".nav-pills, .nav-tabs, .glass-tabbar, nav.fixed-bottom, .navbar")) return;
      noteTabInteraction();
    }
    document.addEventListener("pointerdown", hit, true);
    document.addEventListener("focusin", hit, true);
  }

  function scheduleIos27Motion() {
    if (refractFrame) return;
    refractFrame = window.requestAnimationFrame(function () {
      refractFrame = 0;
      try {
        syncRefraction();
        syncMorph();
      } catch (err) { /* keep the page usable if a surface is mid-detach */ }
    });
  }

  function setFlag(datasetName, on) {
    rootEl().dataset[datasetName] = on ? "true" : "false";
    scheduleIos27Motion();
  }

  function setIconStyle(style) {
    if (style !== "clear" && style !== "color" && style !== "all") style = "clear";
    rootEl().dataset.glassIconStyle = style;
  }

  function initIos27Motion() {
    if (ios27Started) {
      scheduleIos27Motion();
      return;
    }
    ios27Started = true;
    bindPressPhysics();
    bindOverlayDismiss();
    bindMenuMorph();
    bindScrollEdges();
    bindTabInteraction();
    scheduleIos27Motion();
    window.addEventListener("resize", scheduleIos27Motion, { passive: true });
    window.addEventListener("scroll", function () {
      var now = Date.now();
      if (now - scrollScanAt < 180) return;
      scrollScanAt = now;
      scheduleIos27Motion();
    }, { passive: true });
  }

  var api = window.shinyglass = window.shinyglass || {};
  api.setRefraction = function (on) { setFlag("glassRefraction", !!on); };
  api.setMorph = function (on) { setFlag("glassMorph", !!on); };
  api.setPress = function (on) { setFlag("glassPress", !!on); };
  api.setScrollEdge = function (on) { setFlag("glassScrollEdge", !!on); };
  api.setMinimizeTabs = function (on) { setFlag("glassMinimizeTabs", !!on); };
  api.setFloatingSidebar = function (on) { setFlag("glassFloatingSidebar", !!on); };
  api.setIconStyle = setIconStyle;
  api.supportsRefraction = supportsDisplacementBackdrop;
  api._buildDisplacementMap = buildDisplacementMap;
  api._isLowTierDevice = isLowTierDevice;
  api._scheduleIos27 = scheduleIos27Motion;
  api._noteTabInteraction = noteTabInteraction;
  api._tabsHoldUntil = function () { return tabsHoldUntil; };

  // Expose the scroll-edge / minimize gates used by shiny-glass.js.
  api._scrollEdgeEnabled = function () { return flagEnabled("glassScrollEdge", true); };
  api._minimizeTabsEnabled = function () { return flagEnabled("glassMinimizeTabs", true); };
  api._reducedMotion = reducedMotion;

  function onReady(fn) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", fn);
    } else {
      fn();
    }
  }

  onReady(initIos27Motion);

  // If shiny-glass.js has not finished evaluating, retry once jquery is up.
  if (window.jQuery) {
    window.jQuery(initIos27Motion);
  }

  // Mutation hook: shiny-glass.js owns the main observer. A light observer
  // here only watches childList so late UI still refracts and morphs.
  onReady(function () {
    if (!window.MutationObserver || !document.body) return;
    var pending = false;
    var obs = new MutationObserver(function () {
      if (pending) return;
      pending = true;
      window.requestAnimationFrame(function () {
        pending = false;
        scheduleIos27Motion();
      });
    });
    obs.observe(document.body, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ["class", "aria-selected", "aria-pressed"]
    });
    document.addEventListener("click", function (e) {
      if (!e.target || !e.target.closest) return;
      if (e.target.closest(MORPH_SELECTOR)) scheduleIos27Motion();
    }, true);
  });

  window.__shinyglassIos27 = {
    init: initIos27Motion,
    schedule: scheduleIos27Motion,
    syncRefraction: syncRefraction,
    syncMorph: syncMorph
  };
})();
