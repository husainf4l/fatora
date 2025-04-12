import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../utils/constants.dart';
import 'package:uuid/uuid.dart';

class ProductsService {
  static const String _productsKey = 'products_data';
  final Uuid _uuid = const Uuid();

  // Get all products (with demo data if none exist)
  Future<List<Product>> getAllProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsJson = prefs.getString(_productsKey);

      if (productsJson != null) {
        final List<dynamic> decoded = jsonDecode(productsJson);
        return decoded.map((item) => Product.fromJson(item)).toList();
      } else {
        // Create demo products if none exist
        final demoProducts = _createDemoProducts();
        await saveProducts(demoProducts);
        return demoProducts;
      }
    } catch (e) {
      throw Exception('Failed to load products: ${e.toString()}');
    }
  }

  // Create a new product
  Future<Product> createProduct({
    required String name,
    String? description,
    required double price,
    double? cost,
    String? unit,
    int? quantity,
    String? sku,
  }) async {
    try {
      final products = await getAllProducts();

      final newProduct = Product(
        id: _uuid.v4(),
        name: name,
        description: description,
        price: price,
        cost: cost,
        unit: unit,
        quantity: quantity,
        sku: sku,
        createdAt: DateTime.now(),
      );

      products.add(newProduct);
      await saveProducts(products);

      return newProduct;
    } catch (e) {
      throw Exception('Failed to create product: ${e.toString()}');
    }
  }

  // Update an existing product
  Future<Product> updateProduct(Product product) async {
    try {
      final products = await getAllProducts();

      final index = products.indexWhere((p) => p.id == product.id);
      if (index == -1) {
        throw Exception('Product not found');
      }

      products[index] = product;
      await saveProducts(products);

      return product;
    } catch (e) {
      throw Exception('Failed to update product: ${e.toString()}');
    }
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      final products = await getAllProducts();

      final newList =
          products.where((product) => product.id != productId).toList();
      await saveProducts(newList);
    } catch (e) {
      throw Exception('Failed to delete product: ${e.toString()}');
    }
  }

  // Get a product by ID
  Future<Product?> getProductById(String id) async {
    try {
      final products = await getAllProducts();
      return products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  // Save products to SharedPreferences
  Future<void> saveProducts(List<Product> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedProducts = jsonEncode(
        products.map((p) => p.toJson()).toList(),
      );
      await prefs.setString(_productsKey, encodedProducts);
    } catch (e) {
      throw Exception('Failed to save products: ${e.toString()}');
    }
  }

  // Create demo products
  List<Product> _createDemoProducts() {
    return [
      Product(
        id: _uuid.v4(),
        name: 'تصميم موقع إلكتروني',
        description: 'تصميم موقع ويب احترافي للشركات',
        price: 5000.00,
        cost: 2000.00,
        unit: 'موقع',
        createdAt: DateTime.now(),
      ),
      Product(
        id: _uuid.v4(),
        name: 'تطوير تطبيق موبايل',
        description: 'تطوير تطبيق للهواتف الذكية متوافق مع iOS و Android',
        price: 8000.00,
        cost: 3500.00,
        unit: 'تطبيق',
        createdAt: DateTime.now(),
      ),
      Product(
        id: _uuid.v4(),
        name: 'ساعة استشارة',
        description: 'استشارة تقنية لمدة ساعة',
        price: 500.00,
        unit: 'ساعة',
        createdAt: DateTime.now(),
      ),
      Product(
        id: _uuid.v4(),
        name: 'صيانة شهرية للموقع',
        description: 'خدمة صيانة وتحديث شهرية للموقع الإلكتروني',
        price: 800.00,
        unit: 'شهر',
        createdAt: DateTime.now(),
      ),
      Product(
        id: _uuid.v4(),
        name: 'تحسين محركات البحث SEO',
        description: 'خدمات تحسين ظهور الموقع في محركات البحث',
        price: 1200.00,
        unit: 'خدمة',
        createdAt: DateTime.now(),
      ),
    ];
  }
}
