# Local development

- Quit bzkeeb before replacing its signed app bundle.
- Ad-hoc rebuilds can invalidate Accessibility grants. If hotkeys fail, check TCC logs for a signature mismatch. Reset only `dev.bzkeeb.prototype` with `tccutil reset Accessibility dev.bzkeeb.prototype`, reopen the app, and have the user re-enable it in Accessibility settings.
- Verify launches with a process check; successful compilation does not establish that the app is running or receiving hotkeys.
- Keep local build and permission troubleshooting out of the public README.
