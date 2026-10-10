# Deploying the demos with GitHub Actions

The **Deploy shinyapps.io demos** workflow is manual, main-only, and uses the
existing deployment script. It installs the exact selected main commit from
GitHub, so the deployed package has remote provenance rather than a local-path
installation. The default `core5` selection deploys the core set: demo,
dashboard, inputs, olympics, plotly + gt, and the harbor-notes chat. The name
is historical. The account needs a free slot for the sixth app. The standalone
intensity example remains available locally; `all` also includes intensity.
Select one demo to retry a partial deployment.

## One-time private configuration

1. Revoke any credential pair previously shared in chat and generate a new pair
   on your shinyapps.io account's Tokens page. Do not paste it into code or issues.
2. In this repository's **Settings → Environments**, create `shinyapps-production`.
3. Restrict its deployment branches to **Selected branches and tags → main**.
   Add a required reviewer if you want an additional approval gate.
4. Add two **environment secrets**: `SHINYAPPS_TOKEN` and `SHINYAPPS_SECRET`, using
   the new token and secret values respectively. The account name is already set
   to `ericrayanderson` in the workflow.

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

`shinyglass-chat` uses a local script until a Gemini key is set. Add
`GEMINI_API_KEY` (or `GOOGLE_API_KEY`) under the app's **Settings → Variables**
on shinyapps.io. Do not commit the key or pass it on the deploy command line.
The live model is Gemini Flash. Each session allows 8 messages of at most 400
characters, and quota or other API errors fall back to the local script.

## Secret handling

Credentials are injected only into the authentication/deployment step via the
GitHub secrets context, not inserted into source, CLI arguments, or artifacts.
The temporary account configuration is outside the checkout and removed in an
always-run cleanup step; no cache or artifact upload is configured. GitHub masks
registered secrets in logs, but masking is not a guarantee against malicious
workflow code. Only run trusted main code, protect the environment and branch,
review workflow changes, and never enable verbose HTTP credential logging.

References: [GitHub environment secrets](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets)
and [rsconnect account setup](https://rstudio.github.io/rsconnect/reference/setAccountInfo.html).
