# Hosting the privacy policy (GitHub Pages)

Play needs a public web address for the policy. GitHub Pages on a free account
only serves public repositories, so use a separate small public repo for the
policy and keep your code repo private.

1. Fill in the placeholders in `site/index.html`. In the Codespace terminal,
   change the three values, then run it. Avoid "/" and "&" in the values.

       sed -i 's/{{PUBLISHER}}/Your Name/g; s/{{EMAIL}}/you@example.com/g; s/{{DATE}}/7 October 2026/g' site/index.html
       grep -n "{{" site/index.html || echo "all placeholders filled"

2. Download `site/index.html` (right-click, Download).
3. On github.com: New repository, name `stillscreen-privacy`, Public, Create.
4. In the new repo choose "uploading an existing file", drop in `index.html`,
   and commit to the main branch.
5. Settings, then Pages. Under Build and deployment pick "Deploy from a branch",
   branch `main`, folder `/ (root)`, Save.
6. After a minute, open `https://YOUR-GITHUB-USERNAME.github.io/stillscreen-privacy/`.
   Check it loads on your phone.
7. Paste that address into Play Console's privacy policy box.

## Keep it true

The policy says the app has no internet permission and collects nothing. That
is correct today. The moment you add accounts, sync, analytics or ads, update
the page, the Play Data safety form and the manifest in the same release.

It also says the app is for people aged 13 and over. Make sure your Play
Console target audience answer matches. This is a decision for you, and not
legal advice. Have someone qualified review the text for your country.
