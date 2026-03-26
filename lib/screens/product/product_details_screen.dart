

import 'package:ecom/screens/auth/LoginScreen.dart';
import 'package:ecom/screens/cart/cart_screen.dart';
import 'package:ecom/screens/product/store_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../providers/cart_provider.dart';
import '../bottombar/widget/product_card_widget.dart';
import '../cart/controller/cart_services.dart';
import '../chat/ConversationScreen.dart';
import '../chat/chat_service.dart';
import '../review/controller/review_service.dart';
import '../review/model/static_review_model.dart';
import '../review/static_review_listScreen.dart';
import 'controller/product_detail_services.dart';
import 'model/Product_Detail_model.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({Key? key, required this.productId})
      : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  int selectedImageIndex = 0;
  bool _isAddingToCart = false;
  bool _isDisposed = false;
  late bool isFav;
  int? _selectedCombinationId;

  // Add these for combination selection
  Map<String, String> _selectedAttributes = {};
  double _selectedPrice = 0;
  int _selectedStock = 0;
  String? _selectedCombinationStockDisplay;

  // For other seller selection
  OtherSeller? _selectedSeller;
  // Cache the product data to avoid reloading
  ProductDetailResponse? _cachedProductData;
  bool _isLoading = true;
  String? _errorMessage;

  List<Review> _reviews = [];
  bool _isLoadingReviews = false;
  double _averageRating = 0;
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _loadProductData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _fetchReviews() async {
    if (!mounted) return;

    setState(() {
      _isLoadingReviews = true;
    });

    try {
      final reviewResponse = await ReviewService.fetchProductReviews(
        widget.productId,
      );

      if (mounted) {
        setState(() {
          _reviews = reviewResponse.reviews;
          _averageRating = reviewResponse.averageRating;
          _totalReviews = reviewResponse.totalReviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      print('Error fetching reviews: $e');
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
        });
      }
    }
  }


  Future<void> _loadProductData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final data = await ProductDetailService.fetchProductDetail(
        widget.productId,
      );

      if (data == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to load product data';
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _cachedProductData = data;

          // Initialize reviews from product data
          _reviews = data.data.reviews;
          _averageRating = data.data.reviewsAvgRating;
          _totalReviews = data.data.reviewsCount;

          // Initialize selected attributes from combinations
          if (data.data.combinations.isNotEmpty) {
            _initializeCombinations(data.data.combinations);
          }

          isFav = data.data.isFavorite ?? false;
          _selectedSeller = null;
          _isLoading = false;
        });

        // Only fetch reviews separately if there are none in the product data
        if (_reviews.isEmpty) {
          _fetchReviews();
        }
      }
    } catch (e) {
      print('Error in _loadProductData: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }


  void _initializeCombinations(List<ProductCombination> combinations) {
    if (combinations.isEmpty) return;

    final firstCombo = combinations.first;
    final attributeKeys = firstCombo.variant.keys.toList();

    for (var key in attributeKeys) {
      _selectedAttributes[key] = firstCombo.variant[key].toString();
    }

    _updateSelectedCombination();
  }

  void _updateSelectedCombination() {
    if (_cachedProductData == null) return;

    final combinations = _cachedProductData!.data.combinations;
    final matchingCombo = combinations.firstWhere(
          (combo) {
        bool matches = true;
        for (var entry in _selectedAttributes.entries) {
          if (combo.variant[entry.key]?.toString() != entry.value) {
            matches = false;
            break;
          }
        }
        return matches;
      },
      orElse: () => combinations.first,
    );

    setState(() {
      _selectedPrice = double.parse(matchingCombo.price.toString());
      _selectedStock = matchingCombo.stock;
      _selectedCombinationId = matchingCombo.id;
      selectedImageIndex = 0;

      // Reset quantity to 1 when combination changes, but ensure it doesn't exceed stock
      quantity = 1;
      if (quantity > _selectedStock) {
        quantity = _selectedStock > 0 ? _selectedStock : 1;
      }

      // Create stock display text for the selected combination
      if (_selectedStock > 0) {
        _selectedCombinationStockDisplay = 'In Stock (${_selectedStock})';
      } else {
        _selectedCombinationStockDisplay = 'Out of Stock';
      }

      print('Selected combination: ${matchingCombo.id}');
      print('Combination stock: ${matchingCombo.stock}');
      print('Combination images: ${matchingCombo.images}');
    });
  }

  String _getDeliveryPriceText(ProductDetail product) {
    if (product.deliveryPrice == null || product.deliveryPrice.isEmpty) {
      return 'Free';
    }
    final price = double.tryParse(product.deliveryPrice) ?? 0;
    if (price == 0) {
      return 'Free';
    }
    return '${price.toInt()} c.';
  }

  String _getDeliveryTimeText(ProductDetail product) {
    if (product.deliveryTime == null || product.deliveryTime.isEmpty) {
      return 'Standard delivery';
    }
    return product.deliveryTime;
  }

  // Helper method to get current image list based on selected combination
  List<String> _getCurrentImageList() {
    if (_selectedCombinationId != null && _cachedProductData != null) {
      final currentCombo = _cachedProductData!.data.combinations.firstWhere(
            (combo) => combo.id == _selectedCombinationId,
        orElse: () => _cachedProductData!.data.combinations.first,
      );

      if (currentCombo.images.isNotEmpty) {
        return currentCombo.images;
      }
    }

    // Fallback to product images
    if (_cachedProductData != null && _cachedProductData!.data.images.isNotEmpty) {
      return _cachedProductData!.data.images.map((img) => img.image).toList();
    }

    return [];
  }

  // Helper method to get current image URL
  String _getCurrentImage() {
    final imageList = _getCurrentImageList();

    if (imageList.isNotEmpty && selectedImageIndex < imageList.length) {
      return imageList[selectedImageIndex];
    }

    if (_cachedProductData != null) {
      return _cachedProductData!.data.primaryImage;
    }

    return '';
  }

  void _selectSeller(OtherSeller seller) {
    if (_selectedSeller?.productId == seller.productId) return;

    setState(() {
      _selectedSeller = seller;
      _isLoading = true;
    });

    _loadOtherSellerProduct(seller.productId);
  }

  Future<void> _loadOtherSellerProduct(int productId) async {
    try {
      final data = await ProductDetailService.fetchProductDetail(productId);

      if (mounted && data != null) {
        setState(() {
          _cachedProductData = data;

          // Update reviews from the new product data
          _reviews = data.data.reviews;
          _averageRating = data.data.reviewsAvgRating;
          _totalReviews = data.data.reviewsCount;

          _selectedAttributes.clear();
          _selectedCombinationId = null;
          selectedImageIndex = 0;
          if (data.data.combinations.isNotEmpty) {
            _initializeCombinations(data.data.combinations);
          }
          isFav = data.data.isFavorite ?? false;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load seller product';
        });
      }
    } catch (e) {
      print('Error loading other seller product: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }


  Widget _buildCombinationSelectors() {
    if (_cachedProductData == null ||
        _cachedProductData!.data.combinations.isEmpty) {
      return const SizedBox.shrink();
    }

    final attributes = _cachedProductData!.data.attributesJson?.data ?? {};
    final combinations = _cachedProductData!.data.combinations;

    if (attributes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: attributes.entries.map((entry) {
        final attributeName = entry.key;
        final options = List<String>.from(entry.value);

        final availableValues = options.where((value) {
          return combinations.any((combo) {
            return combo.variant[attributeName]?.toString() == value;
          });
        }).toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                attributeName.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: availableValues.map((value) {
                  final isSelected = _selectedAttributes[attributeName] == value;
                  return ChoiceChip(
                    label: Text(value),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedAttributes[attributeName] = value;
                          _updateSelectedCombination();
                        });
                      }
                    },
                    selectedColor: Colors.black,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOtherSellersSection() {
    if (_cachedProductData == null ||
        _cachedProductData!.data.otherSellers.isEmpty) {
      return const SizedBox.shrink();
    }

    final otherSellers = _cachedProductData!.data.otherSellers;

    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Other Sellers',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...otherSellers.map((seller) => _buildSellerCard(seller)),
        ],
      ),
    );
  }

  Widget _buildSellerCard(OtherSeller seller) {
    final isSelected = _selectedSeller?.productId == seller.productId;
    final price = double.tryParse(
        (seller.discounted_price != null && seller.discounted_price!.isNotEmpty)
            ? seller.discounted_price!
            : seller.price
    ) ?? 0.0;
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(left: 12,right: 12,top: 8,bottom: 8),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withOpacity(0.15),
            cs.primary.withOpacity(0.05),
          ],
        )
            : null,
        color: isSelected ? null : cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? cs.primary
              : cs.outlineVariant.withOpacity(0.5),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? cs.primary.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Store Logo with animated border and verified badge
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isSelected
                      ? LinearGradient(
                    colors: [
                      cs.primary,
                      cs.primary.withOpacity(0.7),
                    ],
                  )
                      : null,
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: cs.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: seller.storeLogo != null
                        ? Image.network(
                      '${ApiService.ImagebaseUrl}/${ApiService.store_logo_URL}${seller.storeLogo}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.store, size: 28, color: Colors.grey),
                      ),
                    )
                        : Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.store, size: 28, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              // Verified Badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.verified,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // Store Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        seller.storeName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isSelected ? cs.primary : cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Verified text badge
                    // Container(
                    //   padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    //   decoration: BoxDecoration(
                    //     color: Colors.blue.withOpacity(0.1),
                    //     borderRadius: BorderRadius.circular(8),
                    //   ),
                    //   child: Row(
                    //     mainAxisSize: MainAxisSize.min,
                    //     children: const [
                    //       Icon(
                    //         Icons.verified,
                    //         size: 10,
                    //         color: Colors.blue,
                    //       ),
                    //       SizedBox(width: 2),
                    //       Text(
                    //         'Verified',
                    //         style: TextStyle(
                    //           fontSize: 8,
                    //           color: Colors.blue,
                    //           fontWeight: FontWeight.w600,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    const SizedBox(width: 6),
                    if (seller.availableQuantity > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 10,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'In Stock',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${seller.availableQuantity} units',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Free Delivery',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (isSelected) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '✓ Selected Seller',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Price and Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${price.toStringAsFixed(0)} c.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              // const SizedBox(height: 12),
              if (!isSelected)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: ElevatedButton(
                    onPressed: () => _selectSeller(seller),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: const Size(70, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.swap_horiz, size: 14),
                        SizedBox(width: 4),
                        Text('Select', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'Selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  Future<void> _handleAddToCart(ProductDetail product) async {
    final isLoggedIn = await AuthStorage.isLoggedIn();

    if (!isLoggedIn) {
      _showLoginDialog();
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final result = await CartService.addToCart(
        productId: product.id,
        quantity: quantity,
        combinationId: _selectedCombinationId,
      );

      setState(() {
        _isAddingToCart = false;
      });

      if (result['status'] == true) {
        if (mounted) {
          context.read<CartProvider>().fetchCartCount();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result['message'] ?? '${product.name} added to cart',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              action: SnackBarAction(
                label: 'VIEW CART',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartScreen()),
                  );
                },
              ),
            ),
          );
        }
      } else {
        if (result['requiresLogin'] == true) {
          _showLoginDialog();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to add to cart'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isAddingToCart = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showLoginDialog() {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.login, color: cs.primary),
            const SizedBox(width: 12),
            const Text('Login Required'),
          ],
        ),
        content: const Text(
          'Please login to add items to your cart and continue shopping.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AuthScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return _buildLoadingState(context);
    }

    if (_errorMessage != null || _cachedProductData == null) {
      return _buildErrorState(
        context,
        _errorMessage ?? 'No product data available',
      );
    }

    final productData = _cachedProductData!.data;
    final relatedProducts = _cachedProductData!.relatedProducts;

    return Scaffold(
      backgroundColor: isDark ? cs.surface : Colors.grey[100],
      body: _buildProductDetail(context, productData, relatedProducts),
      bottomNavigationBar: _buildBottomBar(context, productData, isDark),
    );
  }

  Widget _buildProductDetail(
      BuildContext context,
      ProductDetail product,
      List<RelatedProduct> relatedProducts,
      ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentImage = _getCurrentImage();
    final imageList = _getCurrentImageList();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: MediaQuery.of(context).size.height * 0.65,
          backgroundColor: cs.surface,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(6.0),
            child: _CircleAction(
              icon: Icons.keyboard_double_arrow_left_outlined,
              bg: isDark ? Colors.white : Colors.black,
              fg: isDark ? Colors.black : Colors.white,
              onTap: () => Navigator.pop(context),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: _CartIconWithBadge(
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 6),
            _CircleAction(
              icon: Icons.message,
              bg: isDark ? Colors.white : Colors.black,
              fg: isDark ? Colors.black : Colors.white,
              onTap: () async {
                final vendorId = product.store!.userId;
                final vendorName = product.store!.name;
                final vendorImage = product.store!.logo;
                final int productId = product.id;

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                  const Center(child: CircularProgressIndicator()),
                );

                final conversationId = await ChatService.startConversation(
                  otherUserId: vendorId,
                  productId: productId,
                );

                Navigator.pop(context);

                if (conversationId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(
                        productimage: currentImage,
                        productname: product.name,
                        name: vendorName,
                        image:
                        "${ApiService.ImagebaseUrl}/${ApiService.profile_image_URL}$vendorImage",
                        conversationId: conversationId,
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () async {
                final token = await AuthStorage.getToken();

                if (token == null || token.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please login first"),
                    ),
                  );
                  return;
                }

                try {
                  final res = await ApiService.post(
                    endpoint: "/customer/product/favorite/toggle",
                    token: token,
                    body: {
                      "product_id": product.id.toString(),
                    },
                  );

                  if (res["success"] == true) {
                    setState(() {
                      isFav = !isFav;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isFav
                              ? "Added to favourites ❤️"
                              : "Removed from favourites",
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  } else {
                    if (res["message"] == "Unauthorized user") {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please login first"),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res["message"] ?? "Something went wrong"),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Server error"),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  size: 25,
                  color: isFav ? Colors.red : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: isDark ? cs.surface : Colors.grey[100],
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10, top: 100, bottom: 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Hero(
                              tag: 'product-${product.id}',
                              child: Image.network(
                                '${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}$currentImage',
                                fit: BoxFit.cover,
                                height: MediaQuery.of(context).size.height * 0.60,
                                width: double.infinity,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.image_not_supported,
                                  size: 100,
                                  color: cs.onSurface.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Image thumbnails - Show combination images when combination selected
                  if (imageList.length > 1)
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: imageList.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final imageUrl = imageList[i];
                          final isSelected = i == selectedImageIndex;
                          return GestureDetector(
                            onTap: () => setState(() => selectedImageIndex = i),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected ? cs.primary : cs.outlineVariant,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.network(
                                  '${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}$imageUrl',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.image,
                                    size: 20,
                                    color: cs.onSurface.withOpacity(0.3),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + qty
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (product.category != null)
                              Text(
                                product.category!.name,
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // _QtyPill(
                      //   onMinus: quantity > 1
                      //       ? () => setState(() => quantity--)
                      //       : null,
                      //   onPlus: () => setState(() => quantity++),
                      //   quantity: quantity,
                      // ),

// Replace it with:
                      _QtyPill(
                        onMinus: quantity > 1
                            ? () {
                          if (quantity > 1) {
                            setState(() {
                              quantity--;
                            });
                          }
                        }
                            : null,
                        onPlus: () {
                          // Check if we can increase quantity based on selected combination stock
                          if (_selectedStock > 0 && quantity < _selectedStock) {
                            setState(() {
                              quantity++;
                            });
                          } else if (_selectedStock == 0 && _cachedProductData!.data.combinations.isNotEmpty) {
                            // Show message if out of stock
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Selected combination is out of stock'),
                                duration: Duration(seconds: 2),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          } else if (quantity >= _selectedStock) {
                            // Show message if max stock reached
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Only $_selectedStock items available in stock'),
                                duration: Duration(seconds: 2),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        quantity: quantity,
                        maxQuantity: _selectedStock > 0 ? _selectedStock : 0,
                        isOutOfStock: _selectedStock == 0 && _cachedProductData!.data.combinations.isNotEmpty,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Stock status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Article Number"),
                          Tooltip(
                            message: "Tap or long press to copy",
                            child: GestureDetector(
                              onTap: () {
                                final text = product.articlenumber?.toString() ?? '';
                                Clipboard.setData(ClipboardData(text: text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Copied"),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              onLongPress: () {
                                final text = product.articlenumber?.toString() ?? '';
                                Clipboard.setData(ClipboardData(text: text));
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    product.articlenumber ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.copy, size: 16, color: Colors.grey),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                      // REPLACE THIS CONTAINER WITH THE UPDATED VERSION BELOW
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStockStatusColor().withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStockStatusColor(),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getStockStatusText(product),
                          style: tt.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getStockStatusColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Delivery info
                  if (product.deliveryAvailable == 1 && _isCombinationAvailable())
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? cs.surfaceVariant : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? cs.outlineVariant : Colors.blue.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Image.asset("assets/images/fast_delivery.png",height: 50,),


                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delivery Available',
                                  style: tt.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                ),
                                Text(
                                  '${_getDeliveryPriceText(product)} • ${_getDeliveryTimeText(product)}',
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Combination selectors
                  if (_cachedProductData!.data.combinations.isNotEmpty) ...[
                    _buildCombinationSelectors(),
                    const SizedBox(height: 24),
                  ],
                  // Other Sellers section
                  _buildOtherSellersSection(),
                  const SizedBox(height: 24),
                  // Description
                  Text(
                    'Description',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (product.store != null)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StoreDetailScreen(
                              storeId: product.store!.id,
                              storeName: product.store!.name,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 8,
                          bottom: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cs.outlineVariant),
                          boxShadow: [
                            BoxShadow(
                              color: cs.shadow.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  height: 50,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: cs.surfaceContainerHighest,
                                    border: Border.all(
                                      color: cs.outlineVariant,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: product.store!.logo.isNotEmpty
                                        ? Image.network(
                                      "${ApiService.ImagebaseUrl}/${ApiService.store_logo_URL}${product.store!.logo}",
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.store,
                                        color: cs.primary,
                                      ),
                                    )
                                        : Icon(Icons.store, color: cs.primary),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: cs.surface,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.verified,
                                      size: 8,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Store",
                                    style: tt.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    product.store!.name,
                                    style: tt.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: cs.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 8),
                  _buildReviewsSection(
                    context,
                    product.id,
                    product.name,
                    product.primaryImage,
                  ),
                  const SizedBox(height: 24),
                  // Related Products
                  if (relatedProducts.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Related Products',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          '${relatedProducts.length} items',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 280,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: relatedProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final product = relatedProducts[i];

                          return SizedBox(
                            width: 170,
                            child: ProductCardWidget(
                              product: product.toProductModel(),
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(
                                      productId: product.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isCombinationAvailable() {
    if (_cachedProductData!.data.combinations.isNotEmpty) {
      return _selectedStock > 0;
    }
    return _cachedProductData!.data.availableQuantity > 0;
  }

  Color _getStockStatusColor() {
    // If combinations exist and we have selected stock, use that
    if (_cachedProductData!.data.combinations.isNotEmpty) {
      if (_selectedStock > 0) {
        return Colors.green.shade700;
      } else {
        return Colors.red.shade700;
      }
    }

    // Fallback to product stock
    final product = _cachedProductData!.data;
    if (product.availableQuantity > 0) {
      return Colors.green.shade700;
    } else {
      return Colors.red.shade700;
    }
  }

  String _getStockStatusText(ProductDetail product) {
    // If combinations exist and we have selected stock, use that
    if (_cachedProductData!.data.combinations.isNotEmpty) {
      if (_selectedStock > 0) {
        return 'In Stock (${_selectedStock})';
      } else {
        return 'Out of Stock';
      }
    }

    // Fallback to product stock
    if (product.availableQuantity > 0) {
      return 'In Stock (${product.availableQuantity})';
    } else {
      return 'Out of Stock';
    }
  }
  Widget _buildBottomBar(
      BuildContext context,
      ProductDetail product,
      bool isDark,
      ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final hasDiscount = product.discountPrice.isNotEmpty &&
        double.parse(product.discountPrice) > 0 &&
        double.parse(product.discountPrice) < double.parse(product.price);

    final displayPrice = _selectedPrice > 0
        ? _selectedPrice
        : (hasDiscount
        ? double.parse(product.discountPrice)
        : double.parse(product.price));

    final originalPrice = double.parse(product.price);

    // Determine if add to cart should be enabled
    bool canAddToCart = false;
    if (_cachedProductData!.data.combinations.isNotEmpty) {
      // If combinations exist, check selected combination stock and quantity
      canAddToCart = _selectedStock > 0 && !_isAddingToCart && quantity <= _selectedStock;
    } else {
      // If no combinations, check product stock
      canAddToCart = product.availableQuantity > 0 && !_isAddingToCart && quantity <= product.availableQuantity;
    }

    // Show warning if quantity exceeds stock
    if (_selectedStock > 0 && quantity > _selectedStock && _cachedProductData!.data.combinations.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            quantity = _selectedStock;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Quantity adjusted to available stock ($_selectedStock)'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Price',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(displayPrice * quantity).toInt()} c.',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    if (hasDiscount) ...[
                      Text(
                        '₮${(originalPrice * quantity).toInt()}',
                        style: tt.bodySmall?.copyWith(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                if (_selectedStock > 0 && _cachedProductData!.data.combinations.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Available: $_selectedStock units',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: canAddToCart
                      ? () => _handleAddToCart(product)
                      : null,
                  icon: _isAddingToCart
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  )
                      : Icon(
                    Icons.shopping_bag_outlined,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                  label: Text(
                    _isAddingToCart ? 'Adding...' :
                    (!canAddToCart && _selectedStock == 0 && _cachedProductData!.data.combinations.isNotEmpty)
                        ? 'Out of Stock'
                        : 'Add to Cart',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    disabledBackgroundColor: cs.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildLoadingState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? cs.surface : Colors.grey[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: cs.primary),
            const SizedBox(height: 16),
            Text(
              'Loading product details...',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection(
      BuildContext context,
      int productId,
      String productName,
      String? productImage,
      ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_isLoadingReviews) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reviews',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  children: [
                    Image.asset("assets/images/comment.png",height: 50,),
                    // Icon(
                    //   Icons.rate_review_outlined,
                    //   size: 48,
                    //   color: cs.onSurfaceVariant,
                    // ),
                    const SizedBox(height: 8),
                    Text(
                      'No reviews yet',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Be the first to review this product',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final displayReviews = _reviews.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Reviews',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        _averageRating.toStringAsFixed(1),
                        style: tt.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($_totalReviews)',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DynamicReviewListScreen(
                      productId: productId,
                      productName: productName,
                      productImage: productImage,
                      initialReviews: _reviews,
                      averageRating: _averageRating,
                      totalReviews: _totalReviews,
                    ),
                  ),
                ).then((_) => _fetchReviews());
              },
              child: Text(
                'See All',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildRatingSummary(cs, tt),
        const SizedBox(height: 16),
        ...displayReviews.map((review) => _buildReviewCard(context, review)),
        if (_reviews.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DynamicReviewListScreen(
                        productId: productId,
                        productName: productName,
                        productImage: productImage,
                        initialReviews: _reviews,
                        averageRating: _averageRating,
                        totalReviews: _totalReviews,
                      ),
                    ),
                  ).then((_) => _fetchReviews());
                },
                child: Text(
                  'View all $_totalReviews reviews',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildRatingSummary(ColorScheme cs, TextTheme tt) {
    Map<int, int> ratingCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var review in _reviews) {
      ratingCounts[review.rating] = (ratingCounts[review.rating] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                _averageRating.toStringAsFixed(1),
                style: tt.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    Icons.star,
                    size: 12,
                    color: i < _averageRating.floor()
                        ? Colors.amber
                        : Colors.grey.shade300,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final rating = 5 - i;
                final count = ratingCounts[rating] ?? 0;
                final percentage = _totalReviews > 0
                    ? count / _totalReviews
                    : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text('$rating', style: tt.bodySmall),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: cs.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.amber,
                            ),
                            minHeight: 4,
                          ),
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
    );
  }

  Widget _buildReviewCard(BuildContext context, Review review) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: cs.surfaceVariant,
                backgroundImage: review.user.profilePhoto != null
                    ? NetworkImage(
                  '${ApiService.ImagebaseUrl}/${ApiService.profile_image_URL}${review.user.profilePhoto}',
                )
                    : null,
                child: review.user.profilePhoto == null
                    ? Text(
                  review.user.name.isNotEmpty
                      ? review.user.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.user.name,
                      style: tt.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          return Icon(
                            i < review.rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 10,
                          );
                        }),
                        const SizedBox(width: 6),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.review.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.review,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tt.bodySmall?.copyWith(color: cs.onSurface, height: 1.4),
            ),
          ],
          if (review.images.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (_, i) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      '${ApiService.ImagebaseUrl}${ApiService.review_images_URL}${review.images[i]}',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50,
                        height: 50,
                        color: cs.surfaceVariant,
                        child: Icon(
                          Icons.broken_image,
                          size: 20,
                          color: cs.onSurfaceVariant,
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

  Widget _buildErrorState(BuildContext context, String error) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(backgroundColor: cs.surface, elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: cs.error),
              const SizedBox(height: 16),
              Text(
                'Error Loading Product',
                style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _loadProductData(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cart Icon with Badge
class _CartIconWithBadge extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _CartIconWithBadge({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: isDark ? Colors.black : Colors.white,
                      size: 20,
                    ),
                  ),
                  if (cartProvider.cartCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${cartProvider.cartCount > 99 ? '99+' : cartProvider.cartCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Circle floating action used on image
class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
  const _CircleAction({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: fg, size: 20),
        ),
      ),
    );
  }
}

/// Quantity stepper pill
class _QtyPill extends StatelessWidget {
  final VoidCallback? onMinus;
  final VoidCallback onPlus;
  final int quantity;
  final int maxQuantity; // Add max quantity parameter
  final bool isOutOfStock; // Add out of stock flag

  const _QtyPill({
    required this.onMinus,
    required this.onPlus,
    required this.quantity,
    this.maxQuantity = 999,
    this.isOutOfStock = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if max quantity is reached
    final bool isMaxReached = quantity >= maxQuantity;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: isOutOfStock
            ? cs.surfaceVariant.withOpacity(0.5)
            : cs.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.remove,
              color: onMinus != null
                  ? cs.onSurface
                  : cs.onSurface.withOpacity(0.3),
              size: 18,
            ),
            onPressed: onMinus,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$quantity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isOutOfStock
                        ? cs.onSurface.withOpacity(0.5)
                        : cs.onSurface,
                  ),
                ),
                if (maxQuantity < 999 && !isOutOfStock)
                  Text(
                    'max $maxQuantity',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.add,
              color: (onPlus != null && !isMaxReached && !isOutOfStock)
                  ? cs.onSurface
                  : cs.onSurface.withOpacity(0.3),
              size: 18,
            ),
            onPressed: (onPlus != null && !isMaxReached && !isOutOfStock)
                ? onPlus
                : null,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}