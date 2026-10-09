import UIKit

/// Three full pages. Continue sits full width at the bottom. Skip writes the same flag.
@MainActor
final class OnboardingController: UIViewController {
    var onFinish: (() -> Void)?
    private var page = 0
    private let pages: [(String, String, String)] = [
        ("The book becomes a ridge.", "Cordillera draws the volume you are reading as an elevation profile.", "cdr_Onboarding1"),
        ("Pin the pages you read.", "Each pin moves you along the ridge toward the summit of the book.", "cdr_Onboarding2"),
        ("Close one gap this week.", "A day without a pin leaves a dashed gap. Bridge closes the oldest one.", "cdr_Onboarding3"),
    ]
    private let art = surveyArt("cdr_Onboarding1", decorative: true)
    private let headline = surveyLabel("", font: SurveyType.display(), color: SurveyColor.ink, kern: SurveyKern.display)
    private let body = surveyLabel("", font: SurveyType.body(), color: SurveyColor.muted)
    private let index = surveyLabel("", font: SurveyType.numerals(SurveyType.caption()), color: SurveyColor.muted)
    private let continueButton = SurveyButton(type: .custom)
    private let skip = SurveyButton(type: .custom)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SurveyColor.background
        headline.numberOfLines = 2
        continueButton.setTitle("Continue", for: .normal)
        continueButton.addTarget(self, action: #selector(advance), for: .touchUpInside)
        skip.tone = .quiet
        skip.setTitle("Skip", for: .normal)
        skip.addTarget(self, action: #selector(finish), for: .touchUpInside)
        let stack = surveyStack(.vertical, spacing: SurveySpace.m)
        art.setContentHuggingPriority(.defaultLow, for: .vertical)
        stack.addArrangedSubview(art)
        stack.addArrangedSubview(index)
        stack.addArrangedSubview(headline)
        stack.addArrangedSubview(body)
        stack.addArrangedSubview(skip)
        stack.addArrangedSubview(continueButton)
        view.addSubview(stack)
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: SurveySpace.m),
            stack.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -SurveySpace.m),
            stack.topAnchor.constraint(equalTo: guide.topAnchor, constant: SurveySpace.l),
            stack.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -SurveySpace.m),
        ])
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (controller: OnboardingController, _: UITraitCollection) in
            controller.showPage(animated: false)
        }
        showPage(animated: false)
    }

    private func showPage(animated: Bool) {
        let item = pages[page]
        surveyWrite(headline, item.0, font: SurveyType.display(), color: SurveyColor.ink, kern: SurveyKern.display)
        surveyWrite(body, item.1, font: SurveyType.body(), color: SurveyColor.muted)
        surveyWrite(
            index,
            SurveyCount.pages(page + 1) + " of " + SurveyCount.pages(pages.count),
            font: SurveyType.numerals(SurveyType.caption()),
            color: SurveyColor.muted
        )
        art.image = UIImage(named: item.2)
        art.isHidden = art.image == nil
        guard animated else { return }
        UIView.transition(with: view, duration: SurveyMotion.duration, options: SurveyMotion.options, animations: {})
    }

    @objc private func advance() {
        if page + 1 >= pages.count {
            finish()
            return
        }
        page += 1
        showPage(animated: true)
    }

    @objc private func finish() {
        UserDefaults.standard.set(true, forKey: DemoSeed.onboardingKey)
        UserDefaults.standard.set(12, forKey: "cdr.page.default")
        onFinish?()
    }
}
