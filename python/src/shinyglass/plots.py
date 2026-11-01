"""Plot helpers that follow the glass light and dark appearance."""

from __future__ import annotations

from typing import Any


def _read_input(input: Any, key: str) -> Any:
    """Read ``input[key]`` from a Shiny ``Inputs`` object or a plain mapping."""
    try:
        if key not in input:
            return None
        val = input[key]
    except (KeyError, TypeError):
        return None
    if callable(val):
        try:
            return val()
        except Exception:  # unset inputs raise a silent exception
            return None
    return val


def glass_resolved_preset(input: Any = None, default: str = "light") -> str:
    """Return ``"light"`` or ``"dark"``, resolving ``"auto"`` to what the page shows.

    When the user picks Auto, ``input.preset()`` stays ``"auto"``. The browser
    also reports the resolved look as ``input.glass_resolved_preset()``,
    which this reads first. Falls back to ``preset`` or ``glass_preset``
    inputs, then ``default``.
    """
    if default not in ("light", "dark"):
        raise ValueError('default must be "light" or "dark"')
    if input is None:
        return default
    for key in ("glass_resolved_preset", "preset", "glass_preset"):
        val = _read_input(input, key)
        if val in ("light", "dark"):
            return str(val)
    return default


def glass_plot_colors(
    preset: str | None = None, input: Any = None, surface: str = "clear"
) -> dict[str, str]:
    """Ink, grid, fill and paper colors for a light or dark glass page.

    Returns a dict with ``preset``, ``ink``, ``grid``, ``fill``, ``paper`` and
    ``surface``. When ``preset`` is ``None`` it uses
    :func:`glass_resolved_preset` on ``input``. Use ``surface="opaque"`` for a
    near-solid panel behind dense charts.
    """
    if preset is None:
        preset = glass_resolved_preset(input)
    if preset not in ("light", "dark"):
        raise ValueError('preset must be "light" or "dark"')
    if surface not in ("clear", "opaque"):
        raise ValueError('surface must be "clear" or "opaque"')
    if preset == "dark":
        pal = {
            "preset": "dark",
            "ink": "#f5f5f7",
            "grid": "rgba(245,245,247,0.12)",
            "fill": "#0A84FF",
            "paper": "rgba(0,0,0,0)",
            "surface": surface,
        }
    else:
        pal = {
            "preset": "light",
            "ink": "#1d1d1f",
            "grid": "rgba(29,29,31,0.10)",
            "fill": "#007AFF",
            "paper": "rgba(0,0,0,0)",
            "surface": surface,
        }
    if surface == "opaque":
        pal["paper"] = (
            "rgba(28,28,30,0.94)" if preset == "dark" else "rgba(245,245,247,0.94)"
        )
    return pal
