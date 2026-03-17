import SwiftUI

struct FollowStatsView: View {
    let followerCount: Int
    let followingCount: Int
    var onFollowersTapped: (() -> Void)? = nil
    var onFollowingTapped: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            statButton(value: followerCount, label: "Followers", action: onFollowersTapped)
            Rectangle()
                .fill(Color.sonderDivider)
                .frame(width: 1, height: 36)
            statButton(value: followingCount, label: "Following", action: onFollowingTapped)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.sonderSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func statButton(value: Int, label: String, action: (() -> Void)?) -> some View {
        Button {
            action?()
        } label: {
            VStack(spacing: 3) {
                Text("\(value)")
                    .font(.georgiaBold(22))
                    .foregroundStyle(Color.sonderTextPrimary)
                Text(label)
                    .font(.georgia(13))
                    .foregroundStyle(Color.sonderTextSecond)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}
