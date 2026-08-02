"""Liquid Glass themes for Shiny for Python.

Spike package: reuses the R package's ``inst/scss/glass.scss`` and
``inst/js/shiny-glass.js`` from the monorepo checkout (Option 2 layout).
"""

from ._version import __version__
from .theme import glass_theme

__all__ = ["glass_theme", "__version__"]
