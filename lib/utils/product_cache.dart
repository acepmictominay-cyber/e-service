class ProductCache {
  static bool _productsLoaded = false;
  static List<dynamic> _cachedProdukList = [];

  static bool get productsLoaded => _productsLoaded;
  static List<dynamic> get cachedProdukList => _cachedProdukList;

  static void setProducts(List<dynamic> products) {
    _cachedProdukList = products;
    _productsLoaded = true;
  }

  static void clearCache() {
    _productsLoaded = false;
    _cachedProdukList = [];
  }
}
