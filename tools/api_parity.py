"""Check that the R and Python packages expose the same functions.

Run from the repository root:

    python tools/api_parity.py

It compares the exports in NAMESPACE with the names in ``__all__`` of the
Python package, then compares argument names for functions found on both
sides. Anything that is one-sided on purpose goes in
``tools/api-parity-allow.toml`` with a short reason. The script exits with
status 1 when it finds a gap that is not on the allow list, or an allow list
entry that is no longer needed.
"""

from __future__ import annotations

import ast
import sys
import tomllib
from pathlib import Path

from r_formals import ROOT, r_exports, r_formals

PY_PKG = ROOT / "python" / "src" / "shinyglass"
ALLOW_FILE = ROOT / "tools" / "api-parity-allow.toml"

# Argument names that differ only by each language's convention. R's "..."
# matches Python *args or **kwargs.
R_TO_PY_ARG = {"inputId": "id", "class": "class_"}


def py_arg_name(r_name: str) -> str:
    if r_name == "...":
        return "..."
    return R_TO_PY_ARG.get(r_name, r_name.replace(".", "_"))


def py_public() -> dict[str, list[str]]:
    """Public Python functions (from ``__all__``) and their argument names."""
    init = ast.parse((PY_PKG / "__init__.py").read_text())
    names: list[str] = []
    for node in init.body:
        if isinstance(node, ast.Assign) and any(
            isinstance(t, ast.Name) and t.id == "__all__" for t in node.targets
        ):
            names = [ast.literal_eval(e) for e in node.value.elts]
    defs: dict[str, list[str]] = {}
    for path in PY_PKG.glob("*.py"):
        for node in ast.parse(path.read_text()).body:
            if isinstance(node, ast.FunctionDef):
                a = node.args
                every = a.posonlyargs + a.args + a.kwonlyargs
                # Leading underscore marks an internal argument.
                args = [x.arg for x in every if not x.arg.startswith("_")]
                # *args and **kwargs play the part of R's "...".
                if a.vararg or a.kwarg:
                    args.append("...")
                defs[node.name] = args
    return {n: defs[n] for n in names if n in defs}


def main() -> int:
    allow = tomllib.loads(ALLOW_FILE.read_text())
    r_only = allow.get("r_only", {})
    py_only = allow.get("python_only", {})
    arg_allow = allow.get("arguments", {})

    r_names = set(r_exports())
    formals = r_formals()
    py = py_public()
    problems: list[str] = []

    for name in sorted(r_names - set(py)):
        if name not in r_only:
            problems.append(f"R export {name}() has no Python counterpart")
    for name in sorted(set(py) - r_names):
        if name not in py_only:
            problems.append(f"Python function {name}() has no R counterpart")
    for name in sorted(set(r_only) & set(py)):
        problems.append(f"{name} is allow-listed as R only but exists in Python")
    for name in sorted(set(py_only) & r_names):
        problems.append(f"{name} is allow-listed as Python only but exists in R")
    for name in sorted(set(r_only) - r_names):
        problems.append(f"{name} is allow-listed as R only but is not exported")
    for name in sorted(set(py_only) - set(py)):
        problems.append(f"{name} is allow-listed as Python only but is not public")

    for name in sorted(r_names & set(py)):
        r_args = [py_arg_name(a) for a, _ in formals.get(name, [])]
        py_args = py[name]
        ok = arg_allow.get(name, {})
        r_ok = set(ok.get("r_only", []))
        py_ok = set(ok.get("python_only", []))
        for a in r_args:
            if a not in py_args and a not in r_ok:
                problems.append(f"{name}(): R argument '{a}' is missing in Python")
        for a in py_args:
            if a not in r_args and a not in py_ok:
                problems.append(f"{name}(): Python argument '{a}' is missing in R")
        for a in sorted(r_ok & set(py_args)):
            problems.append(f"{name}(): '{a}' is allow-listed but exists in Python")
        for a in sorted(py_ok & set(r_args)):
            problems.append(f"{name}(): '{a}' is allow-listed but exists in R")

    shared = len(r_names & set(py))
    print(f"R exports: {len(r_names)}, Python public functions: {len(py)}, "
          f"in both: {shared}")
    print(f"Allow-listed: {len(r_only)} R only, {len(py_only)} Python only")
    if problems:
        print("\nParity problems:")
        for p in problems:
            print(f"  - {p}")
        print("\nPort the missing piece, or add it to tools/api-parity-allow.toml "
              "with a reason.")
        return 1
    print("R and Python APIs match.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
