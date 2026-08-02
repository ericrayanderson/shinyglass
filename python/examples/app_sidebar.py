"""Minimal page_sidebar demo for the shinyglass Python spike.

Run from the monorepo root (or with SHINYGLASS_PKG_ROOT set)::

    cd python
    pip install -e .
    shiny run examples/app_sidebar.py
"""

from __future__ import annotations

from shiny import App, reactive, render, ui

from shinyglass import glass_theme

app_ui = ui.page_sidebar(
    ui.sidebar(
        ui.h4("Filters"),
        ui.input_select(
            "species",
            "Species",
            choices=["All", "setosa", "versicolor", "virginica"],
            selected="All",
        ),
        ui.input_slider("n", "Sample n", min=20, max=150, value=80),
        ui.input_switch("smooth", "Smooth", True),
        title="Glass sidebar",
        width=280,
    ),
    ui.h2("shinyglass · Shiny for Python"),
    ui.layout_columns(
        ui.value_box("Rows", ui.output_text("vb_n"), theme="primary"),
        ui.value_box("Species", ui.output_text("vb_sp"), theme="success"),
        ui.value_box("Mean SL", ui.output_text("vb_mu"), theme="info"),
        fill=False,
    ),
    ui.layout_columns(
        ui.card(
            ui.card_header("Histogram"),
            ui.output_plot("hist", height="280px"),
            full_screen=True,
        ),
        ui.card(
            ui.card_header("Notes"),
            ui.p(
                "Python spike reuses the R package ",
                ui.tags.code("inst/scss/glass.scss"),
                " and ",
                ui.tags.code("inst/js/shiny-glass.js"),
                " (Option 2 layout).",
            ),
            ui.input_action_button("go", "Notify", class_="btn-primary"),
        ),
        col_widths=[8, 4],
    ),
    title="shinyglass (Python)",
    fillable=True,
    theme=glass_theme(preset="light"),
)


def server(input, output, session):
    @reactive.calc
    def dat():
        # Tiny in-memory iris subset without requiring pandas
        import random

        # Approximate iris sepal lengths by species for the demo
        base = {
            "setosa": [5.1, 4.9, 4.7, 4.6, 5.0, 5.4, 4.6, 5.0],
            "versicolor": [7.0, 6.4, 6.9, 5.5, 6.5, 5.7, 6.3, 4.9],
            "virginica": [6.3, 5.8, 7.1, 6.3, 6.5, 7.6, 4.9, 7.3],
        }
        species = input.species()
        keys = list(base.keys()) if species == "All" else [species]
        vals: list[tuple[str, float]] = []
        for sp in keys:
            for v in base[sp]:
                vals.append((sp, v))
        random.seed(1)
        random.shuffle(vals)
        n = min(input.n(), len(vals))
        return vals[:n]

    @render.text
    def vb_n():
        return str(len(dat()))

    @render.text
    def vb_sp():
        return str(len({s for s, _ in dat()}))

    @render.text
    def vb_mu():
        xs = [v for _, v in dat()]
        return f"{sum(xs) / len(xs):.2f}" if xs else "—"

    @render.plot
    def hist():
        import matplotlib.pyplot as plt

        xs = [v for _, v in dat()]
        fig, ax = plt.subplots()
        ax.hist(xs, bins=10, color="#007AFF", edgecolor="none")
        ax.set_xlabel("Sepal length")
        ax.set_ylabel("Count")
        fig.tight_layout()
        return fig

    @reactive.effect
    @reactive.event(input.go)
    def _notify():
        ui.notification_show("shinyglass Python spike", type="message")


app = App(app_ui, server)
