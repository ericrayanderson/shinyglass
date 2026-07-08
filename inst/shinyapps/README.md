# dreamRs/shinyapps (vendored)

Glass-themed demos for [dreamRs/shinyapps](https://github.com/dreamRs/shinyapps).

Each app folder includes an `app-glass.R` entry point that swaps in
`shinyglass::glass_theme()`. Launch from the package examples:

```r
shiny::runApp(system.file("examples", "dreamrs-gh-dashboard.R", package = "shinyglass"))
```

| App | Launcher | Notes |
|-----|----------|-------|
| GitHub dashboard | `dreamrs-gh-dashboard.R` | Public GitHub API; optional `GITHUB_PAT` |
| Olympic medals | `dreamrs-olympic-medals.R` | Offline RDS data |
| Births in France | `dreamrs-tdb-naissances.R` | Offline RDS + maps |
| Paris metro traffic | `dreamrs-ratp-traffic.R` | Offline RDS + leaflet |

Refresh upstream sources:

```bash
git clone --depth 1 https://github.com/dreamRs/shinyapps.git /tmp/shinyapps
rsync -a --exclude='.git' /tmp/shinyapps/ inst/shinyapps/
# Re-apply app-glass.R files from this repo if overwritten
```