import SwiftUI

/// SPEC section 7. The only place these hex values live — reach colours
/// and the font family through here. Keep this file and its values.
enum DesignTokens {
    /// #272C1B
    static let bg = Color(red: 0.152941, green: 0.172549, blue: 0.105882)
    static let bgHex = "#272C1B"
    /// #2E3D29
    static let surface = Color(red: 0.180392, green: 0.239216, blue: 0.160784)
    static let surfaceHex = "#2E3D29"
    /// #F3F4F1
    static let ink = Color(red: 0.952941, green: 0.956863, blue: 0.945098)
    static let inkHex = "#F3F4F1"
    /// #87D86E
    static let accent = Color(red: 0.529412, green: 0.847059, blue: 0.431373)
    static let accentHex = "#87D86E"
    /// #BABFB0
    static let muted = Color(red: 0.729412, green: 0.749020, blue: 0.690196)
    static let mutedHex = "#BABFB0"
    static let fontFamily = "Palatino"
}
