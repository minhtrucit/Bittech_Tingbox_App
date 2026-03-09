import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ting_box/pages/SalesPage/bloc/cart_bloc.dart';
import 'package:ting_box/pages/SalesPage/bloc/cart_event.dart';
import '../../../ting_box.dart';
import 'package:ting_box/pages/SalesPage/bloc/cart_state.dart';
import '../../../models/table_model.dart';
import 'products_list_skeleton.dart';
import 'scan_menu_page.dart';
import '../../ConfigPage/bloc/config_bloc.dart';
import '../../ConfigPage/bloc/config_state.dart';

class ProductsListPage extends StatefulWidget {
  final TableModel? table;
  const ProductsListPage({super.key, this.table});

  @override
  State<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends State<ProductsListPage> {
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = false;
  bool isSearching = false;
  String _searchQuery = '';
  Timer? _debounceTimer;
  bool _isAdmin = false;

  void _loadUser() async {
    final user = await UserRepository.getUser();
    if (mounted) {
      setState(() {
        _isAdmin = user?.roleId == 1 || user == null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
    // Only load products if not already loaded

    context.read<ProductBloc>().add(GetProductsEvent());

    // Listen to search input changes with debounce
    _searchController.addListener(() {
      // Cancel previous timer
      _debounceTimer?.cancel();

      // Show searching state immediately if text is not empty
      if (_searchController.text.isNotEmpty && !isSearching) {
        setState(() {
          isSearching = true;
        });
      }

      // Set new timer for 300ms
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _searchQuery = _searchController.text.toLowerCase();
          isSearching = false;
        });
      });

      // If search is cleared, update immediately
      if (_searchController.text.isEmpty) {
        _debounceTimer?.cancel();
        setState(() {
          _searchQuery = '';
          isSearching = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  List<Product> _filterProducts(List<Product> products) {
    if (_searchQuery.isEmpty) {
      return products;
    }

    return products.where((product) {
      final nameMatch = product.name.toLowerCase().contains(_searchQuery);
      final priceMatch = product.price.toString().contains(_searchQuery);
      return nameMatch || priceMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listenWhen: (prev, curr) => prev != curr,
      listener: (context, state) {
        if (state is ProductLoading) {
          setState(() {
            isLoading = true;
          });
        }

        if (state is ProductLoadProductsSuccess ||
            state is ProductUpdateSuccess ||
            state is ProductCreateSuccess ||
            state is ProductFailure ||
            state is ProductLoadCategoriesSuccess) {
          setState(() {
            isLoading = false;
          });
        }
      },
      child: AppScaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: BlocBuilder<ConfigBloc, ConfigState>(
            builder: (context, configState) {
              bool isFnB = false;
              if (configState is ConfigLoaded) {
                isFnB = configState.config.businessMode == BusinessMode.fnb;
              }

              // Only allow selling if we have a table OR if it's not FnB mode (Retail)
              final bool isManagementMode = isFnB && widget.table == null;

              return Stack(
                children: [
                  Column(
                    children: [
                      _buildSearchBar(),
                      isLoading
                          ? const Expanded(child: ProductsListSkeleton())
                          : Expanded(
                            child: BlocBuilder<ProductBloc, ProductState>(
                              builder: (context, state) {
                                if (state is ProductLoading || isSearching) {
                                  return const ProductsListSkeleton();
                                }

                                if (state is ProductLoadProductsSuccess) {
                                  final filteredProducts = _filterProducts(
                                    state.products,
                                  );
                                  return filteredProducts.isEmpty
                                      ? _buildEmptyState()
                                      : _buildProductGrid(
                                        filteredProducts,
                                        isManagementMode,
                                      );
                                }

                                return _buildEmptyState();
                              },
                            ),
                          ),
                    ],
                  ),
                  if (isManagementMode && _isAdmin) _buildAddButton(context),
                  if (!isManagementMode) _buildCartSummary(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppAppBar(title: TitleAppbarText(title: "Sản phẩm"));
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm sản phẩm...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey.shade400),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                  : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
        ),
      ),
    );
  }

  // Widget _buildFilterRow() {
  //   return SizedBox(
  //     width: double.infinity,
  //     height: 56.h,
  //     child: SingleChildScrollView(
  //       scrollDirection: Axis.horizontal,
  //       padding: EdgeInsets.symmetric(horizontal: 16.w),
  //       child: Row(
  //         children: [
  //           _buildFilterChip('Danh mục'),
  //           SizedBox(width: 8.w),
  //           _buildFilterChip('Giá'),
  //           SizedBox(width: 8.w),
  //           _buildFilterChip('Trạng thái'),
  //           SizedBox(width: 8.w),
  //           TextButton.icon(
  //             onPressed: () {},
  //             icon: const Icon(Icons.filter_list, size: 18),
  //             label: const Text('Lọc'),
  //             style: TextButton.styleFrom(
  //               foregroundColor: AppColors.primaryBlue,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildFilterChip(String label) {
  //   return Container(
  //     padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
  //     decoration: BoxDecoration(
  //       border: Border.all(color: Colors.grey.shade300),
  //       borderRadius: BorderRadius.circular(20.r),
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Text(label, style: TextStyle(fontSize: 13.sp, color: Colors.black87)),
  //         SizedBox(width: 4.w),
  //         Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black87),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildProductGrid(List<Product> products, bool isManagementMode) {
    return RefreshIndicator(
      color: AppColors.primaryBlue,
      backgroundColor: AppColors.white,
      onRefresh: () async {
        context.read<ProductBloc>().add(GetProductsEvent());
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        cacheExtent: 2,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return _buildProductCard(products[index], isManagementMode);
        },
      ),
    );
  }

  Widget _buildProductCard(Product product, bool isManagementMode) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder:
                (_, animation, secondaryAnimation) =>
                    ProductDetailPage(product: product),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );

        // Reload list when returning
        if (mounted) {
          context.read<ProductBloc>().add(GetProductsEvent());
        }
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section with Hero for smooth transitions
            Expanded(
              child: Hero(
                tag: 'product-image-${product.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12.r),
                  ),
                  child:
                      product.images != null && product.images!.isNotEmpty
                          ? Image.network(
                            product.images!.first.url,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    _buildPlaceholderImage(),
                          )
                          : _buildPlaceholderImage(),
                ),
              ),
            ),

            // Content section
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF101828),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: formatMoney(product.price),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFF667085),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: ' đ',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: const Color(0xFF667085),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  if (!isManagementMode)
                    GestureDetector(
                      onTap: () {
                        context.read<CartBloc>().add(AddToCartEvent(product));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã thêm ${product.name}'),
                            duration: const Duration(milliseconds: 500),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          color:
                              isManagementMode
                                  ? AppColors.primaryBlue.withAlpha(20)
                                  : const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_shopping_cart_rounded,
                              size: 18.sp,
                              color:
                                  isManagementMode
                                      ? AppColors.primaryBlue
                                      : const Color(0xFF344054),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Thêm',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color:
                                    isManagementMode
                                        ? AppColors.primaryBlue
                                        : const Color(0xFF344054),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Center(
      child: Icon(Icons.image_outlined, size: 48, color: Colors.grey.shade400),
    );
  }

  Widget _buildEmptyState() {
    final isSearchingNow = _searchQuery.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearchingNow ? Icons.search_off : Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16.h),
          Text(
            isSearchingNow ? 'Không tìm thấy sản phẩm' : 'Chưa có sản phẩm nào',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade600),
          ),
          SizedBox(height: 8.h),
          Text(
            isSearchingNow
                ? 'Thử tìm kiếm với từ khóa khác'
                : ' Nhấn nút "Thêm" để tạo sản phẩm mới',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Positioned(
      right: 16.w,
      bottom: 80.h,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Scan Menu Button
          _buildActionLabelButton(
            context,
            icon: Icons.auto_fix_high_rounded,
            color: Colors.amber.shade700,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanMenuPage()),
              );
            },
          ),
          SizedBox(height: 12.h),
          // Standard Add Button
          _buildActionLabelButton(
            context,
            icon: Icons.add,
            color: AppColors.primaryBlue,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateProductPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionLabelButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.all(14.r),
        elevation: 4,
        shadowColor: color.withAlpha(100),
      ),
      icon: Icon(icon, color: Colors.white, size: 24.sp),
    );
  }

  Widget _buildCartSummary() {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state.items.isEmpty) return const SizedBox.shrink();

        return Positioned(
          bottom: 20.h,
          left: 16.w,
          right: 16.w,
          child: GestureDetector(
            onTap: () => _showCurrentSelectionBottomSheet(state),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withAlpha(80),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${state.totalItems}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đã chọn ${state.items.length} món',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${formatMoney(state.totalPrice)} đ',
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (widget.table != null) {
                        _confirmTableOrder(state.items);
                      } else {
                        // Generic checkout
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryBlue,
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      widget.table != null ? 'Gọi món' : 'Giỏ hàng',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmTableOrder(List<Product> products) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác nhận gọi món'),
            content: Text(
              'Gửi ${products.length} món đã chọn vào ${widget.table?.name}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kiểm tra lại'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Construct OrderItems to return
                  final orderItems =
                      products
                          .map(
                            (p) => OrderItem(
                              productId: p.id,
                              quantity: p.quantity,
                              unitPrice: p.price,
                              product: p, // Pass full product info for display
                            ),
                          )
                          .toList();

                  Navigator.pop(context); // Close dialog
                  context.read<CartBloc>().add(ClearCartEvent());

                  // Return the items to table management
                  Navigator.pop(context, orderItems);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã gửi món vào ${widget.table?.name}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                ),
                child: const Text(
                  'Gửi lệnh gọi món',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showCurrentSelectionBottomSheet(CartState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder:
                (_, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24.r),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Món đã chọn',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                context.read<CartBloc>().add(ClearCartEvent());
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Xóa tất cả',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: BlocBuilder<CartBloc, CartState>(
                          builder: (context, cartState) {
                            if (cartState.items.isEmpty) {
                              return Center(
                                child: Text(
                                  'Chưa chọn món nào',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              );
                            }
                            return ListView.builder(
                              controller: scrollController,
                              padding: EdgeInsets.all(16.w),
                              itemCount: cartState.items.length,
                              itemBuilder: (context, index) {
                                final product = cartState.items[index];
                                return _buildSelectionItemCard(product);
                              },
                            );
                          },
                        ),
                      ),
                      _buildBottomSheetFooter(state),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildSelectionItemCard(Product product) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.bgLightGrey.withAlpha(100),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${formatMoney(product.price)} đ',
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildQtyButton(Icons.remove, () {
                context.read<CartBloc>().add(
                  UpdateQuantityEvent(product, product.quantity - 1),
                );
              }),
              Container(
                width: 35.w,
                alignment: Alignment.center,
                child: Text(
                  '${product.quantity}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildQtyButton(Icons.add, () {
                context.read<CartBloc>().add(
                  UpdateQuantityEvent(product, product.quantity + 1),
                );
              }),
              SizedBox(width: 8.w),
              IconButton(
                onPressed: () {
                  context.read<CartBloc>().add(RemoveFromCartEvent(product));
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16.sp, color: AppColors.primaryBlue),
      ),
    );
  }

  Widget _buildBottomSheetFooter(CartState state) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tổng cộng:'),
                Text(
                  '${formatMoney(state.totalPrice)} đ',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.table != null) {
                _confirmTableOrder(state.items);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: const Text(
              'Xác nhận',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTableSelectionDialog(Product product) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      builder:
          (_) => Container(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Chọn điểm đến cho món',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),

                // List of tables (for demo we can take them from a shared provider or pass them in)
                // Here we use a quick selection for demo:
                ListTile(
                  leading: const Icon(
                    Icons.shopping_bag_rounded,
                    color: AppColors.primaryBlue,
                  ),
                  title: const Text('Mang về'),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<CartBloc>().add(AddToCartEvent(product));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã thêm vào giỏ hàng Mang về'),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.table_bar_rounded,
                    color: AppColors.primaryBlue,
                  ),
                  title: const Text('Chọn từ Sơ đồ bàn'),
                  subtitle: const Text(
                    'Bạn hãy quay lại Sơ đồ bàn để chọn chính xác bàn',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pop(context); // Go back to Table Map
                  },
                ),
              ],
            ),
          ),
    );
  }
}
