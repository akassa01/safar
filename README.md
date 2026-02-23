# Safar (iOS)

Safar is a social iOS travel app for discovering, tracking, and ranking cities you've visited. Users maintain a bucket list, save memorable places per city, rate destinations through an intelligent comparison engine, and connect with fellow travelers via a social feed.

## Features

### City Tracking
- Search a global city database and add cities as Visited or Bucket List (`user_city`)
- View stats: cities, countries, and continents visited
- Interactive world map shows all your cities with color-coded markers
- Toggle map between Visited and Bucket List view

### Smart City Ratings
- Rating unlocks after visiting 5 cities (0.0–10.0 scale)
- Pairwise comparison flow: pick a category (Exceptional → Meh), then compare head-to-head with existing cities using binary search to land a precise rating
- All ratings auto-adjust when cities are added or removed to maintain consistent relative order
- Community average rating shown once a city has 5+ user ratings

### Places & Notes
- Save places per city via Apple Maps search (`user_place`): restaurants, hotels, activities, shops, nightlife, and other
- Rate each place: thumbs up / thumbs down / neutral
- Add trip notes per city
- City detail map shows city center and all saved places with category-colored markers

### Explore & Leaderboards
- Top-rated cities and countries by community average (min 5 ratings to appear)
- Top travelers ranked by cities or countries visited
- Leaderboard rows link to city/country/profile detail views

### Social Feed
- Visiting a city creates a trip post visible to your followers
- Feed shows posts from followed users: city map, places, rating, notes, timestamp
- Like posts and write comments (with reply threading)
- Like individual comments
- "Friends who visited" section in city detail shows which people you follow have been there
- Post detail view (`PostDetailView`) with full comments section

### User Profiles
- Sign up with email/password or Sign in with Apple
- Multi-step onboarding: full name → username → avatar
- Profile: avatar (Supabase Storage), bio, username (30-day change cooldown)
- Follow / unfollow users
- View any user's visited cities and bucket list; recent trips visible to followers only
- Followers and following lists

### Offline Support
- City list cached locally via SQLite (`CityCacheManager`)
- Offline banner + last sync date shown in app
- Editing and social features disabled offline; read-only browsing available
- Auto-sync on reconnection (via `NetworkMonitor`)

## Tech Stack

- SwiftUI + MapKit (iOS 18.5+)
- Supabase (Auth, PostgREST, Storage)
- Sign in with Apple
- SQLite (offline cache)

## Project Structure

```
Safar/
├── App/                        # Screens and main navigation
│   ├── safarApp.swift         # App entry point (@main)
│   ├── AppView.swift          # Root routing
│   ├── LoadingView.swift      # Auth check / splash
│   ├── AuthView.swift         # Login / signup
│   ├── HomeView.swift         # Tab container + dashboard
│   ├── YourCitiesView.swift   # Personal city list
│   ├── ExploreView.swift      # Leaderboards & discovery
│   ├── FeedView.swift         # Social feed
│   ├── PostDetailView.swift   # Trip post + comments
│   ├── SearchMainView.swift   # Global search (cities / countries / people)
│   ├── CityDetailView.swift   # City detail: map, places, notes
│   ├── AddCityView.swift      # Add city workflow
│   ├── UserProfileView.swift  # User profile
│   ├── EditProfileView.swift  # Edit avatar, username, bio
│   ├── FullScreenMapView.swift # Expandable world map
│   └── ...                    # Onboarding, leaderboard, follow list views
├── Components/                 # Reusable UI
│   ├── Home/                  # Dashboard components
│   ├── AddCity/               # Add city sections + PlaceSearchView
│   ├── CityDetail/            # CityBannerView, CityMapView, place rows
│   ├── CityRanking/           # CityRatingView (pairwise comparison)
│   ├── Feed/                  # FeedPostCard, comment rows
│   └── Explore/               # Leaderboard rows
└── Data/                       # Data layer and models
    ├── Supabase.swift          # Supabase client
    ├── DatabaseManager.swift   # All Supabase queries / mutations
    ├── UserCitiesViewModel.swift
    ├── CityPlacesViewModel.swift
    ├── FeedViewModel.swift
    ├── LeaderboardViewModel.swift
    ├── UserProfileViewModel.swift
    ├── PostDetailViewModel.swift
    ├── CityCacheManager.swift  # SQLite offline cache
    ├── NetworkMonitor.swift    # Connectivity detection
    └── Place.swift, Models.swift, ...
```

## Data Model (Supabase)

```
cities(id, display_name, plain_name, admin, country, country_id, population, latitude, longitude)
countries(id, name, country_code, capital, continent, population)
user_city(id, user_id, city_id, visited, rating, notes, created_at)
user_place(id, user_id, city_id, name, latitude, longitude, category, liked, created_at)
profiles(id, username, full_name, avatar_url, bio, onboarding_completed)
follows(follower_id, following_id, created_at)
post_comments(id, user_city_id, user_id, content, parent_comment_id, created_at)
post_likes(user_id, user_city_id)
comment_likes(user_id, comment_id)
```

Notes:
- `rating` is `real` (0–10). UI shows 1.0–10.0 for visited cities.
- `liked` for places is nullable boolean: `true`, `false`, or `null`.
- `category` for places: `restaurant`, `hotel`, `activity`, `shop`, `nightlife`, `other`.
- Social posts are derived from `user_city` rows (visited = true).

## Supabase Setup

1. Open `Safar/Data/Supabase.swift` and set your project URL and anon key:
```swift
let supabase = SupabaseClient(
  supabaseURL: URL(string: "https://YOUR-PROJECT.supabase.co")!,
  supabaseKey: "YOUR_ANON_PUBLIC_KEY"
)
```
2. Enable Row Level Security (RLS):
   - `user_city`, `user_place`: user can read/write rows where `user_id = auth.uid()`
   - `profiles`: public read, own-row write
   - `follows`, `post_comments`, `post_likes`, `comment_likes`: auth-based policies
   - `cities`, `countries`: readable by all
3. Configure Supabase Storage bucket for avatar uploads.

Security reminder: never embed service role keys in the app.

## Building & Running

1. Xcode 15+ and an iOS 18.5+ simulator or device
2. Open `Safar.xcodeproj`
3. Select the `safar` scheme and run (Cmd+R)

## How Things Work

### DatabaseManager

Centralized Supabase API layer:
- **Cities**: `searchCities`, `searchCountries`, `getCityById`, `getCityWithUserData`
- **User Cities**: `getUserCities`, `addUserCity`, `updateUserCity`, `removeUserCity`, `markCityAsVisited`, `addCityToBucketList`, `updateUserCityRating`, `updateUserCityNotes`
- **User Places**: `getUserPlaces`, `insertUserPlaces`, `updateUserPlaceLiked`, `deleteUserPlace`
- **Feed**: fetch posts from followed users, paginated
- **Comments**: fetch, insert, delete comments and replies; like/unlike
- **Leaderboards**: top cities, countries, travelers
- **Profiles**: fetch profile, update username/bio/avatar, follow/unfollow, search users

### City Rating Logic (`CityRatingView`)

- **First 5 cities**: simple category selection (Exceptional/Great/Good/Okay/Meh) + pairwise comparisons within the category range to determine unique ordering
- **5+ cities**: category selection → binary search comparisons → precise rating using lower/upper bounds
- After rating, all existing ratings are rescaled so the highest is 10.0 and a minimum gap of 0.2 is maintained between adjacent ratings
- "Can't Choose" option handles ties gracefully

### Key Screens

- `AddCityView` — Search-prefilled; add notes and places via `PlaceSearchView` (MapKit); saves city then inserts places
- `CityDetailView` — City banner (name, rating, community stats), interactive map, categorized places (like/unlike/add/delete), notes, friends who visited
- `FeedView` — Paginated feed of trip posts from followed users; pull-to-refresh and infinite scroll
- `PostDetailView` — Full trip post with map, places, notes, rating; threaded comments with likes
- `ExploreView` — Top 5 preview sections linking to full leaderboard views
- `UserProfileView` — Profile header, follow button, recent trips (followers only); navigates to `EditProfileView`
- `FullScreenMapView` — Expandable world map from home; toggles visited/bucket list; tapping a marker opens city detail

### Offline Cache

`CityCacheManager` stores user cities in SQLite. `NetworkMonitor` publishes connectivity changes. When offline, the app shows a banner, disables editing and social actions, and resumes syncing on reconnect.

## Maps & Markers

- World map: visited = green, bucket list = yellow circle markers
- City detail map: city center = accent color; places = per-category color

## Testing

Targets exist (`safarTests`, `safarUITests`) but are currently templates.
Run tests with Cmd+U in Xcode.

## Troubleshooting

- "Socket is not connected": check simulator network and your Supabase URL/key.
- RLS errors: verify policies allow the authed user to read/write their rows.
- Missing data: confirm ID types match (e.g., `city_id` is bigint in Postgres; decoded as `Int` in Swift).

## License

This project is proprietary. All rights reserved.
