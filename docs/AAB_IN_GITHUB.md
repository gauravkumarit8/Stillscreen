# Getting the release bundle from GitHub Actions

The earlier workflow (`build-apk.yml`) only makes a DEBUG APK. It never makes a
bundle. To get a signed `.aab` from GitHub, the workflow needs your upload key,
which lives only in the Codespace. Give it to GitHub as encrypted secrets:

1. In the Codespace, print the key as one line of text and copy it:

       base64 -w0 ~/stillscreen-upload.jks

2. On github.com open your repo > Settings > Secrets and variables > Actions >
   New repository secret. Add two secrets:

   | Name | Value |
   |---|---|
   | `UPLOAD_KEYSTORE_BASE64` | the line you copied |
   | `UPLOAD_KEYSTORE_PASSWORD` | the keystore password you chose |

   The workflow assumes the key alias is `upload`, which is what
   `make_upload_key.sh` creates.

3. Actions tab > "Build signed release bundle" > Run workflow.
4. When it finishes, open the run and download `stillscreen-release-aab` from
   Artifacts. It contains `app-release.aab`.

The workflow also fails on purpose if the bundle is signed with the debug key
or if a release manifest contains the INTERNET permission.

Keep your repository private while it holds the secrets. Secrets are not shown
in logs, but anyone with write access can use them in a workflow.
