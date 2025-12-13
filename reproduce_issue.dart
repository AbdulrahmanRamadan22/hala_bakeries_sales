
void main() {
  final products = [
    Product(name: "Bread", barcode: "123456"),
    Product(name: "Milk", barcode: "789012"),
    Product(name: "Cheese", barcode: "ABC-123"),
  ];

  testSearch(products, "123");
  testSearch(products, "Bread");
  testSearch(products, "bread");
  testSearch(products, "ABC");
  testSearch(products, "abc"); // Case sensitivity check
  testSearch(products, "١٢٣"); // Arabic digits check
}

void testSearch(List<Product> products, String query) {
  final trimmedQuery = query.trim().toLowerCase();
  print("Searching for: '$query' (trimmed/lower: '$trimmedQuery')");
  
  final filtered = products.where((p) {
    return p.name.toLowerCase().contains(trimmedQuery) ||
           p.barcode.contains(trimmedQuery);
  }).toList();

  print("Found ${filtered.length} results:");
  for (var p in filtered) {
    print("- ${p.name} (${p.barcode})");
  }
  print("---");
}

class Product {
  final String name;
  final String barcode;

  Product({required this.name, required this.barcode});
}
