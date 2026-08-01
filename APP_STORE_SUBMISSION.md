# App Store submission checklist

## Done in this repo

- [x] **Privacy manifest** — `TempoRep/PrivacyInfo.xcprivacy` declares no tracking, no collected data, and the one required-reason API category the app actually uses (`UserDefaults`, reason `CA92.1`, for local-only settings/history/preset storage).
- [x] **Store listing text** — `fastlane/metadata/{en-US,nl-NL,fr-FR,de-DE}/` has name, subtitle, description, keywords, and promotional text in all 4 of the app's languages. (This is the standard [fastlane deliver](https://docs.fastlane.tools/actions/deliver/) folder layout — usable whether or not you actually use fastlane; App Store Connect's own metadata import tools read the same shape.)
- [x] **Privacy policy draft** — `PRIVACY_POLICY.md`, written directly from what the app's code actually does (no network calls, no third-party SDKs, no analytics). Needs your contact info filled in, then hosting somewhere public (a GitHub Pages page, a Gist, your own site — anywhere with a stable URL).

## Still needed before you can submit — none of these I can do from here

- [ ] **Support URL and privacy policy URL** — `fastlane/metadata/*/support_url.txt` and `privacy_url.txt` are placeholders. Host `PRIVACY_POLICY.md` somewhere and fill in both. Apple requires a live privacy policy URL for every submission, even for a no-data-collection app like this one.
- [ ] **Screenshots** — see below.
- [ ] **App Store Connect record**: create the app in [App Store Connect](https://appstoreconnect.apple.com), which requires an active Apple Developer Program membership ($99/year). Set:
  - **Primary category**: Health & Fitness (Productivity is a reasonable second choice)
  - **Age rating**: should qualify for 4+ — no objectionable content, no user-generated content, no web browsing
  - **Bundle ID**: `com.dries.temporep` (already set in the Xcode project — register this exact ID in your developer account)
- [ ] **Code signing and TestFlight**: see **[TESTFLIGHT.md](TESTFLIGHT.md)**. There's now a `TestFlight` GitHub Actions workflow that archives, signs and uploads a build; it needs an Apple Developer account, an App Store Connect API key and a distribution certificate, all of which that document walks through. `DEVELOPMENT_TEAM` stays empty in the committed project on purpose — CI supplies it from a secret, so your Team ID isn't published in a public repo.
- [ ] **App icon**: already done (`Assets.xcassets/AppIcon.appiconset`) — no action needed.

## Screenshots — flagged separately

I don't have a macOS/Xcode/Simulator environment available in this session, so I can't launch the app and capture real screenshots — everything in this repo has only ever been verified via `xcodebuild` on GitHub Actions CI, never actually run and viewed. I didn't want to fabricate placeholder images and label them as "app screenshots" when they're not.

**What Apple requires**: at minimum, screenshots for the largest current iPhone display size (6.9", e.g. iPhone 17 Pro Max) — App Store Connect will let you upload for other sizes too, but that one's mandatory. Sizes shift as new iPhones ship, so check App Store Connect's current requirements when you get there.

**Suggested screens to capture** (once you have Xcode open and the app running in the simulator — press `⌘S` in the simulator to save a screenshot to your desktop):
1. Setup screen with a preset applied (shows the exercise picker entry point, tempo digits, and unilateral toggle in one shot)
2. Workout screen mid-rep (the big phase name + countdown ring — this is the app's core visual identity)
3. Workout screen in unilateral mode, showing the LEFT/RIGHT badge
4. The exercise picker, mid-search
5. Workout history

If you'd like, I can also build HTML/CSS mockups that closely match the app's exact colors and layout as a stand-in while you don't have Xcode handy — just ask, and I'll flag those clearly as mockups, not real screenshots, since App Store Connect requires the real thing regardless.
