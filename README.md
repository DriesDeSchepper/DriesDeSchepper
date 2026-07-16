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

- Tempo input as 4 digits with presets (4010, 3110, 2020, 5050)
- Reps per set, number of sets, rest between sets
- Huge phase name + countdown ring, readable from across the room
- Distinct sound + haptic cues for phase changes, rep completion, and set completion
- Optional voice countdown: spoken "Down / Hold / Up", rep numbers, "Rest", and a 3-2-1 lead-in before each set
- Background audio mode: cues keep playing when the app is backgrounded or the screen is locked, and your music (Spotify etc.) keeps playing alongside
- Automatic rest countdown between sets
- Pause/resume and stop
- Screen stays awake during a workout
- Drift-free timing: state is derived from wall-clock elapsed time, not accumulated timer ticks
- Cues play even when the phone is on silent (`.playback` audio session category)

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

## Project layout

```
TempoRep/
  TempoRepApp.swift              App entry point
  Models/WorkoutModels.swift  Config, phases, timeline segments
  Engine/WorkoutEngine.swift  Elapsed-time-driven workout state machine
  Services/SoundPlayer.swift  Synthesized beep cues via AVFoundation
  Services/SpeechPlayer.swift  Voice cues via AVSpeechSynthesizer
  Services/HapticsPlayer.swift  UIKit feedback generators
  Views/SetupView.swift       Tempo/reps/sets/rest configuration
  Views/WorkoutView.swift     In-workout display and controls
```
