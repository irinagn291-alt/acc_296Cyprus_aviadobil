@preconcurrency import AVFoundation
import UIKit

/// Pack sheet. Title search and ISBN capture share this screen, then a row opens a hold.
@MainActor
final class PackSheetController: UIViewController, UITextFieldDelegate {
    var onChange: (() -> Void)?
    private let store: ContourStore
    private let client: OpenLibraryClient
    private let titles: TitleSearch
    private let capture = ISBNCapture()
    private let keyboard = SurveyKeyboard()
    private let scroll = UIScrollView()
    private let stack = surveyStack(.vertical, spacing: SurveySpace.m)
    private let status = surveyLabel("Search a title or scan the barcode.", font: SurveyType.body(), color: SurveyColor.ink)
    private let query = UITextField()
    private let pages = UITextField()
    private let list = surveyStack(.vertical, spacing: SurveySpace.s)
    private let searchButton = SurveyButton(type: .custom)
    private let retryButton = SurveyButton(type: .custom)
    private let cameraSlot = surveyStack(.vertical, spacing: SurveySpace.s)
    private let previewHost = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private var requestingCamera = false
    private var flight = 0
    private var searchTask: Task<Void, Never>?
    private var resolveTask: Task<Void, Never>?
    private var isbnInFlight: String?

    init(store: ContourStore) {
        let client = OpenLibraryClient.live()
        self.store = store
        self.client = client
        self.titles = TitleSearch(client: client)
        super.init(nibName: nil, bundle: nil)
    }

    /// Interface Builder is unused. This path is a programmer error.
    required init?(coder: NSCoder) {
        fatalError("PackSheetController is built in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SurveyColor.background
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        keyboard.bind(scroll)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        scroll.addGestureRecognizer(tap)

        surveyField(query, label: "Title or ISBN")
        query.placeholder = "Title or ISBN"
        query.font = SurveyType.body()
        query.delegate = self
        query.returnKeyType = .search
        query.keyboardType = .default
        surveyField(pages, label: "Page count")
        pages.placeholder = "Pages"
        pages.keyboardType = .numberPad
        pages.font = SurveyType.numerals(SurveyType.body())
        pages.delegate = self

        searchButton.setTitle("Search", for: .normal)
        searchButton.accessibilityLabel = "Search titles"
        searchButton.addTarget(self, action: #selector(searchTitles), for: .touchUpInside)
        let manual = SurveyButton(type: .custom)
        manual.tone = .quiet
        manual.setTitle("Moor ISBN", for: .normal)
        manual.accessibilityLabel = "Moor the typed ISBN"
        manual.addTarget(self, action: #selector(moorTyped), for: .touchUpInside)
        retryButton.tone = .quiet
        retryButton.setTitle("Try again", for: .normal)
        retryButton.isHidden = true
        retryButton.addTarget(self, action: #selector(searchTitles), for: .touchUpInside)
        let close = SurveyButton(type: .custom)
        close.tone = .quiet
        close.setTitle("Close", for: .normal)
        close.setSymbol("xmark")
        close.accessibilityLabel = "Close pack"
        close.addTarget(self, action: #selector(closeSheet), for: .touchUpInside)

        previewHost.translatesAutoresizingMaskIntoConstraints = false
        previewHost.clipsToBounds = true
        previewHost.layer.cornerRadius = SurveyRadius.card
        capture.preview.videoGravity = .resizeAspectFill
        previewHost.contentView.layer.addSublayer(capture.preview)
        previewHost.heightAnchor.constraint(equalToConstant: SurveySpace.xl * 5).isActive = true
        refreshCameraNote()

        let title = surveyLabel("Pack", font: SurveyType.display(), color: SurveyColor.ink, kern: SurveyKern.display)
        title.numberOfLines = 1
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(status)
        stack.addArrangedSubview(previewHost)
        stack.addArrangedSubview(cameraSlot)
        stack.addArrangedSubview(query)
        stack.addArrangedSubview(pages)
        stack.addArrangedSubview(searchButton)
        stack.addArrangedSubview(manual)
        stack.addArrangedSubview(retryButton)
        stack.addArrangedSubview(list)
        stack.addArrangedSubview(close)
        scroll.addSubview(stack)
        view.addSubview(scroll)
        let guide = view.safeAreaLayoutGuide
        let frame = scroll.frameLayoutGuide
        let content = scroll.contentLayoutGuide
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: guide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: SurveySpace.m),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -SurveySpace.m),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: SurveySpace.m),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -SurveySpace.m),
            stack.widthAnchor.constraint(equalTo: frame.widthAnchor, constant: -SurveySpace.m * 2),
        ])
        capture.onCode = { [weak self] code in
            guard let self, self.isbnInFlight != code else { return }
            self.isbnInFlight = code
            self.query.text = code
            self.resolve(code)
        }
        Task { await showPacked() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        capture.preview.frame = previewHost.contentView.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshCameraNote()
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            capture.start()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        capture.stop()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField === query {
            searchTitles()
        }
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField === pages else { return true }
        if string.isEmpty { return true }
        return string.unicodeScalars.allSatisfy { CharacterSet.decimalDigits.contains($0) }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func cameraNote() -> UIView {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .authorized {
            return surveyLabel("The preview reads the barcode on the book.", font: SurveyType.caption(), color: SurveyColor.muted)
        }
        if status == .denied || status == .restricted {
            let column = surveyStack(.vertical, spacing: SurveySpace.s)
            column.addArrangedSubview(surveyLabel("The camera is off, so type the ISBN or search a title.", font: SurveyType.body(), color: SurveyColor.ink))
            let settings = SurveyButton(type: .custom)
            settings.tone = .quiet
            settings.setTitle("Open Settings", for: .normal)
            settings.setSymbol("gearshape")
            settings.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
            column.addArrangedSubview(settings)
            return column
        }
        let column = surveyStack(.vertical, spacing: SurveySpace.s)
        column.addArrangedSubview(surveyLabel("The next step starts the camera so a barcode can fill the ISBN.", font: SurveyType.body(), color: SurveyColor.ink))
        let next = SurveyButton(type: .custom)
        next.setTitle("Continue", for: .normal)
        next.addTarget(self, action: #selector(continueCamera), for: .touchUpInside)
        column.addArrangedSubview(next)
        #if targetEnvironment(simulator)
        let chips = surveyStack(.horizontal, spacing: SurveySpace.s)
        for sample in ["9780141185381", "9780140255089"] {
            let chip = SurveyButton(type: .custom)
            chip.tone = .quiet
            chip.shape = .chip
            chip.setTitle(sample, for: .normal)
            chip.accessibilityLabel = "Sample ISBN " + sample
            chip.addAction(UIAction { [weak self] _ in
                self?.query.text = sample
                self?.resolve(sample)
            }, for: .touchUpInside)
            chips.addArrangedSubview(chip)
        }
        column.addArrangedSubview(chips)
        #endif
        return column
    }

    private func refreshCameraNote() {
        cameraSlot.arrangedSubviews.forEach { $0.removeFromSuperview() }
        cameraSlot.addArrangedSubview(cameraNote())
    }

    @objc private func continueCamera() {
        guard !requestingCamera else { return }
        requestingCamera = true
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            Task { @MainActor in
                guard let self else { return }
                self.requestingCamera = false
                if granted {
                    self.capture.start()
                    self.status.text = "Point the preview at the barcode."
                } else {
                    self.capture.stop()
                    self.status.text = "The camera is off. Type the ISBN or search a title."
                }
                self.refreshCameraNote()
            }
        }
    }

    @objc private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    @objc private func searchTitles() {
        view.endEditing(true)
        let text = query.text ?? ""
        resolveTask?.cancel()
        searchTask?.cancel()
        let token = nextFlight()
        searchTask = Task { await runSearch(text, token: token) }
    }

    private func nextFlight() -> Int {
        flight += 1
        return flight
    }

    private func isCurrent(_ token: Int) -> Bool {
        token == flight && !Task.isCancelled
    }

    private func runSearch(_ text: String, token: Int) async {
        searchButton.isEnabled = false
        retryButton.isHidden = true
        let flash = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled, self.isCurrent(token) else { return }
            self.searchButton.setLoading(true)
        }
        defer {
            flash.cancel()
            if isCurrent(token) {
                searchButton.setLoading(false)
            }
        }
        do {
            let found = try await titles.replaceQuery(text)
            guard isCurrent(token) else { return }
            for record in found {
                await store.remember(record)
            }
            guard isCurrent(token) else { return }
            if found.isEmpty {
                status.text = "No match on the network. Holds already moored on this device are listed."
                retryButton.isHidden = false
                let local = await store.snapshot().localMoorings(matching: text)
                guard isCurrent(token) else { return }
                renderRecords(local, empty: "No holds match that search.")
            } else {
                status.text = "Moor a title with a page count, then open it."
                renderRecords(found, empty: "")
            }
        } catch is CancellationError {
            return
        } catch {
            guard isCurrent(token) else { return }
            retryButton.isHidden = false
            status.text = "No match on the network. Holds already moored on this device are listed."
            let local = await store.snapshot().localMoorings(matching: text)
            guard isCurrent(token) else { return }
            renderRecords(local, empty: "No holds match that search.")
        }
    }

    @objc private func moorTyped() {
        view.endEditing(true)
        resolve(query.text ?? "")
    }

    private func resolve(_ code: String) {
        searchTask?.cancel()
        resolveTask?.cancel()
        let token = nextFlight()
        resolveTask = Task { await resolveISBN(code, token: token) }
    }

    private func resolveISBN(_ code: String, token: Int) async {
        searchButton.isEnabled = false
        let flash = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled, self.isCurrent(token) else { return }
            self.searchButton.setLoading(true)
        }
        defer {
            flash.cancel()
            if isbnInFlight == code {
                isbnInFlight = nil
            }
            if isCurrent(token) {
                searchButton.setLoading(false)
            }
        }
        do {
            let record = try await store.resolveISBN(code, client: client)
            guard isCurrent(token) else { return }
            renderRecords([record], empty: "")
            if let count = record.pageCount {
                pages.text = SurveyCount.pages(count)
            }
            status.text = "Moor " + record.title + " with a page count, then open it."
            retryButton.isHidden = true
        } catch is CancellationError {
            return
        } catch {
            guard isCurrent(token) else { return }
            let local = await store.snapshot().localMoorings(matching: code)
            guard isCurrent(token) else { return }
            retryButton.isHidden = false
            if local.isEmpty {
                status.text = "That ISBN was not found. Type a title and a page count, then search again."
                renderRecords([], empty: "No holds match that search.")
            } else {
                renderRecords(local, empty: "")
                status.text = "The network missed. These holds are already on this device."
            }
        }
    }

    private func renderRecords(_ records: [MoorRecord], empty: String) {
        list.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if records.isEmpty {
            showEmpty(empty.isEmpty ? "No volume in the pack yet." : empty, line: "Search a title, then moor it.")
            return
        }
        let plate = SurveyPlate()
        for (index, record) in records.enumerated() {
            if index > 0 {
                plate.column.addArrangedSubview(surveyHairline())
            }
            let button = SurveyButton(type: .custom)
            button.tone = .quiet
            button.shape = .chip
            let count = record.pageCount.map { SurveyCount.pages($0) } ?? "unknown"
            button.setTitle(record.title + "  " + count, for: .normal)
            button.contentHorizontalAlignment = .leading
            button.addAction(UIAction { [weak self] _ in
                self?.moor(record)
            }, for: .touchUpInside)
            plate.column.addArrangedSubview(button)
        }
        list.addArrangedSubview(plate)
    }

    private func moor(_ record: MoorRecord) {
        let typed = Int(pages.text?.filter(\.isNumber) ?? "") ?? record.pageCount ?? 0
        guard typed > 0 else {
            status.text = "Enter the page count, then moor the hold."
            return
        }
        Task { await commitMoor(record, pages: typed) }
    }

    private func commitMoor(_ record: MoorRecord, pages typed: Int) async {
        searchButton.isEnabled = false
        defer { searchButton.setLoading(false) }
        do {
            let day = SurveyDay.stamp(Date())
            let hold = try await store.moor(
                title: record.title.isEmpty ? "Untitled" : record.title,
                isbn: record.isbn,
                totalPages: typed,
                on: day
            )
            do {
                _ = try await store.open(holdID: hold.id, on: day, plannedSummitDay: SurveyDay.adding(days: 14, to: day))
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                status.text = "The traverse is open. Pin today's pages on the profile."
                onChange?()
            } catch let refusal as ContourRefusal where refusal == .secondOpen {
                status.text = "A traverse is already active. Peel it or finish the summit before another open."
            }
            await showPacked()
        } catch {
            status.text = "The hold could not be moored. Check the page count and try again."
            retryButton.isHidden = false
        }
    }

    private func showPacked() async {
        list.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let chart = await store.snapshot()
        let packed = chart.holds.filter { $0.phase == .packed }
        if packed.isEmpty {
            showEmpty("No volume in the pack yet.", line: "Search a title, then moor it.")
            return
        }
        let plate = SurveyPlate()
        let heading = surveyLabel("Ready to open", font: SurveyType.headline(), color: SurveyColor.ink)
        plate.column.addArrangedSubview(heading)
        for hold in packed {
            let button = SurveyButton(type: .custom)
            button.tone = .quiet
            button.shape = .chip
            button.setTitle("Open " + hold.title, for: .normal)
            button.contentHorizontalAlignment = .leading
            button.addAction(UIAction { [weak self] _ in
                self?.openHold(hold.id)
            }, for: .touchUpInside)
            plate.column.addArrangedSubview(button)
        }
        list.addArrangedSubview(plate)
    }

    private func showEmpty(_ headline: String, line: String) {
        list.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let art = surveyArt("cdr_EmptyList")
        art.isHidden = art.image == nil
        art.heightAnchor.constraint(equalToConstant: SurveySpace.xl * 4).isActive = true
        list.addArrangedSubview(art)
        let title = surveyLabel(headline, font: SurveyType.headline(), color: SurveyColor.ink)
        title.numberOfLines = 2
        list.addArrangedSubview(title)
        list.addArrangedSubview(surveyLabel(line, font: SurveyType.body(), color: SurveyColor.muted))
    }

    private func openHold(_ id: UUID) {
        Task { await commitOpen(id) }
    }

    private func commitOpen(_ id: UUID) async {
        do {
            let day = SurveyDay.stamp(Date())
            _ = try await store.open(holdID: id, on: day, plannedSummitDay: SurveyDay.adding(days: 14, to: day))
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            status.text = "Traverse open. Return to the profile and pin."
            onChange?()
            await showPacked()
        } catch {
            status.text = "A traverse is already active. Peel it before you open another hold."
        }
    }

    @objc private func closeSheet() {
        dismiss(animated: SurveyMotion.duration > 0)
    }
}
