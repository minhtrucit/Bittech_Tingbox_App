
class Product {
  final String id;
  final String name;
  final double price;
  // final String imageUrl;
   int quantity;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    // required this.imageUrl,
  });
}