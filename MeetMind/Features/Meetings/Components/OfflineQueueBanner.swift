import SwiftUI

struct OfflineQueueBanner: View {
    @ObservedObject private var offlineQueue = OfflineQueueService.shared

    var body: some View {
        if !offlineQueue.isOnline || offlineQueue.queuedCount > 0 {
            HStack(spacing: 10) {
                Image(systemName: offlineQueue.isProcessingQueue ? "arrow.triangle.2.circlepath" : "wifi.slash")
                    .font(MMTypography.subheadlineMedium)
                    .foregroundColor(MMColors.warning)
                    .rotationEffect(.degrees(offlineQueue.isProcessingQueue ? 360 : 0))
                    .animation(
                        offlineQueue.isProcessingQueue
                            ? .linear(duration: 1).repeatForever(autoreverses: false)
                            : .default,
                        value: offlineQueue.isProcessingQueue
                    )

                VStack(alignment: .leading, spacing: 2) {
                    if offlineQueue.isProcessingQueue {
                        Text("Processing queued meetings...")
                            .font(MMTypography.footnoteMedium)
                            .foregroundColor(MMColors.textPrimary)
                    } else if offlineQueue.queuedCount > 0 {
                        Text("\(offlineQueue.queuedCount) meeting\(offlineQueue.queuedCount == 1 ? "" : "s") queued for processing")
                            .font(MMTypography.footnoteMedium)
                            .foregroundColor(MMColors.textPrimary)
                    } else {
                        Text("You're offline")
                            .font(MMTypography.footnoteMedium)
                            .foregroundColor(MMColors.textPrimary)
                    }

                    if !offlineQueue.isOnline && offlineQueue.queuedCount > 0 {
                        Text("Will process when back online")
                            .font(MMTypography.caption1)
                            .foregroundColor(MMColors.textSecondary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(MMColors.warningLight)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(MMColors.warning.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: offlineQueue.isOnline)
            .animation(.easeInOut(duration: 0.3), value: offlineQueue.queuedCount)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        OfflineQueueBanner()
        Spacer()
    }
    .padding()
    .background(MMColors.background)
}
