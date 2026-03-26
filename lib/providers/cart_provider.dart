import 'package:flutter/foundation.dart';
import '../screens/cart/controller/cart_services.dart';
import '../screens/cart/model/cart_model.dart';

class CartProvider with ChangeNotifier {
  int _cartCount = 0;
  bool _isLoading = false;
  CartResponse? _cartData;

  /// 🔥 NEW: productId -> quantity
  Map<int, int> _cartItems = {};

  int get cartCount => _cartCount;
  bool get isLoading => _isLoading;
  CartResponse? get cartData => _cartData;

  /// 🔥 Get quantity of specific product
  int getQuantity(int productId) {
    return _cartItems[productId] ?? 0;
  }


  int? getCartItemId(int productId) {
    try {
      return _cartData?.data?.items
          .firstWhere((item) => item.productId == productId)
          .id;
    } catch (e) {
      return null;
    }
  }

  /// Initialize cart
  Future<void> initializeCart() async {
    await fetchCartCount();
  }

  /// Fetch cart from API
  Future<void> fetchCartCount() async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await CartService.getCartList();

      if (result['status'] == true && result['data'] != null) {
        _cartData = CartResponse.fromJson(result);

        final items = _cartData?.data?.items ?? [];

        _cartItems.clear();

        for (var item in items) {
          /// productId -> quantity
          _cartItems[item.product.id] = item.quantity;
        }

        _cartCount = items.length;
      } else {
        _cartCount = 0;
        _cartItems.clear();
        _cartData = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _cartCount = 0;
      _cartItems.clear();
      _cartData = null;
      notifyListeners();
    }
  }

  /// 🔥 Set product quantity locally
  void setProductQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      _cartItems.remove(productId);
    } else {
      _cartItems[productId] = quantity;
    }

    notifyListeners();
  }

  /// Clear cart (logout)
  void clearCart() {
    _cartCount = 0;
    _cartItems.clear();
    _cartData = null;
    notifyListeners();
  }

  /// Refresh cart
  Future<void> refreshCart() async {
    await fetchCartCount();
    notifyListeners(); // 🔥 VERY IMPORTANT

  }
}