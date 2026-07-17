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
- Huge phase name + countdown ring, readable from across the room
- Distinct sound + haptic cues for phase changes, rep completion, and set completion
- Localized in English, Dutch, French, and German — follows the iOS system language by default, with an override in Settings
- Optional voice countdown: spoken "Down / Hold / Up" per language, counted per second through multi-second phases (e.g. "Down, 2, 3, 4" for a 4s eccentric), "Rest", and a 3-2-1 lead-in before each set — uses a matching AVSpeechSynthesisVoice for the current language
- Background audio mode: cues keep playing when the app is backgrounded or the screen is locked, and your music (Spotify etc.) keeps playing alongside
- Unilateral (single-side) mode: does all reps for one side, a switch pause, then all reps for the other side, within the same set — rest between sets only starts once both sides are done
- Bundled exercise database (873 exercises from the public-domain [free-exercise-db](https://github.com/yuhonas/free-exercise-db), no network calls): searchable picker with muscle/equipment filters and a recents list; picking an exercise suggests unilateral mode and starting phase (deadlifts/pull-ups lead with the concentric phase) — or skip it and run a bare timer
- Presets (4 built-in — Squat, Push-Up, Single-Leg RDL, Deadlift — plus any you save) set exercise + tempo + reps + sets + rest + unilateral settings all at once; long-press a saved one to delete it
- Automatic rest countdown between sets
- Pause/resume and stop
- Settings (tempo, reps, sets, rest, voice) are remembered between launches
- Workout history: finished workouts are logged with tempo, sets × reps, and time under tension
- Finish screen shows a checkmark animation, correctly-pluralized sets/reps ("1 rep", not "1 reps"), and time under tension for that workout
- Screen stays awake during a workout
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
  Models/WorkoutModels.swift  Config, phases, timeline segments
  Models/Exercise.swift       Bundled exercise-database entry
  Models/WorkoutPreset.swift  Built-in and user-saved exercise+settings presets
  Engine/WorkoutEngine.swift  Elapsed-time-driven workout state machine
  Services/SoundPlayer.swift  Synthesized beep cues via AVFoundation
  Services/SpeechPlayer.swift  Voice cues via AVSpeechSynthesizer
  Services/HapticsPlayer.swift  UIKit feedback generators
  Services/HistoryStore.swift  Persisted log of completed workouts
  Services/LocalizationManager.swift  System-language / override language resolution
  Services/ExerciseDatabase.swift  Loads the bundled dataset, tracks recents
  Services/PresetStore.swift  Persisted log of user-saved presets
  Views/SplashView.swift      Brief launch screen with the wordmark
  Views/SetupView.swift       Tempo/reps/sets/rest/exercise configuration
  Views/WorkoutView.swift     In-workout display and controls
  Views/HistoryView.swift     Workout history sheet
  Views/SettingsView.swift    Language override
  Views/ExercisePickerView.swift  Searchable exercise picker
  Resources/exercises.json    Bundled exercise dataset (name/category/muscles/equipment, no images)
  Localizable.xcstrings       String catalog (en, nl, fr, de)
  PrivacyInfo.xcprivacy       Privacy manifest — no tracking, no collected data

TempoRepTests/
  WorkoutEngineTests.swift    Timeline-building logic (bilateral/unilateral/switch/reordering)
  WorkoutConfigTests.swift    Codable round-trip, computed properties
  WorkoutPresetTests.swift    Preset application and persistence shape
  ExerciseDatabaseTests.swift  Bundled dataset loads correctly, no duplicate IDs
  LocalizationCatalogTests.swift  Every checked key resolves in all 4 languages

fastlane/metadata/           App Store listing text (name/subtitle/description/keywords) in en-US/nl-NL/fr-FR/de-DE
PRIVACY_POLICY.md            Ready-to-host privacy policy draft
APP_STORE_SUBMISSION.md      Checklist of what's done vs. what you still need to do before submitting
```
