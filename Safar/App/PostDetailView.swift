//
//  PostDetailView.swift
//  Safar
//
//  Full post detail view with larger map, expanded places, and comments
//

import SwiftUI

private struct PostUserNavItem: Hashable, Identifiable {
    let userId: String
    var id: String { userId }
}

private struct PostCityNavItem: Hashable, Identifiable {
    let cityId: Int
    var id: Int { cityId }
}

struct PostDetailView: View {
    let post: FeedPost
    var feedViewModel: FeedViewModel?
    @StateObject private var viewModel: PostDetailViewModel
    @State private var commentText = ""
    @State private var showLikesSheet = false
    @State private var selectedUserId: PostUserNavItem?
    @State private var selectedCityId: PostCityNavItem?
    @Environment(\.dismiss) private var dismiss
    private let currentUserId = DatabaseManager.shared.getCurrentUserId()

    init(post: FeedPost, feedViewModel: FeedViewModel? = nil) {
        self.post = post
        self.feedViewModel = feedViewModel
        self._viewModel = StateObject(wrappedValue: PostDetailViewModel(post: post))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                headerSection

                // Large map
                mapSection

                // Notes
                if let notes = post.notes, !notes.isEmpty {
                    notesSection(notes)
                }

                // Places (expanded, not disclosure)
                placesSection

                Divider()

                // Interaction bar with likes detail
                interactionSection

                Divider()

                // Comments section
                commentsSection
            }
            .padding()
        }
        .background(Color("Background"))
        .safeAreaInset(edge: .bottom) {
            commentInputSection
        }
        .task {
            await viewModel.loadComments()
        }
        .sheet(isPresented: $showLikesSheet) {
            likesSheet
        }
        .navigationDestination(item: $selectedUserId) { nav in
            UserProfileView(userId: nav.userId)
        }
        .navigationDestination(item: $selectedCityId) { nav in
            CityDetailView(cityId: nav.cityId)
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Button { selectedUserId = PostUserNavItem(userId: post.userId) } label: {
                AvatarImageView(
                    avatarPath: post.avatarURL,
                    size: 50,
                    placeholderIconSize: 20
                )
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Button { selectedUserId = PostUserNavItem(userId: post.userId) } label: {
                    Text(post.fullName ?? post.username ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)

                HStack(spacing: 4) {
                    Text("visited")
                        .foregroundColor(.secondary)
                    Button { selectedCityId = PostCityNavItem(cityId: post.cityId) } label: {
                        Text("\(post.cityName), \(post.cityCountry)")
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                }
                .font(.subheadline)

                if let username = post.username {
                    Text("@\(username) · \(timeAgoString(from: post.visitedAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let rating = post.rating {
                RatingCircle(rating: rating, size: 50)
            }
        }
    }

    private var mapSection: some View {
        CityMapView(
            latitude: post.cityLatitude,
            longitude: post.cityLongitude,
            places: post.places,
            height: 250,
            isInteractive: true
        )
    }

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)

            Text(notes)
                .font(.body)
                .foregroundColor(.primary)
        }
    }

    private var placesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !post.places.isEmpty {
                Text("Places")
                    .font(.headline)

                let placesByCategory = Dictionary(grouping: post.places, by: { $0.category })

                ForEach(PlaceCategory.allCases, id: \.self) { category in
                    if let categoryPlaces = placesByCategory[category], !categoryPlaces.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.systemColor)
                                Text(category.pluralDisplayName)
                                    .fontWeight(.medium)
                            }
                            .font(.subheadline)

                            ForEach(categoryPlaces, id: \.localKey) { place in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(category.systemColor)
                                        .frame(width: 8, height: 8)

                                    Text(place.name)
                                        .font(.subheadline)

                                    Spacer()

                                    if let liked = place.liked {
                                        Image(systemName: liked ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                                            .font(.caption)
                                            .foregroundColor(liked ? .green : .red)
                                    }
                                }
                                .padding(.leading, 8)
                            }
                        }
                        .padding(.bottom, 8)
                    }
                }
            }
        }
    }

    private var interactionSection: some View {
        HStack(spacing: 20) {
            // Like button
            Button {
                Task { await feedViewModel?.toggleLike(for: post) }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: currentPost.isLikedByCurrentUser ? "heart.fill" : "heart")
                        .foregroundColor(currentPost.isLikedByCurrentUser ? .red : .primary)
                    Text("\(currentPost.likeCount)")
                }
                .font(.subheadline)
            }
            .buttonStyle(.plain)

            // Likes detail button
            if currentPost.likeCount > 0 {
                Button {
                    showLikesSheet = true
                    Task { await viewModel.loadLikes() }
                } label: {
                    Text("View likes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Comment count
            HStack(spacing: 6) {
                Image(systemName: "bubble.right")
                Text("\(viewModel.comments.count)")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comments")
                .font(.headline)

            if viewModel.isLoadingComments {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else if viewModel.comments.isEmpty {
                Text("No comments yet. Be the first to comment!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical)
            } else {
                ForEach(viewModel.comments) { comment in
                    CommentRow(
                        comment: comment,
                        canDelete: viewModel.canDeleteComment(comment),
                        onDelete: {
                            Task {
                                await viewModel.deleteComment(comment)
                                feedViewModel?.updateCommentCount(for: post.id, delta: -1)
                            }
                        }
                    )

                    if comment.id != viewModel.comments.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private var commentInputSection: some View {
        VStack(spacing: 0) {
            Divider()
            CommentInputView(
                text: $commentText,
                isLoading: viewModel.isAddingComment,
                onSubmit: {
                    Task {
                        let success = await viewModel.addComment(content: commentText)
                        if success {
                            commentText = ""
                            feedViewModel?.updateCommentCount(for: post.id, delta: 1)
                        }
                    }
                }
            )
            .padding()
            .background(Color("Background"))
        }
    }

    private var likesSheet: some View {
        NavigationStack {
            Group {
                if viewModel.isLoadingLikes {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.likes.isEmpty {
                    Text("No likes yet")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.likes) { like in
                        HStack(spacing: 12) {
                            AvatarImageView(
                                avatarPath: like.avatarURL,
                                size: 40,
                                placeholderIconSize: 16
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(like.fullName ?? like.username ?? "Unknown")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                if let username = like.username {
                                    Text("@\(username)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Likes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showLikesSheet = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Helpers

    /// Get the current state of the post from the feed viewmodel (for like updates)
    private var currentPost: FeedPost {
        feedViewModel?.posts.first(where: { $0.id == post.id }) ?? post
    }

    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        PostDetailView(
            post: FeedPost(
                id: 1,
                userId: "123",
                cityId: 1,
                cityName: "Tokyo",
                cityAdmin: "Tokyo",
                cityCountry: "Japan",
                cityLatitude: 35.6762,
                cityLongitude: 139.6503,
                rating: 9.2,
                notes: "Absolutely loved Tokyo! The food was incredible and the culture was fascinating.",
                visitedAt: Date().addingTimeInterval(-86400)
            ),
            feedViewModel: FeedViewModel()
        )
    }
}
