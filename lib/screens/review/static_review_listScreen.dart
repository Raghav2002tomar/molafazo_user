// lib/screens/review/dynamic_review_list_screen.dart

import 'package:ecom/extensions/context_extension.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'model/static_review_model.dart';

class DynamicReviewListScreen extends StatefulWidget {
  final int productId;
  final String productName;
  final String? productImage;
  final List<Review> initialReviews;
  final double averageRating;
  final int totalReviews;

  const DynamicReviewListScreen({
    super.key,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.initialReviews,
    required this.averageRating,
    required this.totalReviews,
  });

  @override
  State<DynamicReviewListScreen> createState() =>
      _DynamicReviewListScreenState();
}

class _DynamicReviewListScreenState extends State<DynamicReviewListScreen> {
  int? selectedRating;
  String sortBy = 'recent';
  bool showWithImages = false;
  bool showWithComments = false;

  late List<Review> _reviews;

  @override
  void initState() {
    super.initState();
    _reviews = widget.initialReviews;
  }

  List<Review> get filteredReviews {
    var filtered = List<Review>.from(_reviews);

    // Filter by rating
    if (selectedRating != null) {
      filtered = filtered.where((r) => r.rating == selectedRating).toList();
    }

    // Filter by images
    if (showWithImages) {
      filtered = filtered.where((r) => r.images.isNotEmpty).toList();
    }

    // Filter by comments (reviews with text)
    if (showWithComments) {
      filtered = filtered.where((r) => r.review.length > 10).toList();
    }

    // Sort
    switch (sortBy) {
      case 'rating_high':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'rating_low':
        filtered.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      default: // recent - keep original order
        break;
    }

    return filtered;
  }

  Map<int, int> get ratingCounts {
    final counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var review in _reviews) {
      counts[review.rating] = (counts[review.rating] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white : Colors.black,
            borderRadius: BorderRadius.circular(25),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.black : Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('txt_review'),
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.productName,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              icon: Icon(Icons.filter_list, color: cs.onSurface, size: 20),
              onPressed: _showFilterSheet,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Stats Header Card
              _buildStatsCard(cs, tt, isDark),

              const SizedBox(height: 20),

              // Filter Chips
              _buildFilterChips(cs, isDark),

              const SizedBox(height: 16),

              // Review Count and Sort
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filteredReviews.length} ${context.tr('reviews')}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  _buildSortButton(cs, isDark),
                ],
              ),

              const SizedBox(height: 16),

              // Reviews List
              filteredReviews.isEmpty
                  ? _buildEmptyState(cs, isDark)
                  : ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: filteredReviews.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _DynamicReviewCard(
                          review: filteredReviews[index],
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(ColorScheme cs, TextTheme tt, bool isDark) {
    final counts = ratingCounts;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Average rating
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      widget.averageRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        return Icon(
                          i < widget.averageRating.floor()
                              ? Icons.star
                              : i < widget.averageRating
                              ? Icons.star_half
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.totalReviews} ${context.tr('reviews')}',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Rating bars
              Expanded(
                flex: 3,
                child: Column(
                  children: List.generate(5, (i) {
                    final rating = 5 - i;
                    final count = counts[rating] ?? 0;
                    final percentage = widget.totalReviews > 0
                        ? count / widget.totalReviews
                        : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 30,
                            child: Row(
                              children: [
                                Text(
                                  '$rating',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.star, size: 10, color: Colors.amber),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: percentage,
                                backgroundColor: cs.surfaceVariant,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark ? Colors.white : Colors.black,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            count.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ColorScheme cs, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // All chip
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(context.tr('txt_all')),
              selected:
                  selectedRating == null &&
                  !showWithImages &&
                  !showWithComments,
              onSelected: (_) {
                setState(() {
                  selectedRating = null;
                  showWithImages = false;
                  showWithComments = false;
                });
              },
              backgroundColor: cs.surfaceVariant,
              selectedColor: isDark ? Colors.white : Colors.black,
              checkmarkColor: isDark ? Colors.black : Colors.white,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color:
                    selectedRating == null &&
                        !showWithImages &&
                        !showWithComments
                    ? (isDark ? Colors.black : Colors.white)
                    : cs.onSurface,
              ),
            ),
          ),

          // Rating chips
          ...List.generate(5, (i) {
            final rating = 5 - i;
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Icon(
                  Icons.star,
                  size: 14,
                  color: selectedRating == rating
                      ? (isDark ? Colors.black : Colors.white)
                      : Colors.amber,
                ),
                label: Text(rating.toString()),
                selected: selectedRating == rating,
                onSelected: (_) {
                  setState(() {
                    selectedRating = rating;
                    showWithImages = false;
                    showWithComments = false;
                  });
                },
                backgroundColor: cs.surfaceVariant,
                selectedColor: isDark ? Colors.white : Colors.black,
                checkmarkColor: isDark ? Colors.black : Colors.white,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selectedRating == rating
                      ? (isDark ? Colors.black : Colors.white)
                      : cs.onSurface,
                ),
              ),
            );
          }),

          // With photos chip
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(
                Icons.image,
                size: 14,
                color: showWithImages
                    ? (isDark ? Colors.black : Colors.white)
                    : cs.onSurfaceVariant,
              ),
              label: Text(context.tr('txt_photo')),
              selected: showWithImages,
              onSelected: (selected) {
                setState(() {
                  showWithImages = selected;
                  if (selected) {
                    selectedRating = null;
                    showWithComments = false;
                  }
                });
              },
              backgroundColor: cs.surfaceVariant,
              selectedColor: isDark ? Colors.white : Colors.black,
              checkmarkColor: isDark ? Colors.black : Colors.white,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: showWithImages
                    ? (isDark ? Colors.black : Colors.white)
                    : cs.onSurface,
              ),
            ),
          ),

          // With comments chip
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(
                Icons.comment,
                size: 14,
                color: showWithComments
                    ? (isDark ? Colors.black : Colors.white)
                    : cs.onSurfaceVariant,
              ),
              label: Text(context.tr('txt_comments')),
              selected: showWithComments,
              onSelected: (selected) {
                setState(() {
                  showWithComments = selected;
                  if (selected) {
                    selectedRating = null;
                    showWithImages = false;
                  }
                });
              },
              backgroundColor: cs.surfaceVariant,
              selectedColor: isDark ? Colors.white : Colors.black,
              checkmarkColor: isDark ? Colors.black : Colors.white,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: showWithComments
                    ? (isDark ? Colors.black : Colors.white)
                    : cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton(ColorScheme cs, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: PopupMenuButton<String>(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: cs.surface,
        offset: const Offset(0, 40),
        onSelected: (value) {
          setState(() {
            sortBy = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.sort, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                _getSortLabel(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'recent',
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 18,
                  color: sortBy == 'recent' ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  context.tr('txt_most_recent'),
                  style: TextStyle(
                    color: sortBy == 'recent' ? cs.primary : cs.onSurface,
                    fontWeight: sortBy == 'recent'
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'rating_high',
            child: Row(
              children: [
                Icon(
                  Icons.star,
                  size: 18,
                  color: sortBy == 'rating_high'
                      ? cs.primary
                      : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  context.tr('txt_highest_rating'),
                  style: TextStyle(
                    color: sortBy == 'rating_high' ? cs.primary : cs.onSurface,
                    fontWeight: sortBy == 'rating_high'
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'rating_low',
            child: Row(
              children: [
                Icon(
                  Icons.star_border,
                  size: 18,
                  color: sortBy == 'rating_low'
                      ? cs.primary
                      : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  context.tr('txt_lowest_rating'),
                  style: TextStyle(
                    color: sortBy == 'rating_low' ? cs.primary : cs.onSurface,
                    fontWeight: sortBy == 'rating_low'
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel() {
    switch (sortBy) {
      case 'rating_high':
        return context.tr('txt_highest');
      case 'rating_low':
        return context.tr('txt_lowest');
      default:
        return context.tr('txt_recent');
    }
  }

  void _showFilterSheet() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                 Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    context.tr('txt_filter_reviews'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  title: Text(context.tr('txt_with_photos_only')),
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: showWithImages
                          ? (isDark ? Colors.white : Colors.black)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: showWithImages
                            ? Colors.transparent
                            : cs.outlineVariant,
                      ),
                    ),
                    child: showWithImages
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: isDark ? Colors.black : Colors.white,
                          )
                        : null,
                  ),
                  onTap: () {
                    setSheetState(() {
                      showWithImages = !showWithImages;
                      if (showWithImages) {
                        showWithComments = false;
                        selectedRating = null;
                      }
                    });
                  },
                ),
                ListTile(
                  title: Text(context.tr('txt_with_comments_only')),
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: showWithComments
                          ? (isDark ? Colors.white : Colors.black)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: showWithComments
                            ? Colors.transparent
                            : cs.outlineVariant,
                      ),
                    ),
                    child: showWithComments
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: isDark ? Colors.black : Colors.white,
                          )
                        : null,
                  ),
                  onTap: () {
                    setSheetState(() {
                      showWithComments = !showWithComments;
                      if (showWithComments) {
                        showWithImages = false;
                        selectedRating = null;
                      }
                    });
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              showWithImages = false;
                              showWithComments = false;
                              selectedRating = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: cs.outlineVariant),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            context.tr('txt_clear_all'),
                            style: TextStyle(color: cs.onSurface),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {});
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white
                                : Colors.black,
                            foregroundColor: isDark
                                ? Colors.black
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(context.tr('txt_apply')),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceVariant.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rate_review_outlined,
              size: 48,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('txt_no_reviews_match'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('txt_try_adjusting_filter'),
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                selectedRating = null;
                showWithImages = false;
                showWithComments = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(context.tr('txt_clear_filters')),
          ),
        ],
      ),
    );
  }
}

// Individual Review Card
class _DynamicReviewCard extends StatelessWidget {
  final Review review;

  const _DynamicReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and rating
          Row(
            children: [
              // Profile Image
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.surfaceVariant,
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: ClipOval(
                  child: review.user.profilePhoto != null
                      ? Image.network(
                          '${ApiService.ImagebaseUrl}/${ApiService.profile_image_URL}${review.user.profilePhoto}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.person, color: cs.primary, size: 22),
                        )
                      : Center(
                          child: Text(
                            review.user.name.isNotEmpty
                                ? review.user.name[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Name and Rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.user.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          return Icon(
                            i < review.rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 14,
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Review comment
          if (review.review.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                review.review,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface,
                  height: 1.4,
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Review images
          // In the image builder section of _DynamicReviewCard
          // In the image builder section of _DynamicReviewCard
          if (review.images.isNotEmpty) ...[
            Text(
              context.tr('txt_review_photos'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  // Since review.images is List<String>, imageItem is already a String
                  final imageFilename = review.images[i];

                  // Construct the full URL
                  final imageUrl =
                      '${ApiService.ImagebaseUrl}${ApiService.review_images_URL}$imageFilename';
                  print('Loading image from: $imageUrl'); // Debug print

                  return GestureDetector(
                    onTap: () {
                      _showImageDialog(context, review.images, i);
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, __) {
                            print('Error loading image: $error');
                            return Container(
                              color: cs.surfaceVariant,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    color: cs.onSurfaceVariant,
                                    size: 30,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    context.tr('txt_error'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: cs.surfaceVariant,
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, List<String> images, [int initialIndex = 0]) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Convert all images to URLs (images are already strings)
    final List<String> imageUrls = images.map((filename) {
      return '${ApiService.ImagebaseUrl}${ApiService.review_images_URL}$filename';
    }).toList();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: cs.outlineVariant),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('txt_review_photos'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.close,
                              color: isDark ? Colors.black : Colors.white,
                              size: 18,
                            ),
                            onPressed: () => Navigator.pop(context),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Images
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: PageView.builder(
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        return InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 3.0,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Image.network(
                              imageUrls[index],
                              fit: BoxFit.contain,
                              errorBuilder: (_, error, __) {
                                print('Error loading dialog image: $error');
                                return Container(
                                  color: cs.surfaceVariant,
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 64,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Counter
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: cs.outlineVariant),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${initialIndex + 1} of ${imageUrls.length}',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
