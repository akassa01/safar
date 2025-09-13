# Safar (iOS)

Safar is an iOS app for discovering, tracking, and ranking cities you’ve visited, maintaining a bucket list of places you want to go, and saving interesting places (restaurants, hotels, activities, shops) per city. It uses Supabase for authentication and data persistence.

## Features

- **Cities**
  - Search global cities via Supabase `cities`
  - Add to your list as Visited or Bucket List (`user_city`)
  - Rank visited cities (0.0–10.0) and add notes
  - Smart rating adjustments when deleting cities (keeps scale intact)
- **Places**
  - Add user places per city (`user_place`) via Apple Maps search
  - Store name, coords, category, liked (thumbs up/down/neutral)
  - View grouped by category and manage like/unlike/delete
- **Maps**
  - Full-screen map of your cities with colored circle markers
  - City detail map with city center and place markers (circles)
- **Media**
  - Add photos when adding a city (local-only for now)

## Tech Stack

- SwiftUI + MapKit
- Supabase (Auth + PostgREST)
- iOS 17+ (MapKit Annotation API; earlier may need tweaks)

## Project Structure

- `Safar/App/*` — Screens and main navigation
  - `HomeView.swift`, `SearchMainView.swift`, `CityDetailView.swift`, `AddCityView.swift`, `FullScreenMapView.swift`, etc.
- `Safar/Components/*` — Reusable UI
  - Add City sections, Place search/list rows, City detail components
- `Safar/Data/*` — Data layer and models
  - `Supabase.swift` — Supabase client
  - `DatabaseManager.swift` — All Supabase queries/mutations
  - `UserCitiesViewModel.swift` — Cities data lifecycle for current user
  - `CityPlacesViewModel.swift` — Places per city for current user
  - `Place.swift`, `Models.swift` — Codable models

## Data Model (Supabase)

The app expects these tables (simplified):

- `cities(id, display_name, plain_name, admin, country, country_id, population, latitude, longitude, created_at)`
- `countries(id, name, country_code, capital, continent, population)`
- `user_city(id, user_id, city_id, visited, rating, notes, created_at)`
- `user_place(id, user_id, city_id, name, latitude, longitude, category, liked, created_at)`

Notes:
- `rating` is `real` (0–10). The UI commonly shows 1.0–10.0 for visited.
- `liked` for places is nullable boolean: `true`, `false`, or `null` (no rating).

## Supabase Setup

1. Open `Safar/Data/Supabase.swift` and set your project URL and anon API key:
```swift
let supabase = SupabaseClient(
  supabaseURL: URL(string: "https://YOUR-PROJECT.supabase.co")!,
  supabaseKey: "YOUR_ANON_PUBLIC_KEY"
)
```
2. Ensure Row Level Security (RLS) allows the current user to read and write:
   - `user_city`: user can insert/select/update/delete rows where `user_id = auth.uid()`
   - `user_place`: same as above
   - `cities` / `countries`: readable for all (or as you prefer)
3. Optional: Seed `cities`/`countries` as needed.

Security reminder: never embed service role keys in the app.

## Building & Running

1. Requirements
   - Xcode 15+/16+
   - iOS 17+ simulator or device
2. Open `Safar.xcodeproj` in Xcode.
3. Select the `safar` scheme and run (⌘R).

If authentication is required in parts of the app, make sure you are logged in via Supabase Auth before testing user operations.

## How Things Work

### DatabaseManager

Centralized API for Supabase queries/mutations:
- **Cities**
  - `searchCities(query:)`, `searchCountries(query:)`
  - `getCountriesByIds(_:)`
  - `getCityById(cityId:)`, `getCityWithUserData(cityId:userId:)`
- **User Cities**
  - `getUserCities(userId:)`
  - `addUserCity(...)`, `updateUserCity(...)`, `removeUserCity(...)`
  - Helpers: `addCityToBucketList(...)`, `markCityAsVisited(...)`, `userHasCity(...)`, `updateUserCityNotes(...)`, `updateUserCityRating(...)`
- **User Places**
  - `getUserPlaces(userId:cityId:)`
  - `insertUserPlaces(userId:cityId:places:)`
  - `updateUserPlaceLiked(placeId:liked:)` (accepts true/false/nil)
  - `deleteUserPlace(placeId:)`

### View Models

- `UserCitiesViewModel`
  - Holds visited/bucket/all user cities
  - Handles add/remove/mark visited, rating updates, and user initialization
- `CityPlacesViewModel`
  - Loads and groups places by `PlaceCategory` per city
  - Insert/like/unlike/delete places, reloading after changes

### Key Screens

- `AddCityView`
  - Search result prefilled; add notes, photos, and places via `PlaceSearchView`
  - Saves the city (visited/bucket) then inserts selected places
- `CityDetailView`
  - Loads city (with user data) and user places
  - Map with circle markers for city and categorized places
  - Sections for places (like/unlike/delete) and notes
  - On deleting a city, adjusts remaining city ratings to keep a clean scale
- `FullScreenMapView`
  - Shows all visited/bucket/all cities with color-coded circles

### Places

- `PlaceSearchView` uses MapKit to search around the city and allows selecting items with an optional liked state.
- Selected places are inserted into `user_place` after the city save in `AddCityView`.

## Maps & Markers

- All map markers are circular annotations:
  - Full-screen: visited = green, bucket list = yellow
  - City detail: city center = accent color; places = category color

## Testing (not yet implemented)

- Targets: `safarTests`, `safarUITests`
- Open Test navigator (⌘6) and run tests (⌘U)

## Troubleshooting

- “Socket is not connected”: ensure the simulator has network access and your Supabase URL/API key are correct.
- Permission/RLS errors: verify policies allow the authed user to read/write their `user_city` and `user_place` rows.
- Missing data: confirm IDs match your schema types (e.g., `city_id` is bigint in Postgres; encoded/decoded as Int in the app).

## Roadmap Ideas

- Place clustering on maps
- Place callouts and richer details
- Photo integration with Supabase storage
- Offline caching
- Onboarding, tutorial, and better sign up flow

## License

This project is proprietary. All rights reserved.
