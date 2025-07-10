import SwiftUI
import MapKit
import SwiftData

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
    
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<City> { $0.isVisited == true }) private var visitedCities: [City]
    
    private var visitedCountries: Set<String> {
        Set(visitedCities.compactMap { $0.country }) 
    }
    private var visitedContinents: Set<String> {
        var continents = Set<String>()
        for country in visitedCountries {
            if let continent = DatabaseManager.shared.getCountryAndContinent(forCountry: country).continent {
                continents.insert(continent)
            }
        }
        return continents
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                VStack {
                     TopBar()
                     Button(action: {
                         showSearchScreen = true
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
                        StatCard(title: String(visitedCities.count), subtitle: "Cities")
                        StatCard(title: String(visitedCountries.count), subtitle: "Countries")
                        StatCard(title: String(visitedContinents.count), subtitle: "Continents")
                    }
                    .padding(.horizontal)
                    .padding(.bottom)

                    // Action Buttons
                    HStack {
                        ActionButton(title: "Add a new city", systemImage: "plus") {
                            showSearchScreen = true;
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
                            .foregroundColor(Color("Background"))
                        
                    }
                    .padding(.horizontal)
                    .padding(.bottom)

                    ZStack {
                        if !showSearchScreen {
                            FullScreenMapView(isFullScreen: isMapExpanded, cameraPosition: cameraPosition, mapPresentation: $mapPresentation)
                                .frame(height : 400)
                                .frame(width: 360)
                                .cornerRadius(20)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        isMapExpanded.toggle()
                                    }
                                }
                        }
                       
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
                        .padding(.top, 320)
                    }
                    Spacer()
                
            }
            .background(Color("Background"))
            .fullScreenCover(isPresented: $showSearchScreen) {
                    SearchMainView()
            }
            .fullScreenCover(isPresented: $isMapExpanded) {
                FullScreenMapView(isFullScreen: isMapExpanded, cameraPosition: cameraPosition, mapPresentation: $mapPresentation)
            }
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            NavigationView {
                YourCitiesView()
            }
            .tabItem {
                Label("Your Cities", systemImage: "building.2")
            }
            .tag(1)

            NavigationView {
                ExploreView()
            }
                .tabItem {
                    Label("Explore", systemImage: "safari")
                }
            .tag(2)

            NavigationView {
                FeedView()
            }
                .tabItem {
                    Label("Feed", systemImage: "airplane.departure")
                }
            .tag(3)
        }
    }
    
}

#Preview {
    let preview = PreviewContainer([City.self])
    return HomeView().modelContainer(preview.container)
}
