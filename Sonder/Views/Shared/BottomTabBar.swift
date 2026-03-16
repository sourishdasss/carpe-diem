import SwiftUI

struct BottomTabBar: View {
    @Binding var selectedTab: AppStore.Tab

    private let tabs: [(AppStore.Tab, String, String)] = [
        (.feed, "square.grid.2x2", "Feed"),
        (.lists, "list.bullet", "Lists"),
        (.profile, "person.crop.circle", "Profile")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.0.rawValue) { tab, icon, label in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .medium))
                        Text(label)
                            .font(.caption2.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(selectedTab == tab ? Color.accentAmber : Color.slate400)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 24)
        .background(Color.night800)
    }
}
