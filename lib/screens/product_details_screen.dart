import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../widgets/custom_modals.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  const ProductDetailsScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1;
  String selectedSize = 'L';
  int selectedColorIndex = 0;

  final List<String> sizes = const ['S', 'M', 'L', 'XL', 'XXL'];
  final List<Color> swatches = const [
    Colors.black,
    Color(0xFFC9D7A8),
    Color(0xFFF4A340),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? cs.surface : Colors.grey[100],
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: MediaQuery.of(context).size.height * 0.45,
                backgroundColor: cs.surface,
                elevation: 0,

                leading: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: _CircleAction(
                    icon: Icons.keyboard_double_arrow_left_outlined,
                    bg: isDark? Colors.white: Colors.black,
                    fg: isDark? Colors.black: Colors.white,
                    onTap: () => Navigator.pop(context),
                  ),
                ),

                actions: [
                  _CircleAction(
                    icon: Icons.shopping_bag_outlined,
                    bg: isDark? Colors.white: Colors.black,
                    fg: isDark? Colors.black: Colors.white,
                    onTap: () {},
                  ),
                  const SizedBox(width: 6),
                  _CircleAction(
                    icon: Icons.favorite_border,
                    bg: isDark? Colors.white: Colors.black,
                    fg: isDark? Colors.black: Colors.white,
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                ],

                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: isDark ? cs.surface : Colors.grey[100],
                    child: Center(
                      child: Hero(
                        tag: 'product-${widget.product.id}',
                        child: CachedNetworkImage(
                          imageUrl: widget.product.image,
                          fit: BoxFit.contain,
                          height: MediaQuery.of(context).size.height * 0.40,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.primary,
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error_outline, color: cs.error),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content section
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                                  Text(widget.product.title,
                                      style: tt.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSurface,
                                      )),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Vado Odelle Dress',
                                    style: tt.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _QtyPill(
                              onMinus: quantity > 1 ? () => setState(() => quantity--) : null,
                              onPlus: () => setState(() => quantity++),
                              quantity: quantity,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Rating
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                ...List.generate(5, (i) {
                                  final filled = widget.product.rating.rate.round() > i;
                                  return Icon(
                                    Icons.star,
                                    size: 18,
                                    color: filled ? Colors.orange : cs.onSurface.withOpacity(0.2),
                                  );
                                }),
                                const SizedBox(width: 8),
                                Text(
                                  '(${widget.product.rating.count} Review)',
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? cs.surfaceVariant : Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Available in stock',
                                style: tt.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Size + color
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Size',
                                      style: tt.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSurface,
                                      )),
                                  const SizedBox(height: 12),
                                  _SizeRow(
                                    sizes: sizes,
                                    selected: selectedSize,
                                    onSelect: (s) => setState(() => selectedSize = s),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            _ColorPill(
                              colors: swatches,
                              selected: selectedColorIndex,
                              onChanged: (i) => setState(() => selectedColorIndex = i),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Text('Description',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            )),
                        const SizedBox(height: 8),
                        Text(
                          widget.product.description,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.5,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Container(
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
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total Price',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(
                  '\$${(widget.product.price * quantity).toStringAsFixed(2)}',
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 50),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<CartProvider>().addItem(widget.product, quantity);
                    CustomModals.showSuccessModal(
                      context,
                      'Added to Cart',
                      '${widget.product.title} has been added to your cart.',
                    );
                  },
                  icon:  Icon(Icons.shopping_bag_outlined, color: isDark? Colors.black: Colors.white,
                  ),
                  label:  Text(
                    'Add to Cart',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark? Colors.black: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor:   isDark? Colors.white: Colors.black,
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
}

/// Circle floating action used on image
class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
  const _CircleAction({required this.icon, required this.bg, required this.fg, required this.onTap});

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
  const _QtyPill({
    required this.onMinus,
    required this.onPlus,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.remove,
                color: onMinus != null ? cs.onSurface : cs.onSurfaceVariant, size: 18),
            onPressed: onMinus,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$quantity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.add, color: cs.onSurface, size: 18),
            onPressed: onPlus,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}

/// Size choices row
class _SizeRow extends StatelessWidget {
  final List<String> sizes;
  final String selected;
  final ValueChanged<String> onSelect;

  const _SizeRow({
    required this.sizes,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 12,
      children: sizes.map((s) {
        final isSel = s == selected;
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        return GestureDetector(
          onTap: () => onSelect(s),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSel
                  ? (isDark ? Colors.white: Colors.black)
                  : (isDark ? cs.surfaceVariant : cs.background),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSel
                    ?(isDark ? Colors.white: Colors.black)
                    : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
                width: 1.5,
              ),
            ),
            child: Text(
              s,
              style: TextStyle(
                color: isSel
                    ? cs.onPrimary
                    : (isDark ? Colors.white : Colors.black),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Vertical color picker pill
class _ColorPill extends StatelessWidget {
  final List<Color> colors;
  final int selected;
  final ValueChanged<int> onChanged;
  const _ColorPill({required this.colors, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 100,
      width: 40,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(colors.length, (i) {
          final sel = i == selected;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: colors[i],
                shape: BoxShape.circle,
                border: Border.all(
                  color: sel ? cs.onSurfaceVariant : Colors.transparent,
                  width: 2,
                ),
              ),
              child: sel ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
          );
        }),
      ),
    );
  }
}
