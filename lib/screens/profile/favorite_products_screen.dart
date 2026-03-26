import 'package:flutter/material.dart';

import '../bottombar/model/product_model.dart';
import '../bottombar/widget/product_card_widget.dart';
import 'controller/favorite_service.dart';

class FavoriteProductsScreen extends StatefulWidget {
  const FavoriteProductsScreen({super.key});

  @override
  State<FavoriteProductsScreen> createState() => _FavoriteProductsScreenState();
}

class _FavoriteProductsScreenState extends State<FavoriteProductsScreen> {

  late Future<List<ProductModel>> futureFavorites;

  @override
  void initState() {
    super.initState();
    futureFavorites = FavoriteService.fetchFavorites();
  }

  Future<void> refreshFavorites() async {
    setState(() {
      futureFavorites = FavoriteService.fetchFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Favorites ❤️"),
      ),

      body: FutureBuilder<List<ProductModel>>(

        future: futureFavorites,

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Text("No favorite products yet"),
            );
          }

          return RefreshIndicator(

            onRefresh: refreshFavorites,

            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: products.length,

              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .72,
              ),

              itemBuilder: (context, index) {

                final product = products[index];

                return ProductCardWidget(
                  product: product,

                  /// refresh when unfavorite
                  onFavourite: refreshFavorites,
                );

              },
            ),
          );
        },
      ),
    );
  }
}