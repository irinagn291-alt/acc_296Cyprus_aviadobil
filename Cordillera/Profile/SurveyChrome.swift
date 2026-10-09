import UIKit
import SwiftUI

/// Colour, type, space, and radius. Every screen reads these accessors.
enum SurveyColor {
    static var background: UIColor { UIColor(DesignTokens.bg) }
    static var surface: UIColor { UIColor(DesignTokens.surface) }
    static var ink: UIColor { UIColor(DesignTokens.ink) }
    static var accent: UIColor { UIColor(DesignTokens.accent) }
    static var muted: UIColor { UIColor(DesignTokens.muted) }
}

enum SurveyType {
    static func display() -> UIFont { face(bold: true, size: 34, textStyle: .largeTitle) }
    static func title() -> UIFont { face(bold: true, size: 28, textStyle: .title2) }
    static func headline() -> UIFont { face(bold: true, size: 22, textStyle: .title3) }
    static func body() -> UIFont { face(bold: false, size: 17, textStyle: .body) }
    static func caption() -> UIFont { face(bold: false, size: 13, textStyle: .caption1) }
    static func micro() -> UIFont { face(bold: false, size: 11, textStyle: .caption2) }

    static func numerals(_ font: UIFont) -> UIFont {
        let descriptor = font.fontDescriptor.addingAttributes([
            UIFontDescriptor.AttributeName.featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.type: kNumberSpacingType,
                    UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector,
                ],
            ],
        ])
        return UIFont(descriptor: descriptor, size: font.pointSize)
    }

    private static func face(bold: Bool, size: CGFloat, textStyle: UIFont.TextStyle) -> UIFont {
        let category = UIApplication.shared.preferredContentSizeCategory
        let name: String
        if category >= .accessibilityExtraExtraLarge {
            name = bold ? "NewYorkMedium-Bold" : "NewYorkMedium-Regular"
        } else {
            name = bold ? "Palatino-Bold" : "Palatino-Roman"
        }
        let base = UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size, weight: bold ? .semibold : .regular)
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: base)
    }
}

enum SurveySpace {
    static let unit: CGFloat = 8
    static var s: CGFloat { unit }
    static var m: CGFloat { unit * 2 }
    static var l: CGFloat { unit * 3 }
    static var xl: CGFloat { unit * 4 }
    /// Apple's minimum control size. Not a spacing step.
    static let hit: CGFloat = 44
    /// Hairline depth shared by every plate. Not a second elevation.
    static let hairline: CGFloat = 1
}

enum SurveyRadius {
    static let card: CGFloat = 24
    static let chip: CGFloat = 10
}

enum SurveyCount {
    static func pages(_ value: Int) -> String {
        formatted(NSNumber(value: value)) { formatter in
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
        }
    }

    static func fraction(_ value: Double) -> String {
        formatted(NSNumber(value: value)) { formatter in
            formatter.numberStyle = .percent
            formatter.maximumFractionDigits = 0
        }
    }

    private static func formatted(_ number: NSNumber, configure: (NumberFormatter) -> Void) -> String {
        let formatter = NumberFormatter()
        formatter.locale = .current
        configure(formatter)
        if let text = formatter.string(from: number) {
            return text
        }
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: number) ?? "0"
    }
}

/// One control style: default, pressed, disabled, loading. Peel uses destructive.
final class SurveyButton: UIButton {
    enum Tone {
        case primary
        case quiet
        case destructive
    }

    enum Shape {
        case card
        case chip
    }

    var tone: Tone = .primary {
        didSet { applyChrome() }
    }

    var shape: Shape = .card {
        didSet {
            layer.cornerRadius = corner
            applyChrome()
        }
    }

    private var corner: CGFloat {
        shape == .chip ? SurveyRadius.chip : SurveyRadius.card
    }

    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private let tintPlate = UIView()
    private var loading = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        blur.isUserInteractionEnabled = false
        blur.clipsToBounds = true
        tintPlate.isUserInteractionEnabled = false
        insertSubview(blur, at: 0)
        insertSubview(tintPlate, aboveSubview: blur)
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(
            top: SurveySpace.s,
            leading: SurveySpace.m,
            bottom: SurveySpace.s,
            trailing: SurveySpace.m
        )
        config.titleLineBreakMode = .byTruncatingTail
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = SurveyType.headline()
            outgoing.foregroundColor = SurveyColor.ink
            return outgoing
        }
        configuration = config
        layer.cornerRadius = SurveyRadius.card
        clipsToBounds = true
        heightAnchor.constraint(greaterThanOrEqualToConstant: SurveySpace.hit).isActive = true
        spinner.color = SurveyColor.ink
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor),
            spinner.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -SurveySpace.m),
        ])
        applyChrome()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (button: SurveyButton, _: UITraitCollection) in
            button.refreshType()
        }
    }

    private let spinner = UIActivityIndicatorView(style: .medium)

    /// Interface Builder is unused. This path is a programmer error.
    required init?(coder: NSCoder) {
        fatalError("SurveyButton is built in code")
    }

    override func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)
        guard state == .normal else { return }
        var config = configuration ?? UIButton.Configuration.plain()
        config.title = title
        configuration = config
    }

    func setFace(named asset: String) {
        guard let image = UIImage(named: asset) else { return }
        let side = SurveySpace.l
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        let scaled = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: side, height: side))
        }
        var config = configuration ?? UIButton.Configuration.plain()
        config.image = scaled.withRenderingMode(.alwaysOriginal)
        config.imagePadding = SurveySpace.s
        config.imagePlacement = .leading
        configuration = config
    }

    func setSymbol(_ name: String, placement: NSDirectionalRectEdge = .leading) {
        var config = configuration ?? UIButton.Configuration.plain()
        config.image = UIImage(systemName: name)
        config.imagePadding = SurveySpace.s
        config.imagePlacement = placement
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: SurveyType.caption().pointSize, weight: .regular)
        configuration = config
    }

    func setLoading(_ loading: Bool) {
        self.loading = loading
        isEnabled = !loading
        if loading {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
        applyChrome()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        blur.frame = bounds
        tintPlate.frame = bounds
        blur.layer.cornerRadius = corner
        layer.cornerRadius = corner
        sendSubviewToBack(tintPlate)
        sendSubviewToBack(blur)
    }

    private func refreshType() {
        let ink = isEnabled ? SurveyColor.ink : SurveyColor.muted
        var config = configuration ?? UIButton.Configuration.plain()
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = SurveyType.headline()
            outgoing.foregroundColor = ink
            return outgoing
        }
        configuration = config
    }

    override var isHighlighted: Bool {
        didSet {
            let pressed = isHighlighted && isEnabled && !loading
            let scale = (pressed && SurveyMotion.duration > 0) ? SurveyMotion.pressedScale : 1
            transform = CGAffineTransform(scaleX: scale, y: scale)
            alpha = pressed ? 0.72 : 1
        }
    }

    override var isEnabled: Bool {
        didSet { applyChrome() }
    }

    private func applyChrome() {
        switch tone {
        case .primary:
            tintPlate.backgroundColor = SurveyColor.accent.withAlphaComponent(isEnabled ? 0.28 : 0.1)
        case .quiet:
            tintPlate.backgroundColor = SurveyColor.surface.withAlphaComponent(0.2)
        case .destructive:
            tintPlate.backgroundColor = SurveyColor.muted.withAlphaComponent(0.28)
        }
        alpha = 1
        var config = configuration ?? UIButton.Configuration.plain()
        config.baseForegroundColor = isEnabled ? SurveyColor.ink : SurveyColor.muted
        configuration = config
    }
}

enum SurveyMotion {
    static let pressedScale: CGFloat = 0.98

    static var duration: TimeInterval {
        UIAccessibility.isReduceMotionEnabled ? 0 : 0.18
    }

    static var options: UIView.AnimationOptions {
        [.transitionCrossDissolve, .curveEaseOut, .allowUserInteraction]
    }
}

func surveyStack(_ axis: NSLayoutConstraint.Axis, spacing: CGFloat) -> UIStackView {
    let stack = UIStackView()
    stack.axis = axis
    stack.spacing = spacing
    stack.translatesAutoresizingMaskIntoConstraints = false
    return stack
}

func surveyLabel(_ text: String, font: UIFont, color: UIColor, kern: CGFloat = 0) -> UILabel {
    let label = UILabel()
    label.numberOfLines = 0
    label.adjustsFontForContentSizeCategory = false
    surveyWrite(label, text, font: font, color: color, kern: kern)
    return label
}

func surveyWrite(_ label: UILabel, _ text: String, font: UIFont, color: UIColor, kern: CGFloat = 0) {
    label.font = font
    label.textColor = color
    if kern == 0 {
        label.attributedText = nil
        label.text = text
        return
    }
    label.attributedText = NSAttributedString(
        string: text,
        attributes: [
            .font: font,
            .foregroundColor: color,
            .kern: kern,
        ]
    )
}

enum SurveyKern {
    static let display: CGFloat = -0.8
    static let title: CGFloat = -0.4
}

/// Material surface. One radius, one elevation, hairline edge.
final class SurveyPlate: UIView {
    let column = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
        blur.translatesAutoresizingMaskIntoConstraints = false
        blur.isUserInteractionEnabled = false
        blur.clipsToBounds = true
        blur.layer.cornerRadius = SurveyRadius.card
        addSubview(blur)
        column.axis = .vertical
        column.spacing = SurveySpace.s
        column.translatesAutoresizingMaskIntoConstraints = false
        column.isLayoutMarginsRelativeArrangement = true
        column.layoutMargins = UIEdgeInsets(
            top: SurveySpace.m,
            left: SurveySpace.m,
            bottom: SurveySpace.m,
            right: SurveySpace.m
        )
        addSubview(column)
        layer.cornerRadius = SurveyRadius.card
        layer.borderWidth = SurveySpace.hairline
        clipsToBounds = true
        NSLayoutConstraint.activate([
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor),
            column.leadingAnchor.constraint(equalTo: leadingAnchor),
            column.trailingAnchor.constraint(equalTo: trailingAnchor),
            column.topAnchor.constraint(equalTo: topAnchor),
            column.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    /// Interface Builder is unused. This path is a programmer error.
    required init?(coder: NSCoder) {
        fatalError("SurveyPlate is built in code")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.borderColor = SurveyColor.muted.withAlphaComponent(0.4).cgColor
    }
}

func surveyField(_ field: UITextField, label: String) {
    field.textColor = SurveyColor.ink
    field.tintColor = SurveyColor.accent
    field.font = SurveyType.body()
    field.backgroundColor = SurveyColor.surface
    field.layer.cornerRadius = SurveyRadius.chip
    field.layer.borderWidth = SurveySpace.hairline
    field.layer.borderColor = SurveyColor.muted.withAlphaComponent(0.4).cgColor
    field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: SurveySpace.m, height: SurveySpace.hit))
    field.leftViewMode = .always
    field.accessibilityLabel = label
    field.heightAnchor.constraint(greaterThanOrEqualToConstant: SurveySpace.hit).isActive = true
    field.autocorrectionType = .no
    field.adjustsFontForContentSizeCategory = false
}

/// A caption plate. Material and the chip radius, not a control.
func surveyReadout(_ text: String) -> UIView {
    let plate = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    plate.translatesAutoresizingMaskIntoConstraints = false
    plate.clipsToBounds = true
    plate.layer.cornerRadius = SurveyRadius.chip
    plate.isUserInteractionEnabled = false
    plate.isAccessibilityElement = true
    plate.accessibilityLabel = text
    let label = surveyLabel(text, font: SurveyType.numerals(SurveyType.caption()), color: SurveyColor.ink)
    label.textAlignment = .center
    label.numberOfLines = 1
    label.isAccessibilityElement = false
    label.translatesAutoresizingMaskIntoConstraints = false
    plate.contentView.addSubview(label)
    NSLayoutConstraint.activate([
        label.leadingAnchor.constraint(equalTo: plate.contentView.leadingAnchor, constant: SurveySpace.s),
        label.trailingAnchor.constraint(equalTo: plate.contentView.trailingAnchor, constant: -SurveySpace.s),
        label.topAnchor.constraint(equalTo: plate.contentView.topAnchor, constant: SurveySpace.s),
        label.bottomAnchor.constraint(equalTo: plate.contentView.bottomAnchor, constant: -SurveySpace.s),
    ])
    return plate
}

func surveyHairline() -> UIView {
    let line = UIView()
    line.backgroundColor = SurveyColor.muted.withAlphaComponent(0.4)
    line.translatesAutoresizingMaskIntoConstraints = false
    line.heightAnchor.constraint(equalToConstant: SurveySpace.hairline).isActive = true
    line.isAccessibilityElement = false
    return line
}

func surveyArt(_ name: String, decorative: Bool = true) -> UIImageView {
    let image = UIImageView(image: UIImage(named: name))
    image.contentMode = .scaleAspectFit
    image.clipsToBounds = true
    image.translatesAutoresizingMaskIntoConstraints = false
    image.isAccessibilityElement = !decorative
    image.backgroundColor = .clear
    return image
}

/// Keeps the focused field above the keyboard. Selector-based so the scroll view stays on the main actor.
@MainActor
final class SurveyKeyboard: NSObject {
    private weak var scroll: UIScrollView?

    func bind(_ scroll: UIScrollView) {
        self.scroll = scroll
        scroll.keyboardDismissMode = .interactive
        NotificationCenter.default.addObserver(self, selector: #selector(move(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc private func move(_ note: Notification) {
        guard let scroll, let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let converted = scroll.convert(frame, from: nil)
        let overlap = max(0, scroll.bounds.maxY - converted.minY)
        scroll.contentInset.bottom = overlap + SurveySpace.m
        scroll.verticalScrollIndicatorInsets.bottom = overlap
    }
}
