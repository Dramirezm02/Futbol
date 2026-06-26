# Deploying the Shiny Dashboard

GitHub stores the source code and report files, but it does not run Shiny apps directly. To publish the interactive dashboard, deploy `app.R` to a Shiny hosting service and then add the public URL to this repository.

## Recommended Option: ShinyApps.io

1. Create or open your account at:

```text
https://www.shinyapps.io/
```

2. In RStudio, open:

```text
FUTBOL.Rproj
```

3. Open:

```text
app.R
```

4. Click **Publish**.

5. In the account window, choose:

```text
ShinyApps.io
```

6. Connect your account. RStudio will ask for an account name, token, and secret. You can find those in shinyapps.io:

```text
Account > Tokens > Show
```

7. In the publish file selection, include:

```text
app.R
R/
```

The app downloads StatsBomb data when needed, so the heavy `data/raw/` and `data/processed/` folders do not need to be uploaded.

8. Click **Publish**.

After deployment, shinyapps.io will give you a public URL similar to:

```text
https://your-account.shinyapps.io/futbol/
```

Current deployed dashboard:

```text
https://71skou-daniela-ramirez0montoya.shinyapps.io/FUTBOL/
```

## Add the Live App URL to GitHub

Once you have the public URL, add it to `README.md` under a section like:

```markdown
## Live Dashboard

Interactive Shiny dashboard: [Open app](https://your-account.shinyapps.io/futbol/)
```

Then commit and push the README.

## Notes

- GitHub Pages can publish `docs/index.html`, but it cannot run Shiny server logic.
- The interactive app should be hosted on ShinyApps.io or Posit Connect Cloud.
- The rendered R Markdown report stays available as a static HTML file in `docs/index.html`.
