# Currency Input Formatter

## Mô tả
`CurrencyInputFormatter` là một custom `TextInputFormatter` để tự động format số tiền với dấu phẩy ngăn cách hàng nghìn khi user nhập.

## Tính năng
- ✅ Tự động thêm dấu phẩy khi nhập: `1000` → `1,000`
- ✅ Hỗ trợ số lớn: `1000000` → `1,000,000`
- ✅ Giữ vị trí cursor chính xác khi nhập ở giữa
- ✅ Chỉ cho phép nhập số
- ✅ Helper methods để parse và format giá trị

## Cách sử dụng

### 1. Import formatter
```dart
import 'package:your_app/utils/currency_input_formatter.dart';
```

### 2. Áp dụng cho TextField
```dart
TextField(
  controller: priceController,
  keyboardType: TextInputType.number,
  inputFormatters: [CurrencyInputFormatter()],
  decoration: InputDecoration(
    hintText: '0đ',
  ),
)
```

### 3. Parse giá trị khi submit
```dart
// Lấy giá trị số từ formatted text
final price = CurrencyInputFormatter.parseValue(priceController.text) ?? 0.0;

// Sử dụng price cho logic
Product product = Product(
  name: nameController.text,
  price: price, // Đã loại bỏ dấu phẩy
);
```

### 4. Format giá trị ban đầu
```dart
// Khi hiển thị giá trị có sẵn (ví dụ: edit mode)
priceController.text = CurrencyInputFormatter.formatValue(product.price);
// Ví dụ: product.price = 1000000 → priceController.text = "1,000,000"
```

## Ví dụ đầy đủ

```dart
class EditProductPage extends StatefulWidget {
  final Product product;
  
  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late TextEditingController priceCtrl;
  
  @override
  void initState() {
    super.initState();
    // Format giá trị ban đầu
    priceCtrl = TextEditingController(
      text: CurrencyInputFormatter.formatValue(widget.product.price),
    );
  }
  
  Future<void> handleSave() async {
    // Parse giá trị khi save
    final price = CurrencyInputFormatter.parseValue(priceCtrl.text) ?? 0.0;
    
    Product updatedProduct = Product(
      id: widget.product.id,
      name: nameCtrl.text,
      price: price,
    );
    
    // Save product...
  }
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: priceCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [CurrencyInputFormatter()],
      decoration: InputDecoration(
        hintText: '0đ',
        labelText: 'Giá tiền',
      ),
    );
  }
}
```

## API Reference

### CurrencyInputFormatter()
Constructor để tạo formatter instance.

### Static Methods

#### `parseValue(String formattedText) → double?`
Parse formatted text thành số.
- **Input:** `"1,000,000"` 
- **Output:** `1000000.0`
- **Return:** `null` nếu text rỗng

#### `formatValue(double value) → String`
Format số thành text với dấu phẩy.
- **Input:** `1000000.0`
- **Output:** `"1,000,000"`

## Lưu ý
- Formatter chỉ cho phép nhập số (0-9)
- Dấu phẩy được thêm tự động, user không cần nhập
- Khi parse, tất cả dấu phẩy sẽ được loại bỏ
- Sử dụng format `en_US` (dấu phẩy cho hàng nghìn)
