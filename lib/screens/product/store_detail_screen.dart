import 'package:ecom/extensions/context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
// import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../search/product_search_screen.dart';
import 'controller/store_detil_service.dart';
import 'model/store_detail.dart';
import '../product/product_details_screen.dart';

class StoreDetailScreen extends StatefulWidget {
  final int storeId;
  final String? storeName;

  const StoreDetailScreen({
    Key? key,
    required this.storeId,
    this.storeName,
  }) : super(key: key);

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen>
    with SingleTickerProviderStateMixin {
  StoreDetailResponse? _cachedStoreData;
  bool _isLoading = true;
  String? _errorMessage;

  /// "All" is always first; rest come from product subcategories
  String _selectedCategory = 'All';

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  Color? _storeBackgroundColor;
  List<Map<String, dynamic>> _socialLinks = [];
  Map<String, dynamic>? _returnPolicy;
  Map<String, dynamic>? _deliveryPolicy;

  /// Dynamic subcategory list built from products
  List<String> _subcategories = ['All'];
  // Back button animation - make them nullable or initialize later
  AnimationController? _backButtonCtrl;
  Animation<double>? _backButtonAnim;
  bool _isBackButtonHovering = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadStoreData();
  }

  // Initialize back button animations after colors are loaded
  void _initBackButtonAnimation() {
    _backButtonCtrl?.dispose();
    _backButtonCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _backButtonAnim = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(parent: _backButtonCtrl!, curve: Curves.elasticOut),
    );
    _backButtonCtrl?.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _backButtonCtrl?.dispose();
    super.dispose();
  }

  // Simplified back button without animation (more reliable)
  Widget _buildBackButton() {
    return Positioned(
      bottom: 24,
      left: 20,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isDark
                  ? [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.85),
              ]
                  : [
                Colors.black.withOpacity(0.85),
                Colors.black.withOpacity(0.75),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: (_isDark ? Colors.black : Colors.white).withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _isDark ? Colors.black87 : Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  // ── LOAD DATA ─────────────────────────────────────────────────────────────
  Future<void> _loadStoreData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final data =
      await StoreDetailService.fetchStoreDetail(widget.storeId);

      setState(() {
        _cachedStoreData = data;

        // Parse background color from API
        final colorHex = data.data.store.backgroundColor;
        if (colorHex != null && colorHex.isNotEmpty) {
          try {
            _storeBackgroundColor = Color(
                int.parse('0xFF${colorHex.replaceAll('#', '')}'));
          } catch (_) {
            _storeBackgroundColor = const Color(0xFFF5F0EB);
          }
        } else {
          _storeBackgroundColor = const Color(0xFFF5F0EB);
        }

        // Social links
        if (data.data.store.socialLinks != null &&
            data.data.store.socialLinks!.isNotEmpty) {
          _socialLinks = List<Map<String, dynamic>>.from(
              data.data.store.socialLinks!);
        }

        // Policies
        if (data.data.store.returnPolicy != null &&
            data.data.store.returnPolicy!.isNotEmpty) {
          _returnPolicy = data.data.store.returnPolicy;
        }
        if (data.data.store.deliveryPolicy != null &&
            data.data.store.deliveryPolicy!.isNotEmpty) {
          _deliveryPolicy = data.data.store.deliveryPolicy;
        }

        // Build dynamic subcategory list from products
        _buildSubcategories(data.data.products);

        _isLoading = false;
      });

      _fadeCtrl.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  /// Extracts unique subcategory names from products.
  /// ── Change the field name below to match your StoreProduct model ──
  void _buildSubcategories(List<StoreProduct> products) {
    final seen = <String>{};
    final cats = <String>['All'];
    for (final p in products) {
      final name = _productSubcategory(p);
      if (name.isNotEmpty && seen.add(name)) cats.add(name);
    }
    _subcategories = cats;
    _selectedCategory = 'All';
  }

  /// Returns the subcategory label for a product.
  /// Adjust `p.subcategoryName` / `p.categoryName` / `p.category`
  /// to whichever field your StoreProduct model uses.
  String _productSubcategory(StoreProduct p) {
    try {
      return (p.subCategoryId ?? p.categoryId ?? p.categoryId ?? '')
          .toString()
          .trim();
    } catch (_) {
      return '';
    }
  }

  // ── FILTERED PRODUCTS ─────────────────────────────────────────────────────
  List<StoreProduct> get _filteredProducts {
    final all = _cachedStoreData?.data.products ?? [];
    if (_selectedCategory == 'All') return all;
    return all
        .where((p) => _productSubcategory(p) == _selectedCategory)
        .toList();
  }

  // ── COLOR HELPERS ─────────────────────────────────────────────────────────
  bool get _isDark =>
      (_storeBackgroundColor?.computeLuminance() ?? 0.5) < 0.4;
  Color get _textColor => _isDark ? Colors.white : Colors.black87;
  Color get _subTextColor =>
      _isDark ? Colors.white.withOpacity(0.7) : Colors.black54;
  Color get _cardColor =>
      _isDark ? Colors.white.withOpacity(0.12) : Colors.white;
  Color get _chipColor =>
      _isDark ? Colors.white.withOpacity(0.15) : Colors.white;
  Color get _selectedChipColor => _isDark ? Colors.white : Colors.black87;
  Color get _selectedChipTextColor =>
      _isDark ? Colors.black87 : Colors.white;

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoader();
    if (_errorMessage != null || _cachedStoreData == null)
      return _buildError();

    final store = _cachedStoreData!.data.store;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
      _isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _storeBackgroundColor,
        body: Stack(
          children: [
            FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildHeroSliver(store),
                  SliverToBoxAdapter(child: _buildCategoryStrip()),
                  SliverToBoxAdapter(child: _buildProductsHeader()),
                  _buildProductsGrid(),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)), // Increased bottom padding
                ],
              ),
            ),
            // Back Button - Bottom Left
            _buildBackButton(),
          ],
        ),
      ),
    );
  }
  // ── HERO SLIVER ───────────────────────────────────────────────────────────
  Widget _buildHeroSliver(dynamic store) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      automaticallyImplyLeading: false,
      backgroundColor: _storeBackgroundColor,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        child: GestureDetector(
          onTap: _showStoreDetailsPage,
          child: _glassIconBtn(Icons.menu_rounded),
        ),
      ),
      actions: [
        // _glassChipBtn('Follow'),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          child: _glassIconBtn(Icons.ios_share_rounded),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          color: _storeBackgroundColor,
          child: _HeroBannerLocal(
            backgroundImage: store.storeBackgroundImage,
            logoImage: store.logo,
            storeName: store.name,
            backgroundColor: _storeBackgroundColor!,
            isDark: _isDark,
          ),
        ),
      ),
    );
  }

  Widget _glassIconBtn(IconData icon) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.28),
      shape: BoxShape.circle,
      border:
      Border.all(color: Colors.white.withOpacity(0.25), width: 1),
    ),
    child: Icon(icon, color: Colors.white, size: 18),
  );

  Widget _glassChipBtn(String label) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.symmetric(horizontal: 18),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.28),
      borderRadius: BorderRadius.circular(30),
      border:
      Border.all(color: Colors.white.withOpacity(0.25), width: 1),
    ),
    child: Center(
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600)),
    ),
  );

  void _showStoreDetailsPage() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, b) => FadeTransition(
          opacity: a,
          child: StoreDetailsPage(
            store: _cachedStoreData!.data.store,
            backgroundColor: _storeBackgroundColor!,
            socialLinks: _socialLinks,
            returnPolicy: _returnPolicy,
            deliveryPolicy: _deliveryPolicy,
          ),
        ),
      ),
    );
  }

  // ── DYNAMIC CATEGORY STRIP ────────────────────────────────────────────────
  Widget _buildCategoryStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.start,
        children: [
          // Search icon
          InkWell(onTap: (){
            Navigator.push(context, MaterialPageRoute(builder: (context)=>ProductSearchScreen()));
          },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _chipColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isDark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
              ),
              child:
              Icon(Icons.search_rounded, size: 20, color: _subTextColor),
            ),
          ),

          // Dynamic subcategory chips
          ..._subcategories.map((cat) {
            final sel = _selectedCategory == cat;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? _selectedChipColor : _chipColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: sel
                        ? Colors.transparent
                        : (_isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.grey.shade200),
                  ),
                  boxShadow: sel
                      ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ]
                      : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4)
                  ],
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? _selectedChipTextColor : _subTextColor,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── PRODUCTS HEADER ───────────────────────────────────────────────────────
  Widget _buildProductsHeader() {
    final count = _filteredProducts.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedCategory == 'All'
                    ? context.tr('txt_all_products')
                    : _selectedCategory,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textColor,
                  letterSpacing: -0.5,
                ),
              ),
              Text('$count item${count == 1 ? '' : 's'}',
                  style:
                  TextStyle(fontSize: 12, color: _subTextColor)),
            ],
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _chipColor,
              shape: BoxShape.circle,
              border: Border.all(
                  color: _isDark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey.shade200),
            ),
            child: Icon(Icons.tune_rounded, size: 18, color: _textColor),
          ),
        ],
      ),
    );
  }

  // ── PRODUCTS GRID ─────────────────────────────────────────────────────────
  Widget _buildProductsGrid() {
    final products = _filteredProducts;
    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 48,
                    color: _isDark
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  _selectedCategory == 'All'
                      ? context.tr('no_product_available')
                      : '${context.tr('txt_no_products_in')} "$_selectedCategory"',
                  style:
                  TextStyle(color: _subTextColor, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.66,
        ),
        delegate: SliverChildBuilderDelegate(
              (_, i) => _buildProductCard(products[i]),
          childCount: products.length,
        ),
      ),
    );
  }

  Widget _buildProductCard(StoreProduct product) {
    final orig = double.tryParse(product.price) ?? 0;
    final disc = double.tryParse(product.discountPrice) ?? 0;
    final hasDisc =
        product.discountPrice != '0.00' && disc > 0 && disc < orig;
    final pct =
    hasDisc ? (((orig - disc) / orig) * 100).round() : 0;
    final imgUrl = product.primaryImage.isNotEmpty
        ? '${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}${product.primaryImage}'
        : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProductDetailScreen(productId: product.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isDark
                ? Colors.white.withOpacity(0.12)
                : Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(_isDark ? 0.25 : 0.07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: _isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.grey.shade100,
                    child: imgUrl != null
                        ? Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.image_not_supported,
                        size: 44,
                        color: _isDark
                            ? Colors.white.withOpacity(0.3)
                            : Colors.grey.shade300,
                      ),
                      loadingBuilder: (_, child, lp) {
                        if (lp == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child:
                            CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                              AlwaysStoppedAnimation<
                                  Color>(
                                _isDark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                        : Icon(
                      Icons.image_outlined,
                      size: 44,
                      color: _isDark
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey.shade300,
                    ),
                  ),
                  if (hasDisc)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isDark
                              ? Colors.white
                              : Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$pct% off',
                          style: TextStyle(
                            color: _isDark
                                ? Colors.black87
                                : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6)
                        ],
                      ),
                      child: const Icon(
                          Icons.favorite_border_rounded,
                          size: 16,
                          color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding:
                const EdgeInsets.fromLTRB(11, 9, 11, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                            (i) => Icon(
                          i < 4
                              ? Icons.star_rounded
                              : Icons.star_half_rounded,
                          size: 11,
                          color: Colors.amber.shade600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          hasDisc
                              ? "${product.discountPrice} c."
                              : "${product.price} c.",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _textColor,
                          ),
                        ),
                        if (hasDisc) ...[
                          const SizedBox(width: 5),
                          Text(
                            "${product.price} c.",
                            style: TextStyle(
                              fontSize: 11,
                              color: _subTextColor,
                              decoration:
                              TextDecoration.lineThrough,
                              decorationColor: _subTextColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── LOADER / ERROR ────────────────────────────────────────────────────────
  Widget _buildLoader() => Scaffold(
    backgroundColor: _storeBackgroundColor ?? Colors.white,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
              color: Colors.black, strokeWidth: 2),
          const SizedBox(height: 14),
          Text(context.tr('txt_loading_store'),
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 13)),
        ],
      ),
    ),
  );

  Widget _buildError() => Scaffold(
    backgroundColor: _storeBackgroundColor ?? Colors.white,
    appBar: AppBar(
      backgroundColor: _storeBackgroundColor ?? Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.black, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(_errorMessage ?? context.tr('txt_something_went_wrong'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadStoreData,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30))),
            child:  Text(context.tr('txt_retry')),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO BANNER
// ─────────────────────────────────────────────────────────────────────────────
class _HeroBannerLocal extends StatelessWidget {
  final String? backgroundImage;
  final String? logoImage;
  final String storeName;
  final Color backgroundColor;
  final bool isDark;

  const _HeroBannerLocal({
    required this.backgroundImage,
    required this.logoImage,
    required this.storeName,
    required this.backgroundColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgUrl = backgroundImage != null && backgroundImage!.isNotEmpty
        ? '${ApiService.ImagebaseUrl}/${ApiService.store_background_URL}$backgroundImage'
        : null;
    final logoUrl = logoImage != null && logoImage!.isNotEmpty
        ? '${ApiService.ImagebaseUrl}/${ApiService.store_logo_URL}$logoImage'
        : null;

    final bottomGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.65, 0.75, 1.0],
      colors: [
        Colors.transparent,
        backgroundColor.withOpacity(0.5),
        backgroundColor,
      ],
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        bgUrl != null
            ? Image.network(bgUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _gradientBox())
            : _gradientBox(),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              stops: const [0.0, 0.3],
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.transparent
              ],
            ),
          ),
        ),
        Container(
            decoration: BoxDecoration(gradient: bottomGradient)),
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8)),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: logoUrl != null
                    ? Image.network(logoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _LetterFallback(name: storeName))
                    : _LetterFallback(name: storeName),
              ),
              const SizedBox(height: 14),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  storeName.isEmpty ? context.tr('txt_store') : storeName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 12)
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded,
                        size: 15, color: Colors.amber.shade400),
                    const SizedBox(width: 4),
                    const Text('4.8',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                                color: Colors.black45,
                                blurRadius: 6)
                          ],
                        )),
                    const SizedBox(width: 4),
                    Text('(2.5K ${context.tr('txt_rating')})',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontSize: 12.5,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _gradientBox() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [Colors.grey.shade900, Colors.black87]
            : [Colors.grey.shade300, Colors.grey.shade100],
      ),
    ),
  );
}

class _LetterFallback extends StatelessWidget {
  final String name;
  const _LetterFallback({required this.name});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.grey.shade100,
    alignment: Alignment.center,
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'S',
      style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade700),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// STORE DETAILS PAGE  (menu → same card layout as preview)
// ─────────────────────────────────────────────────────────────────────────────
class StoreDetailsPage extends StatefulWidget {
  final StoreInfo store;
  final Color backgroundColor;
  final List<Map<String, dynamic>> socialLinks;
  final Map<String, dynamic>? returnPolicy;
  final Map<String, dynamic>? deliveryPolicy;

  const StoreDetailsPage({
    Key? key,
    required this.store,
    required this.backgroundColor,
    this.socialLinks = const [],
    this.returnPolicy,
    this.deliveryPolicy,
  }) : super(key: key);

  @override
  State<StoreDetailsPage> createState() => _StoreDetailsPageState();
}

class _StoreDetailsPageState extends State<StoreDetailsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  bool get _isDark =>
      widget.backgroundColor.computeLuminance() < 0.4;
  Color get _textColor => _isDark ? Colors.white : Colors.black87;
  Color get _subTextColor =>
      _isDark ? Colors.white.withOpacity(0.65) : Colors.black54;
  Color get _cardColor =>
      _isDark ? Colors.white.withOpacity(0.1) : Colors.white;
  Color get _dividerColor =>
      _isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100;

  // ── URL launcher ──────────────────────────────────────────────────────────
  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(
        url.startsWith('http') ? url : 'https://$url');
    if (uri == null) return;
    // if (await canLaunchUrl(uri)) {
    //   await launchUrl(uri, mode: LaunchMode.externalApplication);
    // }
  }

  // ── Policy dialog ─────────────────────────────────────────────────────────
  void _showPolicyDialog({
    required String title,
    required Map<String, dynamic>? policy,
  }) {
    if (policy == null || policy.isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isDark
                  ? Colors.white.withOpacity(0.12)
                  : Colors.grey.shade200,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _textColor,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: _textColor),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 20,
                indent: 20,
                endIndent: 20,
                color: _dividerColor,
              ),
              // Content
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight:
                  MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (policy['message'] != null) ...[
                        Text(
                          policy['message'].toString(),
                          style: TextStyle(
                              fontSize: 14,
                              color: _subTextColor,
                              height: 1.6),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (policy['days'] != null)
                        _policyInfoRow(Icons.schedule_rounded,
                            '${context.tr('txt_duration')}: ${policy['days']} days'),
                      if (policy['type'] != null)
                        _policyInfoRow(Icons.info_outline,
                            '${context.tr('txt_type')}: ${policy['type']}'),
                      // Any remaining key-value pairs
                      ...policy.entries
                          .where((e) =>
                      !['message', 'days', 'type']
                          .contains(e.key) &&
                          e.value != null &&
                          e.value.toString().isNotEmpty)
                          .map((e) => _policyInfoRow(
                        Icons.circle_outlined,
                        '${_cap(e.key)}: ${e.value}',
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _policyInfoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _subTextColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 13,
                  color: _subTextColor,
                  height: 1.5)),
        ),
      ],
    ),
  );

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                  const EdgeInsets.fromLTRB(14, 8, 14, 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildStoreHeader(store),
                      const SizedBox(height: 16),
                      _buildReviewsCard(),
                      const SizedBox(height: 12),
                      _buildPoliciesCard(),
                      const SizedBox(height: 12),
                      if (widget.socialLinks.isNotEmpty)
                        _buildContactCard(),
                      const SizedBox(height: 12),
                      if (store.description.isNotEmpty ||
                          store.address.isNotEmpty)
                        _buildAboutCard(store),
                      const SizedBox(height: 12),
                      if (store.deliveryBySeller == 1 ||
                          store.selfPickup == 1)
                        _buildDeliveryCard(store),
                      const SizedBox(height: 20),
                      _buildVisitStoreBtn(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _isDark
                  ? Colors.white.withOpacity(0.12)
                  : Colors.black.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close_rounded,
                color: _textColor, size: 20),
          ),
        ),
        const Spacer(),
        // Container(
        //   padding: const EdgeInsets.symmetric(
        //       horizontal: 20, vertical: 10),
        //   decoration: BoxDecoration(
        //     color: _isDark
        //         ? Colors.white.withOpacity(0.15)
        //         : Colors.black.withOpacity(0.07),
        //     borderRadius: BorderRadius.circular(30),
        //   ),
        //   child: Text('Follow',
        //       style: TextStyle(
        //           color: _textColor,
        //           fontSize: 14,
        //           fontWeight: FontWeight.w600)),
        // ),
        const SizedBox(width: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _isDark
                ? Colors.white.withOpacity(0.12)
                : Colors.black.withOpacity(0.07),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.ios_share_rounded,
              color: _textColor, size: 18),
        ),
      ],
    ),
  );

  // ── STORE HEADER ──────────────────────────────────────────────────────────
  Widget _buildStoreHeader(StoreInfo store) {
    final logoUrl = store.logo.isNotEmpty
        ? '${ApiService.ImagebaseUrl}/${ApiService.store_logo_URL}${store.logo}'
        : null;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
                color: _isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey.shade200,
                width: 1.5),
          ),
          clipBehavior: Clip.hardEdge,
          child: logoUrl != null
              ? Image.network(logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _LetterFallback(name: store.name))
              : _LetterFallback(name: store.name),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(store.name.isEmpty ? context.tr('your_store') : store.name,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textColor)),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.star_rounded,
                    size: 14, color: Colors.amber),
                const SizedBox(width: 3),
                Text('4.8 (2.5K ratings)',
                    style: TextStyle(
                        fontSize: 12, color: _subTextColor)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ── REVIEWS CARD ──────────────────────────────────────────────────────────
  Widget _buildReviewsCard() => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(context.tr('txt_review'),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textColor)),
            const Spacer(),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward_rounded,
                  color: _textColor, size: 17),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('4.8',
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: _textColor,
                        height: 1)),
                const SizedBox(height: 4),
                Text('2.5K ratings',
                    style: TextStyle(
                        fontSize: 13, color: _subTextColor)),
              ],
            ),
            const SizedBox(width: 20),
            Row(
              children: List.generate(
                  5,
                      (i) => Icon(
                    i < 4
                        ? Icons.star_rounded
                        : Icons.star_half_rounded,
                    size: 30,
                    color: Colors.amber.shade500,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('amazing_store'),
                      style: TextStyle(
                          fontSize: 13,
                          color: _subTextColor,
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ...List.generate(
                            5,
                                (_) => Icon(Icons.star_rounded,
                                size: 12,
                                color: Colors.amber)),
                        const SizedBox(width: 6),
                        Text('${context.tr('txt_customer')} · 2 ${context.tr('txt_days_ago')}',
                            style: TextStyle(
                                fontSize: 11,
                                color: _subTextColor)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.shopping_bag_outlined,
                    size: 20, color: _subTextColor),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  // ── POLICIES CARD — Return + Delivery only, tap → dialog ─────────────────
  Widget _buildPoliciesCard() {
    final hasReturn = widget.returnPolicy != null &&
        widget.returnPolicy!.isNotEmpty;
    final hasDelivery = widget.deliveryPolicy != null &&
        widget.deliveryPolicy!.isNotEmpty;
    if (!hasReturn && !hasDelivery) return const SizedBox.shrink();

    final items = <Map<String, dynamic>>[
      if (hasReturn)
        {
          'label': context.tr('faq_quick_return'),
          'icon': Icons.assignment_return_outlined,
          'title': context.tr('faq_quick_return'),
          'data': widget.returnPolicy,
        },
      if (hasDelivery)
        {
          'label': context.tr('delivery_policy'),
          'icon': Icons.local_shipping_outlined,
          'title': context.tr('delivery_policy'),
          'data': widget.deliveryPolicy,
        },
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('txt_policies'),
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textColor)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.6,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              return GestureDetector(
                onTap: () => _showPolicyDialog(
                  title: item['title'] as String,
                  policy: item['data'] as Map<String, dynamic>?,
                ),
                child: _gridItem(
                  item['label'] as String,
                  item['icon'] as IconData,
                  showArrow: true,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── CONTACT CARD — social links only, each opens URL ─────────────────────
  Widget _buildContactCard() {
    final items = widget.socialLinks.map((link) {
      final type = (link['type'] ?? '').toString();
      final url = (link['url'] ?? link['link'] ?? '').toString();
      IconData icon;
      switch (type.toLowerCase()) {
        case 'instagram':
          icon = Icons.camera_alt_outlined;
          break;
        case 'facebook':
          icon = Icons.facebook_outlined;
          break;
        case 'youtube':
          icon = Icons.play_circle_outline_rounded;
          break;
        case 'twitter':
        case 'x':
          icon = Icons.chat_bubble_outline_rounded;
          break;
        case 'whatsapp':
          icon = Icons.chat_outlined;
          break;
        case 'linkedin':
          icon = Icons.work_outline;
          break;
        case 'website':
          icon = Icons.language_outlined;
          break;
        case 'tiktok':
          icon = Icons.music_note_outlined;
          break;
        case 'pinterest':
          icon = Icons.push_pin_outlined;
          break;
        default:
          icon = Icons.link_outlined;
      }
      return {'label': type, 'icon': icon, 'url': url};
    }).toList();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('txt_contact'),
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textColor)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.8,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              return GestureDetector(
                onTap: () {
                  final u = item['url'].toString();
                  if (u.isNotEmpty) _launchUrl(u);
                },
                child: _gridItem(
                  _cap(item['label'].toString()),
                  item['icon'] as IconData,
                  showExternalIcon: true,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── ABOUT CARD ────────────────────────────────────────────────────────────
  Widget _buildAboutCard(StoreInfo store) => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('about_store'),
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _textColor)),
        const SizedBox(height: 10),
        if (store.description.isNotEmpty) ...[
          _ExpandableText(
            text: store.description,
            style: TextStyle(
                fontSize: 14,
                color: _subTextColor,
                height: 1.6),
            maxLines: 2,
            textColor: _textColor,
          ),
          const SizedBox(height: 12),
        ],
        if (store.address.isNotEmpty || store.city.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (store.address.isNotEmpty)
                Expanded(
                    child: GestureDetector(
                      onTap: () => _showFullAddressDialog(
                        title: context.tr('txt_address'),
                        content: store.address,
                      ),
                      child: _gridItem(
                          store.address,
                          Icons.location_on_outlined),
                    )),
              if (store.address.isNotEmpty &&
                  store.city.isNotEmpty)
                const SizedBox(width: 12),
              if (store.city.isNotEmpty)
                Expanded(
                    child: GestureDetector(
                      onTap: () => _showFullAddressDialog(
                        title: context.tr('txt_city'),
                        content: store.city,
                      ),
                      child: _gridItem(
                          store.city,
                          Icons.location_city_outlined),
                    )),
            ],
          ),
        if (store.workingHours.isNotEmpty) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showFullAddressDialog(
              title: context.tr('working_hours'),
              content: store.workingHours,
            ),
            child: _gridItem(store.workingHours, Icons.schedule_rounded),
          ),
        ],
      ],
    ),
  );

  void _showFullAddressDialog({
    required String title,
    required String content,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isDark
                  ? Colors.white.withOpacity(0.12)
                  : Colors.grey.shade200,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _textColor,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: _textColor),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 20,
                indent: 20,
                endIndent: 20,
                color: _dividerColor,
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content,
                      style: TextStyle(
                        fontSize: 14,
                        color: _subTextColor,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Optional: Add copy button
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: content));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$title ${context.tr('txt_cliped_to_clipboard')}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: _textColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.tr('txt_copy'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
      ),
    );
  }
  // ── DELIVERY CARD ─────────────────────────────────────────────────────────
  Widget _buildDeliveryCard(StoreInfo store) => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('delivery'),
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _textColor)),
        const SizedBox(height: 10),
        if (store.deliveryBySeller == 1)
          _deliveryRow(context.tr('txt_home_delivery_available'),
              Icons.local_shipping_outlined),
        if (store.selfPickup == 1)
          _deliveryRow(
              context.tr('self_pickup_available'), Icons.storefront_outlined),
      ],
    ),
  );

  Widget _deliveryRow(String label, IconData icon) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    color: _subTextColor,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 15, color: _subTextColor),
            ),
          ],
        ),
      ),
      Divider(height: 1, color: _dividerColor),
    ],
  );

  // ── VISIT STORE ───────────────────────────────────────────────────────────
  Widget _buildVisitStoreBtn() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: _isDark
          ? Colors.white.withOpacity(0.12)
          : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
          color: _isDark
              ? Colors.white.withOpacity(0.15)
              : Colors.grey.shade200),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(context.tr('txt_visit_store_online'),
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _textColor)),
        const SizedBox(width: 8),
        Icon(Icons.open_in_new_rounded,
            size: 16, color: _textColor),
      ],
    ),
  );

  // ── SHARED GRID ITEM ──────────────────────────────────────────────────────
  Widget _gridItem(
      String label,
      IconData icon, {
        bool showArrow = false,
        bool showExternalIcon = false,
      }) =>
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: _subTextColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      color: _textColor,
                      fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
            if (showExternalIcon)
              Icon(Icons.open_in_new_rounded,
                  size: 13, color: _subTextColor),
            if (showArrow && !showExternalIcon)
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: _subTextColor),
          ],
        ),
      );

  // ── CARD WRAPPER ──────────────────────────────────────────────────────────
  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
          color: _isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.shade100),
      boxShadow: [
        BoxShadow(
          color: Colors.black
              .withOpacity(_isDark ? 0.2 : 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPANDABLE TEXT
// ─────────────────────────────────────────────────────────────────────────────
class _ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final Color textColor;

  const _ExpandableText({
    required this.text,
    this.style,
    this.maxLines = 2,
    required this.textColor,
  });

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _isExpanded = false;
  bool _isOverflow = false;
  final GlobalKey _textKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkOverflow());
  }

  void _checkOverflow() {
    final rp = _textKey.currentContext?.findRenderObject()
    as RenderParagraph?;
    if (rp != null) {
      final overflow = rp.size.height >
          ((rp.text.style?.fontSize ?? 14) * widget.maxLines * 1.5);
      if (_isOverflow != overflow)
        setState(() => _isOverflow = overflow);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        widget.text,
        key: _textKey,
        style: widget.style,
        maxLines: _isExpanded ? null : widget.maxLines,
        overflow: TextOverflow.ellipsis,
      ),
      if (_isOverflow)
        GestureDetector(
          onTap: () =>
              setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _isExpanded ? context.tr('txt_see_less') : context.tr('txt_see_more'),
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
    ],
  );
}