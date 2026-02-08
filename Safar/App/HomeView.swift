import SwiftUI
import MapKit

struct HomeView: View {
    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20.0, longitude: 0.0),
            span: MKCoordinateSpan(latitudeDelta: 100.0, longitudeDelta: 100.0)
        )
    )
    @State private var mapPresentation: mapType = .visited

    @State private var selectedTab: Int = 0
    @State private var isMapExpanded = false
    @State private var showSearchScreen = false
    @State private var showOfflineToast = false

    @State private var homeNavigationPath = NavigationPath()
    @State private var citiesNavigationPath = NavigationPath()
    @State private var exploreNavigationPath = NavigationPath()
    @State private var feedNavigationPath = NavigationPath()

    @EnvironmentObject var viewModel: UserCitiesViewModel
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        VStack(spacing: 0) {
            if !networkMonitor.isConnected {
                OfflineBannerView(lastSyncDate: CityCacheManager.shared.lastSyncDate)
            }

            TabView(selection: $selectedTab) {
            NavigationStack(path: $homeNavigationPath) {
                VStack {
                     TopBar()
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
                         .background(Color(.systemGray5))
                         .cornerRadius(20)
                     }
                     .buttonStyle(PlainButtonStyle())
                     .padding(.horizontal)
                     .background(Color("Background"))
                     .padding(.bottom)
                     
                    // Stat Cards
                    HStack(spacing: 12) {
                        StatCard(title: String(viewModel.visitedCitiesCount), subtitle: "Cities")
                        StatCard(title: String(viewModel.visitedCountriesCount), subtitle: "Countries")
                        StatCard(title: String(viewModel.visitedContinents.count), subtitle: "Continents")
                    }
                    .padding(.horizontal)
                    .padding(.bottom)

                    // Action Buttons
                    HStack {
                        ActionButton(title: "Add a new city", systemImage: "plus") {
                            if networkMonitor.isConnected {
                                showSearchScreen = true
                            } else {
                                showOfflineToast = true
                            }
                        }
                        Spacer()
                        ShareLink(item: "Download Safar on the App Store") {
                                HStack {
                                    Image(systemName: "paperplane")
                                    Text("Invite friends")
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 25)
                                .background(Color.accentColor)
                                .cornerRadius(20)
                                .bold(true)
                            }
                            .foregroundColor(Color.white)
                        
                    }
                    .padding(.horizontal)
                    .padding(.bottom)

                    if !showSearchScreen {
                        FullScreenMapView(isFullScreen: isMapExpanded, cameraPosition: cameraPosition, mapPresentation: $mapPresentation, viewModel: viewModel) { city in
                                homeNavigationPath.append(city)
                            }
                            .frame(height: 400)
                            .cornerRadius(20)
                            .padding(.horizontal)
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
                                    selectedTab = 1
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
                                .padding(.bottom, 16)
                            }
                    }
                    Spacer()
                
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
                .navigationDestination(for: City.self) { city in
                    CityDetailView(cityId: city.id)
                        .environmentObject(viewModel)
                }
                .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack(path: $citiesNavigationPath) {
                YourCitiesView()
            }
            .tabItem {
                Label("Your Cities", systemImage: "building.2")
            }
            .tag(1)

            NavigationStack(path: $exploreNavigationPath) {
                ExploreView()
            }
            .tabItem {
                Label("Explore", systemImage: "safari")
            }
            .tag(2)

            NavigationStack(path: $feedNavigationPath) {
                FeedView()
            }
            .tabItem {
                Label("Feed", systemImage: "airplane.departure")
            }
            .tag(3)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // If the same tab is selected again, pop to root
            if oldValue == newValue {
                switch newValue {
                case 0:
                    homeNavigationPath = NavigationPath()
                    showSearchScreen = false
                    isMapExpanded = false
                case 1:
                    citiesNavigationPath = NavigationPath()
                case 2:
                    exploreNavigationPath = NavigationPath()
                case 3:
                    feedNavigationPath = NavigationPath()
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
        .toast(isPresented: $showOfflineToast, message: "This feature is unavailable offline")
    }
}

//#Preview {
//    let preview = PreviewContainer([City.self])
//    return HomeView().modelContainer(preview.container)
//}
