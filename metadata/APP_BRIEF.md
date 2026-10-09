<!-- gf-brief source=7d50e89be207da7b84f2f710eb68e27bd192567e06f8ed87c38553156b39ac23 written=2026-10-09T12:35:48+03:00 -->
# Cordillera

## What it is

Cordillera is a private reading tracker. The book you are on is drawn as a ridge; you pin the pages you read today and the profile climbs toward the last page, which the app calls the summit. It is for one reader who wants an on-device expedition through a volume, not a social shelf or a storefront. The Home Screen name is Cordillera. The wordmark on today's profile reads Aviadobil.

## Launch and onboarding

A cold launch shows the system launch screen (no titles or buttons), then either the introduction or today's profile.

The introduction is three full-screen pages. Each page has a page index, a headline, a body line, **Skip**, and **Continue**. **Skip** on any page ends the introduction and opens today's profile. **Continue** on page 1 or 2 goes to the next page. **Continue** on page 3 ends the introduction the same way.

1. Index **1 of 3**. Headline: **The book becomes a ridge.** Body: **Cordillera draws the volume you are reading as an elevation profile.**
2. Index **2 of 3**. Headline: **Pin the pages you read.** Body: **Each pin moves you along the ridge toward the summit of the book.**
3. Index **3 of 3**. Headline: **Close one gap this week.** Body: **A day without a pin leaves a dashed gap. Bridge closes the oldest one.**

After **Skip** or the last **Continue**, the **Pages read today** field is filled with **12**. That field is visible only after a volume is in the pack.

The introduction can be shown again from Settings via **Show introduction**. That replay does not clear the pack. Finishing it again writes **12** as the default page count.

## Screens

There is no tab bar. Today's profile is the home screen. **Pack**, **Traverse**, **Summits**, and **Settings** open as sheets over it and return here.

### Today's profile

Wordmark: **Aviadobil**. Line under it: **Pin today's pages on this book.**

This chrome is shown only when at least one volume is in the pack (open, waiting, or already a summit). When the pack is empty, a different empty state replaces it.

With an open traverse:

- A large percent of the way along the book (device number format, no decimal places).
- The volume's title beside that figure.
- Caption: **\<pages along\> of \<total pages\> pages. \<n\> open gaps.** then either **Bridge is open this week.** or **Bridge is already used this week.** Pages and counts use the device's grouping (for example **12 of 320 pages. 0 open gaps.**). Pages along include pages spent by **Bridge this week**.
- An elevation profile: a ridgeline, a marker for where you stand, solid cairns for pins, and dashed vertical strokes for open gaps. VoiceOver on the drawing is **\<title\>. \<pages along\> of \<total pages\> pages. Elevation profile.**
- Label **Pages read today** and a number field (digits only). It opens with **12** after the introduction.
- **Pin today's pages** — records that page count on today's traverse. A cairn graphic flashes briefly on success. Status becomes **Pinned \<n\> pages on the traverse.**
- Plate copy: **Once this week, at twice the page count.**
- **Bridge this week** (VoiceOver: **Bridge the oldest gap**) — spends twice the number in **Pages read today**. If a gap is open: **Bridge closed the oldest gap at double the page count.** If no gap is open: **No open gap. The bridge spent double the pages as a hollow mark.** Those spent pages also move the profile toward the summit.
- Twist line: **A missed day leaves a dashed gap. Bridge closes the oldest one, once this week.**
- Status under that (when nothing else is blocking): **Today's pages land on the traverse when you pin.**
- **Settings** — opens Settings.
- **Pack** — opens Pack.
- **Traverse** — opens Traverse.
- **Summits** — opens Summits.

When volumes are in the pack but none is open (including after the only open book has reached its last page):

- Large figure: how many volumes are waiting, or **0**.
- Title line: **volumes waiting**.
- Caption: **Open one volume, then pin today's pages.**
- Status: **Open a packed volume to start the traverse.**
- VoiceOver on the drawing: **Packed volumes waiting. Open one to start the traverse.**
- **Pin today's pages** and **Bridge this week** are disabled.
- **Settings**, **Pack**, **Traverse**, and **Summits** still work.

When the pack has never had a volume, or after **Reset**:

- Headline: **No expedition yet**
- Line: **Open a volume.**
- **Open** (VoiceOver: **Open a volume**) — opens Pack.
- **Settings**, **Pin today's pages**, **Bridge this week**, **Pack**, **Traverse**, and **Summits** are not on this screen.

Other status lines that can replace the usual one are listed under Behaviours.

### Pack

Title: **Pack**. Opening line: **Search a title or scan the barcode.**

- A live camera preview.
- If the camera has not been decided yet: **The next step starts the camera so a barcode can fill the ISBN.** and **Continue**. **Continue** shows the system camera alert. After allow: **Point the preview at the barcode.** and **The preview reads the barcode on the book.** After deny: **The camera is off. Type the ISBN or search a title.**
- If the camera was denied or is restricted: **The camera is off, so type the ISBN or search a title.** and **Open Settings** (the device Settings page for this app).
- If the camera is already allowed: **The preview reads the barcode on the book.** Pointing the preview at a book barcode (or a QR code that holds an ISBN) fills **Title or ISBN** and looks the volume up.
- Field placeholder **Title or ISBN**.
- Field placeholder **Pages** (digits only; VoiceOver **Page count**).
- **Search** (VoiceOver: **Search titles**) — looks up the typed title or ISBN. The keyboard Search key on **Title or ISBN** does the same. A match list appears; status: **Moor a title with a page count, then open it.** Each row is **\<title\>  \<page count\>** or **\<title\>  unknown**. Tapping a row moors that title (using **Pages** if you typed a count, otherwise the listed count) and tries to open a traverse.
- **Moor ISBN** (VoiceOver: **Moor the typed ISBN**) — looks up whatever is in **Title or ISBN** as an ISBN. On a hit: **Moor \<title\> with a page count, then open it.** and **Pages** fills when a count is known. Then tap the result row to moor and open.
- **Try again** — shown after a failed or empty network lookup; runs **Search** again.
- **Close** (VoiceOver: **Close pack**) — dismisses Pack. It does not remove volumes.

A successful moor that can open: **The traverse is open. Pin today's pages on the profile.**

Opening a volume that is already waiting: **Open \<title\>** under **Ready to open**. Success: **Traverse open. Return to the profile and pin.**

If the pack has nothing waiting and you have not just searched: **No volume in the pack yet.** and **Search a title, then moor it.**

A title that comes back blank is moored as **Untitled**.

### Traverse

Title: **Traverse**.

When no traverse is open:

- Large figure **0**.
- Status: **No traverse is open.** (or a recovery line from Data and support).
- **Open a volume.**
- **Open Pack** (VoiceOver: **Open a volume from Pack**) — opens Pack.
- **Close traverse** — dismisses this sheet only. It does not end an expedition.

When a traverse is open:

- Large figure: total pages pinned so far (pins only; Bridge pages are not in this figure).
- Status: **\<title\>. \<n\> open gaps.**
- Plate with the title, then **\<pinned\> pages pinned of \<total\>.**
- If there are no pins yet: **No pin on this traverse yet.**
- Otherwise one line per pin: **Pinned \<n\> pages, ending at page \<end\>.**
- Heading **Open gaps**. If none: **No open gap on \<title\>. A missed day draws a dashed gap here.** If some: **Gap on day \<number\> is still open.** for each. The number is that calendar day written as one figure (year, month, and day run together, with the device's grouping), for example **Gap on day 20,261,008 is still open.** for 8 October 2026 in a grouping locale.
- **Peel the last pin** — asks **Peel the last pin?** / **The latest page count comes off this traverse.** Buttons: **Cancel**, **Peel**. After **Peel**: **The last pin is off the traverse.** Disabled when there is no pin.
- **Recenter waits for four gaps** when three or fewer gaps are open (disabled), with **Recenter stays quiet until more than three gaps are open.**
- **Recenter the summit day** when more than three gaps are open (VoiceOver: **Recenter the planned summit**), with **Recenter pushes the planned summit day forward and clears the block on Pin.** Success: **The planned summit day moved forward. Pin is open again.** Recenter leaves three gaps open; it does not clear every dashed stroke.
- **Close traverse** — dismisses this sheet. The expedition stays open.

### Summits

Title: **Summits**.

Empty: **No summit yet.** / **Pin until the profile reaches the last page.** / **Back to the profile** (dismisses).

With finished volumes, each plate shows the title, **\<total\> pages. The profile is complete.**, then either **No benchmark yet.** or **Benchmarks crossed on the way up.** and one line per tenth of the book: **10% of the book.** through **90% of the book.**, and **100% is the summit.** Percents follow the device locale.

**Back to today's pin** dismisses when at least one summit is listed.

### Settings

Title: **Settings**. Line: **Replay the introduction, write to Cordillera, or clear the pack.**

This sheet is only reachable from today's profile after at least one volume exists. A brand-new empty pack has no **Settings** control.

- Status: **The contour stays on this device.** unless a recovery line is showing.
- **Show introduction** — closes Settings and replays the three introduction pages.
- **Reset** (VoiceOver: **Reset all data**) — alert **Reset the contour?** / **Every hold, pin, and summit on this device is removed.** Buttons: **Cancel**, **Reset**. After **Reset**: **The pack is bare.** Today's profile becomes **No expedition yet**.
- **Contact** (VoiceOver: **Contact Cordillera**) — opens the support page. The address is shown on this screen: **https://cordillera-profile.pro/contact-us**. If it does not open: **The contact page did not open. Try again.**
- **Try again** — reloads the status line.
- **Close** (VoiceOver: **Close settings**) — dismisses Settings.

## Features

- Treat the current volume as a ridge and show an elevation profile toward the summit.
- **Pack**: search a title, type an ISBN, or scan the barcode on a book, then **moor** a hold with a page count.
- **Open** a packed volume to start a **traverse** (only one traverse at a time).
- **Pin today's pages** on the open traverse; the list of pins grows.
- Missed days leave a dashed **gap**.
- **Bridge this week**: once this week, at twice the page count, close the oldest gap, or spend those pages with no gap to close. Those pages count toward the summit.
- **Recenter the summit day** after more than three gaps, so **Pin** works again.
- **Peel the last pin** (with confirmation) to take the latest page count off the traverse.
- **Summits** and **benchmarks** at each tenth of the book, including **100% is the summit.**
- **Settings**: replay the introduction, **Contact**, or **Reset** the contour.
- Everything in the pack stays on this device.

## Behaviours that can look like bugs

- First launch (and after **Reset**) shows **No expedition yet** / **Open a volume.** There is no **Settings** and no profile until you **Open** a volume from Pack, moor it, and open a traverse.
- **Pin today's pages** stays disabled until an expedition is open and **Pages read today** is above zero. Tapping while the field is empty or **0** sets status to **Enter a page count above zero.**
- **Bridge this week** stays disabled with no open expedition, a page count of zero, or after it has already been used this week. Status if you still try: **Bridge is already used this week.** or **Enter a page count above zero.**
- A calendar day with no pin does not become a gap until you tap **Pin today's pages**. After several missed days the home caption may still say **0 open gaps** and Pin may still be enabled. The first tap then writes the missed days as gaps. If more than three are open, Pin is refused and status is **Open gaps block Pin. Recenter on the traverse.**
- After more than three open gaps, **Pin today's pages** is disabled. Open **Traverse** and tap **Recenter the summit day**. Until then the Recenter control reads **Recenter waits for four gaps** and, if tapped too early: **Recenter waits until more than three gaps are open.** Recenter leaves three gaps; dashed strokes remain. Pin works again.
- With exactly four open gaps, **Bridge this week** can close the oldest one and unblock Pin without Recenter. With five or more, one Bridge is not enough; Recenter is still required.
- **Bridge this week** can be used when there is no gap. That is intended: **No open gap. The bridge spent double the pages as a hollow mark.** The weekly Bridge is then used. Home progress moves; Traverse does not gain a new **Pinned … pages** row.
- You can pin more than once on the same day. Traverse grows another **Pinned … pages, ending at page ….** row each time.
- Pinning more pages than remain still works. The profile stops at **100%** and the volume becomes a summit.
- Only one traverse can be open. A second open shows **A traverse is already active. Peel it or finish the summit before another open.** or **A traverse is already active. Peel it before you open another hold.** Finish by pinning until the last page, or peel pins until the volume returns to the pack.
- **Peel the last pin** removes only the latest pin, not a Bridge. If Bridge (or a no-gap Bridge) has already been used on this expedition and every pin is peeled, the traverse can stay open with **Peel the last pin** disabled. Keep pinning this volume, or pin until the last page.
- If every pin is peeled and Bridge was never used on that expedition, the volume returns to the pack. Traverse then shows **No traverse is open.** Home shows **volumes waiting**.
- When the only book has reached the last page and nothing is waiting, home shows **0**, **volumes waiting**, and **Open a packed volume to start the traverse.** Open **Pack**, search, and moor another volume.
- **Close traverse** only dismisses the Traverse sheet. The expedition stays open.
- **Search** or **Moor ISBN** with no network hit: **No match on the network. Holds already moored on this device are listed.** or **That ISBN was not found. Type a title and a page count, then search again.** or **The network missed. These holds are already on this device.** Empty list: **No holds match that search.** / **Search a title, then moor it.** Use **Try again**, or type a title and a page count.
- **Moor ISBN** treats the field as an ISBN. A typed book title with no digits yields **That ISBN was not found. Type a title and a page count, then search again.** Use **Search** for a title.
- Tapping a result with no page count (listed as **unknown**) and an empty **Pages** field: **Enter the page count, then moor the hold.** Type a count, then tap the row again.
- A failed moor: **The hold could not be moored. Check the page count and try again.**
- A failed pin or Bridge save: **The pin did not save. Pin the same page count again.** or **The bridge did not save. Try again with a page count.**
- Other refusals: **Open a hold before you pin.** / **Open a hold from Pack before this mark.** / **Finish or peel the active traverse before another open.** / **There is no pin to peel.** / **That hold is no longer in the pack.**
- Camera **Continue** does nothing further until the system alert is answered. After deny, type the ISBN or search; do not look for another Allow button. Use **Open Settings** if the camera is off.
- **Search** and **Moor ISBN** show a spinner and ignore taps while a lookup is in flight.
- Gap lines use a large day number, not a written calendar date. That is how missed days are labelled, not a page count.
- Home progress can be ahead of Traverse's **pages pinned** after a Bridge. Both are intended.

## Starter content and resume

None. A first launch on a device starts with an empty pack.

Unfinished work resumes. The pack, the open traverse, pins, gaps, Bridge use for the week, and summits stay on this device after you quit. The introduction does not play again unless you choose **Show introduction**.

## Permissions

Camera, only from Pack, and only after **Continue** (or automatically if it was already allowed). Usage string: **Cordillera reads the barcode on a book so Pack can moor that volume on this device.**

The system alert is the only place that says Allow. If access is off: **The camera is off, so type the ISBN or search a title.** and **Open Settings**.

## Absent

Genuinely absent: login or accounts, in-app purchase, ads, analytics, user-generated content for other people, an account deletion flow, and an App Tracking Transparency prompt.

## Data and support

The pack, pins, gaps, and summits stay on this device. Settings says **The contour stays on this device.** Title search and ISBN lookup need a network match; they do not create an account. **Contact** (and the address **https://cordillera-profile.pro/contact-us**) is the support control. It is on Settings, which appears only after at least one volume exists.

If a saved contour cannot be read or written, these lines can appear (with **Try again** on Settings, Traverse, or Summits): **The latest contour was unreadable. The previous contour is restored.** / **The saved contour was restored from the file copy.** / **The contour file was unreadable. The previous file is restored.** / **The saved contour could not be read. A bare pack is ready.** / **The contour could not be encoded. The screen still shows the open pack.** / **The contour file could not be saved. The screen still shows the open pack.** / **The contour file could not be removed. The in-memory pack is bare.**

## Scanning and health

The Pack preview reads the barcode on a book so an ISBN can fill **Title or ISBN**. It also accepts a QR code that contains an ISBN (a run of 8 to 14 digits). It does not scan groceries or tickets.

None for health, medical, or product-health information. There are no citations.

## Platform

The interface is English only. There is no region lock. Counts and percents follow the device locale. Appearance is dark. Portrait only, on iPhone and iPad, full screen. Minimum iOS 17.0.

## Category

Books
