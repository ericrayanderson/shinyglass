# Deploying the demos with GitHub Actions

The **Deploy Connect Cloud demos** workflow publishes the hosted demos to
Posit Connect Cloud. It runs when a GitHub release is published (Python
releases tagged `py-v*` are skipped), and it can be run by hand from main. Merges to main do not deploy, which keeps the free
plan's monthly usage credits for releases. It installs the exact release or
main commit from GitHub, so the deployed package has remote provenance rather
than a local-path installation.

The default `core5` selection deploys five apps: `shinyglass-demo`,
`shinyglass-dashboard`, `shinyglass-inputs`, `shinyglass-olympics`, and
`shinyglass-chat`. The free plan allows five applications.

## Existing content items

Each hosted demo is an existing content item on the `ericrayanderson`
account. They were migrated from shinyapps.io, and the old shinyapps.io URLs
redirect to them. `inst/scripts/deploy-connect-cloud-demos.R` keeps the
content ids in `content_ids` and always calls
`rsconnect::deployApp(appId = ..., forceUpdate = TRUE)`, so a deploy updates
the existing item and never creates a new one. If an id no longer exists, the
deploy stops instead of creating a replacement.

`plotly_gt` and `intensity` stay in the catalog for dry runs and local use.
They have no content item, so a real deploy of either is refused. Hosting one
would need a free slot and a new id in `content_ids`.

Do not rename or delete the content items. The shinyapps.io redirects point
at their current URL names.

| App | URL |
|-----|-----|
| shinyglass-chat | https://ericrayanderson-shinyglass-chat.share.connect.posit.cloud/ |
| shinyglass-demo | https://ericrayanderson-shinyglass-demo.share.connect.posit.cloud/ |
| shinyglass-dashboard | https://ericrayanderson-shinyglass-dashboard.share.connect.posit.cloud/ |
| shinyglass-inputs | https://ericrayanderson-shinyglass-inputs.share.connect.posit.cloud/ |
| shinyglass-olympics | https://ericrayanderson-shinyglass-olympics.share.connect.posit.cloud/ |

## One-time private configuration

1. Create a credential at https://login.posit.cloud/identity/credentials with
   **Use with: Connect Cloud**. The secret is shown once.
2. In this repository's **Settings, Environments**, create
   `connect-cloud-production`. It has no branch rule today. If you add one
   later, allow release tags (for example `v*`) as well as main, or release
   runs will be blocked.
3. Add the environment secrets `CONNECT_CLOUD_CLIENT_ID` and
   `CONNECT_CLOUD_CLIENT_SECRET`.
4. Add `GEMINI_API_KEY` to the same environment. Leave it unset to keep
   Harbor notes on the local script.

## Run

Open **Actions, Deploy Connect Cloud demos, Run workflow**, choose `main`,
pick an app or `core5`, and leave **Stage and validate only** checked for a
dry run. A dry run stages files, resolves dependencies and validates
repository URLs. It does not authenticate.

The workflow deploys sequentially. A failure stops the remaining deploys, and
earlier apps may already be updated. Select the affected app to retry.

## Harbor notes key

`shinyglass-chat` uses the local script until `GEMINI_API_KEY` is present in
the environment that runs the deploy. The script writes the value to a
temporary `.Renviron` in the chat staging directory and does not print it.
The app reads that file at startup. The file is created only for
`shinyglass-chat`, only when the variable is non-empty, and only under
`tempdir()`. It is not committed.

## Secret handling

Credentials reach only the deploy step through the GitHub secrets context.
The account configuration lives under the runner temp directory and is
removed in an always-run cleanup step. No cache or artifact upload is
configured. Only run trusted main code and review workflow changes.

References: [Connect Cloud publishing from the console](https://docs.posit.co/connect-cloud/user/publish/console-or-terminal.html)
and [migrating from shinyapps.io](https://docs.posit.co/connect-cloud/user/shinyapps-migration.html).
