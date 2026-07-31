# TempoRep

A minimal, high-contrast tempo training timer for strength workouts, built with SwiftUI (iOS 17+).

In tempo training every rep follows a 4-digit tempo like **4010**:

| Digit | Phase | Meaning |
|---|---|---|
| 1st | Eccentric | lowering, in seconds |
| 2nd | Pause | at the bottom |
| 3rd | Concentric | lifting — `0` means explosive, timed as 1 s |
| 4th | Pause | at the top |

## Features

- Tempo input as 4 digits, with a toggle for which phase a rep starts with (eccentric or concentric)
- Reps per set, number of sets, rest between sets
- Huge phase name + countdown ring, readable from across the room — tinted violet during the eccentric (lowering) phase and accent green during concentric (lifting), with a brief colored flash at the top edge on every phase change (skipped under Reduce Motion)
- Tempo shown as directional notation (`↓4·0·↑1·0`) everywhere it's displayed — arrows mark eccentric/concentric, dots separate the four digits — instead of a bare digit string
- Distinct sound + haptic cues for phase changes (single tap), rep completion (double tap), and set completion (triple ascending tap) — built with Core Haptics for genuinely different felt patterns, not just different impact intensities; falls back to plain `UIImpactFeedbackGenerator`/`UINotificationFeedbackGenerator` on hardware without a custom-haptics-capable Taptic Engine
- Haptic feedback throughout the UI too: steppers, toggles, pickers, presets, and the Start/Pause/Stop/Continue buttons (haptics only fire on a real device — the simulator can't drive the Taptic Engine at all)
- Localized in English, Dutch, French, and German — follows the iOS system language by default, with an override in Settings
- Optional voice countdown (toggle in Settings): spoken "Down / Hold / Up" per language, counted per second through multi-second phases (e.g. "Down, 2, 3, 4" for a 4s eccentric), "Rest", and a 3-2-1 lead-in before each set — uses a matching AVSpeechSynthesisVoice for the current language by default, or a specific installed voice picked in Settings (with an instant spoken preview, and each language remembering its own choice)
- Background audio mode: cues keep playing when the app is backgrounded or the screen is locked, and your music (Spotify etc.) keeps playing alongside
- Unilateral (single-side) mode: does all reps for one side, a switch pause, then all reps for the other side, within the same set — rest between sets only starts once both sides are done
- Bundled exercise database (873 exercises from the public-domain [free-exercise-db](https://github.com/yuhonas/free-exercise-db), no network calls): searchable picker with a filter sheet (muscle/equipment), a favorites star per exercise, and a recents list; picking an exercise suggests unilateral mode, starting phase (deadlifts/pull-ups lead with the concentric phase), and a starting tempo for its primary muscle group (e.g. slower eccentric + explosive concentric for calves/arms) — always shown as an overridable suggestion, never applied silently once you've changed the digits yourself; or skip it and run a bare timer
- Presets (4 built-in — Squat, Push-Up, Single-Leg RDL, Deadlift — plus any you save) set exercise + tempo + reps + sets + rest + unilateral settings all at once; long-press a saved one to delete it. Save a few tempos for the same exercise (e.g. one per training phase) and the presets row narrows to just that exercise's presets once it's selected
- Automatic rest countdown between sets
- Pause/resume and stop
- Settings (tempo, reps, sets, rest, voice) are remembered between launches
- Workout history: finished workouts are logged with exercise (if one was picked), tempo, sets × reps, and time under tension (shown as "15s" under a minute, "1:30" once it isn't, to avoid an ambiguous bare "0:15")
- Finish screen shows a checkmark animation, correctly-pluralized sets/reps ("1 rep", not "1 reps"), and time under tension for that workout
- Screen stays awake during a workout
- The workout screen supports landscape (phone propped on a shelf, in a stand, etc.) with an adapted side-by-side layout; every other screen stays portrait-only — see `OrientationLock.swift`
- Settings, History, and the exercise picker are plain native `Form`/`List` sheets (system materials, resizable via `.presentationDetents`) with the system's standard round close button, not a text "Done"; they follow the system light/dark appearance, while the workout screen and launch splash are deliberately always dark (see `WorkoutView`'s doc comment)
- Every color, font, spacing, corner-radius, and animation value in the UI comes from one design-system file (`DesignSystem.swift`) — semantic tokens, a 4/8/12/16/24/32 spacing scale, and Dynamic Type text styles throughout (the oversized workout-display digits scale via `@ScaledMetric` instead, since they're bigger than any standard text style)
- VoiceOver: tempo digit steppers and counters (reps/sets/rest/switch time) present as single adjustable elements with real labels, not unlabeled +/- buttons; the workout screen announces phase changes via `UIAccessibility.post` independent of the optional voice-cue feature; Reduce Motion replaces the finish-screen checkmark's pop-in with a plain crossfade
- Drift-free timing: state is derived from wall-clock elapsed time, not accumulated timer ticks
- Cues play even when the phone is on silent (`.playback` audio session category)
- No network access, no accounts, no tracking, no third-party SDKs — everything lives in local `UserDefaults` and the bundled exercise dataset (see `PrivacyInfo.xcprivacy` and `PRIVACY_POLICY.md`)

## Requirements

- Xcode 16 or newer (the project uses the Xcode 16 project format)
- iOS 17+ deployment target

## Running in the simulator

1. Open `TempoRep.xcodeproj` in Xcode
2. Select the **TempoRep** scheme and any iPhone simulator
3. Press **⌘R**

Or from the command line:

```sh
xcodebuild build -project TempoRep.xcodeproj -scheme TempoRep \
  -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
```

Note: haptics don't fire in the simulator — run on a device to feel them. To run on a device, set your development team under *Signing & Capabilities* first.

## Running the tests

Press **⌘U** in Xcode, or from the command line:

```sh
xcodebuild test -project TempoRep.xcodeproj -scheme TempoRep \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' CODE_SIGNING_ALLOWED=NO
```

`TempoRepTests` covers the timeline-building logic in `WorkoutEngine.buildTimeline` (bilateral/unilateral/switch-pause/zero-duration-phase-skipping/start-phase reordering), `WorkoutConfig`'s Codable round-trip, the bundled exercise dataset, preset application, and localization catalog completeness across all 4 languages.

## Project layout

```
TempoRep/
  TempoRepApp.swift              App entry point
  DesignSystem.swift          Semantic color/spacing/typography/motion tokens — the only source of styling constants
  Models/WorkoutModels.swift  Config, phases, timeline segments
  Models/Exercise.swift       Bundled exercise-database entry
  Models/WorkoutPreset.swift  Built-in and user-saved exercise+settings presets
  Engine/WorkoutEngine.swift  Elapsed-time-driven workout state machine
  Services/SoundPlayer.swift  Synthesized beep cues via AVFoundation
  Services/SpeechPlayer.swift  Voice cues via AVSpeechSynthesizer
  Services/VoicePreferenceStore.swift  Per-language chosen speech voice, persisted
  Services/HapticsPlayer.swift  UIKit feedback generators
  Services/HistoryStore.swift  Persisted log of completed workouts
  Services/LocalizationManager.swift  System-language / override language resolution
  Services/ExerciseDatabase.swift  Loads the bundled dataset, tracks recents
  Services/PresetStore.swift  Persisted log of user-saved presets
  Views/SplashView.swift      Brief launch screen with the wordmark
  Views/SetupView.swift       Tempo/reps/sets/rest/exercise configuration
  Views/WorkoutView.swift     In-workout display and controls, with a landscape layout
  Services/OrientationLock.swift  Runtime portrait lock, released only while WorkoutView is on screen
  Views/HistoryView.swift     Workout history sheet
  Views/SettingsView.swift    Language override, voice countdown toggle, per-language speech voice picker
  Views/ExercisePickerView.swift  Searchable exercise picker
  Views/CloseButton.swift     Shared round "xmark.circle.fill" sheet-dismiss button
  Resources/exercises.json    Bundled exercise dataset (name/category/muscles/equipment, no images)
  Localizable.xcstrings       String catalog (en, nl, fr, de)
  PrivacyInfo.xcprivacy       Privacy manifest — no tracking, no collected data

TempoRepTests/
  WorkoutEngineTests.swift    Timeline-building logic (bilateral/unilateral/switch/reordering)
  WorkoutConfigTests.swift    Codable round-trip, computed properties
  WorkoutPresetTests.swift    Preset application and persistence shape
  ExerciseDatabaseTests.swift  Bundled dataset loads correctly, no duplicate IDs
  LocalizationCatalogTests.swift  Every checked key resolves in all 4 languages
  VoicePreferenceStoreTests.swift  Per-language voice override persistence and lookup

fastlane/metadata/           App Store listing text (name/subtitle/description/keywords) in en-US/nl-NL/fr-FR/de-DE
PRIVACY_POLICY.md            Ready-to-host privacy policy draft
APP_STORE_SUBMISSION.md      Checklist of what's done vs. what you still need to do before submitting
UI_MODERNIZATION.md          Design-system audit, native-iOS-26 pass, and the Live Activity proposal
```
