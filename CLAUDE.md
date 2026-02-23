# CLAUDE.md - Safar Project Guide

## Project Overview

Safar is an iOS social travel tracking and discovery app. Users discover, visit, and rank cities globally; maintain bucket lists; save places (restaurants, hotels, activities, shops, nightlife, etc.) within cities; view interactive maps; and connect with other travelers through a social feed with follows, likes, and comments.

## Tech Stack

- **Language**: Swift 5.0
- **UI**: SwiftUI (iOS 18.5+ minimum)
- **Maps**: MapKit
- **Backend**: Supabase (Auth, PostgREST, Storage)
- **Auth**: Email/password + Sign in with Apple
- **Local Storage**: SQLite (via CityCacheManager)
- **IDE**: Xcode 15+

## Project Structure

```
/Safar/
├── App/                    # Screen views and navigation
│   ├── safarApp.swift     # App entry point (@main)
│   ├── AppView.swift      # Root view routing
│   ├── LoadingView.swift  # Auth check and splash
│   ├── AuthView.swift     # Login/signup (email + Apple)
│   ├── HomeView.swift     # Main dashboard (tab container)
│   ├── YourCitiesView.swift   # Personal city list
│   ├── ExploreView.swift      # Leaderboards & discovery
│   ├── FeedView.swift         # Social activity feed
│   ├── PostDetailView.swift   # Trip post with comments
│   ├── SearchMainView.swift   # Global search (cities/countries/people)
│   ├── CityDetailView.swift   # City info, map, places, notes
│   ├── AddCityView.swift      # Add city workflow
│   ├── UserProfileView.swift  # User profile
│   ├── EditProfileView.swift  # Edit avatar, username, bio
│   ├── FullScreenMapView.swift # Expandable world map
│   └── ...                # Leaderboard, onboarding, follow list views
├── Components/            # Reusable UI components
│   ├── Home/             # Home screen components
│   ├── AddCity/          # Add city workflow
│   ├── CityDetail/       # City detail components
│   ├── CityRanking/      # Rating/comparison UI
│   ├── Feed/             # Feed post cards and comment rows
│   └── Explore/          # Leaderboard rows
├── Data/                  # Data layer
│   ├── Supabase.swift    # Supabase client init
│   ├── DatabaseManager.swift  # Central DB operations
│   ├── UserCitiesViewModel.swift
│   ├── CityPlacesViewModel.swift
│   ├── FeedViewModel.swift
│   ├── LeaderboardViewModel.swift
│   ├── UserProfileViewModel.swift
│   ├── PostDetailViewModel.swift
│   └── Models (Place.swift, Photo.swift, etc.)
└── Info.plist
```

## Build & Run

1. Open `Safar.xcodeproj` in Xcode
2. Select the `safar` scheme
3. Run with `Cmd+R`

Supabase credentials are configured in `/Safar/Data/Supabase.swift`.

## Architecture Patterns

### State Management (MVVM)
- `@StateObject` for ViewModel instances in views
- `@Published` properties for reactive updates
- `@MainActor` on ViewModels for thread safety
- `@State/@Binding` for local view state

### Data Layer
- **DatabaseManager.shared** - Singleton for all Supabase operations
- All async/await with `throws`
- Custom `DatabaseError` enum for error handling
- Models are `Codable` for direct Supabase JSON mapping

### Key ViewModels
- `UserCitiesViewModel` - Manages city list state (visited + bucket list)
- `CityPlacesViewModel` - Manages places per city
- `FeedViewModel` - Social feed posts with pagination
- `LeaderboardViewModel` - City, country, and traveler leaderboards
- `UserProfileViewModel` - Profile data and follow/unfollow
- `PostDetailViewModel` - Trip post detail, comments, likes

## Database Schema

**Supabase Tables:**
- `cities` - Global city data (name, country, coordinates, population)
- `countries` - Country metadata with continent
- `user_city` - User's cities with visited status, rating (0-10), notes
- `user_place` - User's saved places with category and liked status
- `profiles` - User profiles (username, fullName, avatarURL, bio)
- `follows` - Follow relationships between users
- `feed_posts` / `user_city` (social view) - Trip posts derived from visited cities
- `post_comments` - Comments on trip posts with reply threading
- `comment_likes` / `post_likes` - Like tracking for posts and comments

**PlaceCategory enum:** restaurant, hotel, activity, shop, nightlife, other

## Code Quality Rules

From `.cursorrules`:
- Max 200-300 lines per file
- Prefer simple solutions over complex ones
- Avoid code duplication
- No stubbing/mocking in production code
- Single target (no extra modules/packages)

## Common Workflows

### Adding a City
1. Search in `SearchMainView` → `AddCityView`
2. Add notes, select places by category via `PlaceSearchView` (MapKit)
3. Save creates `user_city` + `user_place` records

### City Detail
1. `CityDetailView` loads city + places
2. Map shows city center + categorized place markers
3. Edit rating, notes; manage places (like/dislike/delete/add)
4. See friends who have also visited the city

### City Rating (unlocks after 5 visited cities)
1. `CityRatingView` prompts category selection (Exceptional / Great / Good / Okay / Meh)
2. Pairwise comparisons determine precise 1–10 rating via binary search
3. All existing ratings auto-adjust to maintain consistent relative order

### Social Feed
1. Visiting a city creates a feed post visible to followers
2. `FeedView` shows posts from followed users with city map, places, rating, notes
3. Users can like/comment on posts and reply to comments in `PostDetailView`

### Onboarding
1. `AuthView` → email/password or Sign in with Apple
2. Multi-step: `FullNameView` → `UsernameView` → `ProfileSetupView` → `WelcomeView`

## Testing

Test targets exist (`safarTests`, `safarUITests`) but are currently templates.
Run tests with `Cmd+U` in Xcode.

## Key Files

- [DatabaseManager.swift](Safar/Data/DatabaseManager.swift) - All Supabase API calls
- [UserCitiesViewModel.swift](Safar/Data/UserCitiesViewModel.swift) - City state management
- [FeedViewModel.swift](Safar/Data/FeedViewModel.swift) - Social feed state
- [LeaderboardViewModel.swift](Safar/Data/LeaderboardViewModel.swift) - Leaderboard data
- [HomeView.swift](Safar/App/HomeView.swift) - Tab container and dashboard
- [CityDetailView.swift](Safar/App/CityDetailView.swift) - City details screen
- [FeedView.swift](Safar/App/FeedView.swift) - Social activity feed
- [ExploreView.swift](Safar/App/ExploreView.swift) - Leaderboards and discovery
- [UserProfileView.swift](Safar/App/UserProfileView.swift) - User profiles

## Offline Support

- `CityCacheManager` caches user cities in SQLite
- `NetworkMonitor` detects connectivity changes
- Offline banner shown on affected screens; editing/social features disabled
- Data re-syncs automatically on reconnection
