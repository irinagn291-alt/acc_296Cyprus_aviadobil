import UIKit

/// The only custom-drawn surface. Ridgeline, hiker, trig chain, and dashed gaps.
/// Drift stays off this canvas. A missed day is a gap segment, not a curl.
final class ProfileCanvas: UIView {
    struct Mark {
        var fraction: CGFloat
    }

    var routeX: CGFloat = 0
    var trigs: [Mark] = []
    var gaps: [Mark] = []
    var title: String = ""
    var readout: String = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
    }

    /// Interface Builder is unused. This path is a programmer error.
    required init?(coder: NSCoder) {
        fatalError("ProfileCanvas is built in code")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let bounds = rect.insetBy(dx: SurveySpace.l, dy: SurveySpace.l)
        guard bounds.width > 1, bounds.height > 1 else { return }

        context.setStrokeColor(SurveyColor.muted.withAlphaComponent(0.45).cgColor)
        context.setLineWidth(SurveySpace.hairline)
        context.move(to: CGPoint(x: bounds.minX, y: bounds.maxY - SurveySpace.xl))
        context.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY - SurveySpace.xl))
        context.strokePath()

        let ridge = path(in: bounds)
        context.setStrokeColor(SurveyColor.ink.cgColor)
        context.setLineWidth(SurveySpace.hairline * 2)
        context.addPath(ridge)
        context.strokePath()

        context.saveGState()
        context.addPath(ridge)
        context.replacePathWithStrokedPath()
        context.clip()
        context.setFillColor(SurveyColor.accent.withAlphaComponent(0.35).cgColor)
        let lit = routeX * bounds.width
        context.fill(CGRect(x: bounds.minX, y: bounds.minY, width: max(0, lit), height: bounds.height))
        context.restoreGState()

        let dash = SurveySpace.s
        for gap in gaps {
            let x = bounds.minX + gap.fraction * bounds.width
            context.setStrokeColor(SurveyColor.muted.cgColor)
            context.setLineWidth(SurveySpace.hairline * 2)
            context.setLineDash(phase: 0, lengths: [dash, dash])
            context.move(to: CGPoint(x: x, y: bounds.minY + SurveySpace.xl))
            context.addLine(to: CGPoint(x: x, y: bounds.maxY - SurveySpace.m))
            context.strokePath()
            context.setLineDash(phase: 0, lengths: [])
        }

        let cairn = SurveySpace.s
        for trig in trigs {
            let point = point(on: bounds, fraction: trig.fraction)
            let mark = UIBezierPath()
            mark.move(to: CGPoint(x: point.x, y: point.y - SurveySpace.m))
            mark.addLine(to: CGPoint(x: point.x + cairn, y: point.y + cairn))
            mark.addLine(to: CGPoint(x: point.x - cairn, y: point.y + cairn))
            mark.close()
            SurveyColor.ink.setFill()
            mark.fill()
        }

        let hiker = point(on: bounds, fraction: min(1, max(0, routeX)))
        let dot = UIBezierPath(ovalIn: CGRect(
            x: hiker.x - cairn,
            y: hiker.y - cairn,
            width: SurveySpace.m,
            height: SurveySpace.m
        ))
        SurveyColor.accent.setFill()
        dot.fill()
        SurveyColor.ink.setStroke()
        dot.lineWidth = SurveySpace.hairline
        dot.stroke()
    }

    private func path(in bounds: CGRect) -> CGPath {
        let path = CGMutablePath()
        let steps = 24
        for step in 0...steps {
            let t = CGFloat(step) / CGFloat(steps)
            let x = bounds.minX + t * bounds.width
            let lift = sin(t * .pi) * bounds.height * 0.55
            let y = bounds.maxY - SurveySpace.xl - lift
            if step == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }

    private func point(on bounds: CGRect, fraction: CGFloat) -> CGPoint {
        let t = min(1, max(0, fraction))
        let x = bounds.minX + t * bounds.width
        let lift = sin(t * .pi) * bounds.height * 0.55
        let y = bounds.maxY - SurveySpace.xl - lift
        return CGPoint(x: x, y: y)
    }
}
