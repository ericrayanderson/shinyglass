/* Desktop phone preview.
   Real phones and narrow windows are untouched: no control, no iframe,
   no second session, and no scroll or touch listeners. The only always-on
   listener is matchMedia('(pointer: fine) and (min-width: 900px)'), which
   mounts or removes the desktop UI when that query changes. */
(function () {
  "use strict";

  var DESKTOP = "(pointer: fine) and (min-width: 900px)";
  var appMeta = document.querySelector('meta[name="shinyglass-phone-app"]');
  var frameMeta = document.querySelector('meta[name="shinyglass-phone-frame"]');
  var root = document.documentElement;
  if (!root || !appMeta) return;

  var appId = appMeta.getAttribute("content") || "";
  if (!/^[a-z0-9-]+$/.test(appId)) return;

  // The framed copy of the app. Stop before any listener or widget.
  if (frameMeta && frameMeta.getAttribute("content") === "0") {
    root.setAttribute("data-phone-app", appId);
    root.setAttribute("data-phone-frame", "0");
    // The iframe is a fine pointer. Coarse rules still have to match a phone.
    root.setAttribute("data-glass-pointer", "coarse");
    return;
  }

  var desktopQuery = window.matchMedia(DESKTOP);
  var storageKey = "shinyglass-phone-preview:" + appId;
  var DEVICE_W = 413;
  var DEVICE_H = 872;
  var ui = null;

  function phoneTime() {
    var d = new Date();
    var h = d.getHours() % 12;
    if (h === 0) h = 12;
    var m = String(d.getMinutes());
    if (m.length < 2) m = "0" + m;
    return h + ":" + m;
  }

  function chromeMode(el) {
    var node = el || root;
    var theme = node.getAttribute("data-bs-theme") || "";
    var preset = node.getAttribute("data-glass-preset") || "";
    if (theme === "dark" || theme === "light") return theme;
    if (preset === "dark" || preset === "light") return preset;
    try {
      return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
    } catch (err) {
      return "light";
    }
  }

  function readMode() {
    try {
      return localStorage.getItem(storageKey) === "phone" ? "phone" : "full";
    } catch (err) {
      return "full";
    }
  }

  function writeMode(mode) {
    try {
      localStorage.setItem(storageKey, mode);
    } catch (err) {}
  }

  function frameUrl() {
    var url = new URL(window.location.href);
    url.searchParams.set("frame", "0");
    url.hash = "";
    return url.toString();
  }

  function mount() {
    if (ui || !desktopQuery.matches || !document.body) return;

    root.setAttribute("data-phone-app", appId);

    var toggle = document.createElement("button");
    toggle.type = "button";
    toggle.className = "phone-preview-toggle";
    toggle.setAttribute("aria-pressed", "false");
    toggle.innerHTML =
      '<svg class="phone-preview-icon" viewBox="0 0 24 24" width="16" height="16" aria-hidden="true" focusable="false">' +
      '<rect x="7" y="2.5" width="10" height="19" rx="2.2" fill="none" stroke="currentColor" stroke-width="1.7"></rect>' +
      '<circle cx="12" cy="18.15" r="0.85" fill="currentColor"></circle>' +
      "</svg>" +
      '<span class="phone-preview-label">Phone view</span>';

    var stage = document.createElement("div");
    stage.className = "phone-preview-root";
    stage.hidden = true;
    stage.innerHTML =
      '<div class="phone-preview-sizer">' +
      '<div class="phone-preview-device">' +
      '<div class="phone-preview-screen">' +
      '<div class="phone-preview-status" aria-hidden="true">' +
      '<span class="phone-preview-time"></span>' +
      '<span class="phone-preview-status-glyphs">' +
      '<svg viewBox="0 0 18 12" width="17" height="12" aria-hidden="true"><rect x="0" y="8" width="3" height="4" rx="0.5"></rect><rect x="5" y="5.5" width="3" height="6.5" rx="0.5"></rect><rect x="10" y="3" width="3" height="9" rx="0.5"></rect><rect x="15" y="0" width="3" height="12" rx="0.5"></rect></svg>' +
      '<svg viewBox="0 0 16 12" width="16" height="12" aria-hidden="true"><path d="M8 10.6a1.15 1.15 0 1 0 .01 0z"></path><path d="M4.1 7.3a5.5 5.5 0 0 1 7.8 0" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"></path><path d="M1.5 4.7a9.1 9.1 0 0 1 13 0" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"></path></svg>' +
      '<svg viewBox="0 0 25 12" width="25" height="12" aria-hidden="true"><rect x="0.7" y="0.7" width="20" height="10.6" rx="2.2" fill="none" stroke="currentColor" stroke-width="1.3"></rect><rect x="2.3" y="2.3" width="15.2" height="7.4" rx="1"></rect><path d="M22.2 4h1.1c.7 0 1.2.5 1.2 1.1v1.8c0 .6-.5 1.1-1.2 1.1h-1.1z"></path></svg>' +
      "</span></div>" +
      '<div class="phone-preview-island" aria-hidden="true"></div>' +
      '<div class="phone-preview-home" aria-hidden="true"><span class="phone-preview-home-bar"></span></div>' +
      "</div></div></div>";

    var sizer = stage.querySelector(".phone-preview-sizer");
    var device = stage.querySelector(".phone-preview-device");
    var screen = stage.querySelector(".phone-preview-screen");
    var label = toggle.querySelector(".phone-preview-label");
    var clock = window.setInterval(function () {
      var time = screen.querySelector(".phone-preview-time");
      if (time) time.textContent = phoneTime();
    }, 30000);
    screen.querySelector(".phone-preview-time").textContent = phoneTime();
    screen.setAttribute("data-phone-chrome", chromeMode(root));
    var phoneOn = false;

    function watchChrome(frame) {
      if (frame.getAttribute("data-chrome-watch")) return;
      frame.setAttribute("data-chrome-watch", "1");
      function apply() {
        var doc = null;
        try {
          doc = frame.contentDocument;
        } catch (err) {
          doc = null;
        }
        var node = doc && doc.documentElement ? doc.documentElement : root;
        screen.setAttribute("data-phone-chrome", chromeMode(node));
        if (!doc || !doc.documentElement || frame._chromeObs) return;
        try {
          frame._chromeObs = new MutationObserver(function () {
            screen.setAttribute("data-phone-chrome", chromeMode(doc.documentElement));
          });
          frame._chromeObs.observe(doc.documentElement, {
            attributes: true,
            attributeFilter: ["data-bs-theme", "data-glass-preset"]
          });
        } catch (err) {}
      }
      frame.addEventListener("load", apply);
    }

    function fit() {
      // About 90% of the window, on the shorter axis, so a short desktop
      // still shows a large phone. Aspect stays 413:872. Scale may exceed 1.
      var scale = Math.min(
        (window.innerHeight * 0.9) / DEVICE_H,
        (window.innerWidth * 0.9) / DEVICE_W
      );
      if (!isFinite(scale) || scale <= 0) scale = 1;
      sizer.style.width = DEVICE_W * scale + "px";
      sizer.style.height = DEVICE_H * scale + "px";
      device.style.transform = "scale(" + scale + ")";
    }

    function dropFrame() {
      var frame = screen.querySelector("iframe.phone-preview-frame");
      if (!frame) return false;
      if (frame._chromeObs) {
        frame._chromeObs.disconnect();
        frame._chromeObs = null;
      }
      frame.removeAttribute("src");
      frame.remove();
      return true;
    }

    function ensureFrame() {
      var frame = screen.querySelector("iframe.phone-preview-frame");
      if (!frame) {
        frame = document.createElement("iframe");
        frame.className = "phone-preview-frame";
        frame.title = "Phone view";
        screen.insertBefore(frame, screen.firstChild);
      }
      if (!frame.getAttribute("src")) frame.setAttribute("src", frameUrl());
      watchChrome(frame);
    }

    function setPhone(on, persist) {
      if (!desktopQuery.matches) on = false;
      var next = Boolean(on);
      var hadFrame = Boolean(screen.querySelector("iframe.phone-preview-frame"));
      phoneOn = next;
      root.classList.toggle("phone-preview-on", next);
      toggle.setAttribute("aria-pressed", next ? "true" : "false");
      label.textContent = next ? "Full view" : "Phone view";
      if (next) {
        fit();
        stage.hidden = false;
        ensureFrame();
      } else {
        stage.hidden = true;
        if (dropFrame() && hadFrame) {
          window.setTimeout(function () {
            window.dispatchEvent(new Event("resize"));
          }, 60);
        }
      }
      if (persist) writeMode(next ? "phone" : "full");
    }

    function onResize() {
      if (phoneOn && desktopQuery.matches) fit();
    }

    toggle.addEventListener("click", function () {
      setPhone(!phoneOn, true);
    });
    window.addEventListener("resize", onResize);

    document.body.appendChild(stage);
    document.body.appendChild(toggle);

    ui = {
      destroy: function () {
        var wasOn = root.classList.contains("phone-preview-on");
        window.removeEventListener("resize", onResize);
        window.clearInterval(clock);
        dropFrame();
        stage.remove();
        toggle.remove();
        root.classList.remove("phone-preview-on");
        root.removeAttribute("data-phone-app");
        phoneOn = false;
        ui = null;
        if (wasOn) {
          window.setTimeout(function () {
            window.dispatchEvent(new Event("resize"));
          }, 60);
        }
      }
    };

    if (readMode() === "phone") setPhone(true, false);
    else root.classList.remove("phone-preview-on");
  }

  function sync() {
    if (desktopQuery.matches) {
      if (document.body) mount();
      else document.addEventListener("DOMContentLoaded", mount, { once: true });
      return;
    }
    if (ui) ui.destroy();
    else root.classList.remove("phone-preview-on");
  }

  if (typeof desktopQuery.addEventListener === "function") {
    desktopQuery.addEventListener("change", sync);
  } else if (typeof desktopQuery.addListener === "function") {
    desktopQuery.addListener(sync);
  }

  if (desktopQuery.matches && readMode() === "phone") {
    root.classList.add("phone-preview-on");
  }

  var current = document.currentScript;
  if (!current || !current.src || document.querySelector("link[data-phone-preview-css]")) {
    sync();
    return;
  }
  var link = document.createElement("link");
  link.rel = "stylesheet";
  link.href = current.src.replace(/phone-preview\.js(\?.*)?$/, "phone-preview.css$1");
  link.setAttribute("data-phone-preview-css", "1");
  link.onload = sync;
  link.onerror = sync;
  document.head.appendChild(link);
})();
