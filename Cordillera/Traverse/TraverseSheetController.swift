import UIKit

/// The active hold: pages pinned, peel of the last trig, and recenter when gaps block pin.
@MainActor
final class TraverseSheetController: UIViewController {
    var onChange: (() -> Void)?
    var onOpenPack: (() -> Void)?
    private let store: ContourStore
    private let scroll = UIScrollView()
    private let stack = surveyStack(.vertical, spacing: SurveySpace.m)
    private let status = surveyLabel("", font: SurveyType.body(), color: SurveyColor.ink)
    private let figure = surveyLabel("", font: SurveyType.numerals(SurveyType.display()), color: SurveyColor.ink, kern: SurveyKern.display)

    init(store: ContourStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    /// Interface Builder is unused. This path is a programmer error.
    required init?(coder: NSCoder) {
        fatalError("TraverseSheetController is built in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SurveyColor.background
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        let title = surveyLabel("Traverse", font: SurveyType.display(), color: SurveyColor.ink, kern: SurveyKern.display)
        title.numberOfLines = 1
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(figure)
        stack.addArrangedSubview(status)
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
        Task { await paint() }
    }

    private func paint() async {
        stack.arrangedSubviews.dropFirst(3).forEach { $0.removeFromSuperview() }
        let chart = await store.snapshot()
        let note = await store.recoveryNote
        guard let hold = chart.activeHold else {
            surveyWrite(figure, SurveyCount.pages(0), font: SurveyType.numerals(SurveyType.display()), color: SurveyColor.ink, kern: SurveyKern.display)
            status.text = note ?? "No traverse is open."
            let art = surveyArt("cdr_EmptyList")
            art.isHidden = art.image == nil
            art.heightAnchor.constraint(equalToConstant: SurveySpace.xl * 5).isActive = true
            stack.addArrangedSubview(art)
            stack.addArrangedSubview(surveyLabel("Open a volume.", font: SurveyType.body(), color: SurveyColor.muted))
            let open = SurveyButton(type: .custom)
            open.setTitle("Open Pack", for: .normal)
            open.accessibilityLabel = "Open a volume from Pack"
            open.addTarget(self, action: #selector(openPack), for: .touchUpInside)
            stack.addArrangedSubview(open)
            if note != nil {
                addRetry()
            }
            addClose()
            return
        }
        let marks = chart.trigMarks.filter { $0.holdID == hold.id }.sorted { $0.endPage < $1.endPage }
        let pinned = marks.reduce(0) { $0 + $1.pages }
        let openGaps = chart.gapSegments.filter { $0.holdID == hold.id && !$0.closed }
        let gaps = openGaps.count
        surveyWrite(figure, SurveyCount.pages(pinned), font: SurveyType.numerals(SurveyType.display()), color: SurveyColor.ink, kern: SurveyKern.display)
        status.text = note ?? (hold.title + ". " + SurveyCount.pages(gaps) + " open gaps.")

        let chain = SurveyPlate()
        let name = surveyLabel(hold.title, font: SurveyType.headline(), color: SurveyColor.ink)
        name.numberOfLines = 2
        chain.column.addArrangedSubview(name)
        chain.column.addArrangedSubview(surveyLabel(
            SurveyCount.pages(pinned) + " pages pinned of " + SurveyCount.pages(hold.totalPages) + ".",
            font: SurveyType.body(),
            color: SurveyColor.ink
        ))
        if marks.isEmpty {
            chain.column.addArrangedSubview(surveyLabel("No pin on this traverse yet.", font: SurveyType.body(), color: SurveyColor.ink))
        } else {
            for mark in marks {
                chain.column.addArrangedSubview(surveyHairline())
                let row = surveyLabel(
                    "Pinned " + SurveyCount.pages(mark.pages) + " pages, ending at page " + SurveyCount.pages(mark.endPage) + ".",
                    font: SurveyType.body(),
                    color: SurveyColor.ink
                )
                chain.column.addArrangedSubview(row)
            }
        }
        stack.addArrangedSubview(chain)

        let gapPlate = SurveyPlate()
        gapPlate.column.addArrangedSubview(surveyLabel("Open gaps", font: SurveyType.headline(), color: SurveyColor.ink))
        if openGaps.isEmpty {
            gapPlate.column.addArrangedSubview(surveyLabel(
                "No open gap on " + hold.title + ". A missed day draws a dashed gap here.",
                font: SurveyType.body(),
                color: SurveyColor.ink
            ))
        } else {
            for gap in openGaps {
                gapPlate.column.addArrangedSubview(surveyHairline())
                gapPlate.column.addArrangedSubview(surveyLabel(
                    "Gap on day " + SurveyCount.pages(gap.day) + " is still open.",
                    font: SurveyType.body(),
                    color: SurveyColor.ink
                ))
            }
        }
        stack.addArrangedSubview(gapPlate)

        let peelButton = SurveyButton(type: .custom)
        peelButton.tone = marks.isEmpty ? .quiet : .destructive
        peelButton.setTitle("Peel the last pin", for: .normal)
        peelButton.accessibilityLabel = "Peel the last pin"
        peelButton.addTarget(self, action: #selector(confirmPeel), for: .touchUpInside)
        peelButton.isEnabled = !marks.isEmpty
        stack.addArrangedSubview(peelButton)

        let recenterButton = SurveyButton(type: .custom)
        recenterButton.setTitle(gaps > 3 ? "Recenter the summit day" : "Recenter waits for four gaps", for: .normal)
        recenterButton.accessibilityLabel = "Recenter the planned summit"
        recenterButton.addTarget(self, action: #selector(recenter), for: .touchUpInside)
        recenterButton.isEnabled = gaps > 3
        stack.addArrangedSubview(recenterButton)
        if gaps <= 3 {
            stack.addArrangedSubview(surveyLabel("Recenter stays quiet until more than three gaps are open.", font: SurveyType.body(), color: SurveyColor.ink))
        } else {
            stack.addArrangedSubview(surveyLabel("Recenter pushes the planned summit day forward and clears the block on Pin.", font: SurveyType.body(), color: SurveyColor.ink))
        }
        if note != nil {
            addRetry()
        }
        addClose()
    }

    private func addRetry() {
        let retry = SurveyButton(type: .custom)
        retry.tone = .quiet
        retry.setTitle("Try again", for: .normal)
        retry.addTarget(self, action: #selector(reloadSheet), for: .touchUpInside)
        stack.addArrangedSubview(retry)
    }

    private func addClose() {
        let close = SurveyButton(type: .custom)
        close.tone = .quiet
        close.setTitle("Close traverse", for: .normal)
        close.accessibilityLabel = "Close traverse"
        close.addTarget(self, action: #selector(closeSheet), for: .touchUpInside)
        stack.addArrangedSubview(close)
    }

    @objc private func reloadSheet() {
        Task { await paint() }
    }

    @objc private func openPack() {
        onOpenPack?()
    }

    @objc private func confirmPeel() {
        let alert = UIAlertController(
            title: "Peel the last pin?",
            message: "The latest page count comes off this traverse.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Peel", style: .destructive) { [weak self] _ in
            Task { await self?.peel() }
        })
        present(alert, animated: SurveyMotion.duration > 0)
    }

    private func peel() async {
        do {
            _ = try await store.peel()
            status.text = "The last pin is off the traverse."
            onChange?()
            await paint()
        } catch {
            status.text = "There is no pin to peel."
        }
    }

    @objc private func recenter() {
        Task { await commitRecenter() }
    }

    private func commitRecenter() async {
        do {
            _ = try await store.recenter(on: SurveyDay.stamp(Date()))
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            status.text = "The planned summit day moved forward. Pin is open again."
            onChange?()
            await paint()
        } catch {
            status.text = "Recenter waits until more than three gaps are open."
        }
    }

    @objc private func closeSheet() {
        dismiss(animated: SurveyMotion.duration > 0)
    }
}
