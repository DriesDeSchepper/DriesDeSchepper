# Shipping TempoRep to TestFlight

Everything in this repo is wired up. What's left is on Apple's side —
none of it can be done from a CI environment, because it needs your
Apple Developer account.

Work through part 1 once. After that, shipping a build is choosing
**Actions → TestFlight → Run workflow** on GitHub.

---

## Part 1 — one-time setup

### 1. Apple Developer Program

You need an active membership (99 EUR/year) at
[developer.apple.com/programs](https://developer.apple.com/programs/).
A free Apple ID can run the app on your own device from Xcode, but it
cannot upload to TestFlight.

### 2. Register the bundle ID

In [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list),
register an App ID with the bundle ID **exactly**:

```
com.dries.temporep
```

That string is already set in the Xcode project. If you'd rather use a
different one, change it in both `TempoRep.xcodeproj/project.pbxproj`
and `fastlane/Fastfile` (the `APP_IDENTIFIER` constant) — but do it
before the first upload, because a bundle ID can't be changed after a
build exists under it.

No capabilities need enabling. The app uses audio playback in the
background, which is an Info.plist key rather than an entitlement.

### 3. Create the app record

In [App Store Connect](https://appstoreconnect.apple.com/apps) →
**+ → New App**:

| Field | Value |
|---|---|
| Platform | iOS |
| Name | TempoRep |
| Primary language | English (U.S.) |
| Bundle ID | `com.dries.temporep` |
| SKU | anything unique, e.g. `temporep-001` |
| User access | Full Access |

Set the primary category to **Health & Fitness**. This record must exist
before the first upload — the pipeline asks App Store Connect what the
latest build number is, and there's nothing to ask about until it does.

### 4. Create an App Store Connect API key

[Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api)
→ **+**.

Give it the **Admin** role. App Manager is enough to *upload* a build,
but the pipeline also lets Xcode create and renew the provisioning
profile on its own, and that needs Admin. Choosing App Manager here is
the single most likely reason for a first run to fail with an opaque
authentication error.

Apple lets you download the `.p8` private key **once**. Save it
somewhere safe. Note the **Key ID** and the **Issuer ID** shown on that
page — you need all three.

### 5. Export your distribution certificate

If you don't have one yet, in Xcode: **Settings → Accounts → (your
account) → Manage Certificates → + → Apple Distribution**.

Then in **Keychain Access**, find `Apple Distribution: <your name>
(TEAMID)`, right-click → **Export**, save as `.p12`, and set a password
you'll paste into GitHub in a moment.

> **Why export a certificate at all,** when `-allowProvisioningUpdates`
> can create one? Because on a fresh CI runner Xcode never finds an
> existing certificate, so it would mint a *new* one on every run —
> and Apple caps you at three distribution certificates. The fourth
> build would fail, and you'd be revoking certificates by hand to
> recover. Importing a fixed `.p12` means Xcode finds one already there
> and only manages the provisioning profile, which renews without limit.

### 6. Add the GitHub secrets

**Settings → Secrets and variables → Actions → New repository secret**,
six of them:

| Secret | Where it comes from |
|---|---|
| `APPLE_TEAM_ID` | [Membership details](https://developer.apple.com/account) — 10 characters, e.g. `A1B2C3D4E5` |
| `APP_STORE_CONNECT_KEY_ID` | shown next to the key you made in step 4 |
| `APP_STORE_CONNECT_ISSUER_ID` | shown above the key list on the same page (a UUID) |
| `APP_STORE_CONNECT_KEY_CONTENT` | the `.p8` file, base64-encoded — see below |
| `DIST_CERTIFICATE_P12` | the `.p12` file, base64-encoded — see below |
| `DIST_CERTIFICATE_PASSWORD` | the password you set when exporting the `.p12` |

To base64-encode the two files, on your Mac:

```sh
base64 -i AuthKey_XXXXXXXXXX.p8 | tr -d '\n' | pbcopy   # → APP_STORE_CONNECT_KEY_CONTENT
base64 -i distribution.p12      | tr -d '\n' | pbcopy   # → DIST_CERTIFICATE_P12
```

Each command puts the value straight on your clipboard; paste it into
the secret and clear the clipboard afterwards.

---

## Part 2 — the first build

**Do a dry run first.** On GitHub: **Actions → TestFlight → Run
workflow**, leave the lane as **`build_only`**, and run it.

That archives and signs a real App Store build and uploads nothing. It
exercises every part of the setup that can fail — credentials, the
certificate, profile creation, the export — without consuming a
TestFlight build number or emailing anyone. If something is wrong, this
is a far nicer place to find out.

When it's green, run it again with the lane set to **`beta`**. That
archives, uploads, and waits for Apple to finish processing, so the job
only goes green once the build is genuinely usable. Expect 10–25
minutes; most of it is Apple's processing, not the build.

Then in App Store Connect → TestFlight, add yourself as an internal
tester, and install [TestFlight](https://apps.apple.com/app/testflight/id899247664)
on your phone.

### Workflow inputs

| Input | Default | Notes |
|---|---|---|
| `lane` | `build_only` | `beta` archives *and* uploads |
| `changelog` | the commit subject | "What to Test", shown to testers |
| `version` | whatever the project says (`1.0`) | marketing version, e.g. `1.1` |
| `build_number` | one higher than TestFlight's latest | only needed to force a specific number |

Build numbers come from App Store Connect rather than from a counter in
the repo, because App Store Connect is the only thing that actually
knows what has been uploaded — a counter in git drifts the moment a run
fails after the upload succeeded, or you archive from your own Mac.

---

## Troubleshooting

**"No profiles for 'com.dries.temporep' were found"** — the App ID isn't
registered (step 2), or the API key isn't Admin (step 4).

**"Authentication credentials are missing or invalid"** — usually the
base64 of the `.p8` got mangled. Re-encode it with the `tr -d '\n'`
above. Check the Issuer ID too; it's easy to paste the Key ID twice.

**"The provided entity includes an attribute with a value that has
already been used"** on upload — that build number already exists. Bump
the marketing `version`, or pass an explicit `build_number`.

**Signing fails with a certificate error** — confirm the `.p12` is an
*Apple Distribution* certificate, not Apple Development, and that its
password matches `DIST_CERTIFICATE_PASSWORD` exactly.

When a run fails, the job uploads a `build-logs` artifact containing the
full gym and fastlane logs. That's where the real error is; the summary
table at the end of the job is usually too terse to diagnose from.

---

## What this does and doesn't do

The pipeline distributes to **internal testers only**. External testing
requires Beta App Review, which shouldn't be something a CI run triggers
on your behalf — do it deliberately in App Store Connect when you're
ready.

It doesn't submit to the App Store, and it doesn't push the store
listing. `fastlane/metadata/` already holds the listing text in all four
languages in `deliver`'s layout, so adding that later is a small step —
but see `APP_STORE_SUBMISSION.md` for what's still missing there
(screenshots, and a hosted privacy policy URL).

Version and build numbers are injected as build settings rather than
written into `project.pbxproj`. Because `GENERATE_INFOPLIST_FILE` is on,
`CFBundleShortVersionString` and `CFBundleVersion` derive from those
settings — so a CI run needs no `agvtool`, makes no commit back to the
branch, and leaves no dirty working tree.

`DEVELOPMENT_TEAM` stays empty in the committed project and is supplied
from the `APPLE_TEAM_ID` secret at build time, so the repository doesn't
publish your Team ID. If you set your team in Xcode for local
device builds, that's fine and independent — CI overrides it either way.

---

## A caveat worth stating plainly

This pipeline has never been run end to end. It was built in a Linux
container with no macOS, no Xcode, and no Apple credentials, so the
parts that could be verified were verified, and the rest could not be:

**Checked:** the Fastfile parses and both lanes register; every option
name passed to every fastlane action exists on that action (this caught
a real bug — `build_app` has no `api_key:` parameter, so the credentials
now reach xcodebuild through `-authenticationKey*` flags instead); the
App Store Connect key is accepted when given a correctly formatted
P-256 `.p8`; the workflow YAML parses; and the argument-building shell
handles blank inputs and refuses to execute shell metacharacters in a
changelog.

**Not checked:** anything requiring macOS or a real Apple account — the
keychain handling, the actual signing, the export, and the upload. The
`build_only` dry run exists precisely because of this. Budget one or two
iterations on the first attempt; if it fails, the `build-logs` artifact
plus the error will usually make the fix obvious.
