# Cordillera — Build Specification

> Portfolio app 195, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Pin each day's pages on an elevation profile as you read a book toward its summit.

| Field | Value |
| --- | --- |
| Product name | Cordillera |
| Bundle identifier | `com.cordillera.profile` |
| Domain | https://cordillera-profile.pro |
| Contact URL | https://cordillera-profile.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Dark |
| Asset prefix | `cdr_` |
| User-Agent | `Cordillera/1.0 (iOS; +https://cordillera-profile.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
   Guideline 4.2 (Minimum Functionality): this is a native SwiftUI product, not
   a web browsing experience. WKWebView / SFSafariViewController as UI is a
   reject. Push notifications, Core Location, and sharing do not make a
   browser or a thin catalog into an App Store app.
5. **Guideline 5.1.1 (Privacy):** never direct the user to grant camera access.
   A pre-permission screen may exist; the proceed button is **Continue** or
   **Next**, never "Allow camera", "Enable camera", "Grant camera", or a bare
   Allow/Enable that triggers `requestAccess`. The system alert is the only Allow.
6. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
7. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
8. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Cordillera -destination 'generic/platform=iOS' build`.
9. **Nothing may echo another app in this batch** in naming, layout or visuals.
10. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

A backpack reader pins today's pages on the open traverse so the elevation profile climbs toward the volume's summit marker.

### 2.1 User flow

1. Pin today's page count on the elevation profile
2. Open a hold from Pack to start or resume a traverse
3. Search or scan an ISBN on Pack to moor a new hold
4. Bridge one dashed gap segment when the weekly bridge is available
5. Recenter the planned summit when too many gap days block Pin
6. Browse summited holds and contour benchmarks on Summits

### 2.2 Essential behaviour

- Cordillera elevation profile home with hiker dot and chained trig markers
- Pack sheet with Open Library title search and live ISBN scan to moor holds
- Traverse sheet for the active hold: open, peel last pin, recenter date
- Contour benchmarks spawned at each ten-percent band crossing
- Dashed gap segments on days without a Pin mark
- One Bridge per ISO week that spends double pages to close a single gap
- Summits registry of finished holds with benchmark badges
- Local-only persistence; no account or sync

---

## 3. Uniqueness assignment for Cordillera

| Axis | Assigned value |
| --- | --- |
| Architecture | **Contour ADT fold (Packed | Active | Summited); the profile is a fold over Holds; Open writes a Traverse on a Hold and folds Packed to Active; Pin writes a TrigMark, advances profileX, and may write Benchmark at decile crossings; GapDay detection appends GapSegment without Pin; Bridge writes BridgeMark once per ISO week and closes oldest gap at double page cost; Recenter writes RecenterMark when gapCount exceeds three and unblocks Pin; Pin on Packed is refused; second Open while Active is refused; Summited when profileX reaches one; empty pack writes Bare** |
| UI approach | **UIKit UIStackView layout · canvas-first** |
| Naming convention | **Cordillera / survey lexicon (Profile, Hold, Traverse, Trig, Pin, Contour, Benchmark, GapSegment, Bridge, Recenter, Summits, Pack)** |
| File organization | **By cordillera role (Profile, Hold, Traverse, TrigMark, Benchmark, GapSegment, BridgeMark, RecenterMark, Summits, Pack)** |
| Dependency strategy | **None (zero external dependencies) · no SPM entry, no CocoaPods, no vendored source; UIKit, Core Graphics, AVFoundation and URLSession only** |
| Design direction | **vercel · dark-canvas · duotone** |
| Typography | **Palatino** |
| Navigation pattern | **Cordillera-locked chrome (the elevation profile never leaves; Pack, Traverse and Summits arrive as sheets; ISBN scan and title search fuse on Pack)** |
| AI art style | **Low poly 3D render · collage** |
| Functional twist | **Pin-then-closure (Pin advances profileX; decile Benchmarks; missed days leave GapSegments; one Bridge per ISO week at double page cost; Recenter when gapCount exceeds three)** |
| Persistence | **UserDefaults+Codable · one Chart root record holding Islands, Books, Sessions, Runs and Rhumbs, encoded under a single key with a debounced save after each mark** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — reading_expedition

**Core** — A backpack reader pins today's pages on the open traverse so the elevation profile climbs toward the volume's summit marker.

**Audience** — Readers who think in contour and trig chains, not schedule drift on a flat chart or genre rhumbs between islands.

**User flow**

1. Pin today's page count on the elevation profile
2. Open a hold from Pack to start or resume a traverse
3. Search or scan an ISBN on Pack to moor a new hold
4. Bridge one dashed gap segment when the weekly bridge is available
5. Recenter the planned summit when too many gap days block Pin
6. Browse summited holds and contour benchmarks on Summits

**Essential features**

- Cordillera elevation profile home with hiker dot and chained trig markers
- Pack sheet with Open Library title search and live ISBN scan to moor holds
- Traverse sheet for the active hold: open, peel last pin, recenter date
- Contour benchmarks spawned at each ten-percent band crossing
- Dashed gap segments on days without a Pin mark
- One Bridge per ISO week that spends double pages to close a single gap
- Summits registry of finished holds with benchmark badges
- Local-only persistence; no account or sync

**Twist** — Pin-then-closure. Home is the cordillera profile, not a plan map. Open on a Hold from Pack sets summit at totalPages and writes a Traverse, folding Packed to Active. Pin writes a TrigMark for today's pages, advances profileX by pages divided by totalPages, and spawns a Benchmark when a ten-percent contour band is newly crossed. Calendar days without Pin append a GapSegment on the profile; they do not rotate bearing like Periplus drift. Bridge writes a BridgeMark once per ISO week, spends twice the usual pages for that Pin, and closes the oldest open gap; Bridge with no open gap writes HollowMark. When open gapCount exceeds three, Pin is refused until Recenter writes a RecenterMark that pushes the planned summit day forward and clears the refusal. Pin on Packed is refused. A second Open while Active is refused until Summits or Peel clears the traverse. Summited when profileX reaches one. Seed already Opens one hold with profileX above zero, gapCount at most two, and no bridge used this week so the opening tap is Pin. Home verb: pin-the-trig—not log-the-leg, bear-the-rhumb, or light-a-lamp. Local only.

**Why this is not a repeat** — Same family as Periplus and Marteloio but a different native verb and mechanic: summit profile with trig pins and gap/bridge closure, not schedule-drift bearing curl (Periplus) or spending Runs to ink genre rhumbs (Marteloio). Screen destinations rename the expedition chrome (Profile/Pack/Traverse/Summits) so they do not collide with Periplus Map/Catalogue/Expedition/Stats. Axes use unused catalog combinations (vercel dark-canvas duotone, Low poly collage, UIStackView canvas-first, cordillera lexicon) rather than Periplus posthog editorial-stack or portolan chart axes.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: Cyanotype route map, not an ISBN shelf.
- Invariant: driftAngle = (lastEndPage/total − progress)×45°. Route x = cumulative pages/total.
- Never: Drift when idle is visible on the map.
- Desk `pack_balance`: fill=Σvol/cap; balanceXY=weight-avg of zones; readiness mixes clip(weight), clip(fill), balance.
- Taste DNA is section 7.6. Do not invent a second look.
- A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.

### 3.1 Architecture contract

Contour is an ADT fold over Holds with cases Packed, Active, and Summited, and an empty Pack writes Bare. Open writes a Traverse on a Packed Hold, sets the summit at totalPages, and folds Packed to Active, while a second Open during Active is refused until Summits or Peel clears the traverse, and Pin on Packed is refused. Pin on Active writes a TrigMark for today's pages, advances profileX by pages divided by totalPages, writes a Benchmark when a ten-percent band is newly crossed, and the Hold is Summited when profileX reaches one. A calendar day without Pin appends a GapSegment without moving profileX, Bridge writes one BridgeMark per ISO week that spends twice the usual pages and closes the oldest gap or writes HollowMark when no gap is open, and when gapCount exceeds three Pin stays refused until Recenter writes a RecenterMark that pushes the planned summit day forward. Unit-test driftAngle = (lastEndPage/total − progress)×45°. Route x = cumulative pages/total, stored as profileX, with lastEndPage read from the latest TrigMark and progress as elapsed days over the planned summit span, and driftAngle stays off the canvas because a missed day is a GapSegment.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

UIKit UIStackView layout, canvas-first. Profile is one full-bleed UIView drawn with Core Graphics inside the root stack: ridgeline, hiker dot, chained trig markers, dashed GapSegments, and the Pin control, using the full iPad width. That canvas is the only custom-drawn surface. Pack, Traverse, Summits, and Settings are UIViewController sheets built from UIStackView, UILabel, UIButton, and UITextField. The ISBN preview is an AVCaptureVideoPreviewLayer inside Pack. One UIButton style covers default, pressed, disabled, and loading, and Peel uses the destructive variant. Reduce Motion follows UIAccessibility.isReduceMotionEnabled with a 180ms cross-fade, or an instant swap. A successful Pin plays one haptic. Every control is at least 44 points with the hit shape on the whole chrome, and icon-only buttons have accessibility labels. Colour, type, space, and radius each come from one accessor.

### 3.3 Naming contract

Convention: Cordillera / survey lexicon (Profile, Hold, Traverse, Trig, Pin, Contour, Benchmark, GapSegment, Bridge, Recenter, Summits, Pack).

Examples to follow: `Hold`, `TrigMark`, `pinPages(_:)`, `ProfileCanvas`

### 3.4 Dependency contract

Zero external dependencies. No SPM entry, no CocoaPods, and no vendored source, so project.yml has no packages key. The linked system frameworks are UIKit, Core Graphics, AVFoundation, and URLSession only. Title search and ISBN lookup go through URLSession to Open Library search.json and the ISBN endpoint, with User-Agent Cordillera/1.0 (iOS; +https://cordillera-profile.pro). An empty or failed search shows holds already moored on this device.

### 3.5 Navigation contract

The elevation profile stays on screen for the life of the session. Pack, Traverse, Summits, and Settings arrive as sheets over that canvas. ISBN scan and title search both live on Pack. Peel and Recenter live on Traverse. After onboarding, ReviewLaunch reads ProcessInfo arguments once: -ReviewScreen today leaves Profile, log presents Traverse, goals presents Summits, pack presents Pack, and settings presents Settings.

### 3.6 Screen composition contract

Profile, Pack, Traverse, Summits, Settings. Profile is the permanent elevation canvas and the home verb Pin, with the hiker dot, trig chain, and dashed GapSegments filling the screen. Pack is a sheet that fuses Open Library title search with live ISBN capture and lists Packed holds, each row opening that hold. Traverse is the sheet for the Active hold: pages pinned, Peel of the last TrigMark, and Recenter when gaps block Pin. Summits is the registry of finished holds and their Benchmark badges. Settings holds the contact link https://cordillera-profile.pro/contact-us, confirmed resetAllData, and onboarding replay. A Bare pack is a full-page empty state on Profile: generated art, the headline No expedition yet, the line Open a volume, and a full-width Open control at the bottom. Onboarding is three or four full pages with Continue full width at the bottom. Denied camera on Pack explains the state and routes to Open Settings. The simulator seed key cdr.demo.v1 runs once, marks onboarding complete, and draws several trig marks on one Active hold so Pin is enabled.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.

---

## 4. Target file organization

Scheme: **By cordillera role (Profile, Hold, Traverse, TrigMark, Benchmark, GapSegment, BridgeMark, RecenterMark, Summits, Pack)**

```
Cordillera/
  Profile/
Hold/
Traverse/
TrigMark/
Benchmark/
GapSegment/
BridgeMark/
RecenterMark/
Summits/
Pack/
Settings/
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Map
A first-class screen for **Map**. Must render empty, populated and error states.

### 5.3 Catalogue
A first-class screen for **Catalogue**. Must render empty, populated and error states.

### 5.4 Expedition
A first-class screen for **Expedition**. Must render empty, populated and error states.

### 5.5 Stats
A first-class screen for **Stats**. Must render empty, populated and error states.

### 5.6 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.7 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.8 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.


---

## 6. Domain model

Minimum entities, named per this app's convention:

- **Volume** — named per this app's convention.
- **Expedition** — named per this app's convention.
- **Waypoint** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **vercel · dark-canvas · duotone**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#272C1B` | Screen background |
| `surface` | `#2E3D29` | Cards, rows, sheets |
| `ink` | `#F3F4F1` | Primary text and icons |
| `accent` | `#87D86E` | Primary action, key figure, progress fill |
| `muted` | `#BABFB0` | Secondary text, dividers, disabled |

The scaffold already wrote these exact values to `Cordillera/DesignTokens.swift`
(`DesignTokens.bg`, `.surface`, `.ink`, `.accent`, `.muted`, plus
`DesignTokens.fontFamily`). Reach every colour through `DesignTokens` — a
typed accessor on top of it is fine. Keep the file and its hex values; do not
move them into `Assets.xcassets` and never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **Palatino**

Palatino is the only UI face, reached through one accessor with six steps: display, title, headline, body, caption, and micro. Palatino-Bold carries the summit figure and the Pin label. Palatino-Roman carries body and sheet copy on the body step, about 17 points. Display stays one or two lines, with slight negative tracking, and no step is set above 34 points before Dynamic Type. Page counts, profile readouts, and gap counts go through NumberFormatter with monospaced digits. Sizes use ScaledMetric, track Dynamic Type, and never use a fixed size. At the largest accessibility size, long lines may fall back to New York so Palatino stays readable. Day edges use Calendar.current.startOfDay before they become a YYYYMMDD int.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- Corner radius and elevation are fixed by section 7.4, not chosen per screen.
- Every interactive element is at least 44x44 pt.

### 7.4 Component contract

Corner radius: **24pt** for cards, sheets and primary surfaces; **10pt** for chips, badges and small controls. Reach both through one accessor. Never a bare literal number, and never zero — a hard edge is not this app's design direction.

Elevation: **material** — SwiftUI `Material` (`.regularMaterial` / `.thinMaterial`), reused everywhere a surface sits above another.

Primary control: **tinted glass** — primary chrome sits on a tinted translucent surface (`Material` plus the accent colour at low opacity), never plain flat colour.

This is arithmetic, not a suggestion: every card, sheet, chip and button in this app uses these two radii and this elevation style. Do not introduce a second radius or a second elevation style.

### 7.5 Custom rendering scope

This app's `ui` axis is **UIKit UIStackView layout · canvas-first**.

If that approach uses anything beyond stock SwiftUI/UIKit controls — `Canvas`, `CALayer`, Metal, SceneKit, SpriteKit, RealityKit, a hand-drawn `UIViewRepresentable`, or any other pixel-level custom rendering — confine it to exactly one hero surface on one screen (the mechanic's home view, or the one screen this axis exists to showcase). Every other screen — every list, every settings screen, every sheet, every secondary surface — is built from stock components: `List`, `Form`, `NavigationStack`, `TabView`, `Button`, `.sheet`, native `Text`/`Image`. A second custom-rendered surface elsewhere in the app is a defect, not a stylistic choice.

If **UIKit UIStackView layout · canvas-first** is already fully native (no custom drawing layer), this section is satisfied automatically — there is nothing to confine.

The `ui` axis value is an implementation choice. It must never appear as a user-visible section title or label.

### 7.6 Taste DNA

Aesthetic: **agency** (High-end agency: huge type, air, one accent, hairline depth.)

Reference system: **vercel** — steal rhythm and restraint, not their colours or logos.

Mood: **Frontend deployment. Black and white precision, Geist font.**.

Home rhythm (`dark-canvas`, dense): A dark canvas and one lit object.

High-end agency: huge type, air, one accent, hairline depth. Layout `dark-canvas`, density dense. Kit 24/10, material, tinted glass. Palette recipe `duotone`. Almost no travel. Cross-fade 180ms ease-out. Numbers tick, they do not fly. Reduce Motion: instant swap. Reduce Motion: fade only. Do not invent a second radius or a second accent.

Type move: Mono numerals, humanist body, no poster type. Reference type feel: agency.

Motion (`quiet`): Almost no travel. Cross-fade 180ms ease-out. Numbers tick, they do not fly. Reduce Motion: instant swap.

Voice (`editorial`): Complete sentences, no slang, no hype. Captions are real lines.

Anti-slop from KNOWLEDGE.md applies. Taste never overrides contrast, 44pt hits, VoiceOver labels, or Reduce Motion.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Sibling cards, images and titles never overlap. Each cell owns its frame;
  `scaledToFill` is clipped to that cell. A chopped headline or two canvases
  in one slot is a defect, not a collage.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


Every item here is a defect if it is missing. Section 7.4 fixed the numbers —
this is where they have to show up on screen.

**Hierarchy and density**

- Every screen has exactly one dominant element (a hero number, a canvas, a
  primary card) that the eye lands on first. A screen where every element has
  equal weight reads as a spreadsheet, not a product.
- Related content is grouped into a card or a section with the elevation
  style from 7.4, not left floating on the bare background.
- Unused flat background is not "minimal" — see the density rule in
  `KNOWLEDGE.md`. If a screen has room left after the mechanic and the
  content, add a secondary surface (a stat strip, a recent-activity card, a
  related-item row), not a `Spacer`.

**Components**

- Every card, sheet, chip, row and button in the app uses the corner radius
  and elevation from section 7.4. No screen introduces its own radius or its
  own shadow value "just for this one card".
- Buttons have a pressed state (`ButtonStyle` with a scale or opacity change
  on `isPressed`) and a disabled state that is visibly different, not just
  non-interactive.
- Chips and badges are pill or rounded-rect shaped per 7.4, never a bare
  `Text` with no background sitting where a control is expected.
- A functional control (add, filter, sort, close, more, share, delete) is an
  SF Symbol inside a properly hit-targeted `Button`. SF Symbols are fine and
  expected here — section 16 only bans them as the app's primary brand
  iconography (app icon, empty-state hero, onboarding art), which is what the
  generated assets in section 13 are for.

**Depth and material**

- At least one surface in the app (a sheet, a modal, a floating toolbar) uses
  the elevation style from 7.4 to visibly sit above the content behind it.
  A flat app with no depth anywhere reads as a wireframe.
- Icons and generated art sit on the surface colour from 7.1, never directly
  on a colour that makes their edges disappear.

**Motion as feedback, not decoration**

- The one dominant element in a screen (7.4's primary control, the mechanic's
  hero) responds visibly to touch: a scale, a colour shift, a haptic — pick
  at least one. A control that looks identical pressed and unpressed reads as
  broken, not calm.

**Taste DNA (section 7.6)**

- Home uses the assigned layout family and density. Three identical equal-weight
  cards, a leftover bento hole, or a second column structure copied down the
  page is a defect.
- Copy follows the assigned voice. No em-dash, no elevate/unlock/seamless, no
  emoji, no SECTION 01 labels.
- Motion follows the assigned personality and honours Reduce Motion with a fade.
  One signature motion per view. No glow stacked on glass stacked on spring.
- Tokens by intent: the live verb wears accent; delete does not wear primary.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **UserDefaults+Codable · one Chart root record holding Islands, Books, Sessions, Runs and Rhumbs, encoded under a single key with a debounced save after each mark**

UserDefaults stores one Codable ContourChart under the single key cdr.contour.v1. That root holds Holds, Traverses, TrigMarks, Benchmarks, GapSegments, BridgeMarks, RecenterMarks, and HollowMarks, with schemaVersion starting at 1. Each Open, Pin, Peel, Bridge, or Recenter schedules a debounced save of that one record and flushes when the scene becomes inactive or background. Day values are Ints in YYYYMMDD form taken from Calendar.current.startOfDay. The UI talks only to the contour store. resetAllData() removes the key and is reachable from Settings. A decode failure restores the previous JSON kept beside the key and, if that also fails, starts from Bare.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Dedicated `JSONDecoder` with `.useDefaultKeys`. Never `convertFromSnakeCase` —
  Open Food Facts keys like `energy-kcal_100g` break snake_case conversion.
- Resolve a scanned code with `GET /api/v2/product/<barcode>.json`, not a search.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Cordillera/1.0 (iOS; +https://cordillera-profile.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- Guideline 5.1.1 (Privacy): do not encourage or direct the user to grant camera
  access. A pre-permission screen may exist, but the proceed button must be
  **Continue** or **Next** — never "Allow camera", "Enable camera",
  "Grant camera", or a bare Allow/Enable that calls `requestAccess`. The
  system dialog is the only Allow. Denied/restricted offers Open Settings.
- The app must not present itself as a clinician or as medical advice.
- Guideline 4.2 (Design — Minimum Functionality): the binary must be a native
  product, not a web browsing experience. No WKWebView / SFSafariViewController
  / UIWebView as home, a tab, or the primary UX. A content catalog, article
  reader, or site wrapper that could be a website is a reject. Push
  notifications, Core Location, and sharing do not make that acceptable.
- Guideline 1.4.1 (Safety — Physical Harm): if the binary shows health or
  medical recommendations, body-based targets, dosages, "you should" guidance,
  or product health claims (food, drink, supplement, remedy), put citations
  in the app. Tappable links to the sources, easy to find: same screen as the
  claim, or a Sources row one tap from Settings. Name the source (Open Food
  Facts, USDA FoodData Central, WHO, NIH MedlinePlus, …) and link it. A
  "not medical advice" footer without sources is a reject. A personal log
  that never advises does not invent claims to cite.
- Nutrition catalog data is credited to the database this app actually uses
  (Open Food Facts unless the spec names another). Credit is a tappable link,
  not a dead "OpenFoodFacts" label.


### First minute on a clean install (Guideline 2.1)

A reviewer judges completeness (Guideline 2.1) in the first minute on a clean
install. The loop must finish there without knowing the app's rules. Long form:
`docs/REVIEW-LESSONS-2026-09-25.md`.

- The home verb writes a visible object on the first tap of a clean install:
  a row, a card, a mark on the dial. No second screen needed to see it.
- Never leave the home control disabled until an unexplained condition holds
  ("two links first", "long press first", "add a volume first"). Accept the
  first input with sane defaults and show the rule afterwards.
- The twist fires after a successful write, as a visible consequence (a highlight,
  a caption, a next step), never instead of the write.
- A refusal is allowed only after the first success, and it must name the next
  tap that works.
- Nothing in the first session waits for midnight, a second day, a second item or
  a streak. A screen that can only fill later shows its action, not a wait.
- Every empty state names one action, and that action completes on the spot.
- Next to home there is at least one more screen that works on a clean install.
- The subtitle and the first description line name an everyday action a stranger
  understands. Coined words may decorate labels; each primary button still says
  what it does.
- A failed network lookup falls back to local data or typed input with a message;
  the loop still finishes offline.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.books`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Dark
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UIRequiresFullScreen: YES
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.books
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Pin-then-closure (Pin advances profileX; decile Benchmarks; missed days leave GapSegments; one Bridge per ISO week at double page cost; Recenter when gapCount exceeds three)

Pin writes a TrigMark for today's pages, advances profileX by those pages divided by totalPages, and writes a Benchmark when a ten-percent contour band is newly crossed. A calendar day without Pin appends a dashed GapSegment on the profile. Bridge writes a BridgeMark once per ISO week, spends twice the pages of that Pin, and closes the oldest open gap, or writes a HollowMark when no gap is open. When open gapCount exceeds three, Pin is refused until Recenter writes a RecenterMark that pushes the planned summit day forward and clears the refusal. Pin on Packed is refused, a second Open while a Hold is Active is refused until Summits or Peel clears the traverse, and the Hold is Summited when profileX reaches one. The simulator seed opens one Hold with profileX above zero, gapCount at most two, and no Bridge used this ISO week, so the first tap on Profile is Pin.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Low poly 3D render · collage**


Base prompt, reused and extended for every asset:

```
Low poly 3D render assembled as a collage. Faceted solid masses, hard planar faces, and overlapping cut planes like a survey model of a ridgeline. One lit object on an unlit field, quiet center, hairline depth, no text, no letters, no glyphs, no rounded icon mask.
```

All 12 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `cdr_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `cdr_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `cdr_Splash` | 1290x2796 | fill | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `cdr_Onboarding1` | 1024x1536 | **required cutout** | Onboarding page 1 illustration: what the app is for. |
| 4 | `cdr_Onboarding2` | 1024x1536 | **required cutout** | Onboarding page 2 illustration: the main verb. |
| 5 | `cdr_Onboarding3` | 1024x1536 | **required cutout** | Onboarding page 3 illustration: why they stay. |
| 6 | `cdr_EmptyHome` | 1024x1024 | **required cutout** | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `cdr_EmptyList` | 1024x1024 | **required cutout** | Empty state: a secondary list has no rows. |
| 8 | `cdr_CardBackdrop` | 1200x800 | fill | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `cdr_ControlFace` | 512x512 | **required cutout** | Custom control artwork used for the primary interactive element. |
| 10 | `cdr_TwistHero` | 1024x1024 | **required cutout** | Hero art for the 'Pin-then-closure (Pin advances profileX; decile Benchmarks; missed days leave GapSegments; one Bridge per ISO week at double page cost; Recenter when gapCount exceeds three)' feature screen. |
| 11 | `cdr_SuccessMark` | 512x512 | **required cutout** | Shown briefly when the primary action succeeds. |
| 12 | `cdr_HeaderDecor` | 1200x600 | **required cutout** | Decorative header accent on the main screen. |

### Prompt per asset

**`cdr_AppIcon`** — 1024x1024

```
Low poly 3D collage emblem of a faceted ridgeline and a solid trig cairn, centred and filling the canvas edge to edge, no text, no alpha, no rounded mask.
```

**`cdr_Splash`** — 1290x2796

```
Vertical low poly 3D collage of a cordillera, one lit cairn, quiet uncluttered centre band for a wordmark, filling the canvas, no text, no letters.
```

**`cdr_Onboarding1`** — 1024x1536

```
Low poly 3D collage cutout of a solid closed pack beside a folded contour sheet, opaque subject centred, transparent corners, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`cdr_Onboarding2`** — 1024x1536

```
Low poly 3D collage cutout of a solid hand pressing a survey pin into a rising faceted ridge, opaque subject centred, transparent corners, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`cdr_Onboarding3`** — 1024x1536

```
Low poly 3D collage cutout of a solid summited cairn with small solid benchmark plaques along the ridge, opaque subject centred, transparent corners, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`cdr_EmptyHome`** — 1024x1024

```
Low poly 3D collage cutout of a solid closed pack in faceted canvas and wood, fully opaque subject, transparent corners, calm, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`cdr_EmptyList`** — 1024x1024

```
Low poly 3D collage cutout of a solid closed survey folio standing empty, opaque subject centred, transparent corners, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`cdr_CardBackdrop`** — 1200x800

```
Abstract low poly collage of broad faceted planes, low contrast, filling the canvas so type can sit on it, no text, no object in the centre.
```

**`cdr_ControlFace`** — 512x512

```
Low poly 3D collage cutout of one solid survey bolt, the face of the pin control, opaque metal mass centred, transparent corners, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`cdr_TwistHero`** — 1024x1024

```
Low poly 3D collage cutout of a solid faceted span closing a break in a ridgeline, opaque subject centred, transparent corners, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`cdr_SuccessMark`** — 512x512

```
Low poly 3D collage cutout of a solid filled cairn, opaque mass in the centre, transparent corners, no outline, no hollow ring, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`cdr_HeaderDecor`** — 1200x600

```
Low poly 3D collage cutout of a long solid faceted ridgeline ornament, opaque subject, transparent corners, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```


### 13.3 Asset rules

- Cut-outs (everything except AppIcon, Splash, CardBackdrop): isolated subject,
  real PNG alpha, all four corners transparent. No square plate.
- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, and seamless tiles are drawn in SwiftUI via `Path` or `Shape`. GenerateImage is not used for those. Every other in-app graphic (except AppIcon, Splash, CardBackdrop) is a **cutout**: isolated SOLID opaque subject in the center, real PNG alpha, all four corners transparent. An opaque square plate inside a circle or pentagon is a fail. A hollow glass box or wire frame with a transparent center is a fail.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. The same seed must mark onboarding complete and
fill the primary surface — otherwise `-ReviewScreen` never fires. Never seed
on a physical device. Guard with `#if targetEnvironment(simulator)` and
`cdr.demo.v1`.

Seed the happy path: the home primary verb is enabled. The blocked / gated /
error state is a unit-test fixture, not Simulator home. Home chrome names the
job and the next tap in words a stranger knows. Axis values (`ui`, `naming`,
`architecture`) never become user-visible titles. A card that looks tappable
is a `Button`. A readout does not use button chrome.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as the app's brand iconography — the app icon, the
  empty-state hero, or onboarding art. Those come from section 13. SF Symbols
  are the right choice for every functional control (add, filter, sort,
  close, share, delete) — leaving those as bare text instead of a symbol is
  also a defect.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.
- A `TabView` with exactly three tabs. That is the factory stamp — two or
  four-to-five destinations, or a different chrome. ReviewScreen keys are
  not tabs.


---

## 17. Tests

Add a unit test target `CordilleraTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. `Cordillera/ReviewLaunch.swift` (scaffold, keep it) parses `ProcessInfo.processInfo.arguments`.
   Read `ReviewLaunch.screen` once after onboarding:
   `-ReviewScreen today|log|goals` switches the running app's live navigation. Extra cover slugs open those screens.
   Cover that parser with a unit test. Do not host a `View` in the test.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Cordillera -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.
- [ ] Seeded home names the job and next tap; primary verb enabled.
- [ ] App reads `-ReviewScreen today|log|goals` after onboarding.

**Uniqueness**
- [ ] Architecture matches **Contour ADT fold (Packed | Active | Summited); the profile is a fold over Holds; Open writes a Traverse on a Hold and folds Packed to Active; Pin writes a TrigMark, advances profileX, and may write Benchmark at decile crossings; GapDay detection appends GapSegment without Pin; Bridge writes BridgeMark once per ISO week and closes oldest gap at double page cost; Recenter writes RecenterMark when gapCount exceeds three and unblocks Pin; Pin on Packed is refused; second Open while Active is refused; Summited when profileX reaches one; empty pack writes Bare** with no leakage across layers.
- [ ] UI approach matches **UIKit UIStackView layout · canvas-first**.
- [ ] Custom rendering, if any, is confined to one hero surface (section 7.5).
- [ ] Navigation matches **Cordillera-locked chrome (the elevation profile never leaves; Pack, Traverse and Summits arrive as sheets; ISBN scan and title search fuse on Pack)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **Palatino** and nothing else.
- [ ] Palette matches section 7.1 exactly.
- [ ] Home rhythm and motion match section 7.6. No second look.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Cordillera
xcodegen generate
xcodebuild build-for-testing -scheme Cordillera -destination 'generic/platform=iOS Simulator' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.cordillera.profile/DerivedData' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
xcodebuild -scheme Cordillera -destination 'generic/platform=iOS' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.cordillera.profile/DerivedData' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build
xcrun simctl list devices available
xcodebuild test-without-building -scheme Cordillera -destination 'platform=iOS Simulator,id=<UDID>' -jobs 4 -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.cordillera.profile/DerivedData'
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY, DEVELOPMENT_TEAM, SWIFT_TREAT_WARNINGS_AS_ERRORS or -derivedDataPath in project.yml — they are command-line only. CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
