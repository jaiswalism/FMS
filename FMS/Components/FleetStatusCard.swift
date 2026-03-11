import SwiftUI

public struct FleetStatusCard: View {
    public let activeCount: Int
    public let subtitle: String
    public let onViewMap: () -> Void
    
    public init(activeCount: Int, subtitle: String, onViewMap: @escaping () -> Void) {
        self.activeCount = activeCount
        self.subtitle = subtitle
        self.onViewMap = onViewMap
    }
    
    public var body: some View {
        ZStack {
            // Background gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            FMSTheme.amber,
                            FMSTheme.amberDark
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Decorative overlay pattern (subtle grid effect)
            GeometryReader { geometry in
                Path { path in
                    let spacing: CGFloat = 20
                    for i in stride(from: 0, to: geometry.size.width, by: spacing) {
                        path.move(to: CGPoint(x: i, y: 0))
                        path.addLine(to: CGPoint(x: i, y: geometry.size.height))
                    }
                }
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            // Content
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("FLEET STATUS")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(FMSTheme.obsidian.opacity(0.6))
                        .tracking(1)
                    
                    Text("\(activeCount) Active")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(FMSTheme.obsidian)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(FMSTheme.obsidian.opacity(0.7))
                    
                    Spacer()
                    
                    Button(action: onViewMap) {
                        HStack(spacing: 6) {
                            Text("View All")
                                .font(.system(size: 14, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(FMSTheme.obsidian)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                }
                .padding(24)
                
                Spacer()
                
                // Right side decorative element (truck silhouette area)
                VStack {
                    Spacer()
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 60))
                        .foregroundColor(FMSTheme.obsidian.opacity(0.15))
                        .offset(x: 10, y: 10)
                }
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(height: 180)
    }
}

#Preview {
    FleetStatusCard(
        activeCount: 14,
        subtitle: "Vehicles in transit",
        onViewMap: {}
    )
    .padding()
    .background(FMSTheme.backgroundPrimary)
}
