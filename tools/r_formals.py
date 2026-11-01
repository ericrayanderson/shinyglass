"""Read exported function names and argument lists from the R package.

Used by ``api_parity.py`` and ``draft_python_wrapper.py``. It reads
``NAMESPACE`` and the files in ``R/`` directly, so it does not need R.
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def r_exports(root: Path = ROOT) -> list[str]:
    """Names listed as ``export(name)`` in NAMESPACE."""
    text = (root / "NAMESPACE").read_text()
    return sorted(re.findall(r"^export\(([^)]+)\)", text, flags=re.M))


def _split_args(src: str) -> list[tuple[str, str | None]]:
    """Split the text between ``function(`` and its closing paren."""
    parts: list[str] = []
    depth = 0
    quote: str | None = None
    buf = ""
    i = 0
    while i < len(src):
        ch = src[i]
        if quote:
            buf += ch
            if ch == "\\" and i + 1 < len(src):
                buf += src[i + 1]
                i += 1
            elif ch == quote:
                quote = None
        elif ch in "\"'`":
            quote = ch
            buf += ch
        elif ch == "#":
            while i < len(src) and src[i] != "\n":
                i += 1
            continue
        elif ch in "([{":
            depth += 1
            buf += ch
        elif ch in ")]}":
            depth -= 1
            buf += ch
        elif ch == "," and depth == 0:
            parts.append(buf)
            buf = ""
        else:
            buf += ch
        i += 1
    if buf.strip():
        parts.append(buf)
    out: list[tuple[str, str | None]] = []
    for part in parts:
        name, eq, default = part.partition("=")
        out.append((name.strip(), " ".join(default.split()) if eq else None))
    return out


def r_formals(root: Path = ROOT) -> dict[str, list[tuple[str, str | None]]]:
    """Map each top level ``name <- function(...)`` in R/ to its arguments."""
    found: dict[str, list[tuple[str, str | None]]] = {}
    pat = re.compile(r"^([A-Za-z_.][A-Za-z0-9_.]*)\s*<-\s*function\s*\(", re.M)
    for path in sorted((root / "R").glob("*.R")):
        text = path.read_text()
        for m in pat.finditer(text):
            start = m.end()
            depth = 1
            i = start
            quote = None
            while i < len(text) and depth:
                ch = text[i]
                if quote:
                    if ch == "\\":
                        i += 1
                    elif ch == quote:
                        quote = None
                elif ch in "\"'`":
                    quote = ch
                elif ch == "(":
                    depth += 1
                elif ch == ")":
                    depth -= 1
                i += 1
            found[m.group(1)] = _split_args(text[start : i - 1])
    return found
