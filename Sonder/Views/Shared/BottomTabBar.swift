import SwiftUI

struct BottomTabBar: View {
    @Binding var selectedTab: AppStore.Tab

    private let tabs: [(AppStore.Tab, String, String)] = [
        (.feed,    "square.stack.fill",   "Feed"),
        (.map,     "map.fill",            "Map"),
        (.lists,   "list.star",           "Lists"),
        (.profile, "person.fill",         "Profile")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.0.rawValue) { tab, icon, label in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .medium))
                        Text(label)
                            .font(.caption2.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(selectedTab == tab ? Color.sonderAccent : Color.sonderTextSecond)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 24)
        .background(Color.sonderSurface)
        .overlay(
            Rectangle()
                .fill(Color.sonderDivider)
                .frame(height: 0.5),
            alignment: .top
        )
    }
}
