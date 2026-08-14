// Browser-side helpers for audit-glass-contrast.R
// Exposes: runGlassAudit(selectors, preset, minContrast) -> { preset, findings }

function glassParseColor(str) {
  if (!str || str === "transparent" || str === "rgba(0, 0, 0, 0)") {
    return null;
  }
  const m = str.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?\)/i);
  if (!m) return null;
  return {
    r: +m[1],
    g: +m[2],
    b: +m[3],
    a: m[4] === undefined ? 1 : +m[4]
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
  if (!bg) return fg.a >= 0.99 ? fg : null;
  const a = fg.a + bg.a * (1 - fg.a);
  if (a < 1e-6) return null;
  return {
    r: Math.round((fg.r * fg.a + bg.r * bg.a * (1 - fg.a)) / a),
    g: Math.round((fg.g * fg.a + bg.g * bg.a * (1 - fg.a)) / a),
    b: Math.round((fg.b * fg.a + bg.b * bg.a * (1 - fg.a)) / a),
    a: 1
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

function glassSampleEl(el, pageBg, preset, minContrast) {
  const cs = getComputedStyle(el);
  const color = glassParseColor(cs.color);
  let bg = glassParseColor(cs.backgroundColor);
  let node = el;
  let guard = 0;
  while (bg && bg.a < 0.15 && node.parentElement && guard < 6) {
    node = node.parentElement;
    const pbg = glassParseColor(getComputedStyle(node).backgroundColor);
    bg = glassComposite(bg.a > 0.01 ? bg : null, pbg) || pbg || bg;
    guard++;
  }
  const effectiveBg = glassComposite(bg, pageBg) || pageBg;
  const effectiveFg = color;
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
    return findings;
  }

  const isControl = glassIsControlSelector(sel, el.className);

  if (effectiveFg && effectiveBg && effectiveFg.a > 0.5) {
    const ratio = glassContrastRatio(effectiveFg, effectiveBg);
    meta.contrast = Math.round(ratio * 100) / 100;
    const hasText = text.length > 0;
    if (hasText && isControl && ratio < minContrast) {
      findings.push({
        level: "FAIL",
        code: "low-contrast",
        message:
          "contrast " + meta.contrast + ":1 < " + minContrast + ':1 for "' + text + '"',
        meta: meta
      });
    } else if (hasText && isControl && ratio < 4.5) {
      findings.push({
        level: "WARN",
        code: "contrast-aa",
        message: "contrast " + meta.contrast + ':1 below WCAG AA 4.5 for "' + text + '"',
        meta: meta
      });
    }
  }

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

function runGlassAudit(selectors, preset, minContrast) {
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
      const findings = glassSampleEl(el, pageBg, preset, minContrast);
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

  return {
    preset: document.documentElement.dataset.glassPreset || preset,
    findings: all
  };
}
