import 'package:flutter/material.dart';
import 'package:ecom/screens/bottombar/widget/store_card_widget.dart';
import '../product/store_detail_screen.dart';
import 'controller/store_services.dart';

class AllStoresScreen extends StatefulWidget {
  final String? city;
  final String? country;

  const AllStoresScreen({
    super.key,
    this.city,
    this.country,
  });

  @override
  State<AllStoresScreen> createState() => _AllStoresScreenState();
}

class _AllStoresScreenState extends State<AllStoresScreen> {

  final TextEditingController searchController = TextEditingController();

  List stores = [];
  List filteredStores = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadStores();
  }

  Future<void> loadStores() async {
    final data = await StoreService.fetchStores(
      city: widget.city,
      country: widget.country,
    );

    setState(() {
      stores = data;
      filteredStores = data;
      isLoading = false;
    });
  }

  void searchStore(String value) {
    setState(() {
      filteredStores = stores
          .where((s) =>
          s.name.toLowerCase().contains(value.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(

      /// APP BAR
      appBar: AppBar(
        title: Text(
          "All Stores",
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _SearchField(
              controller: searchController,
              onChanged: (value) {
                searchStore(value);
              },              // onFilterTap: _showFilterBottomSheet,
            ),
          ),


          /// STORE COUNT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "${filteredStores.length} Stores Available",
                style: tt.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// STORE GRID
          Expanded(
            child: isLoading
                ? Center(
              child: CircularProgressIndicator(
                color: cs.primary,
              ),
            )
                : filteredStores.isEmpty
                ? _emptyState(context)
                : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              itemCount: filteredStores.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.63,
              ),
              itemBuilder: (_, i) {

                final store = filteredStores[i];

                return StoreCardWidget(
                  store: store,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoreDetailScreen(
                          storeId: store.id,
                          storeName: store.name,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// EMPTY STATE
  Widget _emptyState(BuildContext context) {

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Icon(
            Icons.storefront_outlined,
            size: 70,
            color: cs.outline,
          ),

          const SizedBox(height: 14),

          Text(
            "No Stores Found",
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Try searching another store",
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilterTap;

  const _SearchField({
    required this.controller,
    required this.onChanged,
     this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        /// 🔍 SEARCH CARD
        Expanded(
          child: Material(
            elevation: 2,

            shadowColor: Colors.black.withOpacity(0.08),
            borderRadius: BorderRadius.circular(30),
            color: cs.surfaceContainerHighest,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: cs.outlineVariant.withOpacity(0.6),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: cs.onSurfaceVariant,
                    size: 22,
                  ),
                  const SizedBox(width: 10),

                  /// TEXT FIELD
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      onChanged: onChanged,
                      textInputAction: TextInputAction.search,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: "Search products or brands",
                        hintStyle: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant.withOpacity(0.7),
                          fontWeight: FontWeight.w400,
                        ),

                        // 🔥 Remove ALL borders
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,

                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),


                  /// ❌ CLEAR (animated)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: controller.text.isNotEmpty
                        ? InkWell(
                      key: const ValueKey('clear'),
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        controller.clear();
                        onChanged('');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    )
                        : const SizedBox(key: ValueKey('empty')),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),



      ],
    );
  }
}
