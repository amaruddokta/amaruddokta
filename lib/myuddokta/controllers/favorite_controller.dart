import 'package:get/get.dart';
import 'package:amar_uddokta/myuddokta/models/cart_item.dart';

class FavoriteController extends GetxController {
  var favoriteItems = <CartItem>[].obs;

  void toggleFavorite(CartItem item) {
    if (favoriteItems.any((element) => element.id == item.id)) {
      favoriteItems.removeWhere((element) => element.id == item.id);
    } else {
      favoriteItems.add(item);
    }
  }

  bool isFavorite(String itemId) {
    return favoriteItems.any((element) => element.id == itemId);
  }

  void removeFromFavorites(CartItem item) {
    favoriteItems.removeWhere((element) => element.id == item.id);
  }
}
