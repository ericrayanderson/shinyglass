/* Desktop phone preview. frame=0 (the iframe) never mounts a control. */
(function () {
  "use strict";

  var appMeta = document.querySelector('meta[name="shinyglass-phone-app"]');
  var frameMeta = document.querySelector('meta[name="shinyglass-phone-frame"]');
  var root = document.documentElement;
  if (!root || !appMeta) return;

  var appId = appMeta.getAttribute("content") || "";
  if (!/^[a-z0-9-]+$/.test(appId)) return;
  root.setAttribute("data-phone-app", appId);

  if (frameMeta && frameMeta.getAttribute("content") === "0") {
    root.setAttribute("data-phone-frame", "0");
    return;
  }

  var storageKey = "shinyglass-phone-preview:" + appId;
  var desktopQuery = window.matchMedia("(min-width: 900px) and (pointer: fine)");
  var DEVICE_W = 413;
  var DEVICE_H = 872;
  var MARGIN = 72;

  function desktop() {
    return desktopQuery.matches;
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

  if (desktop() && readMode() === "phone") {
    root.classList.add("phone-preview-on");
  }

  function boot() {
    if (!document.body || document.body.querySelector(".phone-preview-toggle")) return;

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
      '<iframe class="phone-preview-frame" title="Phone view"></iframe>' +
      '<div class="phone-preview-island" aria-hidden="true"></div>' +
      "</div></div></div>";

    var sizer = stage.querySelector(".phone-preview-sizer");
    var device = stage.querySelector(".phone-preview-device");
    var iframe = stage.querySelector(".phone-preview-frame");
    var label = toggle.querySelector(".phone-preview-label");
    var phoneOn = false;

    function frameUrl() {
      var url = new URL(window.location.href);
      url.searchParams.set("frame", "0");
      url.hash = "";
      return url.toString();
    }

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

    function setPhone(on, persist) {
      var next = Boolean(on) && desktop();
      var hadFrame = Boolean(iframe.getAttribute("src"));
      phoneOn = next;
      root.classList.toggle("phone-preview-on", next);
      toggle.setAttribute("aria-pressed", next ? "true" : "false");
      label.textContent = next ? "Full view" : "Phone view";
      if (next) {
        fit();
        stage.hidden = false;
        if (!hadFrame) iframe.setAttribute("src", frameUrl());
      } else {
        stage.hidden = true;
        if (hadFrame) {
          iframe.removeAttribute("src");
          window.setTimeout(function () {
            window.dispatchEvent(new Event("resize"));
          }, 60);
        }
      }
      if (persist) writeMode(next ? "phone" : "full");
    }

    toggle.addEventListener("click", function () {
      setPhone(!phoneOn, true);
    });

    function onDesktopChange() {
      if (!desktop()) {
        if (phoneOn || root.classList.contains("phone-preview-on")) setPhone(false, false);
        return;
      }
      if (!phoneOn && readMode() === "phone") setPhone(true, false);
    }

    if (typeof desktopQuery.addEventListener === "function") {
      desktopQuery.addEventListener("change", onDesktopChange);
    } else if (typeof desktopQuery.addListener === "function") {
      desktopQuery.addListener(onDesktopChange);
    }
    window.addEventListener("resize", function () {
      if (phoneOn) fit();
    });

    document.body.appendChild(stage);
    document.body.appendChild(toggle);

    if (desktop() && readMode() === "phone") setPhone(true, false);
    else root.classList.remove("phone-preview-on");
  }

  if (document.body) boot();
  else document.addEventListener("DOMContentLoaded", boot);
})();
