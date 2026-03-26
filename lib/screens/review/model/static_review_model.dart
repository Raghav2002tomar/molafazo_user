// lib/screens/review/model/review_model.dart

class ReviewResponse {
  final bool status;
  final double averageRating;
  final int totalReviews;
  final List<Review> reviews;

  ReviewResponse({
    required this.status,
    required this.averageRating,
    required this.totalReviews,
    required this.reviews,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      status: json['status'] ?? false,
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      reviews: (json['reviews'] as List?)
          ?.map((e) => Review.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class Review {
  final int id;
  final int rating;
  final String review;
  final ReviewUser user;
  final List<String> images;

  Review({
    required this.id,
    required this.rating,
    required this.review,
    required this.user,
    required this.images,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    // Parse images - assuming API returns list of objects with 'image' field
    List<String> imageList = [];

    if (json['images'] != null && json['images'] is List) {
      imageList = (json['images'] as List)
          .map((e) {
        // If e is a Map, extract 'image' field
        if (e is Map) {
          return e['image']?.toString() ?? '';
        }
        // If e is already a String
        return e.toString();
      })
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return Review(
      id: json['id'] ?? 0,
      rating: json['rating'] ?? 0,
      review: json['review'] ?? '',
      user: ReviewUser.fromJson(json['user'] ?? {}),
      images: imageList,
    );
  }
}

class ReviewUser {
  final int id;
  final String name;
  final String? profilePhoto;

  ReviewUser({
    required this.id,
    required this.name,
    this.profilePhoto,
  });

  factory ReviewUser.fromJson(Map<String, dynamic> json) {
    return ReviewUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Anonymous',
      profilePhoto: json['profile_photo'],
    );
  }
}