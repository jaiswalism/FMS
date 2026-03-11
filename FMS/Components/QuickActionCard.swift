import SwiftUI

public struct QuickActionCard: View {
    public let icon: String
    public let title: String
    public let subtitle: String
    public let action: () -> Void
    
    public init(icon: String, title: String, subtitle: String, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(FMSTheme.amber.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(FMSTheme.amber)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(FMSTheme.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(FMSTheme.textSecondary)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(FMSTheme.textTertiary)
            }
            .padding(16)
            .background(FMSTheme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(FMSTheme.borderLight, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuickActionCard(
        icon: "shippingbox.fill",
        title: "Pending Orders",
        subtitle: "12 orders awaiting dispatch",
        action: {}
    )
    .padding()
    .background(FMSTheme.backgroundPrimary)
}
