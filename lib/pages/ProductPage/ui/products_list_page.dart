import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../ting_box.dart';
import 'products_list_skeleton.dart';

class ProductsListPage extends StatefulWidget {
  const ProductsListPage({super.key});

  @override
  State<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends State<ProductsListPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = false;
  bool isSearching = false;
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // Only load products if not already loaded
    final currentState = context.read<ProductBloc>().state;
    if (currentState is! ProductLoadProductsSuccess) {
      context.read<ProductBloc>().add(GetProductsEvent());
    }

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
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return BlocListener<ProductBloc, ProductState>(
      listenWhen: (prev, curr) => prev != curr,
      listener: (context, state) {
        if (state is ProductLoading || state is ProductFailure) {
          setState(() {
            isLoading = true;
          });
        }

        if (state is ProductLoadProductsSuccess) {
          setState(() {
            isLoading = false;
          });
        }
      },
      child: AppScaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildSearchBar(),
                  _buildFilterRow(),
                  isLoading
                      ? const Expanded(child: ProductsListSkeleton())
                      : Expanded(
                        child: BlocBuilder<ProductBloc, ProductState>(
                          builder: (context, state) {
                            // Show skeleton when loading or searching
                            if (state is ProductLoading || isSearching) {
                              return const ProductsListSkeleton();
                            }

                            if (state is ProductLoadProductsSuccess) {
                              final filteredProducts = _filterProducts(
                                state.products,
                              );

                              return filteredProducts.isEmpty
                                  ? _buildEmptyState()
                                  : _buildProductGrid(filteredProducts);
                            }

                            return _buildEmptyState();
                          },
                        ),
                      ),
                ],
              ),
              _buildAddButton(context),
            ],
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

  Widget _buildFilterRow() {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            _buildFilterChip('Danh mục'),
            SizedBox(width: 8.w),
            _buildFilterChip('Giá'),
            SizedBox(width: 8.w),
            _buildFilterChip('Trạng thái'),
            SizedBox(width: 8.w),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_list, size: 18),
              label: const Text('Lọc'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 13.sp, color: Colors.black87)),
          SizedBox(width: 4.w),
          Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black87),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    return GridView.builder(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 100.h),
      physics: BouncingScrollPhysics(),
      cacheExtent: 2,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildProductCard(products[index]);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
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
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Hero
            Expanded(
              child: Hero(
                tag: 'product_${product.id}',
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12.r),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12.r),
                    ),
                    child:
                        product.images!.isNotEmpty
                            ? Image.network(
                              product.images!.map((e) => e).toList()[0].url,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderImage();
                              },
                            )
                            : _buildPlaceholderImage(),
                  ),
                ),
              ),
            ),
            // Product Info
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${formatMoney(product.price)} đ',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey.shade600,
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
                : 'Nhấn nút "Thêm" để tạo sản phẩm mới',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Positioned(
      right: 16.w,
      bottom: 100.h,
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateProductPage()),
          );
        },
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Thêm',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
