import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../ting_box.dart';

class ProductBottomSheet extends StatefulWidget {
  final List<Product> products;
  final Function(Product) onSelected;

  const ProductBottomSheet({
    super.key,
    required this.products,
    required this.onSelected,
  });

  @override
  State<ProductBottomSheet> createState() => _ProductBottomSheetState();
}

class _ProductBottomSheetState extends State<ProductBottomSheet> {
  Product? selectedProduct;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(GetProductsEvent());
    if (widget.products.isNotEmpty) {
      selectedProduct = widget.products.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chọn sản phẩm thay thế',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 20, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm sản phẩm...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue),
                borderRadius: BorderRadius.circular(12.r),
              ),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
          SizedBox(height: 8),
          // List of products
          BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              if (state is ProductLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              List<Product> currentProducts = [];
              if (state is ProductLoadProductsSuccess) {
                currentProducts = state.products;
              } else {
                // Fallback to widget.products if needed or empty
                currentProducts = widget.products;
              }

              final filteredProducts =
                  currentProducts
                      .where(
                        (p) => p.name.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();

              if (filteredProducts.isEmpty && state is! ProductLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Không tìm thấy sản phẩm"),
                  ),
                );
              }

              return SizedBox(
                height: 300,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final isSelected = selectedProduct == product;
                
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 0.5,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Color(0xFFDFE8FA)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: RadioListTile<Product>(
                            activeColor: AppColors.primaryBlue,
                            title: Text(
                              product.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              '${formatMoney(product.price)}đ',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.grey),
                            ),
                            value: product,
                            groupValue: selectedProduct,
                            onChanged: (value) {
                              setState(() {
                                selectedProduct = value;
                              });
                            },
                            secondary: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                product.images!.isNotEmpty ?
                                product.images!.first.url : '',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 12),
          // Buttons
          Row(
            children: [
              Expanded(
                child: AppTextButton(
                  style: ButtonStyle(
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          width: 1.w,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                    backgroundColor: WidgetStatePropertyAll(AppColors.white),
                    textStyle: WidgetStatePropertyAll(
                      Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  label: Text(
                    "Hủy",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: AppTextButton(
                  style: ButtonStyle(
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    backgroundColor: WidgetStatePropertyAll(
                      AppColors.primaryBlue,
                    ),
                    textStyle: WidgetStatePropertyAll(
                      Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  onPressed: () {
                    if (selectedProduct != null) {
                      widget.onSelected(selectedProduct!);
                      Navigator.pop(context);
                    }
                  },
                  label: Text(
                    "Chọn",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
