/**
 Summary
 -------
 Design tokens and theming utilities (colors, typography helpers, spacing constants) used to maintain a consistent
 visual language throughout the app.
 */
import SwiftUI

// MARK: - Theme

/// Type documentation.
struct Theme {
    // MARK: - Colors
    
    /// Type documentation.
    struct Colors {
        // Primary Colors
        static let primary = Color(hex: "6B5CE6") // Purple
        static let secondary = Color(hex: "8B7FE8") // Light Purple
        static let accent = Color(hex: "FFB74D") // Orange
        
        // Background Colors
        static let background = Color(hex: "0A0E27") // Dark Blue
        static let secondaryBackground = Color(hex: "1A1F3A") // Lighter Dark Blue
        static let cardBackground = Color(hex: "242B47") // Card Blue
        
        // Text Colors
        static let primaryText = Color.white
        static let secondaryText = Color(hex: "A0A6BF") // Gray
        static let tertiaryText = Color(hex: "6B7294") // Darker Gray
        
        // State Colors
        static let success = Color(hex: "4CAF50") // Green
        static let warning = Color(hex: "FFA726") // Orange
        static let error = Color(hex: "EF5350") // Red
        static let info = Color(hex: "42A5F5") // Blue
        
        // Gradient Colors
        static let gradientStart = Color(hex: "6B5CE6")
        static let gradientEnd = Color(hex: "4A3F9F")
        
        // Focus Mode Colors
        static let focusActive = Color(hex: "7C4DFF") // Purple
        static let focusInactive = Color(hex: "3F51B5") // Indigo
        
        // Sleep Colors
        static let bedtime = Color(hex: "3F51B5") // Indigo
        static let wakeTime = Color(hex: "FFB74D") // Orange
    }
    
    // MARK: - Gradients
    
    /// Type documentation.
    struct Gradients {
        static let primary = LinearGradient(
            colors: [Colors.gradientStart, Colors.gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let card = LinearGradient(
            colors: [Colors.cardBackground, Colors.secondaryBackground],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let focus = LinearGradient(
            colors: [Colors.focusActive, Colors.focusInactive],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let sleep = LinearGradient(
            colors: [Colors.bedtime, Color.black],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Typography
    
    /// Type documentation.
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 24, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    }
    
    // MARK: - Spacing
    
    /// Type documentation.
    struct Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
        static let xxLarge: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    /// Type documentation.
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
        static let round: CGFloat = 999
    }
    
    // MARK: - Animation
    
    /// Type documentation.
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
    }
    
    func primaryButtonStyle() -> some View {
        self
            .foregroundColor(.white)
            .font(Theme.Typography.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Theme.Gradients.primary)
            .cornerRadius(Theme.CornerRadius.medium)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .foregroundColor(Theme.Colors.primary)
            .font(Theme.Typography.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Theme.Colors.primary, lineWidth: 2)
            )
    }
}