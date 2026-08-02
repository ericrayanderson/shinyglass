"""Hatch build hook: vendor static assets when monorepo inst/ is available."""

from __future__ import annotations

import sys
from pathlib import Path

from hatchling.builders.hooks.plugin.interface import BuildHookInterface


class CustomBuildHook(BuildHookInterface):
    """Before wheel/sdist: refresh static/ from monorepo if possible."""

    PLUGIN_NAME = "custom"

    def initialize(self, version: str, build_data: dict) -> None:
        root = Path(self.root)
        static_css = root / "src" / "shinyglass" / "static" / "theme-light.css"
        monorepo_scss = root.parent / "inst" / "scss" / "glass.scss"
        script = root / "scripts" / "vendor_assets.py"

        if monorepo_scss.is_file() and script.is_file():
            # Building from git checkout — always re-vendor so CSS matches SCSS.
            sys.path.insert(0, str(root / "scripts"))
            from vendor_assets import vendor  # noqa: WPS433

            print("hatch: vendoring assets from monorepo inst/")
            vendor(quiet=False)
            return

        if not static_css.is_file():
            raise RuntimeError(
                "shinyglass static/theme-light.css is missing and monorepo "
                "inst/scss was not found. Run `python scripts/vendor_assets.py` "
                "from a full git checkout before building, or build from the "
                "shinyglass repository root."
            )

        print("hatch: using committed/prebuilt static/ assets")
