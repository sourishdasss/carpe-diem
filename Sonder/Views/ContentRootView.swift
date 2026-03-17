import SwiftUI

struct ContentRootView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch store.selectedTab {
                case .feed:    FeedView()
                case .map:     TravelMapView()
                case .lists:   ListsView()
                case .profile: ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            BottomTabBar(selectedTab: $store.selectedTab)
        }
        .background(Color.sonderBackground)
    }
}
