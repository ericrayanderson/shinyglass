"""Print a first draft of a Python wrapper for an exported R function.

Run from the repository root:

    python tools/draft_python_wrapper.py glass_plot_surface_input

The draft copies the argument names and simple defaults from the R source,
using the same name mapping as ``api_parity.py`` (``inputId`` becomes
``id``, ``...`` becomes ``**kwargs``). Defaults it cannot translate are left
as ``None`` with a TODO. The body is a placeholder: read the R function and
write the Python version by hand, then add it to ``__all__``.
"""

from __future__ import annotations

import re
import sys

from api_parity import py_arg_name
from r_formals import r_formals


def py_default(r_default: str | None) -> tuple[str | None, str | None]:
    """Return (python default, note) for an R default expression."""
    if r_default is None:
        return None, None
    d = r_default.strip()
    simple = {"TRUE": "True", "FALSE": "False", "NULL": "None"}
    if d in simple:
        return simple[d], None
    if re.fullmatch(r"-?\d+(\.\d+)?L?", d):
        return d.rstrip("L"), None
    if re.fullmatch(r'"[^"]*"', d):
        return d, None
    m = re.fullmatch(r'c\(\s*("[^"]*")(\s*,\s*"[^"]*")*\s*\)', d)
    if m:
        return m.group(1), f"R choices: {d}"
    return "None", f"TODO: R default is {d}"


def draft(name: str) -> str:
    formals = r_formals()
    if name not in formals:
        raise SystemExit(f"No R function named {name} in R/")
    lines = [f"def {name}("]
    notes: list[str] = []
    has_dots = False
    seen_default = False
    star_added = False
    for r_arg, r_default in formals[name]:
        if r_arg == "...":
            has_dots = True
            continue
        arg = py_arg_name(r_arg)
        default, note = py_default(r_default)
        if default:
            seen_default = True
        elif seen_default and not star_added:
            # Python needs a bare * before a required argument that follows
            # one with a default.
            lines.append("    *,")
            star_added = True
        lines.append(f"    {arg}: Any" + (f" = {default}," if default else ","))
        if note:
            notes.append(f"{arg}: {note}")
    if has_dots:
        lines.append("    **kwargs: Any,")
    lines.append(") -> Any:")
    lines.append(f'    """Python version of R {name}(). Write the description."""')
    for note in notes:
        lines.append(f"    # {note}")
    lines.append(f'    raise NotImplementedError("port {name}() from R/")')
    return "\n".join(lines)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: python tools/draft_python_wrapper.py <r_function>")
    print(draft(sys.argv[1]))
