import UIKit

/// Permanent elevation profile. Pack, Traverse, Summits, and Settings arrive as sheets.
@MainActor
final class ProfileViewController: UIViewController, UITextFieldDelegate {
    private let store: ContourStore
    private let keyboard = SurveyKeyboard()
    private var chart = ContourChart.bare
    private var recovery: String?
    private var didRouteReview = false
    private var didPaint = false
    private var shownDay = SurveyDay.stamp(Date())
    private var statusLine = "Pin today's pages on the open traverse."

    private let scroll = UIScrollView()
    private let root = surveyStack(.vertical, spacing: SurveySpace.m)
    private let mechanic = surveyStack(.vertical, spacing: SurveySpace.m)
    private let canvas = ProfileCanvas()
    private let wordmark = surveyLabel("Aviadobil", font: SurveyType.display(), color: SurveyColor.ink, kern: SurveyKern.display)
    private let job = surveyLabel("Pin today's pages on this book.", font: SurveyType.body(), color: SurveyColor.ink)
    private let figure = surveyLabel("", font: SurveyType.numerals(SurveyType.display()), color: SurveyColor.ink, kern: SurveyKern.display)
    private let volume = surveyLabel("", font: SurveyType.title(), color: SurveyColor.ink, kern: SurveyKern.title)
    private let caption = surveyLabel("", font: SurveyType.caption(), color: SurveyColor.muted)
    private let twistLine = surveyLabel(
        "A missed day leaves a dashed gap. Bridge closes the oldest one, once this week.",
        font: SurveyType.body(),
        color: SurveyColor.ink
    )
    private let pagesField = UITextField()
    private let pinButton = SurveyButton(type: .custom)
    private let bridgeButton = SurveyButton(type: .custom)
    private let status = surveyLabel("", font: SurveyType.caption(), color: SurveyColor.muted)
    private let successMark = surveyArt("cdr_SuccessMark")

    private let emptyArt = surveyArt("cdr_EmptyHome")
    private let emptyTitle = surveyLabel("No expedition yet", font: SurveyType.display(), color: SurveyColor.ink, kern: SurveyKern.display)
    private let emptyLine = surveyLabel("Open a volume.", font: SurveyType.body(), color: SurveyColor.muted)
    private let emptyOpen = SurveyButton(type: .custom)
    private let emptyStack = surveyStack(.vertical, spacing: SurveySpace.m)

    init(store: ContourStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    /// Interface Builder is unused. This path is a programmer error.
    required init?(coder: NSCoder) {
        fatalError("ProfileViewController is built in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SurveyColor.background
        buildChrome()
        NotificationCenter.default.addObserver(self, selector: #selector(dayMayHaveChanged), name: UIApplication.significantTimeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dayMayHaveChanged), name: UIApplication.didBecomeActiveNotification, object: nil)
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (controller: ProfileViewController, _: UITraitCollection) in
            controller.applyFonts()
        }
        Task { await boot() }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dayMayHaveChanged()
    }

    private func buildChrome() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.backgroundColor = .clear
        keyboard.bind(scroll)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        scroll.addGestureRecognizer(tap)

        wordmark.numberOfLines = 1
        job.numberOfLines = 2
        figure.setContentCompressionResistancePriority(.required, for: .horizontal)
        figure.setContentHuggingPriority(.required, for: .horizontal)
        volume.numberOfLines = 1
        volume.lineBreakMode = .byTruncatingTail
        volume.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        caption.numberOfLines = 2

        let settings = SurveyButton(type: .custom)
        settings.shape = .chip
        settings.tone = .quiet
        settings.setTitle("Settings", for: .normal)
        settings.accessibilityLabel = "Settings"
        settings.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        settings.setContentHuggingPriority(.required, for: .horizontal)

        let mast = surveyStack(.horizontal, spacing: SurveySpace.m)
        mast.alignment = .center
        mast.addArrangedSubview(wordmark)
        mast.addArrangedSubview(settings)

        let figureRow = surveyStack(.horizontal, spacing: SurveySpace.m)
        figureRow.alignment = .firstBaseline
        figureRow.addArrangedSubview(figure)
        figureRow.addArrangedSubview(volume)

        canvas.translatesAutoresizingMaskIntoConstraints = false
        canvas.isAccessibilityElement = true
        canvas.setContentHuggingPriority(.defaultLow, for: .vertical)
        canvas.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        let pagesCaption = surveyLabel("Pages read today", font: SurveyType.caption(), color: SurveyColor.muted)
        surveyField(pagesField, label: "Pages read today")
        pagesField.keyboardType = .numberPad
        pagesField.delegate = self
        pagesField.font = SurveyType.numerals(SurveyType.body())
        let stored = UserDefaults.standard.integer(forKey: "cdr.page.default")
        pagesField.text = SurveyCount.pages(stored > 0 ? stored : 12)
        pagesField.addTarget(self, action: #selector(pagesEdited), for: .editingChanged)

        pinButton.setTitle("Pin today's pages", for: .normal)
        pinButton.accessibilityLabel = "Pin today's pages"
        pinButton.addTarget(self, action: #selector(pinToday), for: .touchUpInside)

        bridgeButton.tone = .quiet
        bridgeButton.setTitle("Bridge this week", for: .normal)
        bridgeButton.accessibilityLabel = "Bridge the oldest gap"
        bridgeButton.addTarget(self, action: #selector(bridgeWeek), for: .touchUpInside)

        let bridgeCopy = surveyLabel("Once this week, at twice the page count.", font: SurveyType.body(), color: SurveyColor.ink)
        bridgeCopy.numberOfLines = 0
        let bridgePlate = SurveyPlate()
        bridgePlate.column.addArrangedSubview(bridgeCopy)
        bridgePlate.column.addArrangedSubview(bridgeButton)

        let routes = SurveyPlate()
        routes.column.spacing = 0
        routes.column.layoutMargins = UIEdgeInsets(top: SurveySpace.s, left: SurveySpace.s, bottom: SurveySpace.s, right: SurveySpace.s)
        let routeItems: [(String, Selector)] = [
            ("Pack", #selector(openPack)),
            ("Traverse", #selector(openTraverse)),
            ("Summits", #selector(openSummits)),
        ]
        for (index, item) in routeItems.enumerated() {
            if index > 0 {
                routes.column.addArrangedSubview(surveyHairline())
            }
            let row = SurveyButton(type: .custom)
            row.tone = .quiet
            row.shape = .chip
            row.setTitle(item.0, for: .normal)
            row.accessibilityLabel = item.0
            row.contentHorizontalAlignment = .fill
            row.addTarget(self, action: item.1, for: .touchUpInside)
            routes.column.addArrangedSubview(row)
        }

        mechanic.addArrangedSubview(mast)
        mechanic.addArrangedSubview(job)
        mechanic.addArrangedSubview(figureRow)
        mechanic.addArrangedSubview(caption)
        mechanic.addArrangedSubview(canvas)
        mechanic.addArrangedSubview(pagesCaption)
        mechanic.addArrangedSubview(pagesField)
        mechanic.addArrangedSubview(pinButton)
        mechanic.addArrangedSubview(bridgePlate)
        mechanic.addArrangedSubview(twistLine)
        mechanic.addArrangedSubview(status)
        mechanic.addArrangedSubview(routes)

        emptyArt.isHidden = emptyArt.image == nil
        emptyTitle.numberOfLines = 2
        emptyOpen.setTitle("Open", for: .normal)
        emptyOpen.accessibilityLabel = "Open a volume"
        emptyOpen.addTarget(self, action: #selector(openPack), for: .touchUpInside)
        emptyStack.addArrangedSubview(emptyArt)
        emptyStack.addArrangedSubview(emptyTitle)
        emptyStack.addArrangedSubview(emptyLine)
        emptyStack.addArrangedSubview(emptyOpen)
        emptyArt.setContentHuggingPriority(.defaultLow, for: .vertical)
        emptyStack.isHidden = true

        root.addArrangedSubview(mechanic)
        root.addArrangedSubview(emptyStack)
        scroll.addSubview(root)
        view.addSubview(scroll)

        successMark.isHidden = true
        successMark.isUserInteractionEnabled = false
        view.addSubview(successMark)

        let guide = view.safeAreaLayoutGuide
        let frame = scroll.frameLayoutGuide
        let content = scroll.contentLayoutGuide
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: guide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            root.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: SurveySpace.m),
            root.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -SurveySpace.m),
            root.topAnchor.constraint(equalTo: content.topAnchor, constant: SurveySpace.m),
            root.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -SurveySpace.m),
            root.widthAnchor.constraint(equalTo: frame.widthAnchor, constant: -SurveySpace.m * 2),
            {
                let fill = mechanic.heightAnchor.constraint(greaterThanOrEqualTo: frame.heightAnchor, constant: -SurveySpace.xl)
                fill.priority = .defaultHigh
                return fill
            }(),
            {
                let ridge = canvas.heightAnchor.constraint(greaterThanOrEqualTo: frame.heightAnchor, multiplier: 0.34)
                ridge.priority = .defaultHigh
                return ridge
            }(),
            {
                let fill = emptyStack.heightAnchor.constraint(greaterThanOrEqualTo: frame.heightAnchor, constant: -SurveySpace.xl)
                fill.priority = .defaultHigh
                return fill
            }(),
            successMark.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            successMark.centerYAnchor.constraint(equalTo: guide.centerYAnchor),
            successMark.widthAnchor.constraint(equalToConstant: SurveySpace.xl * 3),
            successMark.heightAnchor.constraint(equalToConstant: SurveySpace.xl * 3),
        ])
        status.numberOfLines = 0
        applyFonts()
    }

    private func applyFonts() {
        surveyWrite(wordmark, wordmark.text ?? "Aviadobil", font: SurveyType.display(), color: SurveyColor.ink, kern: SurveyKern.display)
        surveyWrite(job, job.text ?? "", font: SurveyType.body(), color: SurveyColor.ink)
        surveyWrite(figure, figure.text ?? "", font: SurveyType.numerals(SurveyType.display()), color: SurveyColor.ink, kern: SurveyKern.display)
        surveyWrite(volume, volume.text ?? "", font: SurveyType.title(), color: SurveyColor.ink, kern: SurveyKern.title)
        surveyWrite(caption, caption.text ?? "", font: SurveyType.caption(), color: SurveyColor.muted)
        surveyWrite(twistLine, twistLine.text ?? "", font: SurveyType.body(), color: SurveyColor.ink)
        surveyWrite(emptyTitle, "No expedition yet", font: SurveyType.display(), color: SurveyColor.ink, kern: SurveyKern.display)
        surveyWrite(emptyLine, "Open a volume.", font: SurveyType.body(), color: SurveyColor.muted)
        surveyWrite(status, status.text ?? "", font: SurveyType.caption(), color: SurveyColor.muted)
        pagesField.font = SurveyType.numerals(SurveyType.body())
    }

    private func boot() async {
        await DemoSeed.installIfNeeded(store: store)
        await reload()
        if UserDefaults.standard.bool(forKey: DemoSeed.onboardingKey) == false {
            let board = OnboardingController()
            board.modalPresentationStyle = .fullScreen
            board.onFinish = { [weak self] in
                self?.dismiss(animated: SurveyMotion.duration > 0) {
                    Task { await self?.reload() }
                }
            }
            present(board, animated: false)
            return
        }
        routeReviewIfNeeded()
    }

    private func reload() async {
        chart = await store.snapshot()
        recovery = await store.recoveryNote
        paint()
    }

    private func paint() {
        let bare = chart.fold == .bare
        mechanic.isHidden = bare
        emptyStack.isHidden = !bare
        let hold = chart.activeHold
        if let hold {
            let gaps = chart.gapSegments.filter { $0.holdID == hold.id && !$0.closed }
            let blocked = gaps.count > 3
            pinButton.isEnabled = !blocked && pagesValue() > 0
            let week = SurveyDay.isoWeek(for: Date())
            let used = chart.bridgeMarks.contains { $0.holdID == hold.id && $0.isoWeek == week }
                || chart.hollowMarks.contains { $0.holdID == hold.id && $0.isoWeek == week }
            bridgeButton.isEnabled = !used && pagesValue() > 0
            canvas.routeX = CGFloat(hold.profileX)
            canvas.title = hold.title
            let along = Int((hold.profileX * Double(hold.totalPages)).rounded())
            canvas.readout = SurveyCount.pages(along) + " of " + SurveyCount.pages(hold.totalPages) + " pages"
            let total = CGFloat(max(hold.totalPages, 1))
            canvas.trigs = chart.trigMarks.filter { $0.holdID == hold.id }.map {
                ProfileCanvas.Mark(fraction: CGFloat($0.endPage) / total)
            }
            let span = max(SurveyDay.span(from: hold.openedDay, to: hold.plannedSummitDay), 1)
            canvas.gaps = gaps.map { gap in
                let alongGap = CGFloat(SurveyDay.span(from: hold.openedDay, to: gap.day)) / CGFloat(span)
                return ProfileCanvas.Mark(fraction: min(1, max(0, alongGap)))
            }
            let nextFigure = SurveyCount.fraction(hold.profileX)
            if didPaint && figure.text != nextFigure {
                UIView.transition(with: figure, duration: SurveyMotion.duration, options: SurveyMotion.options) {
                    surveyWrite(self.figure, nextFigure, font: SurveyType.numerals(SurveyType.display()), color: SurveyColor.ink, kern: SurveyKern.display)
                }
            } else {
                surveyWrite(figure, nextFigure, font: SurveyType.numerals(SurveyType.display()), color: SurveyColor.ink, kern: SurveyKern.display)
            }
            surveyWrite(volume, hold.title, font: SurveyType.title(), color: SurveyColor.ink, kern: SurveyKern.title)
            let bridgeNote = used ? "Bridge is already used this week." : "Bridge is open this week."
            surveyWrite(
                caption,
                canvas.readout + ". " + SurveyCount.pages(gaps.count) + " open gaps. " + bridgeNote,
                font: SurveyType.caption(),
                color: SurveyColor.muted
            )
            canvas.accessibilityLabel = hold.title + ". " + canvas.readout + ". Elevation profile."
            if blocked {
                statusLine = "Open gaps block Pin. Recenter on the traverse."
            } else if let recovery {
                statusLine = recovery
            } else {
                statusLine = "Today's pages land on the traverse when you pin."
            }
        } else if bare {
            statusLine = "No expedition yet. Open a volume from Pack."
            bridgeButton.isEnabled = false
            pinButton.isEnabled = false
        } else {
            let waiting = chart.holds.filter { $0.phase == .packed }
            pinButton.isEnabled = false
            bridgeButton.isEnabled = false
            canvas.routeX = 0
            canvas.title = waiting.first?.title ?? "Packed"
            canvas.readout = SurveyCount.pages(waiting.count) + " volumes waiting"
            canvas.trigs = []
            canvas.gaps = []
            surveyWrite(figure, SurveyCount.pages(waiting.count), font: SurveyType.numerals(SurveyType.display()), color: SurveyColor.ink, kern: SurveyKern.display)
            surveyWrite(volume, "volumes waiting", font: SurveyType.title(), color: SurveyColor.ink, kern: SurveyKern.title)
            surveyWrite(caption, "Open one volume, then pin today's pages.", font: SurveyType.caption(), color: SurveyColor.muted)
            canvas.accessibilityLabel = "Packed volumes waiting. Open one to start the traverse."
            statusLine = "Open a packed volume to start the traverse."
        }
        surveyWrite(status, statusLine, font: SurveyType.caption(), color: SurveyColor.muted)
        let fade = didPaint ? SurveyMotion.duration : 0
        didPaint = true
        UIView.transition(with: canvas, duration: fade, options: SurveyMotion.options) {
            self.canvas.setNeedsDisplay()
        }
    }

    private func routeReviewIfNeeded() {
        guard !didRouteReview else { return }
        didRouteReview = true
        switch ReviewLaunch.screen {
        case "log":
            openTraverse()
        case "goals":
            openSummits()
        case "pack":
            openPack()
        case "settings":
            openSettings()
        default:
            break
        }
    }

    @objc private func dayMayHaveChanged() {
        let day = SurveyDay.stamp(Date())
        guard day != shownDay else { return }
        shownDay = day
        Task { await reload() }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func pagesEdited() {
        let digits = pagesField.text?.filter(\.isNumber) ?? ""
        if digits != pagesField.text {
            pagesField.text = digits
        }
        if chart.activeHold != nil {
            let blocked = chart.openGapCount(holdID: chart.activeHold?.id ?? UUID()) > 3
            pinButton.isEnabled = !blocked && pagesValue() > 0
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty { return true }
        return string.unicodeScalars.allSatisfy { CharacterSet.decimalDigits.contains($0) }
    }

    private func pagesValue() -> Int {
        Int(pagesField.text?.filter(\.isNumber) ?? "") ?? 0
    }

    @objc private func pinToday() {
        view.endEditing(true)
        let pages = pagesValue()
        Task { await commitPin(pages) }
    }

    private func commitPin(_ pages: Int) async {
        guard pages > 0 else {
            statusLine = "Enter a page count above zero."
            surveyWrite(status, statusLine, font: SurveyType.caption(), color: SurveyColor.muted)
            return
        }
        pinButton.isEnabled = false
        let flash = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            self.pinButton.setLoading(true)
        }
        defer { flash.cancel() }
        do {
            _ = try await store.pin(pages: pages, on: SurveyDay.stamp(Date()))
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            statusLine = "Pinned " + SurveyCount.pages(pages) + " pages on the traverse."
            pinButton.setLoading(false)
            showSuccess()
            await reload()
        } catch let refusal as ContourRefusal {
            pinButton.setLoading(false)
            statusLine = message(for: refusal)
            surveyWrite(status, statusLine, font: SurveyType.caption(), color: SurveyColor.muted)
            await reload()
        } catch {
            pinButton.setLoading(false)
            statusLine = "The pin did not save. Pin the same page count again."
            surveyWrite(status, statusLine, font: SurveyType.caption(), color: SurveyColor.muted)
            pinButton.isEnabled = true
        }
    }

    @objc private func bridgeWeek() {
        view.endEditing(true)
        let pages = pagesValue()
        Task { await commitBridge(pages) }
    }

    private func commitBridge(_ pages: Int) async {
        guard pages > 0 else {
            statusLine = "Enter a page count above zero."
            surveyWrite(status, statusLine, font: SurveyType.caption(), color: SurveyColor.muted)
            return
        }
        bridgeButton.isEnabled = false
        let flash = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            self.bridgeButton.setLoading(true)
        }
        defer { flash.cancel() }
        do {
            let outcome = try await store.bridge(pages: pages, on: SurveyDay.stamp(Date()))
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            switch outcome {
            case .closed:
                statusLine = "Bridge closed the oldest gap at double the page count."
            case .hollow:
                statusLine = "No open gap. The bridge spent double the pages as a hollow mark."
            }
            bridgeButton.setLoading(false)
            await reload()
        } catch let refusal as ContourRefusal {
            bridgeButton.setLoading(false)
            statusLine = message(for: refusal)
            surveyWrite(status, statusLine, font: SurveyType.caption(), color: SurveyColor.muted)
            await reload()
        } catch {
            bridgeButton.setLoading(false)
            statusLine = "The bridge did not save. Try again with a page count."
            surveyWrite(status, statusLine, font: SurveyType.caption(), color: SurveyColor.muted)
            bridgeButton.isEnabled = true
        }
    }

    private func showSuccess() {
        guard successMark.image != nil else { return }
        successMark.alpha = 0
        successMark.isHidden = false
        UIView.animate(withDuration: SurveyMotion.duration, delay: 0, options: [.curveEaseOut]) {
            self.successMark.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: SurveyMotion.duration, delay: 0.45, options: [.curveEaseOut]) {
                self.successMark.alpha = 0
            } completion: { _ in
                self.successMark.isHidden = true
            }
        }
    }

    private func message(for refusal: ContourRefusal) -> String {
        switch refusal {
        case .invalidPages:
            return "Enter a page count above zero."
        case .pinOnPacked:
            return "Open a hold before you pin."
        case .gapsBlockPin:
            return "Open gaps block Pin. Recenter on the traverse."
        case .bridgeAlreadyUsed:
            return "Bridge is already used this week."
        case .noActiveHold:
            return "Open a hold from Pack before this mark."
        case .secondOpen:
            return "Finish or peel the active traverse before another open."
        case .nothingToPeel:
            return "There is no pin to peel."
        case .recenterNotNeeded:
            return "Recenter waits until more than three gaps are open."
        case .missingHold:
            return "That hold is no longer in the pack."
        }
    }

    @objc private func openPack() {
        let sheet = PackSheetController(store: store)
        sheet.onChange = { [weak self] in Task { await self?.reload() } }
        presentSheet(sheet)
    }

    @objc private func openTraverse() {
        let sheet = TraverseSheetController(store: store)
        sheet.onChange = { [weak self] in Task { await self?.reload() } }
        sheet.onOpenPack = { [weak self] in self?.openPack() }
        presentSheet(sheet)
    }

    @objc private func openSummits() {
        presentSheet(SummitsSheetController(store: store))
    }

    @objc private func openSettings() {
        let sheet = SettingsSheetController(store: store)
        sheet.onChange = { [weak self] in Task { await self?.reload() } }
        sheet.onReplay = { [weak self] in
            self?.dismiss(animated: false) {
                let board = OnboardingController()
                board.modalPresentationStyle = .fullScreen
                board.onFinish = { [weak self] in
                    self?.dismiss(animated: SurveyMotion.duration > 0)
                }
                self?.present(board, animated: false)
            }
        }
        presentSheet(sheet)
    }

    private func presentSheet(_ controller: UIViewController) {
        controller.modalPresentationStyle = .pageSheet
        if let sheet = controller.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = SurveyRadius.card
        }
        if let presented = presentedViewController {
            presented.dismiss(animated: false) { [weak self] in
                self?.present(controller, animated: SurveyMotion.duration > 0)
            }
        } else {
            present(controller, animated: SurveyMotion.duration > 0)
        }
    }
}
