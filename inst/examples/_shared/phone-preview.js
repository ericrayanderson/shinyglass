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
    return;
  }

  var desktopQuery = window.matchMedia(DESKTOP);
  var storageKey = "shinyglass-phone-preview:" + appId;
  var DEVICE_W = 413;
  var DEVICE_H = 872;
  var MARGIN = 72;
  var ui = null;

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
      '<div class="phone-preview-island" aria-hidden="true"></div>' +
      "</div></div></div>";

    var sizer = stage.querySelector(".phone-preview-sizer");
    var device = stage.querySelector(".phone-preview-device");
    var screen = stage.querySelector(".phone-preview-screen");
    var label = toggle.querySelector(".phone-preview-label");
    var phoneOn = false;

    function fit() {
      var scale = Math.min(
        (window.innerHeight - MARGIN) / DEVICE_H,
        (window.innerWidth - MARGIN) / DEVICE_W,
        1
      );
      if (!isFinite(scale) || scale <= 0) scale = 1;
      sizer.style.width = DEVICE_W * scale + "px";
      sizer.style.height = DEVICE_H * scale + "px";
      device.style.transform = "scale(" + scale + ")";
    }

    function dropFrame() {
      var frame = screen.querySelector("iframe.phone-preview-frame");
      if (!frame) return false;
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
