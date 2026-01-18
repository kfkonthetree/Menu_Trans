import SwiftUI

enum TabIdentifier: Int, CaseIterable {
    case history = 0
    case scan = 1
    case collections = 2
    case profile = 3
}

struct MainTabView: View {
    @StateObject private var collectionsManager = CollectionsManager()
    @StateObject private var orderManager = OrderManager()
    @State private var selectedTab: TabIdentifier = .scan
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HistoryView(historyManager: HistoryManager())
                .environmentObject(collectionsManager)
                .environmentObject(orderManager)
                .tag(TabIdentifier.history)
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text(NSLocalizedString("search_history", comment: "Search history tab"))
                }
            
            ContentView()
                .environmentObject(collectionsManager)
                .environmentObject(orderManager)
                .tag(TabIdentifier.scan)
                .tabItem {
                    Image(systemName: "camera.viewfinder")
                    Text(NSLocalizedString("scan_menu_title", comment: "Scan menu tab"))
                }
            
            CollectionsView(collectionsManager: collectionsManager)
                .environmentObject(collectionsManager)
                .environmentObject(orderManager)
                .tag(TabIdentifier.collections)
                .tabItem {
                    Image(systemName: "star.fill")
                    Text(NSLocalizedString("collections", comment: "Collections tab"))
                }
            
            ProfileView()
                .tag(TabIdentifier.profile)
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
        }
    }
} 