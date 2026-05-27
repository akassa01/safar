# Safar Transformation Plan
## From Ranking App → Travel Diary with Social Layer

**Goal:** Remove city ratings entirely, reduce friction of adding cities, strengthen social features, and restructure navigation to reflect the new model.

---

## Phase 1 — Rating System Removal & Dead Code Cleanup

This is the foundation. Everything else builds on a clean codebase.

### Files to delete entirely
- `Safar/App/CityRatingView.swift` — the full rating/comparison/categorization flow (~620 lines)
- `Safar/Components/CityRanking/CategoryCard.swift`
- `Safar/Components/CityRanking/CityCategory.swift` — `CityCategory` enum, `ratingRange`, `baseRating`
- `Safar/Components/CityRanking/CityComparisonCard.swift`
- `Safar/Components/CityDetail/PlaceRatingSection.swift` — confirm usage in `CityDetailView` first

### Files to partially clean

**`Safar/Components/RatingCircle.swift`**
- Delete `RatingCircle` struct entirely
- Audit `CommunityRatingCircle` — only keep if community visit-count badge replaces it; otherwise delete the whole file

**`Safar/Components/CityListMember.swift`**
- Remove `index: Int` parameter and the numbered rank display (`Text(String(index + 1))`)
- Remove `locked: Bool` parameter and the `lock.circle.fill` / `RatingCircle` conditional block
- Result: a simple row with city name + subtitle only

**`Safar/Components/Feed/FeedPostHeader.swift`**
- Remove the `RatingCircle` badge block (lines 71–73: the `if authorVisitedCitiesCount >= 5, let rating = post.rating` guard)
- The space it occupied is where the bookmark button will eventually live (Phase 6)

**`Safar/Data/UserCitiesViewModel.swift`**
- Delete `updateCityRating(cityId:rating:)` (line 280)
- Delete `updateCityRatingWithoutRefresh(cityId:rating:)` (line 291)
- Remove `CityRatingUpdate` struct usage (check if defined in DatabaseManager or Models)
- Remove `has_rating` analytics property from `markCityAsVisited` (line 244)
- Remove `city_rating_set` analytics event

**`Safar/App/AddCityView.swift`**
- Remove `@State private var showingRating`, `selectedRating`
- Remove the `RatingSection` form row (lines 65–71)
- Remove the `.sheet(isPresented: $showingRating)` block (lines 84–97) — CityRatingView sheet
- Remove `rating: selectedRating` from `markCityAsVisited` call
- Note: `saveCity()` no longer triggers on rating selection; it saves immediately on the Save button

**`Safar/Components/AddCity/AddCitySections.swift`**
- Delete `RatingSection` view

**`Safar/App/YourCitiesView.swift`**
- Remove `@State private var showingRatingSheet`, `cityToRate`
- Remove `.sorted(by: { $0.rating ?? 0 > $1.rating ?? 0 })` from `currentCities` — replace with alphabetical sort (Phase 4)
- Remove the `.sheet(isPresented: $showingRatingSheet)` CityRatingView sheet block
- Remove "Change Rating" context menu item
- Remove the lock state banner at the bottom (`if selectedTab == .visited && viewModel.visitedCities.count < 5`)

**`Safar/App/ExploreView.swift`**
- Change section title "Top Rated Cities" → "Most Visited Cities"
- Change subtitle "Based on community ratings" → "Based on visit count"
- Change section title "Top Rated Countries" → "Most Visited Countries"
- Change subtitle "Based on city averages" → "Based on visit count"
- (Leaderboard data source changes happen in Phase 5)

**`Safar/Data/LeaderboardModels.swift`**
- `CityLeaderboardEntry`: replace `averageRating: Double` and `ratingCount: Int` with `visitCount: Int`
- `CountryLeaderboardEntry`: replace `averageRating: Double` with `visitCount: Int`
- Update `CodingKeys` to match new Supabase columns/views

**`Safar/Data/LeaderboardViewModel.swift`**
- Replace `getTopRatedCities` / `getTopRatedCitiesByContinent` calls with `getMostVisitedCities`
- Replace `getTopRatedCountries` call with `getMostVisitedCountries`
- Country filter will expand beyond continent to include specific country (Phase 5)

**`Safar/Data/DatabaseManager.swift`**
- Remove `updateCityRating(_:)` function
- Remove `getTopRatedCities(limit:)` and `getTopRatedCitiesByContinent(continent:limit:)`
- Remove `getTopRatedCountries(limit:continent:)`
- Add `getMostVisitedCities(limit:continent:country:)` — queries a view/function counting unique user visits
- Add `getMostVisitedCountries(limit:continent:)` — same, aggregated by country
- Add `getFriendVisitCount(cityId:userId:)` — returns count of followed users who have visited a city (needed for Phase 4 and Phase 7)

**`Safar/Data/FeedModels.swift`** (check this file)
- Remove `rating` field from `FeedPost` model, or make it fully optional and stop rendering it

**`Safar/Components/CityDetail/DetailDisplays.swift`**
- Remove `CommunityRatingBadge` view if no longer used after rating removal
- Confirm `CommunityRatingCircle` in `RatingCircle.swift` is also unused

**`Safar/App/HomeView.swift`**
- Update ShareLink message text: `"Check out Safar – track and rank every city you visit!"` → `"Check out Safar – track every city you visit and share your travels!"`

### Supabase
- The `rating` column in `user_city` can be left in place (schema changes are risky); just stop writing to it
- Create or update DB views/functions for most-visited city and country rankings (these replace the rating-based RPC calls)
- New notification types needed: `bucket_list_friend_visit`, `post_bookmarked` (add to `notifications` table inserts in Phase 9)

---

## Phase 2 — Navigation Restructure

Replace the 4-tab layout (Home / Your Cities / Explore / Feed) with a 4-tab layout that promotes Profile.

### `Safar/App/HomeView.swift`

**Tab bar changes:**
- Remove tab 1 (YourCities / `building.2`)
- Add Profile tab (tag 3 becomes Feed, new tag for Profile — `person.fill`)
- New tab order: Home (0), Explore (1), Feed (2), Profile (3)
- Update `tabNames` array in the `onChange(of: selectedTab)` handler
- Add `profileNavigationPath = NavigationPath()` state variable
- Add navigation stack for Profile tab pointing to `UserProfileView` for the current user

**View List button:**
- Currently sets `selectedTab = 1` (Your Cities tab) — this will break
- Change to present `YourCitiesView` as a sheet or push it onto `homeNavigationPath`
- Recommended: present as a `.sheet` to keep the map context visible underneath

**`Safar/App/UserProfileView.swift`**
- Confirm it can operate without a passed `userId` for the "my profile" case (self-view)
- If not, add a default initializer that resolves to the current authenticated user

---

## Phase 3 — New City Add Flow (Instant Add + Optional Enrichment)

The biggest UX change. Adding a visited city becomes a single tap from search results; enrichment is optional.

### `Safar/Components/SearchListMember.swift`

**Plus button behavior change (`plus.circle`):**
- Currently calls `onMarkVisited(result)` which opens `AddCityView`
- New behavior: directly call `viewModel.markCityAsVisited(cityId:)` inline (no rating, no notes, no places — bare add)
- After successful add, fire a toast: **"{City Name} added. Tap to add details."**
- Toast tap → open `AddCityView` in a sheet (passed city context)
- The toast needs to carry the city context; consider a `@State var lastAddedCity: SearchResult?` in `SearchMainView`

### `Safar/App/SearchMainView.swift`

- Add `@State private var lastAddedCity: SearchResult?` and `@State private var showAddCitySheet = false`
- After instant add succeeds, set `lastAddedCity` and trigger toast
- Toast's tap action sets `showAddCitySheet = true`
- Present `AddCityView` as `.sheet` bound to `showAddCitySheet`

### `Safar/App/AddCityView.swift` (post Phase 1)

- After rating removal, this view is: Notes + Places sections only
- Rename nav title from "Add City" to "Add Details" or "Edit {City}"
- Add a "Done" or "Save" toolbar button (currently save is gated on rating completion — remove that gate)
- `saveCity()` saves notes + places immediately without any rating step

### `Safar/Components/ToastView.swift`

- Confirm existing `ToastView` supports a tap action/callback (check implementation)
- If not, extend it to accept an optional `onTap: (() -> Void)?` closure
- Toast should persist for ~4 seconds, longer than standard if it has an action

### Bucket list cities → "Mark as Visited"

- Currently in `YourCitiesView`, context menu "Mark as Visited" opens full `AddCityView`
- Keep this flow — the sheet opens `AddCityView` in "edit/enrich" mode (notes + places, no rating)
- No change needed beyond Phase 1 cleanup

---

## Phase 4 — YourCitiesView Restructure

### `Safar/App/YourCitiesView.swift`

- Change list sort from rating-descending to alphabetical: `.sorted(by: { $0.displayName < $1.displayName })`
- Remove `.enumerated()` wrapper from the list (no longer need index for rank number)
- Pass `index: 0` as a dummy or refactor `CityListMember` to not take an index (done in Phase 1)
- Update `CityListMember` call to remove `index:` and `locked:` parameters

**Bucket List rows — friend count caption:**
- In the bucket list tab, beneath each city's subtitle, add: `"X friends have been here"`
- Requires a friend count per city; options:
  - Fetch counts in bulk when `bucketListCities` loads (preferred — one query for all bucket cities)
  - Store as `@State private var friendCounts: [Int: Int] = [:]` (cityId → count)
  - Add `loadFriendCounts()` async function that calls `DatabaseManager.getFriendVisitCount` for each bucket city (or batch version)
- Display: if count == 0, show nothing; if 1, "1 friend has been here"; if 2+, "X friends have been here"

### `Safar/Components/CityListMember.swift` (post Phase 1)

- Add optional `friendCount: Int?` parameter (only used in bucket list context)
- If `friendCount > 0`, render a caption line in accent color below the subtitle

### `Safar/Components/SearchListMember.swift`

- For cities that are in the user's bucket list, add the same friend count caption
- Alternatively: show it for all unvisited cities in search results (more discoverable)
- Same data approach: count followers who have visited this city

---

## Phase 5 — Leaderboard Pivot & Filters

### Data layer (see Phase 1 DB changes)

New Supabase views/RPCs needed:
- `most_visited_cities` — city id, name, admin, country, continent, unique visitor count
- `most_visited_countries` — country id, name, continent, unique visitor count (sum across cities)
- Both need to support filtering by continent and by specific country

### `Safar/App/LeaderboardView.swift`

**New filter system:**
- Add a filter icon button in the navigation bar (`.toolbar` placement: `.navigationBarTrailing`)
- Tapping it presents a `.sheet` (half-height, `presentationDetents([.medium])`)
- Inside the sheet:
  - **Continent picker:** horizontal chip row for the 6 continents + "All" (existing `continents` array in `LeaderboardViewModel`)
  - **Country search:** a `TextField` with `List` below showing matching countries (from a fetched country list)
  - "Apply" / "Clear" buttons or auto-apply on selection
- When a filter is active: show chips below the tab selector in the main view, each with an X to remove
  - Chip row uses `FilterChip.swift` (already exists at `Safar/Components/Leaderboard/FilterChip.swift`)

**`LeaderboardViewModel` additions:**
- Add `@Published var selectedCountry: String?`
- Add `countries: [String]` populated from a DB call (list of all countries, cached)
- Update `loadTopCities` and `loadTopCountries` to pass both continent and country filters
- Update `selectContinent` to also clear country filter (they're mutually exclusive or stackable — decide)

### `Safar/Components/Leaderboard/LeaderboardCityRow.swift`
- Replace rating display with visit count: e.g., `"12,450 visits"` or `"12K visitors"`

### `Safar/Components/Leaderboard/LeaderboardCountryRow.swift`
- Same — replace average rating with total unique visitor count

---

## Phase 6 — Feed Changes

### Bookmark button

**What "bookmark" means:** the user adds the post's city to their bucket list, sourced from a feed post. No separate bookmarks table — it reuses the existing `user_city` bucket list flow. The only new thing is the notification.

**`Safar/Components/Feed/FeedPostCard.swift`**
- Add `onBookmarkTapped: () -> Void` callback parameter
- Placement: `FeedInteractionBar` alongside like/comment (see below)

**`Safar/Components/Feed/FeedInteractionBar.swift`**
- Add bookmark icon button (`bookmark` / `bookmark.fill` for toggled state)
- Add `isBookmarked: Bool` and `onBookmarkTapped: () -> Void` parameters
- `isBookmarked` = true if the post's city is already in the current user's bucket list or visited list

**`Safar/Data/FeedModels.swift`**
- `FeedPost`: add `isCityInUserList: Bool` (derived from whether the city is already in `user_city` for the viewer — used to drive the toggled bookmark state)

**`Safar/Data/FeedViewModel.swift`**
- Add `bookmarkCityFromPost(postId: Int, cityId: Int)` — calls `viewModel.addCityToBucketList` then calls a DB function to fire the notification (see Supabase below)
- Add `unbookmarkCityFromPost(postId: Int, cityId: Int)` — calls `viewModel.removeCityFromList` then calls a DB function to delete the notification
- If city is already visited, the bookmark button shows as filled/disabled (already in list)

**`Safar/Data/DatabaseManager.swift`**
- Add `notifyPostBookmarked(actorId: UUID, postUserCityId: Int)` — calls a Supabase RPC that inserts the notification
- Add `deletePostBookmarkedNotification(actorId: UUID, postUserCityId: Int)` — calls a Supabase RPC that deletes the matching notification row

**Supabase — new migration file** (follow patterns in `supabase/migrations/20260525_notification_triggers.sql` and `20260526_notification_rich_text.sql`):
```sql
-- Function: create post_bookmarked notification
-- Called by the iOS client after adding to bucket list from a post.
-- Does NOT use a trigger (no post_bookmarks table) — called explicitly.
CREATE OR REPLACE FUNCTION notify_post_bookmarked(
    p_actor_id      uuid,
    p_user_city_id  bigint   -- the post's user_city.id
)
RETURNS void AS $$
DECLARE
    v_post_owner_id uuid;
    v_city_name     text;
BEGIN
    SELECT uc.user_id, c.name
      INTO v_post_owner_id, v_city_name
      FROM user_city uc
      JOIN cities c ON c.id = uc.city_id
     WHERE uc.id = p_user_city_id;

    IF v_post_owner_id IS NOT NULL
       AND v_post_owner_id != p_actor_id
    THEN
        INSERT INTO notifications (type, user_id, actor_id, reference_id, city_name)
        VALUES ('post_bookmarked', v_post_owner_id, p_actor_id, p_user_city_id, v_city_name)
        ON CONFLICT DO NOTHING;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: delete post_bookmarked notification (on unbookmark)
CREATE OR REPLACE FUNCTION delete_post_bookmarked_notification(
    p_actor_id      uuid,
    p_user_city_id  bigint
)
RETURNS void AS $$
BEGIN
    DELETE FROM notifications
     WHERE type       = 'post_bookmarked'
       AND actor_id   = p_actor_id
       AND reference_id = p_user_city_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```
Note: a unique partial index on `(type, user_id, actor_id, reference_id) WHERE type = 'post_bookmarked'` is needed for `ON CONFLICT DO NOTHING` — follow the `notifications_city_ranked_unique` index pattern in `20260525_notification_triggers.sql`.

### Map visibility rule

**`Safar/Components/Feed/FeedPostCard.swift`**
- Keep the map always visible — the map is the visual anchor even without places; removing it makes posts feel like plain text

### Post header — post-rating removal

**`Safar/Components/Feed/FeedPostHeader.swift`** (post Phase 1)
- The space freed by removing the `RatingCircle` badge can hold the bookmark button, or simply collapse gracefully
- No forced replacement needed — the header is cleaner without it

---

## Phase 7 — Social Surface Changes

### Share button in CityDetailView

**`Safar/App/CityDetailView.swift`**
- Add a share button to the navigation bar (`.toolbar`, placement: `.navigationBarTrailing`)
- Only show if the city is in the user's visited list (the post exists)
- Use `ShareLink` pointing to `https://apps.apple.com/app/id6759003685` with a message like: "Check out {City} on Safar!"
- Consider a deep link URL if the app supports universal links (deferred feature)

### Friends Who Visited — CityDetailView

**`Safar/Components/CityOverview/FriendsWhoVisitedSection.swift`**
- Already exists — confirm it's surfaced prominently in `CityDetailView`
- No structural changes needed; this section becomes more prominent now that ratings are gone

### Map default on Home

**`Safar/App/HomeView.swift`**
- Change `@State private var mapPresentation: mapType = .visited` to `.all`
- This shows both visited and bucket list cities by default

---

## Phase 8 — Styling Pass

All changes are cosmetic and can be batched as a single pass.

### Remove green/red thumbs
- Search codebase for `hand.thumbsup` and `hand.thumbsdown` SF Symbol names
- Replace both with the accent color treatment appropriate to context (a single heart, bookmark, or checkmark in `.accent`)
- Likely in: `Safar/Components/CityDetail/PlaceRatingSection.swift` (being deleted), `Safar/Components/PlaceRowView.swift`, possibly `Safar/App/CityDetailView.swift`

### "Places" → "Your Places"
**`Safar/App/CityDetailView.swift`**
- Find the section header for places and change label text from `"Places"` to `"Your Places"`

### Rename section headers / subtitles that mention ratings
- Any remaining `"Rate"`, `"Rating"`, `"Rank"` copy in UI strings — audit with a project-wide string search
- Key ones already covered above (Explore section headers, ShareLink message)

### `CityListMember` visual cleanup (post Phase 1)
- With the number and rating circle removed, the row may need left-padding adjustment
- Verify the city name + subtitle is visually balanced without the rank number on the left

---

## Phase 9 — Push Notifications (reference notifications.md for what has already been planned as well. feel free to override/make a different decision wehre necessary given any new context you have vs when that doc was created a few days ago)

Reference `supabase/migrations/20260525_notification_triggers.sql` and `20260526_notification_rich_text.sql` for all existing trigger/function patterns. All new notifications follow the same shape: a PL/pgSQL function + trigger (or explicit RPC call) that inserts into the `notifications` table.

Do this last — depends on Phase 6 (bookmark RPC functions exist) and Phase 4 (bucket list is the primary city state).

### Notification types to add

**`{friend} visited a city on your bucket list`**
- Pattern: DB trigger on `user_city`, same approach as `notify_city_ranked` in `20260525_notification_triggers.sql`
- Fires: `AFTER INSERT OR UPDATE OF visited ON user_city` when `NEW.visited = TRUE`
- Logic: find all followers of `NEW.user_id` who have `NEW.city_id` in their bucket list (`visited = false` in `user_city`) — insert one `bucket_list_friend_visit` notification per match
- Columns: `type = 'bucket_list_friend_visit'`, `user_id = follower`, `actor_id = NEW.user_id`, `reference_id = NEW.city_id`, `city_name` looked up from `cities`
- Needs a unique partial index `(type, user_id, actor_id, reference_id) WHERE type = 'bucket_list_friend_visit'` + `ON CONFLICT DO NOTHING` to prevent duplicates on re-saves
- Deep link: `reference_id` = city id → `CityDetailView(cityId:)`

**`{friend} bookmarked {city} from your post`**
- No trigger — fires via the explicit RPC call `notify_post_bookmarked(actor_id, user_city_id)` added in Phase 6
- Deleted via `delete_post_bookmarked_notification(actor_id, user_city_id)` on unbookmark
- Deep link: `reference_id` = post's `user_city.id` → `PostDetailView`

### iOS-side changes

**`Safar/Data/NotificationsViewModel.swift`**
- Add handling for new notification types `bucket_list_friend_visit` and `post_bookmarked`
- Ensure display text is correct (notification row copy)

**`Safar/App/NotificationsView.swift`**
- Add row rendering for new notification types
- `bucket_list_friend_visit`: "{actor} visited {city}, which is on your bucket list"
- `post_bookmarked`: "{actor} bookmarked your post about {city}"

**`Safar/App/safarApp.swift` / `AppView.swift`**
- Confirm APNs registration is set up; if not, add `UNUserNotificationCenter` request on first launch
- Handle notification deep links: route `bucket_list_friend_visit` → `CityDetailView(cityId:)`, route `post_bookmarked` → `PostDetailView`

**`Safar/Data/Models.swift`**
- Add new type string constants for the two new notification types (or handle in `NotificationsViewModel` switch)

---

## Implementation Order Summary

| Phase | Scope | Dependencies |
|-------|-------|-------------|
| 1 | Rating removal + dead code | None — start here |
| 2 | Navigation restructure | Phase 1 (YourCities cleanup) |
| 3 | Instant add city flow | Phase 1 (AddCityView cleanup) |
| 4 | YourCitiesView restructure | Phase 1, Phase 2 (tab changes) |
| 5 | Leaderboard pivot + filters | Phase 1 (new DB functions) |
| 6 | Feed bookmark feature | Phase 1 (rating removal from feed) |
| 7 | Social surface changes | Phase 6 (share button, friend counts) |
| 8 | Styling pass | Phases 1–7 complete (clean sweep) |
| 9 | Push notifications | Phase 6 (bookmark exists), Phase 4 (bucket list exists) |

---

## Out of Scope (Later Features)

- Favourite cities
- Custom lists (best food, etc.)
- City tags (#foodie, #resort) + app-wide aggregated lists
- Photo uploads (paid)
- Travel recommendations (paid)
- Trip planning / itineraries
- Best season to visit
