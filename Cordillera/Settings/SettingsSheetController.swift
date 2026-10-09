import UIKit

/// Contact, confirmed reset, and onboarding replay.
@MainActor
final class SettingsSheetController: UIViewController {
    var onChange: (() -> Void)?
    var onReplay: (() -> Void)?
    private let store: ContourStore
    private let keyboard = SurveyKeyboard()
    private let scroll = UIScrollView()
    private let stack = surveyStack(.vertical, spacing: SurveySpace.m)
    private let status = surveyLabel("The contour stays on this device.", font: SurveyType.body(), color: SurveyColor.ink)
    private let contactURL = "https://cordillera-profile.pro/contact-us"

    init(store: ContourStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    /// Interface Builder is unused. This path is a programmer error.
    required init?(coder: NSCoder) {
        fatalError("SettingsSheetController is built in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SurveyColor.background
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        keyboard.bind(scroll)
        let title = surveyLabel("Settings", font: SurveyType.display(), color: SurveyColor.ink, kern: SurveyKern.display)
        title.numberOfLines = 1
        let plate = SurveyPlate()
        let replayButton = SurveyButton(type: .custom)
        replayButton.tone = .quiet
        replayButton.setTitle("Show introduction", for: .normal)
        replayButton.setSymbol("arrow.counterclockwise")
        replayButton.addTarget(self, action: #selector(replay), for: .touchUpInside)
        let reset = SurveyButton(type: .custom)
        reset.tone = .destructive
        reset.setTitle("Reset", for: .normal)
        reset.setSymbol("trash")
        reset.accessibilityLabel = "Reset all data"
        reset.addTarget(self, action: #selector(confirmReset), for: .touchUpInside)
        let contact = SurveyButton(type: .custom)
        contact.setTitle("Contact", for: .normal)
        contact.setSymbol("envelope")
        contact.accessibilityLabel = "Contact Cordillera"
        contact.addTarget(self, action: #selector(openContact), for: .touchUpInside)
        let address = surveyLabel(contactURL, font: SurveyType.caption(), color: SurveyColor.accent)
        address.numberOfLines = 2
        let retry = SurveyButton(type: .custom)
        retry.tone = .quiet
        retry.setTitle("Try again", for: .normal)
        retry.addTarget(self, action: #selector(reloadNote), for: .touchUpInside)
        plate.column.addArrangedSubview(status)
        plate.column.addArrangedSubview(replayButton)
        plate.column.addArrangedSubview(reset)
        plate.column.addArrangedSubview(contact)
        plate.column.addArrangedSubview(address)
        plate.column.addArrangedSubview(retry)
        let close = SurveyButton(type: .custom)
        close.tone = .quiet
        close.setTitle("Close", for: .normal)
        close.setSymbol("xmark")
        close.accessibilityLabel = "Close settings"
        close.addTarget(self, action: #selector(closeSheet), for: .touchUpInside)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(surveyLabel("Replay the introduction, write to Cordillera, or clear the pack.", font: SurveyType.body(), color: SurveyColor.muted))
        stack.addArrangedSubview(plate)
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
        Task { await paint() }
    }

    private func paint() async {
        if let note = await store.recoveryNote {
            status.text = note
        } else {
            status.text = "The contour stays on this device."
        }
    }

    @objc private func reloadNote() {
        Task { await paint() }
    }

    @objc private func replay() {
        UserDefaults.standard.set(false, forKey: DemoSeed.onboardingKey)
        onReplay?()
    }

    @objc private func confirmReset() {
        let alert = UIAlertController(
            title: "Reset the contour?",
            message: "Every hold, pin, and summit on this device is removed.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            Task { await self?.wipe() }
        })
        present(alert, animated: SurveyMotion.duration > 0)
    }

    private func wipe() async {
        await store.resetAllData()
        status.text = "The pack is bare."
        onChange?()
    }

    @objc private func openContact() {
        guard let url = URL(string: contactURL) else {
            status.text = "The contact page did not open. Try again."
            return
        }
        UIApplication.shared.open(url, options: [:]) { [weak self] accepted in
            Task { @MainActor in
                if !accepted {
                    self?.status.text = "The contact page did not open. Try again."
                }
            }
        }
    }

    @objc private func closeSheet() {
        dismiss(animated: SurveyMotion.duration > 0)
    }
}
