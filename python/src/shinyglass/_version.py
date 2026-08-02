"""Package version (kept free of import cycles)."""

__version__ = "0.1.0.9000"

try:
    from importlib.metadata import version as _pkg_version

    __version__ = _pkg_version("shinyglass")
except Exception:  # pragma: no cover
    pass
