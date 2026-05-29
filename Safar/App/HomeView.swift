import SwiftUI
import MapKit

/// Typed navigation target for push notification deep links to a city.
/// Kept separate from `City` because deep links only carry a cityId, not a full model.
private struct DeepLinkCityTarget: Hashable {
    let cityId: Int
}

/// Typed navigation target for push notification deep links to a user profile.
private struct DeepLinkUserTarget: Hashable {
    let userId: String
}

struct HomeView: View {
    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20.0, longitude: 0.0),
            span: MKCoordinateSpan(latitudeDelta: 100.0, longitudeDelta: 100.0)
        )
    )
    @State private var mapPresentation: mapType = .all

    @State private var selectedTab: Int = 0
    @State private var isMapExpanded = false
    @State private var showSearchScreen = false
    @State private var showOfflineToast = false
    @State private var showingCityList = false

    @State private var homeNavigationPath = NavigationPath()
    @State private var exploreNavigationPath = NavigationPath()
    @State private var feedNavigationPath = NavigationPath()
    @State private var profileNavigationPath = NavigationPath()

    @StateObject private var notificationsViewModel = NotificationsViewModel()
    @State private var profileTabImage: UIImage?

    @EnvironmentObject var viewModel: UserCitiesViewModel
    @EnvironmentObject var currentUserProfileViewModel: UserProfileViewModel
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @ObservedObject private var pushRouter = PushNotificationRouter.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        VStack(spacing: 0) {
            if !networkMonitor.isConnected {
                OfflineBannerView(lastSyncDate: CityCacheManager.shared.lastSyncDate)
            }

            TabView(selection: $selectedTab) {
            NavigationStack(path: $homeNavigationPath) {
                GeometryReader { geometry in
                VStack {
                     TopBar(notificationsViewModel: notificationsViewModel)
                     Button(action: {
                         if networkMonitor.isConnected {
                             showSearchScreen = true
                         } else {
                             showOfflineToast = true
                         }
                     }) {
                         HStack {
                             Image(systemName: "magnifyingglass")
                                 .foregroundColor(.gray)
                             Text("Search for a city, member, or anything else")
                                 .foregroundColor(.gray)
                                 .font(.subheadline)
                             Spacer()
                         }
                         .padding()
                         .background(Color(.systemGray6))
                         .cornerRadius(20)
                     }
                     .buttonStyle(PlainButtonStyle())
                     .padding(.horizontal)
                     .background(Color("Background"))
                     .padding(.bottom, 6)
                     
                    // Stat Cards
                    HStack(spacing: 12) {
                        StatCard(title: String(viewModel.visitedCitiesCount), subtitle: "Cities", screenHeight: geometry.size.height)
                        StatCard(title: String(viewModel.visitedCountriesCount), subtitle: "Countries", screenHeight: geometry.size.height)
                        StatCard(title: String(viewModel.visitedContinents.count), subtitle: "Continents", screenHeight: geometry.size.height)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 6)

                    // Action Buttons
                    HStack() {
                        ActionButton(title: "Add a new city", systemImage: "plus", screenHeight: geometry.size.height) {
                            if networkMonitor.isConnected {
                                showSearchScreen = true
                            } else {
                                showOfflineToast = true
                            }
                        }
			Spacer()
                        ShareLink(
                            item: URL(string: "https://apps.apple.com/app/id6759003685")!,
                            message: Text("Check out Safar – track every city you visit and share your travels!")
                        ) {
                                HStack {
                                    Image(systemName: "paperplane")
                                    Text("Invite friends")
                                        .font(.subheadline)
                                }
                                .padding(.vertical, geometry.size.height * 0.012)
                                .padding(.horizontal, geometry.size.height * 0.037)
                                .background(Color.accentColor)
                                .cornerRadius(20)
                                .bold(true)
                            }
                            .foregroundColor(Color.white)
                        
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 6)

                    if !showSearchScreen {
                        FullScreenMapView(isFullScreen: isMapExpanded, cameraPosition: cameraPosition, mapPresentation: $mapPresentation, viewModel: viewModel) { city in
                                print("[NAV] City tapped on map: \(city.displayName) (id: \(city.id))")
                                print("[NAV] viewModel.currentUserId: \(String(describing: viewModel.currentUserId))")
                                print("[NAV] viewModel.allUserCities count: \(viewModel.allUserCities.count)")
                                homeNavigationPath.append(city)
                                print("[NAV] Appended to homeNavigationPath, count: \(homeNavigationPath.count)")
                            }
                            .frame(maxHeight: .infinity)
                            .cornerRadius(20)
                            .padding(.horizontal)
                            .padding(.bottom)
                            .overlay(alignment: .topTrailing) {
                                Button(action: {
                                    withAnimation(.spring()) {
                                        isMapExpanded.toggle()
                                    }
                                }) {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .font(.headline)
                                        .padding(10)
                                        .foregroundColor(Color.white)
                                        .background(Color(.accent))
                                        .bold()
                                        .cornerRadius(20)
                                }
                                .padding(.top, 16)
                                .padding(.trailing, 24)
                            }
                            .overlay(alignment: .bottom) {
                                Button(action: {
                                    showingCityList = true
                                }) {
                                    Text("View List")
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 30)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemGray5))
                                        .clipShape(Capsule())
                                        .foregroundColor(.primary)
                                }
                                .opacity(0.8)
                                .padding(.bottom, 20)
                            }
                    }

                }
                }
                .background(Color("Background"))
                .fullScreenCover(isPresented: $showSearchScreen) {
                    SearchMainView()
                        .environmentObject(viewModel)
                }
                .fullScreenCover(isPresented: $isMapExpanded) {
                    FullScreenMapView(isFullScreen: isMapExpanded, cameraPosition: cameraPosition, mapPresentation: $mapPresentation, viewModel: viewModel)
                        .environmentObject(viewModel)
                }
                .sheet(isPresented: $showingCityList) {
                    YourCitiesView()
                        .environmentObject(viewModel)
                }
                .navigationDestination(for: City.self) { city in
                    CityDetailView(cityId: city.id)
                        .environmentObject(viewModel)
                }
                .navigationDestination(for: DeepLinkCityTarget.self) { target in
                    CityDetailView(cityId: target.cityId)
                        .environmentObject(viewModel)
                }
                .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack(path: $exploreNavigationPath) {
                ExploreView()
            }
            .tabItem {
                Label("Explore", systemImage: "safari")
            }
            .tag(1)

            NavigationStack(path: $feedNavigationPath) {
                FeedView()
                    .navigationDestination(for: FeedPost.self) { post in
                        PostDetailView(post: post)
                    }
                    .navigationDestination(for: DeepLinkUserTarget.self) { target in
                        UserProfileView(userId: target.userId)
                    }
            }
            .tabItem {
                Label("Feed", systemImage: "airplane.departure")
            }
            .tag(2)

            NavigationStack(path: $profileNavigationPath) {
                UserProfileView(viewModel: currentUserProfileViewModel)
            }
            .tabItem { profileTabItem }
            .tag(3)

        }
        .task {
            // Seed the unread count for the badge on first load
            await notificationsViewModel.refreshUnreadCount()
        }
        .task(id: viewModel.currentUserAvatarURL) {
            await loadProfileTabImage()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await notificationsViewModel.refreshUnreadCount() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .safar_notificationReceived)) { _ in
            Task { await notificationsViewModel.refreshUnreadCount() }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if oldValue != newValue {
                let tabNames = ["home", "explore", "feed", "profile"]
                let tabName = newValue < tabNames.count ? tabNames[newValue] : "\(newValue)"
                AnalyticsManager.shared.capture("tab_selected", properties: ["tab": tabName])
            }
            // If the same tab is selected again, pop to root
            if oldValue == newValue {
                switch newValue {
                case 0:
                    homeNavigationPath = NavigationPath()
                    showSearchScreen = false
                    isMapExpanded = false
                case 1:
                    exploreNavigationPath = NavigationPath()
                case 2:
                    feedNavigationPath = NavigationPath()
                case 3:
                    profileNavigationPath = NavigationPath()
                default:
                    break
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        }
        .onChange(of: pushRouter.pendingDestination) { _, destination in
            guard let destination else { return }
            switch destination {
            case .cityDetail(let cityId):
                // Switch to Home tab, clear the stack, then push city detail
                selectedTab = 0
                homeNavigationPath = NavigationPath()
                Task { @MainActor in
                    // Brief pause lets the tab switch settle before pushing
                    try? await Task.sleep(for: .milliseconds(50))
                    homeNavigationPath.append(DeepLinkCityTarget(cityId: cityId))
                }
            case .postDetail(let userCityId):
                // Switch to Feed tab, then fetch + push post detail
                selectedTab = 2
                feedNavigationPath = NavigationPath()
                Task {
                    if let post = try? await DatabaseManager.shared.getFeedPost(userCityId: Int64(userCityId)) {
                        try? await Task.sleep(for: .milliseconds(50))
                        await MainActor.run { feedNavigationPath.append(post) }
                    }
                }
            case .userProfile(let userId):
                // Switch to Feed tab and push the actor's profile
                selectedTab = 2
                feedNavigationPath = NavigationPath()
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(50))
                    feedNavigationPath.append(DeepLinkUserTarget(userId: userId))
                }
            }
            pushRouter.pendingDestination = nil
        }
        .toast(isPresented: $showOfflineToast, message: "This feature is unavailable offline")
    }

    @ViewBuilder
    private var profileTabItem: some View {
        if let img = profileTabImage {
            Label(title: { Text("Profile") }, icon: { Image(uiImage: img) })
        } else {
            Label("Profile", systemImage: "person.fill")
        }
    }

    private func loadProfileTabImage() async {
        guard let path = viewModel.currentUserAvatarURL, !path.isEmpty else {
            profileTabImage = nil
            return
        }
        guard let raw = await AvatarCache.shared.image(for: path) else {
            profileTabImage = nil
            return
        }
        profileTabImage = makeCircularTabImage(raw).withRenderingMode(.alwaysOriginal)
    }

    private func makeCircularTabImage(_ image: UIImage) -> UIImage {
        let size: CGFloat = 26
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
            UIBezierPath(ovalIn: rect).addClip()
            image.draw(in: rect)
        }
    }
}

//#Preview {
//    let preview = PreviewContainer([City.self])
//    return HomeView().modelContainer(preview.container)
//}
