
class Product {
  final String id;
  final String name;
  final double price;
  final String url;
   int quantity;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.url,
    this.quantity = 1,
  });
}