import 'package:flutter/foundation.dart';
import '../screens/cart/controller/cart_services.dart';
import '../screens/cart/model/cart_model.dart';

class CartProvider with ChangeNotifier {
  int _cartCount = 0;
  bool _isLoading = false;
  CartResponse? _cartData;

  int get cartCount => _cartCount;
  bool get isLoading => _isLoading;
  CartResponse? get cartData => _cartData;

  // Initialize cart count on app start
  Future<void> initializeCart() async {
    await fetchCartCount();
  }

  // Fetch cart count from API
  Future<void> fetchCartCount() async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await CartService.getCartList();

      if (result['status'] == true && result['data'] != null) {
        _cartData = CartResponse.fromJson(result);
        _cartCount = _cartData?.data?.items.length ?? 0;
      } else {
        _cartCount = 0;
        _cartData = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _cartCount = 0;
      _cartData = null;
      notifyListeners();
    }
  }

  // Increment cart count (call after adding to cart)
  void incrementCount() {
    _cartCount++;
    notifyListeners();
  }

  // Decrement cart count (call after removing from cart)
  void decrementCount() {
    if (_cartCount > 0) {
      _cartCount--;
      notifyListeners();
    }
  }

  // Update cart count to specific value
  void updateCount(int count) {
    _cartCount = count;
    notifyListeners();
  }

  // Clear cart count (on logout)
  void clearCart() {
    _cartCount = 0;
    _cartData = null;
    notifyListeners();
  }

  // Refresh cart data
  Future<void> refreshCart() async {
    await fetchCartCount();
  }
}