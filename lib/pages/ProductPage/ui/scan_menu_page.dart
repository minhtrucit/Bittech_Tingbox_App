import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart'; // Keep this as TakePicturePage result is XFile
import '../../../ting_box.dart';
import '../../Camera/take_picture_page.dart';
import 'menu_scan_result_page.dart';

class ScanMenuPage extends StatefulWidget {
  const ScanMenuPage({super.key});

  @override
  State<ScanMenuPage> createState() => _ScanMenuPageState();
}

class _ScanMenuPageState extends State<ScanMenuPage> {
  bool _isProcessing = false;

  Future<void> _processMenuImage(String imagePath) async {
    setState(() {
      _isProcessing = true;
    });

    context.read<ProductBloc>().add(MenuUploadEvent(imagePath: imagePath));
  }

  Future<void> _takePicture() async {
    final XFile? image = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TakePicturePage()),
    );

    if (image != null) {
      _processMenuImage(image.path);
    }
  }

  Future<void> _pickFromGallery() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'docx', 'doc'],
    );
    if (result != null && result.files.single.path != null) {
      _processMenuImage(result.files.single.path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductMenuScanResultState || state is MenuScanFailure) {
          setState(() {
            _isProcessing = false;
          });
        }
        if (state is ProductMenuScanResultState) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MenuScanResultPage(menu: state.menu),
            ),
          );
        }
        if (state is MenuScanFailure) {
          DialogUtils.showAppDialog(
            context: context,
            title: 'Lỗi',
            content: state.message,
            onFirstAction: () => Navigator.pop(context),
            firstActionText: 'Đóng',
          );
        }
      },
      child: AppScaffold(
        hasSafeArea: false,
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu_rounded,
                    size: 100.sp,
                    color: AppColors.primaryBlue.withValues(alpha: 0.2),
                  ),
                  SizedBox(height: 32.h),
                  Text(
                    "Tự động thêm sản phẩm",
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    "Chụp ảnh menu của quán, hệ thống AI sẽ tự động bóc tách Tên và Giá sản phẩm để thêm vào danh mục của bạn.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 48.h),
                  _buildOptionButton(
                    icon: Icons.camera_alt_rounded,
                    label: "Chụp ảnh menu",
                    onTap: _takePicture,
                    isPrimary: true,
                  ),
                  SizedBox(height: 16.h),
                  _buildOptionButton(
                    icon: Icons.photo_library_rounded,
                    label: "Chọn từ thư viện",
                    onTap: _pickFromGallery,
                    isPrimary: false,
                  ),
                  SizedBox(height: 40.h),
                  _buildTipCard(),
                ],
              ),
            ),
            if (_isProcessing)
              const AILoadingOverlay(message: "AI đang phân tích menu..."),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppColors.primaryBlue : Colors.white,
          foregroundColor: isPrimary ? Colors.white : AppColors.primaryBlue,
          elevation: isPrimary ? 2 : 0,
          side:
              isPrimary
                  ? BorderSide.none
                  : BorderSide(color: AppColors.primaryBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24.sp),
            SizedBox(width: 12.w),
            Text(
              label,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: Colors.amber.shade800,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              "Mẹo: Hãy giữ camera song song với menu và đảm bảo đủ ánh sáng để kết quả nhận diện chính xác nhất.",
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.amber.shade900,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
