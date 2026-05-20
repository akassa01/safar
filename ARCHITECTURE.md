# Safar — Codebase Architecture Reference

Generated 2026-05-19. A comprehensive reference so future sessions don't require a full codebase exploration.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | Swift 5.0 |
| UI | SwiftUI (iOS 18.5+ minimum) |
| Backend | Supabase (Auth, PostgREST, Storage) |
| Maps | MapKit |
| Local cache | SQLite via `CityCacheManager` (SQLite.swift 0.15.4) |
| Analytics | PostHog (posthog-ios 3.x, SPM) |
| Auth | Email/password + Sign in with Apple |

**SPM dependencies:** `supabase-swift` 2.5.1+, `SQLite.swift` 0.15.4+, `posthog-ios` 3.0.0+

---

## Project Structure

```
Safar/
├── App/                      # Screen views and navigation
├── Components/               # Reusable UI pieces (grouped by feature)
│   ├── AddCity/
│   ├── CityDetail/
│   ├── CityOverview/
│   ├── CityRanking/
│   ├── CountryBanner/
│   ├── Explore/
│   ├── Feed/
│   ├── Home/
│   └── Leaderboard/
├── Data/                     # ViewModels, models, services, infrastructure
└── Info.plist
```

---

## App Layer — All Screens

### Onboarding (4 steps, router: `OnboardingContainerView`)
| File | Purpose |
|------|---------|
| `FullNameView.swift` | Step 1 — collect full name |
| `UsernameView.swift` | Step 2 — pick unique username (async availability check) |
| `ProfileSetupView.swift` | Step 3 — avatar photo + bio |
| `WelcomeView.swift` | Step 4 — "You're all set", triggers `completeOnboarding()` |

### Main App (tab bar container: `HomeView.swift`)
| File | Tab | Key User Actions |
|------|-----|-----------------|
| `HomeView.swift` | 0 Home | Search bar, stat cards, map, Add City, Invite Friends |
| `YourCitiesView.swift` | 1 Cities | Visited/Bucket tab, city rows, context menu (rate/delete/visit) |
| `ExploreView.swift` | 2 Explore | Top travelers, top cities, top countries sections |
| `FeedView.swift` | 3 Feed | Paginated posts, like, tap to expand |
| `CityDetailView.swift` | — | Map, places by category, notes, rating, friends who visited |
| `AddCityView.swift` | — | Form to add city (notes, places, photos, rating) |
| `CityRatingView.swift` | — | Binary-search comparison rating modal |
| `PostDetailView.swift` | — | Expanded post, comments, likes |
| `UserProfileView.swift` | — | Own or other's profile, follow button, recent trips |
| `EditProfileView.swift` | — | Avatar, username (cooldown), bio, sign out, delete account |
| `SearchMainView.swift` | — | Full-screen search: cities / countries / people tabs |
| `LeaderboardView.swift` | — | Cities or Countries ranked list |
| `CountryDetailView.swift` | — | Country rating, rank, top cities |
| `FollowListView.swift` | — | Followers / following modal |
| `ReportView.swift` | — | Report post / comment / user |
| `FullScreenMapView.swift` | — | Expanded world map with city pins |

### Unimplemented (placeholder)
- `SettingsView.swift`
- `NotificationsView.swift`

---

## Navigation Flow

```
safarApp (@main)
├── AuthView  (not authenticated)
├── OnboardingContainerView  (authenticated, needsOnboarding)
└── HomeView  (authenticated, onboarded)
    ├── Tab 0: Home
    │   ├── fullScreenCover → SearchMainView
    │   │   ├── NavigationLink → CityDetailView
    │   │   ├── NavigationLink → CountryDetailView
    │   │   └── NavigationLink → UserProfileView
    │   ├── fullScreenCover → FullScreenMapView
    │   └── navigationDestination(City) → CityDetailView
    │       ├── sheet → CityRatingView
    │       ├── sheet → NotesEditorView
    │       ├── sheet → PlaceSearchView
    │       └── NavigationLink → UserProfileView
    ├── Tab 1: YourCitiesView
    │   └── NavigationLink → CityDetailView
    ├── Tab 2: ExploreView
    │   └── NavigationLink → LeaderboardView / CountryDetailView / UserProfileView
    └── Tab 3: FeedView
        └── NavigationLink → PostDetailView / UserProfileView / CityDetailView
            └── UserProfileView
                ├── sheet → EditProfileView
                └── sheet → FollowListView
```

---

## Data Layer — Files

| File | Role |
|------|------|
| `DatabaseManager.swift` | Singleton. All Supabase DB operations (~50 functions, 2000 lines) |
| `AuthManager.swift` | Auth state machine. Persistent listener for entire app lifetime |
| `AuthView.swift` | Sign-up / sign-in UI + logic (email + Apple) |
| `BlockManager.swift` | In-memory set of blocked user IDs; applied to feed/search/leaderboard |
| `CityCacheManager.swift` | SQLite offline cache for cities, places, countries |
| `NetworkMonitor.swift` | Connectivity singleton; drives offline banner and fallback logic |
| `Logger.swift` | `os.Logger` subsystems: data, ui, auth, network, cache |
| `AnalyticsManager.swift` | PostHog wrapper singleton |
| `Supabase.swift` | `SupabaseClient` global constant (URL + public key) |
| `UsernameValidator.swift` | Username format + availability checks (with cooldown) |

### ViewModels

| ViewModel | State It Owns | Key Async Operations |
|-----------|---------------|---------------------|
| `UserCitiesViewModel` | Visited + bucket cities, country/continent lists, profile counts | `initializeWithCurrentUser`, `loadUserData`, `markCityAsVisited`, `addCityToBucketList`, `removeCityFromList`, `updateCityRating` |
| `CityPlacesViewModel` | `placesByCategory: [PlaceCategory: [Place]]` | `loadPlaces`, `addPlaces`, `updateLiked`, `deletePlace` |
| `FeedViewModel` | Paginated `[FeedPost]`, pagination offset | `loadFeed(refresh:)`, `loadMoreIfNeeded`, `toggleLike`, `updateCommentCount`, `removePostsByUser` |
| `PostDetailViewModel` | `[PostComment]` (threaded), `[PostLike]` | `loadComments`, `loadLikes`, `addComment`, `deleteComment`, `toggleCommentLike` |
| `LeaderboardViewModel` | Top cities, countries, travelers (×2 sort) | `loadTopCities`, `loadTopCountries`, `loadTopTravelersByCities/Countries`, `refresh`, `selectContinent` |
| `UserProfileViewModel` | Profile, cities, follow state, paginated posts | `loadProfile`, `toggleFollow`, `toggleLike`, `loadRecentPosts`, `loadMorePostsIfNeeded` |
| `OnboardingViewModel` | `currentStep: OnboardingStep` (fullName→username→profile→welcome) | `saveFullName`, `saveUsername`, `saveProfile(avatarData:)`, `completeOnboarding` |
| `RecommendationsViewModel` | `[CityRecommendation]`, cached in UserDefaults | `generateRecommendations` (uses Foundation Models AI), `reload` |

### Architecture Patterns

- All ViewModels are `@MainActor` — no manual `DispatchQueue.main` needed
- `@StateObject` in views, `@EnvironmentObject` passed down from `safarApp`
- Optimistic updates in `toggleLike` (Feed, UserProfile) and `toggleFollow` — revert on error
- Offline fallback: Network → try DB → catch → `CityCacheManager` (SwiftData)
- `BlockManager.shared.filter()` applied to feed posts, comments, leaderboard, search results

---

## DatabaseManager Operations (Complete Catalog)

### Search
- `searchCities(query)` — prefix search on `plain_name`, limit 50
- `searchCitiesByDisplayName(query)` — substring on `display_name`
- `searchCountries(query)` — substring on country name
- `searchPeople(query)` — full-text on username + full_name, limit 50

### City / user_city
- `getUserCities(userId)` — all user cities with ratings and notes
- `getCityById(cityId)` — basic city row
- `getCityWithUserData(cityId, userId)` — city + user-specific data
- `userHasCity(userId, cityId)` — boolean check
- `addUserCity(userId, cityId, visited, rating, notes)` — insert
- `updateUserCity(...)` — update fields
- `markCityAsVisited(userId, cityId, rating?, notes?)` — upsert as visited
- `addCityToBucketList(userId, cityId, notes)` — insert with visited=false
- `removeUserCity(userId, cityId)` — delete
- `updateUserCityRating(userId, cityId, rating)` — rating field only
- `updateUserCityNotes(userId, cityId, notes)` — notes field only
- `getVisitedCities(userId)` — filter visited=true
- `getBucketListCities(userId)` — filter visited=false

### Places / user_place
- `getUserPlaces(userId, cityId)` — join query
- `insertUserPlaces(userId, cityId, places)` — upsert
- `updateUserPlaceLiked(userPlaceId, liked)` — true/false/nil
- `deleteUserPlace(userPlaceId)` — delete

### Social / follows
- `followUser(followingId)` — insert (prevents self-follow)
- `unfollowUser(followingId)` — delete
- `isFollowing(userId)` — boolean
- `getFollowers(userId)` / `getFollowing(userId)` — profile lists
- `getFollowCounts(userId)` — `(followers: Int, following: Int)`

### Feed / post_likes / post_comments
- `getFeedPosts(limit, offset)` — followed users' visited cities with social data
- `getUserFeedPosts(userId, limit, offset)` — same but single user
- `getPostSocialData(userCityId)` — `(likeCount, commentCount, isLiked)`
- `likePost(userCityId)` / `unlikePost(userCityId)`
- `getPostLikes(userCityId)` — liker profiles
- `getPostComments(userCityId)` — threaded (replies nested client-side)
- `addComment(userCityId, content, parentCommentId?)` — returns new `PostComment`
- `deleteComment(commentId)`
- `likeComment(commentId)` / `unlikeComment(commentId)`
- `getCommentLikeCounts(commentIds)` / `getUserCommentLikeStatus(commentIds, userId)`

### Profiles
- `getUserProfile(userId)` — full profile with stats
- `getVisitedCitiesForUser(userId)` / `getBucketListCitiesForUser(userId)`
- `getContinentsCountForUser(userId)`

### Leaderboards
- `getTopRatedCities(limit, offset)` — global
- `getTopRatedCitiesByContinent(continent, limit)` — filtered
- `getTopRatedCountries(limit, offset, continent?)` — global or filtered
- `getTopCitiesForCountry(countryName, limit)`
- `getTopTravelersByCities(limit, offset)` — ordered by visited city count
- `getTopTravelersByCountries(limit, offset)` — ordered by visited country count

### Blocking / Reporting / Onboarding
- `getBlockedUserIds()` / `blockUser(blockedId)` / `unblockUser(blockedId)`
- `submitReport(type, targetId, reason, details?)`
- `getFriendsWhoVisitedCity(cityId, userId)`
- `checkOnboardingCompleted(userId)` / `markOnboardingCompleted(userId)`
- `acceptTerms()`
- `getCountryAndContinent(forCountry)` / `getCountriesByIds(ids)`

---

## Data Models

### City
```
id: Int, displayName: String, plainName: String, admin: String
country: String, countryId: Int64, population: Int
latitude: Double, longitude: Double
visited: Bool?, rating: Double?, notes: String?
averageRating: Double?, ratingCount: Int?
```

### FeedPost
```
id: Int64 (= user_city.id, serves as post ID)
userId: String (UUID), cityId: Int, cityName: String
cityAdmin: String, cityCountry: String
cityLatitude: Double, cityLongitude: Double
rating: Double?, notes: String?, visitedAt: Date
username: String?, fullName: String?, avatarURL: String?
likeCount: Int, commentCount: Int, isLikedByCurrentUser: Bool
places: [Place]
```

### PostComment
```
id: Int64, userCityId: Int64, userId: String
content: String, createdAt: Date
parentCommentId: Int64?  // nil = top-level
username: String?, fullName: String?, avatarURL: String?
replies: [PostComment]?  // nested client-side
likeCount: Int, isLikedByCurrentUser: Bool
```

### Place
```
id: Int?, userPlaceId: Int?, name: String
latitude: Double, longitude: Double
category: PlaceCategory  // restaurant|hotel|activity|shop|nightlife|other
cityId: Int?, likes: Int, userId: UUID?, liked: Bool?
mapKitId: String  // deduplication key
```

### UserProfile
```
id: String (UUID), username: String?, fullName: String?
avatarURL: String?, bio: String?
visitedCitiesCount: Int?, visitedCountriesCount: Int?
onboardingCompleted: Bool?
```

### Leaderboard entries
- `CityLeaderboardEntry`: id, displayName, admin, country, averageRating, ratingCount, rank
- `CountryLeaderboardEntry`: id, name, continent, averageRating, rank
- `PeopleLeaderboardEntry`: id, username, fullName, avatarURL, visitedCitiesCount, visitedCountriesCount, rank

---

## Database Schema (Supabase)

| Table | Purpose |
|-------|---------|
| `cities` | Global city data |
| `countries` | Country + continent |
| `user_city` | User's cities (visited/bucket, rating, notes, visitedAt) |
| `user_place` | User's saved places (linked to places table) |
| `places` | Global place data |
| `profiles` | User profiles (username, fullName, avatarURL, bio, counts) |
| `follows` | Follow relationships |
| `post_likes` | Likes on visited-city posts (user_city rows) |
| `post_comments` | Comments with optional parentCommentId for threading |
| `comment_likes` | Likes on comments |
| `user_blocks` | Block relationships |
| `content_reports` | User-submitted reports |

---

## Key Journey Milestones

| Milestone | Code Path |
|-----------|-----------|
| Fresh install | `hasLaunchedBefore` UserDefaults check → sign out stale Keychain session |
| Sign up (email) | `AuthView.signUpButtonTapped()` → `supabase.auth.signUp()` → auth listener `.signedIn` → `checkOnboardingStatus` → `needsOnboarding = true` |
| Sign up (Apple) | `handleSignInWithApple()` → `signInWithIdToken()` → same auth listener path |
| Onboarding | `OnboardingContainerView` → 4 steps via `OnboardingViewModel` → `completeOnboarding()` sets flag in DB + UserDefaults |
| First city added | `SearchMainView` → `AddCityView` → `markCityAsVisited()` or `addCityToBucketList()` in `UserCitiesViewModel` |
| City rated | `CityRatingView` → binary search comparisons → `updateCityRating()` in `UserCitiesViewModel` |
| Feed post created | Implicit — any visited city row in `user_city` appears in followed users' feeds |
| Sign out | `AuthManager.signOut()` → clears SQLite cache + UserDefaults → `supabase.auth.signOut()` → listener `.signedOut` |

---

## Secrets & Configuration

| Key | Location |
|-----|---------|
| Supabase URL + anon key | Hardcoded in `Safar/Data/Supabase.swift` |
| Unsplash API key | `Secrets.xcconfig` → `Info.plist` → `Bundle.main.infoDictionary["UNSPLASH_ACCESS_KEY"]` |
| PostHog API key | `Secrets.xcconfig` → `Info.plist` → `AnalyticsManager.configure()` |

Custom URL scheme: `safar://` (for auth callbacks, deep links).

---

## Analytics Events (PostHog)

All calls go through `AnalyticsManager.shared.capture(event, properties:)`.

### Auth & Lifecycle
| Event | Properties | Source |
|-------|-----------|--------|
| `user_signed_up` | `method: email\|apple` | `AuthView` |
| `user_signed_in` | `method: email\|apple` | `AuthManager` listener |
| `user_signed_out` | — | `AuthManager` listener |
| `account_deleted` | — | `AuthManager.deleteAccount()` |
| `onboarding_step_completed` | `step: full_name\|username\|profile\|welcome` | `OnboardingViewModel` |
| `onboarding_completed` | — | `OnboardingViewModel.completeOnboarding()` |

### Cities
| Event | Properties | Source |
|-------|-----------|--------|
| `city_added` | `city_id`, `city_name`, `country`, `visited`, `has_notes`, `places_count`, `has_rating` | `UserCitiesViewModel` |
| `city_removed` | `city_id`, `city_name`, `was_visited` | `UserCitiesViewModel.removeCityFromList()` |
| `city_rating_set` | `city_id`, `rating`, `cities_count` | `UserCitiesViewModel.updateCityRating()` |

### Places
| Event | Properties | Source |
|-------|-----------|--------|
| `place_added` | `category`, `city_id`, `places_added_count` | `CityPlacesViewModel.addPlaces()` |
| `place_removed` | `category`, `city_id` | `CityPlacesViewModel.deletePlace()` |
| `place_liked` | `category`, `city_id`, `liked` | `CityPlacesViewModel.updateLiked()` |

### Social
| Event | Properties | Source |
|-------|-----------|--------|
| `post_liked` | `post_id`, `author_id` | `FeedViewModel`, `UserProfileViewModel` |
| `post_unliked` | `post_id` | `FeedViewModel`, `UserProfileViewModel` |
| `comment_added` | `post_id`, `is_reply` | `PostDetailViewModel.addComment()` |
| `comment_deleted` | `post_id` | `PostDetailViewModel.deleteComment()` |
| `comment_liked` | `comment_id` | `PostDetailViewModel.toggleCommentLike()` |
| `user_followed` | `followed_user_id` | `UserProfileViewModel.toggleFollow()` |
| `user_unfollowed` | `unfollowed_user_id` | `UserProfileViewModel.toggleFollow()` |
| `user_blocked` | — | `BlockManager.blockUser()` |

### Discovery & Navigation
| Event | Properties | Source |
|-------|-----------|--------|
| `tab_selected` | `tab: home\|cities\|explore\|feed` | `HomeView` onChange |
| `search_performed` | `category`, `query_length`, `results_count` | `SearchMainView.executeSearch()` |
| `leaderboard_viewed` | `tab: cities\|countries`, `continent_filter` | `LeaderboardViewModel` |
| `feed_refreshed` | — | `FeedViewModel.loadFeed(refresh: true)` |
| `feed_page_loaded` | `page`, `posts_count` | `FeedViewModel.loadMoreIfNeeded()` |

---

## Offline Support

- `NetworkMonitor.shared.isConnected` checked before every DB call
- On failure: `CityCacheManager.shared` (SwiftData, per-user) provides cities, places, countries
- `isOfflineData: Bool` flag on `UserCitiesViewModel` and `CityPlacesViewModel` drives offline banner
- `OfflineBannerView` shows last sync date; editing and social features disabled while offline
- `BlockManager` and `AuthManager` state both survive offline (in-memory / UserDefaults / Keychain)

---

## Component Quick Reference

| Component | Purpose |
|-----------|---------|
| `FeedPostCard` | Compact post in feed list |
| `FeedInteractionBar` | Like/comment bar + report/block menu |
| `CommentRow` | Single comment with threading, likes, context menu |
| `CityMapView` | Embedded map with category-colored place pins |
| `CityRatingView` | Modal: category → pairwise comparison → numeric rating |
| `PlaceSearchView` | MapKit place search modal used in AddCity + CityDetail |
| `RatingCircle` | Color-coded numeric rating circle |
| `FriendsWhoVisitedSection` | Avatar carousel of followers who visited a city |
| `LeaderboardPersonRow` / `CityRow` / `CountryRow` | Leaderboard list entries |
| `OfflineBannerView` | Pinned top banner with last sync date |
| `ToastView` | Ephemeral dismissible overlay message |
