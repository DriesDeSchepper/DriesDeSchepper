# UI consistency & modernization pass

This documents the design-system audit, the native/iOS-26 pass, and the
platform-feature proposals from the full UI consistency pass. Environment
note up front: this session has no macOS/Xcode/Simulator access, so
verification below is code-level review + CI (build and unit tests on
`iPhone 17` simulator, iOS 26 via Xcode 26.5), not actual on-device
screenshots. See **Part 4** for exactly what that does and doesn't cover.

## Part 1 — Design system (`TempoRep/DesignSystem.swift`)

One file, four token groups. Every screen was rewritten to use only these
— no more raw `Color.black`, `.font(.system(size: 17))`, `padding(20)`,
`cornerRadius(16)`, or `.easeInOut(duration: 0.2)` scattered per-screen.

- **Color** — `Color.tempoBackground` / `.tempoSurface` / `.tempoSurfaceRaised`
  / `.tempoPrimaryText` / `.tempoSecondaryText` / `.tempoDestructive` /
  `.tempoSuccess`, all derived from system semantic colors (adapt to
  light/dark automatically) or `.primary`/`.secondary`-relative opacities.
  Plus `.tempoWorkoutBackground` / `.tempoOnDark` / `.tempoOnDarkSurface(Raised)`
  for the two screens that deliberately never adapt (see Part 2). One
  accent color throughout, defined once in `Assets.xcassets/AccentColor` —
  **updated in the follow-up round below**: it now has separate light/dark
  appearance variants (it didn't originally, which is exactly what broke
  contrast in light mode — see "Follow-up fixes").
- **Spacing** — `Spacing.xs/sm/md/lg/xl/xxl` = 4/8/12/16/24/32. Every
  padding and stack-spacing call in every view now uses one of these six
  values.
- **CornerRadius** — `.sm/md/lg` = 14/16/20, matching what was already in
  use, just named.
- **Typography** — `TempoFont.rounded(_:weight:)` wraps `Font.system(_
  style:, design: .rounded)`, i.e. real Dynamic Type text styles
  (`.body`, `.headline`, `.caption`, …) in the app's rounded design. Every
  label, button, and row now scales with the user's text-size setting.
  The oversized workout-display faces (96pt countdown, 54pt phase title,
  56pt "DONE", 40pt tempo digits, splash wordmark) don't map to a text
  style — they're intentionally larger than `.largeTitle` — so those use
  `@ScaledMetric` seeded from `TempoMetrics.Display.*` base sizes instead,
  which still scales with accessibility text size while preserving the
  "readable across a room" design.
- **Motion** — `TempoAnimation.standard` (`.easeInOut(duration: 0.25)`)
  for all routine UI-state transitions (splash→setup crossfade, a section
  revealing/hiding). The one exception is the finish-screen checkmark
  spring (`TempoAnimation.celebration`), which is a deliberate one-off
  flourish, not a state transition — called out explicitly rather than
  silently lumped in.

### Inconsistencies found and fixed

- Card corner radii were 14 / 16 / 20 used inconsistently by feel, not by
  role — now `.sm`/`.md`/`.lg` map to a fixed meaning (digit box / button /
  card).
- Section-transition animation duration was 0.2s in one place (`SetupView`
  unilateral reveal) and 0.25s/0.3s in another (`RootView`'s
  splash/screen crossfades) — now one `TempoAnimation.standard`.
- Row/card "raised surface" opacity varied between 0.06 / 0.08 / 0.1 /
  0.12 with no discernible rule — consolidated to two tiers,
  `.tempoSurface` (0.06) and `.tempoSurfaceRaised` (0.10).
- Several tap targets were smaller than Apple's 44pt minimum:
  `CounterRow`'s +/- buttons were 40×40, the exercise-picker's favorite
  star was 32×32. Bumped to 44×44. (**Not changed, flagged instead**:
  `DigitStepper`'s chevrons are 44 wide but 32 tall — fixing that changes
  the visual proportions of the tempo-digit steppers, a real design call;
  left as-is pending your input rather than changed unilaterally.)
- Icon-only buttons (chevrons, +/-, digit steppers, tempo-info `ⓘ`) had no
  `.accessibilityLabel` at all — VoiceOver read them as "chevron up,
  button" ×4 identical times with no way to tell which tempo digit each
  one adjusted. Fixed — see Part 2.
- Fixed point sizes everywhere (17, 22, 24, 13, 11, 15, 18, 20, 54, 96,
  56…) with no scale or Dynamic Type behind them — replaced per Typography
  above.

## Part 2 — Native iOS 26 patterns

- **Light/Dark mode, made an explicit decision, not an accident** (per
  your framing): `Setup`, `Settings`, `History`, and the exercise
  picker/filter sheet now follow the system appearance via the semantic
  color tokens — no forced scheme. `WorkoutView` and `SplashView` are the
  deliberate exception and now say so in a doc comment plus their own
  local `.preferredColorScheme(.dark)` (previously this was forced
  *app-wide* from `TempoRepApp`, which is what was actually forcing every
  other screen dark too — that's the "accident" this makes explicit).
- **System components over custom-styled ones**: `Settings` and `History`
  no longer fight `Form`/`List` with `.scrollContentBackground(.hidden)` +
  a hand-picked black background + hand-picked row-background opacity.
  They're now plain `Form`/`List` using the system's own grouped-list
  materials — this is also what makes them pick up Liquid Glass and any
  future OS list styling automatically, and it incidentally fully
  resolves last session's black-box/seam bug at the root instead of
  papering over it.
  **Gap, flagged rather than guessed at**: `SetupView`'s cards (exercise
  button, tempo digits, presets row, counters, unilateral toggle) are
  bespoke, not `List`/`Form` rows, so they don't inherit this for free.
  Explicitly opting them into Liquid Glass means the `.glassEffect(_:in:)`
  modifier (iOS 26+, needs an `#available` fallback to the current
  solid-token styling for iOS 17–25). I didn't hand-write that blind: it's
  API I can't compile-check here, and a mistake in it breaks the whole
  build for a purely cosmetic gap CI would only surface 5-10 minutes later
  per attempt. Left as `.tempoSurface` (solid, adaptive, correct) for now
  — a concrete next step if you want it, not silently skipped.
- **`ContentUnavailableView`** replaces the hand-rolled "no workouts yet"
  VStack in `HistoryView`.
- **`.presentationDetents`**: Settings and History sheets now support
  `[.medium, .large]` (resizable half-sheet, standard for short
  settings/list content); the exercise picker stays `[.large]` since it
  has search plus a long scrollable list.
- **`.searchable`** was already in place on the exercise picker — no
  change needed there.
- **`.sensoryFeedback`** was already used throughout for value-bound
  controls (steppers, toggles, pickers) — audited, no gaps found beyond
  what Part 3's haptics section covers (event-driven cues during a
  workout, which are a different mechanism, see below).
- **Reduce Motion**: the finish-screen checkmark's scale-up (0.4→1) is
  skipped entirely when Reduce Motion is on — it still fades in
  (opacity-only crossfade), it just doesn't "pop." `TempoAnimation`'s
  `standard(reduceMotion:)`/`celebration(reduceMotion:)` helpers make this
  the default everywhere animations are driven from the design system,
  not an opt-in a future screen could forget.
- **VoiceOver / Dynamic Type accessibility pass**:
  - `DigitStepper` and `CounterRow` (used for eccentric/pause/concentric/
    pause digits, reps, sets, rest, switch time) now present to VoiceOver
    as a single adjustable element per control — labeled ("Eccentric
    duration", "Pause at top duration", "Reps per set", …), with the
    current value read out, and a swipe-up/down gesture to change it —
    the same pattern the native `Stepper` control uses, rather than two
    separately unlabeled +/- buttons.
  - The exercise-picker's favorite star, the settings/history header
    buttons, the "save as preset" button, and the exercise-row tap target
    all got (or already had, now double-checked) real
    `.accessibilityLabel`s.
  - `WorkoutView`'s phase title/countdown now post
    `UIAccessibility.post(notification: .announcement, …)` when the phase
    changes, and `.screenChanged` when a workout finishes — so a VoiceOver
    user gets phase changes announced without needing voice cues turned
    on (that's a separate, optional feature) or needing to manually
    re-swipe to the phase label after every change. The label itself
    stays in the accessibility tree too (not hidden), so it's still
    directly inspectable on demand.
  - The countdown ring is now one combined accessibility element
    ("Time remaining in this phase" / current seconds), instead of
    separately exposing the decorative progress arc.

## Part 3 — Platform features

### Haptics refinement — implemented

`HapticsPlayer` now uses Core Haptics (`CHHapticEngine`/`CHHapticPattern`)
for three genuinely distinct patterns instead of three different
`UIImpactFeedbackGenerator` *styles* (which mostly just vary intensity,
not felt rhythm):

- **Phase change** — one sharp tap.
- **Rep complete** — two quick taps.
- **Set complete** — three taps, ascending in intensity.

Devices without a custom-haptics-capable Taptic Engine (checked via
`CHHapticEngine.capabilitiesForHardware().supportsHaptics` — this is also
`false` in the Simulator, which is why this degrades safely in CI) fall
back to the exact `UIImpactFeedbackGenerator`/`UINotificationFeedbackGenerator`
calls this used before. No API changes — `WorkoutEngine` calls
`phaseChange()`/`repComplete()`/`setComplete()` exactly as before.

### Live Activity — proposal, not implemented

**Why not implemented here**: a Live Activity's Lock Screen/Dynamic Island
UI can only be defined inside a separate WidgetKit extension target —
that's an ActivityKit requirement, not a choice. Adding a new Xcode target
means hand-editing `project.pbxproj` to add a product, a build phase, an
embed-extension step, and (for the widget's own bundle identifier/App
Group, if the widget needs to read data outside what `Activity.request`
already pushes to it) an entitlements file — all without Xcode available
in this environment to validate the resulting project graph. Getting this
wrong risks a `pbxproj` that Xcode can't open at all, which is a much
worse outcome than not having the feature. This is exactly the situation
your instructions anticipated ("implement if straightforward, otherwise
list as proposal").

**Proposed design**, for when you (or a future session with Xcode) adds
the target shell:

1. **New target**: `TempoRepWidget` (WidgetKit Extension), embedded in the
   main app target, iOS 16.1+ deployment (Live Activities' minimum).
2. **Shared `ActivityAttributes`**, in a file added to *both* targets:
   ```swift
   struct WorkoutActivityAttributes: ActivityAttributes {
       struct ContentState: Codable, Hashable {
           var phaseTitle: String       // already-localized, computed app-side
           var currentRep: Int
           var totalReps: Int
           var currentSet: Int
           var totalSets: Int
           var phaseEndDate: Date       // lets the Lock Screen countdown tick
                                          // on its own via Text(timerInterval:),
                                          // no push updates needed for the ring
       }
       var exerciseName: String?
   }
   ```
3. **Starting/updating/ending the Activity** — from `WorkoutEngine`, no
   widget-side code needed for this part:
   - `Activity.request(attributes:content:)` in `start()`.
   - `activity.update(...)` on each `playCues(enteringIndex:)` phase
     change (same call site already driving haptics/sound/voice cues —
     natural integration point).
   - `activity.end(...)` in `stop()`/`finish()`.
4. **Widget UI** (`TempoRepWidget/WorkoutLiveActivity.swift`): a
   `Widget` conforming to `ActivityConfiguration<WorkoutActivityAttributes>`
   with `.lockScreen`, plus `.dynamicIsland` presentations for compact
   leading/trailing (rep/set count), minimal (a compact ring), and
   expanded (full phase + countdown, matching the main app's design
   tokens above so it doesn't look like a different app).
5. **Entitlement**: none required for a same-app Live Activity that only
   receives data the main app already pushes via `Activity.update` — no
   App Group needed unless the widget needs to read `UserDefaults`
   directly, which this design avoids.
6. **Risk/cost note for you**: this is a half-day-to-day of real work even
   with Xcode available (widget target setup, testing Dynamic Island
   states on a real device — Live Activities don't render meaningfully in
   the Simulator either), not a quick follow-up.

## Part 4 — Verification

**What I could actually verify**: every changed file was re-read in full
after editing (not just diffed), a repo-wide grep confirmed no leftover
hardcoded colors/fonts/spacing/radii/durations outside `DesignSystem.swift`
itself, the String Catalog collision check (case-insensitive symbol
generation) was re-run after every catalog edit, and CI (`xcodebuild
build` + `xcodebuild test` on iPhone 17 Simulator, Xcode 26.5) is green —
see the commit(s) for this pass.

**What I could not verify, and you should check on a real device**:

- Actual visual appearance in light mode — I changed the color tokens to
  be theoretically correct (system semantic colors, contrast-safe by
  construction), but I have never seen this app rendered in light mode.
  Please open Setup/Settings/History/the exercise picker with the system
  in light mode and confirm nothing looks washed out or low-contrast,
  especially `.tempoSurface`'s `.primary.opacity(0.06)` cards against a
  white background.
- VoiceOver announcements in practice — the `UIAccessibility.post` calls
  and adjustable-action steppers are implemented per Apple's documented
  API, but announcement timing/interruption behavior is something Apple's
  own simulator support for VoiceOver is notoriously unreliable for; a
  real device pass with VoiceOver on is the only real check.
- Dynamic Type at the largest accessibility sizes — `@ScaledMetric` should
  keep the giant countdown/phase text from overflowing its containers
  (they already had `.minimumScaleFactor` as a backstop), but I can't
  screenshot-confirm the largest AX sizes don't clip anything on the
  finish screen or digit steppers.
- Haptic feel — Core Haptics patterns are only felt on a real device; the
  Simulator can't exercise the custom-pattern path at all (only the
  fallback path, which is unchanged from before).
- Reduce Motion end-to-end — logic is in place and code-reviewed, but I
  can't toggle the real Accessibility setting and watch the finish screen.

## Looking ahead to iOS 27

Nothing in this pass depends on beta-only APIs, so there's nothing to
unwind. Two things worth a look once iOS 27 actually ships and its
final APIs are public:

- If Apple extends Liquid Glass materials to `Form`/`List` grouped
  backgrounds with a new opt-in modifier (rather than it being automatic,
  as it is today), revisit whether `Settings`/`History` want it explicitly
  — right now they get whatever the system default is, which is the
  correct default assumption today.
- Re-check `@ScaledMetric`'s interaction with any new Dynamic Type range
  Apple adds — unlikely to break anything (it's designed to be
  forward-compatible), but worth a glance at release notes.

## Follow-up fixes (from real light-mode testing)

Once the adaptive-appearance change above actually got seen in light mode:

- **Accent-color contrast in light mode.** `AccentColor` was a single
  "universal" value (a bright lime, `#C7FF45`-ish) with no light/dark
  variants — fine when the whole app was forced dark, actively broken
  once Setup/Settings/History/the picker started following the system
  appearance, since that same bright, high-luminosity green has poor
  contrast against a light background. Fixed by giving `AccentColor` a
  separate light-appearance value (`Assets.xcassets/AccentColor` — a
  darker, more saturated olive-green in the same hue family, ~4.6:1
  contrast against white) while the dark-appearance value stays exactly
  the original lime. Every screen that's always-dark (`WorkoutView`,
  `SplashView`) keeps resolving the original bright variant automatically
  since they force the dark trait; nothing there changed.
- **Tempo digits not centered.** The info (`ⓘ`) button used to share a
  row with the 4 digit steppers, pushing them off-center to make room for
  it. Moved to its own right-aligned row above the digits, which now
  center in a `.frame(maxWidth: .infinity)` row of their own.
- **Start button now floats.** It sat on an opaque `.tempoBackground` bar
  (solid white in light mode) — swapped for `.ultraThinMaterial`, so it's
  a blurred, floating capsule over the scrolling content instead of a
  bar with a hard edge.
- **Modals are full-height, not resizable half-sheets.** Removed the
  `.presentationDetents([.medium, .large])` added in the first pass —
  Settings/History/the exercise picker (and its nested filter sheet) now
  just use the sheet default (full height), no partial "half" state.
- **Close button moved to the leading (left) side** in all four modals.
  Where a leading item already existed (History's "Clear", the exercise
  picker's "Filters"), it moved to trailing instead, rather than being
  removed or doubled up.
- **No more green icons inside modals.** The `.tint(Color.accentColor)`
  on these `NavigationStack`s is still there — it's what correctly keeps
  Toggle/Picker/segmented-control selection colors on-brand — but every
  standalone icon glyph that had been silently inheriting that tint
  (the exercise-picker's Filters icon, the filter sheet's selection
  checkmark, History's empty-state icon) now has an explicit
  `.foregroundStyle(.secondary)` / `.primary` instead. `CloseButton` was
  already neutral. The favorite star (yellow) and a history row's tempo
  number (accent-colored text, not an icon) were left as-is — not in
  scope of "icons," and the tempo number's contrast is covered by the
  AccentColor fix above.
