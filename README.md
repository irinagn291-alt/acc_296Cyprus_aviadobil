# Cordillera

Cordillera is a backpack reader for people who think in contour lines. You pin today's pages on the open traverse and the elevation profile climbs toward the volume's summit. It stays on this device. There is no account.

## Architecture

The profile is a contour fold over holds: Bare when the pack is empty, otherwise Packed, Active, or Summited. That suits a single live expedition better than a schedule of rows. Open writes a traverse on a packed hold and folds it to Active. A second open while one hold is active is refused. Pin writes a trig mark, advances profileX by pages divided by total pages, and writes a benchmark when a ten percent band is newly crossed. The hold is summited when profileX reaches one. Missed days append a gap segment and do not move the hiker. The derived drift angle stays off the canvas.

## Pin, then closure

Pin is the home verb. Each ten percent of the book leaves a benchmark. A calendar day without a pin leaves a dashed gap. Bridge may be used once each ISO week, spends twice the page count, and closes the oldest open gap, or writes a hollow mark when no gap is open. When more than three gaps are open, pin waits until Recenter pushes the planned summit day forward.

## Art

Low poly 3D render assembled as a collage. Faceted solid masses, hard planar faces, and overlapping cut planes like a survey model of a ridgeline. One lit object on an unlit field, quiet center, hairline depth, no text, no letters, no glyphs, no rounded icon mask.

- cdr_AppIcon: Low poly 3D collage emblem of a faceted ridgeline and a solid trig cairn, centred and filling the canvas edge to edge, no text, no alpha, no rounded mask.
- cdr_Splash: Vertical low poly 3D collage of a cordillera, one lit cairn, quiet uncluttered centre band for a wordmark, filling the canvas, no text, no letters.
- cdr_Onboarding1: Low poly 3D collage cutout of a solid closed pack beside a folded contour sheet, opaque subject centred, transparent corners, no text.
- cdr_Onboarding2: Low poly 3D collage cutout of a solid hand pressing a survey pin into a rising faceted ridge, opaque subject centred, transparent corners, no text.
- cdr_Onboarding3: Low poly 3D collage cutout of a solid summited cairn with small solid benchmark plaques along the ridge, opaque subject centred, transparent corners, no text.
- cdr_EmptyHome: Low poly 3D collage cutout of a solid closed pack in faceted canvas and wood, fully opaque subject, transparent corners, calm, no text.
- cdr_EmptyList: Low poly 3D collage cutout of a solid closed survey folio standing empty, opaque subject centred, transparent corners, no text.
- cdr_CardBackdrop: Abstract low poly collage of broad faceted planes, low contrast, filling the canvas so type can sit on it, no text, no object in the centre.
- cdr_ControlFace: Low poly 3D collage cutout of one solid survey bolt, the face of the pin control, opaque metal mass centred, transparent corners, no text.
- cdr_TwistHero: Low poly 3D collage cutout of a solid faceted span closing a break in a ridgeline, opaque subject centred, transparent corners, no text.
- cdr_SuccessMark: Low poly 3D collage cutout of a solid filled cairn, opaque mass in the centre, transparent corners, no outline, no hollow ring, no text.
- cdr_HeaderDecor: Low poly 3D collage cutout of a long solid faceted ridgeline ornament, opaque subject, transparent corners, no text.

## How this differs

Periplus curls a bearing when the schedule drifts. Marteloio spends runs to ink genre rhumbs. Cordillera pins pages on a summit profile, leaves gap segments on missed days, and closes one gap a week with a bridge.

## Build

```bash
cd apps/Cordillera
xcodegen generate
xcodebuild build-for-testing -scheme Cordillera -destination 'generic/platform=iOS Simulator' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
```
