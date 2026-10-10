# Deploying the demos with GitHub Actions

The **Deploy shinyapps.io demos** workflow is manual, main-only, and uses the
existing deployment script. It installs the exact selected main commit from
GitHub, so the deployed package has remote provenance rather than a local-path
installation. The default `core5` selection deploys five apps:
`shinyglass-demo`, `shinyglass-dashboard`, `shinyglass-inputs`,
`shinyglass-olympics`, and `shinyglass-chat`. That matches a shinyapps.io
plan with five slots. `plotly_gt` stays in the catalog, and
`inst/examples/plotly-gt-demo.R` stays a local example. The standalone
intensity example stays local too. `all` still lists every catalog entry,
which is more than five apps. Select one demo to retry a partial deployment.

## One-time private configuration

1. Revoke any credential pair previously shared in chat and generate a new pair
   on your shinyapps.io account's Tokens page. Do not paste it into code or issues.
2. In this repository's **Settings → Environments**, create `shinyapps-production`.
3. Restrict its deployment branches to **Selected branches and tags → main**.
   Add a required reviewer if you want an additional approval gate.
4. Add two **environment secrets**: `SHINYAPPS_TOKEN` and `SHINYAPPS_SECRET`, using
   the new token and secret values respectively. The account name is already set
   to `ericrayanderson` in the workflow.
5. Optionally add `GEMINI_API_KEY` to the same environment. Leave it unset to
   keep Harbor notes on the local script. Do not put the key in the
   repository or in a workflow log.

These settings must be configured by a repository owner/admin; committing the
workflow does not create the secrets or protection rules.

## Run

Open **Actions → Deploy shinyapps.io demos → Run workflow**, choose `main`,
select `core5`, and leave **Stage and validate only** checked for a first dry run.
After it succeeds and the main CI checks are green, run it again with that box
unchecked. Approve the environment deployment if required. A dry run stages
files, resolves dependencies, and validates repository URLs; it does not
authenticate or prove that remote builds will succeed.

The workflow deploys sequentially. A failure stops remaining deployments; earlier
apps may already be updated. Select the affected app to retry, or rerun `core5`.
Do not queue multiple individual runs: GitHub concurrency retains only one
pending run and replaces it when another is queued.
Review each deployment's logs and open the printed public URL to verify it.

## Harbor notes key

`shinyglass-chat` uses the local script until `GEMINI_API_KEY` is present in
the environment that runs the deploy. The workflow copies the optional
`shinyapps-production` secret into that step. A manual run can `export` the
same name before `Rscript`. The script writes the value to a temporary
`.Renviron` in the chat staging directory and does not print it.

shinyapps.io does not accept `rsconnect::deployApp(envVars = ...)`. That
argument is Posit Connect only, and passing it aborts the deploy. The staged
`.Renviron` is the equivalent. shinyapps.io reads it when the app starts, and
the example also calls `readRenviron(".Renviron")`. The file is created only
for `shinyglass-chat`, only when the variable is non-empty, and only under
`tempdir()`. It is not committed.

An empty or missing key leaves the local script in place. The live model is
Gemini Flash. Each session allows 8 messages of at most 400 characters, and
quota or other API errors fall back to the local script.

## Secret handling

Credentials are injected only into the authentication/deployment step via the
GitHub secrets context, not inserted into source, CLI arguments, or artifacts.
`GEMINI_API_KEY` is an environment variable on that step. The deploy script
reads it for the chat app and does not echo it.
The temporary account configuration is outside the checkout and removed in an
always-run cleanup step; no cache or artifact upload is configured. GitHub masks
registered secrets in logs, but masking is not a guarantee against malicious
workflow code. Only run trusted main code, protect the environment and branch,
review workflow changes, and never enable verbose HTTP credential logging.

References: [GitHub environment secrets](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets)
and [rsconnect account setup](https://rstudio.github.io/rsconnect/reference/setAccountInfo.html).
