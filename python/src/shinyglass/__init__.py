"""Liquid Glass themes for Shiny for Python.

Shares ``inst/scss/glass.scss`` and ``inst/js/shiny-glass.js`` with the R
package (Option 2 layout).
"""

from ._version import __version__
from .theme import (
    GLASS_SCENES,
    glass_intensity_slider,
    glass_theme,
    update_glass_theme,
)

__all__ = [
    "GLASS_SCENES",
    "glass_intensity_slider",
    "glass_theme",
    "update_glass_theme",
    "__version__",
]
