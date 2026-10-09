import UIKit

/// Finished holds and the benchmark badges they earned.
@MainActor
final class SummitsSheetController: UIViewController {
    private let store: ContourStore
    private let scroll = UIScrollView()
    private let stack = surveyStack(.vertical, spacing: SurveySpace.m)

    init(store: ContourStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    /// Interface Builder is unused. This path is a programmer error.
    required init?(coder: NSCoder) {
        fatalError("SummitsSheetController is built in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SurveyColor.background
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
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
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let title = surveyLabel("Summits", font: SurveyType.display(), color: SurveyColor.ink, kern: SurveyKern.display)
        title.numberOfLines = 1
        stack.addArrangedSubview(title)
        let chart = await store.snapshot()
        let note = await store.recoveryNote
        if let note {
            stack.addArrangedSubview(surveyLabel(note, font: SurveyType.body(), color: SurveyColor.ink))
            let retry = SurveyButton(type: .custom)
            retry.tone = .quiet
            retry.setTitle("Try again", for: .normal)
            retry.addTarget(self, action: #selector(reloadSheet), for: .touchUpInside)
            stack.addArrangedSubview(retry)
        }
        let registry = SummitRegistry.make(from: chart)
        if registry.entries.isEmpty {
            stack.addArrangedSubview(surveyLabel("No summit yet.", font: SurveyType.headline(), color: SurveyColor.ink))
            stack.addArrangedSubview(surveyLabel("Pin until the profile reaches the last page.", font: SurveyType.body(), color: SurveyColor.muted))
            let art = surveyArt("cdr_EmptyList")
            art.isHidden = art.image == nil
            art.heightAnchor.constraint(greaterThanOrEqualToConstant: SurveySpace.xl * 4).isActive = true
            stack.addArrangedSubview(art)
            let back = SurveyButton(type: .custom)
            back.setTitle("Back to the profile", for: .normal)
            back.addTarget(self, action: #selector(closeSheet), for: .touchUpInside)
            stack.addArrangedSubview(back)
            return
        }
        for entry in registry.entries {
            stack.addArrangedSubview(summitPlate(entry))
        }
        let back = SurveyButton(type: .custom)
        back.setTitle("Back to today's pin", for: .normal)
        back.accessibilityLabel = "Back to today's pin"
        back.addTarget(self, action: #selector(closeSheet), for: .touchUpInside)
        stack.addArrangedSubview(back)
    }

    private func summitPlate(_ entry: SummitRegistry.Entry) -> SurveyPlate {
        let plate = SurveyPlate()
        let name = surveyLabel(entry.hold.title, font: SurveyType.title(), color: SurveyColor.ink, kern: SurveyKern.title)
        name.numberOfLines = 2
        plate.column.addArrangedSubview(name)
        plate.column.addArrangedSubview(surveyLabel(
            SurveyCount.pages(entry.hold.totalPages) + " pages. The profile is complete.",
            font: SurveyType.body(),
            color: SurveyColor.ink
        ))
        if entry.bands.isEmpty {
            plate.column.addArrangedSubview(surveyLabel("No benchmark yet.", font: SurveyType.body(), color: SurveyColor.ink))
            return plate
        }
        plate.column.addArrangedSubview(surveyLabel("Benchmarks crossed on the way up.", font: SurveyType.body(), color: SurveyColor.ink))
        for band in entry.bands {
            plate.column.addArrangedSubview(surveyHairline())
            let percent = SurveyCount.fraction(Double(band) / 10)
            let line = band == 10
                ? percent + " is the summit."
                : percent + " of the book."
            plate.column.addArrangedSubview(surveyLabel(line, font: SurveyType.headline(), color: SurveyColor.ink))
        }
        return plate
    }

    @objc private func reloadSheet() {
        Task { await paint() }
    }

    @objc private func closeSheet() {
        dismiss(animated: SurveyMotion.duration > 0)
    }
}
