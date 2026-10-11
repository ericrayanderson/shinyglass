// Browser-side helpers for audit-glass-contrast.R
// Exposes: runGlassAudit(selectors, preset, minContrast) -> { preset, findings }

function glassParseColor(str) {
  if (!str || str === "transparent" || str === "rgba(0, 0, 0, 0)") {
    return null;
  }
  const m = str.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?\)/i);
  if (m) {
    return {
      r: +m[1],
      g: +m[2],
      b: +m[3],
      a: m[4] === undefined ? 1 : +m[4]
    };
  }
  // Chrome resolves color-mix() to color(srgb … / a), not rgba().
  const c = str.match(/color\(srgb\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)(?:\s*\/\s*([\d.]+))?\)/i);
  if (!c) return null;
  return {
    r: Math.round(+c[1] * 255),
    g: Math.round(+c[2] * 255),
    b: Math.round(+c[3] * 255),
    a: c[4] === undefined ? 1 : +c[4]
  };
}

function glassSrgbChannel(c) {
  c = c / 255;
  return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}

function glassRelLum(col) {
  return (
    0.2126 * glassSrgbChannel(col.r) +
    0.7152 * glassSrgbChannel(col.g) +
    0.0722 * glassSrgbChannel(col.b)
  );
}

function glassContrastRatio(a, b) {
  const L1 = glassRelLum(a);
  const L2 = glassRelLum(b);
  const hi = Math.max(L1, L2);
  const lo = Math.min(L1, L2);
  return (hi + 0.05) / (lo + 0.05);
}

function glassComposite(fg, bg) {
  if (!fg) return bg;
  if (!bg) return fg;
  const a = fg.a + bg.a * (1 - fg.a);
  if (a < 1e-6) return null;
  return {
    r: Math.round((fg.r * fg.a + bg.r * bg.a * (1 - fg.a)) / a),
    g: Math.round((fg.g * fg.a + bg.g * bg.a * (1 - fg.a)) / a),
    b: Math.round((fg.b * fg.a + bg.b * bg.a * (1 - fg.a)) / a),
    a: a
  };
}

function glassIsNearBlack(c) {
  return c && c.a > 0.9 && c.r < 8 && c.g < 8 && c.b < 8;
}

function glassIsBootstrapLightGrey(c) {
  if (!c || c.a < 0.9) return false;
  return c.r > 220 && c.r < 245 && c.g > 220 && c.g < 245 && c.b > 220 && c.b < 245;
}

function glassIsControlSelector(sel, className) {
  const s = (sel || "") + " " + (className || "");
  return /page-link|paginate|btn-primary|btn-secondary|irs-single|nav-link|value-box|form-check|selectize|bg-primary|bg-success|bg-info|datepicker|shiny-notification|accordion|tooltip|popover|toast|dropdown-menu|btn-close|btn-file|form-control|form-select/i.test(
    s
  );
}

function glassSampleEl(el, pageBg, preset, minContrast, textAA) {
  const cs = getComputedStyle(el);
  const color = glassParseColor(cs.color);
  let bg = glassParseColor(cs.backgroundColor);
  const ownBg = bg;
  let node = el;
  let guard = 0;
  while ((!bg || bg.a < 0.99) && node.parentElement && guard < 30) {
    node = node.parentElement;
    const pbg = glassParseColor(getComputedStyle(node).backgroundColor);
    bg = glassComposite(bg, pbg);
    guard++;
  }
  const effectiveBg = glassComposite(bg, pageBg) || pageBg;
  const effectiveFg = glassComposite(color, effectiveBg);
  const findings = [];
  const text = (el.innerText || el.textContent || "").trim().slice(0, 40);
  const sel = el.__auditSelector || el.tagName;
  const meta = {
    selector: sel,
    text: text,
    color: cs.color,
    bg: cs.backgroundColor
  };

  if (cs.display === "none" || cs.visibility === "hidden" || Number(cs.opacity) === 0) {
    return [{ level: "SKIP", code: "hidden", message: "hidden element", meta: meta }];
  }
  if (!el.getClientRects().length) {
    return [{ level: "SKIP", code: "hidden", message: "no rendered box", meta: meta }];
  }
  const disabled = el.matches(":disabled") || el.closest('[aria-disabled="true"], .disabled');
  const size = parseFloat(cs.fontSize);
  const weight = cs.fontWeight === "bold" ? 700 : parseFloat(cs.fontWeight);
  const largeText = size >= 24 || (size >= 56 / 3 && weight >= 700);
  const required = largeText ? 3 : 4.5;
  meta.required_text_contrast = required;
  meta.font_size = cs.fontSize;
  meta.font_weight = cs.fontWeight;
  meta.measurement = "computed-color estimate; gradients, backdrop content and ancestor opacity require visual review";

  if (effectiveFg && effectiveBg && effectiveFg.a > 0.5) {
    const ratio = glassContrastRatio(effectiveFg, effectiveBg);
    meta.contrast = Math.round(ratio * 100) / 100;
    const hasText = text.length > 0;
    const threshold = textAA ? Math.max(minContrast, required) : minContrast;
    if (hasText && !disabled && ratio < threshold) {
      findings.push({
        level: "FAIL",
        code: "low-contrast",
        message:
          "contrast " + meta.contrast + ":1 < " + threshold + ':1 for "' + text + '"',
        meta: meta
      });
    } else if (hasText && !disabled && ratio < required) {
      findings.push({
        level: "WARN",
        code: "contrast-aa",
        message: "contrast " + meta.contrast + ':1 below text threshold ' + required + ' for "' + text + '"',
        meta: meta
      });
    }
  }

  // Signature checks inspect the actual element fill, not ancestor compositing.
  bg = ownBg;

  // Dark-mode solid black chips (DT pagination bug signature)
  if (preset === "dark" && bg && glassIsNearBlack(bg) && bg.a > 0.95) {
    if (/page-link|paginate|selectize-input|form-control|form-select|btn-secondary|datepicker|shiny-notification|accordion|dropdown-menu|toast|popover/i.test(sel)) {
      findings.push({
        level: "FAIL",
        code: "solid-black-chip",
        message:
          'near-black opaque background in dark mode ("' + (text || sel) + '")',
        meta: meta
      });
    }
  }

  // Bootstrap light grey on dark glass (disabled page chips etc.)
  if (preset === "dark" && bg && glassIsBootstrapLightGrey(bg)) {
    findings.push({
      level: "FAIL",
      code: "bootstrap-light-grey",
      message:
        'Bootstrap light-grey fill in dark mode ("' + (text || sel) + '")',
      meta: meta
    });
  }

  // Solid accent blue with dark body ink
  if (bg && effectiveFg && bg.a > 0.9) {
    const isAccentBlue = bg.b > 200 && bg.r < 80 && bg.g < 160;
    const isDarkInk = glassRelLum(effectiveFg) < 0.25;
    if (
      isAccentBlue &&
      isDarkInk &&
      /btn-primary|bg-primary|page-item.active|page-link|value-box|irs-single/i.test(sel)
    ) {
      findings.push({
        level: "FAIL",
        code: "dark-ink-on-accent",
        message: 'dark ink on solid accent ("' + (text || sel) + '")',
        meta: meta
      });
    }
  }

  // Active pagination should use light ink
  if (
    /page-item\.active|paginate_button\.current|page-item\.active \.page-link/i.test(sel) ||
    (el.closest && el.closest(".page-item.active") && el.classList.contains("page-link"))
  ) {
    if (effectiveFg && glassRelLum(effectiveFg) < 0.5 && text.length) {
      findings.push({
        level: "FAIL",
        code: "active-page-dark-ink",
        message: 'active pagination ink not light ("' + text + '")',
        meta: meta
      });
    }
  }

  return findings;
}

function glassCssColorVar(name, fallbackRgb) {
  const raw = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  const parsed = glassParseColor(raw);
  if (parsed) return parsed;
  // hex #rrggbb
  const hex = raw.match(/^#([0-9a-f]{6})$/i);
  if (hex) {
    const n = parseInt(hex[1], 16);
    return { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255, a: 1 };
  }
  return fallbackRgb;
}

function runGlassAudit(selectors, preset, minContrast, textAA) {
  // Prefer CSS custom properties (glass page pack) over computed body bg:
  // body may be transparent while --glass-page-bg holds the real surface.
  const fallback =
    preset === "dark"
      ? { r: 0, g: 0, b: 0, a: 1 }
      : { r: 232, g: 238, b: 248, a: 1 };
  const tokenPage = glassCssColorVar("--glass-page-bg", fallback);
  const bodyRaw =
    glassParseColor(getComputedStyle(document.body).backgroundColor) ||
    glassParseColor(getComputedStyle(document.documentElement).backgroundColor);
  let pageBg = tokenPage || fallback;
  if (bodyRaw && bodyRaw.a >= 0.99) {
    pageBg = bodyRaw;
  } else if (bodyRaw) {
    pageBg = glassComposite(bodyRaw, tokenPage || fallback) || tokenPage || fallback;
  }

  const all = [];
  for (let i = 0; i < selectors.length; i++) {
    const sel = selectors[i];
    let nodes;
    try {
      nodes = Array.from(document.querySelectorAll(sel));
    } catch (e) {
      all.push({
        level: "WARN",
        code: "bad-selector",
        message: sel + ": " + e.message,
        meta: { selector: sel }
      });
      continue;
    }
    if (!nodes.length) {
      all.push({
        level: "SKIP",
        code: "missing",
        message: "no match: " + sel,
        meta: { selector: sel }
      });
      continue;
    }
    const limit = Math.min(nodes.length, 8);
    for (let idx = 0; idx < limit; idx++) {
      const el = nodes[idx];
      el.__auditSelector = sel + (nodes.length > 1 ? "[" + idx + "]" : "");
      const findings = glassSampleEl(el, pageBg, preset, minContrast, textAA);
      if (!findings.length) {
        all.push({
          level: "PASS",
          code: "ok",
          message: el.__auditSelector + " ok",
          meta: {
            selector: el.__auditSelector,
            text: (el.innerText || "").trim().slice(0, 40),
            color: getComputedStyle(el).color,
            bg: getComputedStyle(el).backgroundColor
          }
        });
      } else {
        for (let f = 0; f < findings.length; f++) all.push(findings[f]);
      }
    }
  }

  // Structure signature: non-active DT page-link must not be solid black in dark
  const pageLinks = document.querySelectorAll(".dataTables_paginate .page-link");
  if (pageLinks.length && preset === "dark") {
    let sample = pageLinks[0];
    for (let i = 0; i < pageLinks.length; i++) {
      const li = pageLinks[i].closest(".page-item");
      if (li && !li.classList.contains("active") && !li.classList.contains("disabled")) {
        sample = pageLinks[i];
        break;
      }
    }
    const bg = glassParseColor(getComputedStyle(sample).backgroundColor);
    if (bg && glassIsNearBlack(bg) && bg.a > 0.95) {
      all.push({
        level: "FAIL",
        code: "dt-pagination-structure",
        message:
          "DT .page-link is solid black — glass styles likely hit wrapper only",
        meta: {
          selector: ".dataTables_paginate .page-link",
          bg: getComputedStyle(sample).backgroundColor
        }
      });
    }
  }

  // The caller names the preset it asked for. Only score dark sheens when the
  // page actually resolved to dark — a light page passed in as "dark" has
  // dark ink, and estimating that ink over black looks like a failed title.
  if (document.documentElement.dataset.glassPreset === "dark") {
    glassAuditTitleSheen(all);
    glassAuditValueBoxShowcase(all);
  }

  return {
    preset: document.documentElement.dataset.glassPreset || preset,
    findings: all
  };
}

// Dark glass used to paint a percentage-based white gradient. On a tall
// sidebar or card that band was 60–90px and sat under the title. The top
// highlight must be a 1px rim plus a short sheen.
function glassSheenReach(image, boxHeight) {
  if (!image || image === "none") return null;
  const parts = String(image).split(/linear-gradient\(/i).slice(1);
  let worst = null;
  parts.forEach((part) => {
    const colors = [];
    const re = /(?:rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?\)|color\(srgb\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)(?:\s*\/\s*([\d.]+))?\))\s*([0-9.]+(?:px|%))?/gi;
    let match;
    while ((match = re.exec(part))) {
      const srgb = match[1] === undefined;
      colors.push({
        r: srgb ? Math.round(+match[5] * 255) : +match[1],
        g: srgb ? Math.round(+match[6] * 255) : +match[2],
        b: srgb ? Math.round(+match[7] * 255) : +match[3],
        a: srgb
          ? (match[8] === undefined ? 1 : +match[8])
          : (match[4] === undefined ? 1 : +match[4]),
        stop: match[9] || null
      });
    }
    if (colors.length < 2) return;
    const start = colors[0];
    const white = start.r > 220 && start.g > 220 && start.b > 220 && start.a > 0.15;
    if (!white) return;
    const fade = colors.find((c) => c.a < 0.05) || colors[colors.length - 1];
    if (!fade.stop) return;
    const reach = fade.stop.slice(-1) === "%"
      ? (parseFloat(fade.stop) / 100) * boxHeight
      : parseFloat(fade.stop);
    if (!isFinite(reach)) return;
    if (!worst || reach > worst.reach) {
      worst = { alpha: start.a, reach: reach, stop: fade.stop };
    }
  });
  return worst;
}

function glassAuditTitleSheen(all) {
  const surfaces = document.querySelectorAll(
    ".bslib-sidebar-layout > .sidebar, .bslib-page-sidebar .sidebar, .card, .bslib-card, .bslib-value-box, .value-box, .stati"
  );
  const titleSel = [
    ".sidebar-title",
    ".card-header",
    ".card-title",
    ".bslib-value-box .value-box-title",
    ".bslib-value-box .value-box-value",
    ".value-box-title",
    ".value-box-value"
  ].join(", ");
  const seen = new Set();
  const limit = Math.min(surfaces.length, 12);
  for (let i = 0; i < limit; i++) {
    const el = surfaces[i];
    if (seen.has(el)) continue;
    seen.add(el);
    const box = el.getBoundingClientRect();
    if (box.width < 8 || box.height < 8) continue;
    const before = getComputedStyle(el, "::before");
    const own = getComputedStyle(el);
    const reachBefore = glassSheenReach(before.backgroundImage, box.height);
    const reachOwn = glassSheenReach(own.backgroundImage, box.height);
    const reach = [reachBefore, reachOwn]
      .filter(Boolean)
      .sort((a, b) => b.reach - a.reach)[0];
    const label = (el.className && String(el.className).split(/\s+/).slice(0, 2).join(".")) || el.tagName;
    if (reach && reach.reach > 24) {
      all.push({
        level: "FAIL",
        code: "wide-sheen",
        message:
          "dark top sheen fades over " +
          Math.round(reach.reach) +
          "px (stop " +
          reach.stop +
          ", alpha " +
          reach.alpha.toFixed(2) +
          ") on ." +
          label,
        meta: { selector: label, reach_px: Math.round(reach.reach), stop: reach.stop }
      });
    }
    // An 8px rim does not sit under the title glyphs. Scoring every header
    // within 12px painted that rim as a white film and failed light ink.
    if (!reach || reach.reach <= 12) continue;
    const titles = el.querySelectorAll(titleSel);
    const titleLimit = Math.min(titles.length, 4);
    for (let t = 0; t < titleLimit; t++) {
      const title = titles[t];
      const tb = title.getBoundingClientRect();
      if (!tb.height) continue;
      const text = (title.innerText || "").trim().slice(0, 40);
      if (!text) continue;
      const overlaps = tb.top < box.top + reach.reach;
      if (!overlaps) continue;
      const ink = glassParseColor(getComputedStyle(title).color);
      const page = { r: 0, g: 0, b: 0, a: 1 };
      const film = glassParseColor(own.backgroundColor) || { r: 255, g: 255, b: 255, a: 0.16 };
      let bg = glassComposite(film, page) || page;
      if (reach && reach.alpha > 0) {
        bg = glassComposite({ r: 255, g: 255, b: 255, a: Math.min(reach.alpha, 0.35) }, bg) || bg;
      }
      const fg = glassComposite(ink, bg);
      if (!fg) continue;
      const ratio = glassContrastRatio(fg, bg);
      if (ratio < 4.5) {
        all.push({
          level: "FAIL",
          code: "title-over-sheen",
          message:
            "title over the dark top sheen is " +
            Math.round(ratio * 100) / 100 +
            ':1 for "' +
            text +
            '"',
          meta: {
            selector: title.className || "title",
            text: text,
            contrast: Math.round(ratio * 100) / 100
          }
        });
      }
    }
  }
}

function glassAuditValueBoxShowcase(all) {
  const boxes = document.querySelectorAll(
    ".bslib-value-box, .small-box, .info-box, .value-box"
  );
  const textSel = [
    ".value-box-value",
    ".value-box-title",
    ".small-box h3",
    ".small-box p",
    ".info-box-number",
    ".info-box-text"
  ].join(", ");
  const limit = Math.min(boxes.length, 8);
  for (let i = 0; i < limit; i++) {
    const el = boxes[i];
    const box = el.getBoundingClientRect();
    if (box.width < 8 || box.height < 8) continue;
    const showcase = el.querySelector(
      ".value-box-showcase, .icon-large, .icon, .info-box-icon"
    );
    if (showcase) {
      const sc = getComputedStyle(showcase);
      const before = getComputedStyle(showcase, "::before");
      const reach =
        glassSheenReach(sc.backgroundImage, box.height) ||
        glassSheenReach(before.backgroundImage, box.height);
      if (reach && reach.reach > 24) {
        all.push({
          level: "FAIL",
          code: "value-box-showcase-sheen",
          message:
            "value-box showcase sheen fades over " +
            Math.round(reach.reach) +
            "px",
          meta: { reach_px: Math.round(reach.reach) }
        });
      }
      const wash = glassParseColor(sc.backgroundColor);
      const sb = showcase.getBoundingClientRect();
      if (
        wash &&
        wash.r > 220 &&
        wash.g > 220 &&
        wash.b > 220 &&
        wash.a > 0.35 &&
        sb.width > 48 &&
        sb.height > 48
      ) {
        all.push({
          level: "FAIL",
          code: "value-box-showcase-wash",
          message: "value-box showcase is a large near-white plate under the text"
        });
      }
    }
    const textEl = el.querySelector(textSel);
    if (!textEl) continue;
    const tb = textEl.getBoundingClientRect();
    if (!tb.width || !tb.height) continue;
    const cx = Math.min(Math.max(tb.left + 12, box.left + 4), box.right - 4);
    const cy = Math.min(Math.max(tb.top + Math.min(tb.height / 2, 16), box.top + 4), box.bottom - 4);
    const top = document.elementFromPoint(cx, cy);
    if (top && !el.contains(top)) {
      const name = (top.className && String(top.className).split(/\s+/).slice(0, 2).join(".")) || top.tagName;
      all.push({
        level: "FAIL",
        code: "value-box-covered",
        message: "value box text is covered by ." + name,
        meta: { text: (textEl.innerText || "").trim().slice(0, 40) }
      });
    }
    const ink = glassParseColor(getComputedStyle(textEl).color);
    const film = glassParseColor(getComputedStyle(el).backgroundColor);
    const page = { r: 28, g: 28, b: 30, a: 1 };
    const bg = glassComposite(film, page) || page;
    const fg = glassComposite(ink, bg);
    if (!fg) continue;
    const ratio = glassContrastRatio(fg, bg);
    const label = (textEl.innerText || "").trim().slice(0, 40);
    if (label && ratio < 4.5) {
      all.push({
        level: "FAIL",
        code: "value-box-contrast",
        message:
          "value box text is " +
          Math.round(ratio * 100) / 100 +
          ':1 for "' +
          label +
          '"',
        meta: { contrast: Math.round(ratio * 100) / 100, text: label }
      });
    }
  }
}
