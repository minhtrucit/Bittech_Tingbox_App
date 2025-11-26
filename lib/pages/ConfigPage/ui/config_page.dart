import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ting_box/ting_box.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final TextEditingController _unitNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _sepayApiKeyController = TextEditingController();

  bool _isApiKeyVisible = false;
  int? _selectedBankIndex;
  int _printModeGroupValue = 1; // 0: Tự động in, 1: Không in, 2: Mặc định

  @override
  void dispose() {
    _unitNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _sepayApiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: Colors.white,
      appBar: AppAppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TitleAppbarText(title: 'Cấu hình'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Tên đơn vị'),
                    SizedBox(height: 8.h),
                    _buildTextField(
                      controller: _unitNameController,
                      hintText: 'Nhập tên đơn vị',
                    ),
                    SizedBox(height: 24.h),
        
                    _buildLabel('Ngân hàng'),
                    SizedBox(height: 8.h),
                    _buildBankGrid(),
                    SizedBox(height: 24.h),
        
                    _buildLabel('Số tài khoản'),
                    SizedBox(height: 8.h),
                    _buildTextField(
                      controller: _accountNumberController,
                      hintText: 'Nhập số tài khoản',
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 24.h),
        
                    _buildLabel('Tên tài khoản'),
                    SizedBox(height: 8.h),
                    _buildTextField(
                      controller: _accountNameController,
                      hintText: 'Nhập tên tài khoản',
                    ),
                    SizedBox(height: 24.h),
        
                    _buildLabel('Sepay API Key'),
                    SizedBox(height: 8.h),
                    _buildTextField(
                      controller: _sepayApiKeyController,
                      hintText: '....................',
                      obscureText: !_isApiKeyVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isApiKeyVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isApiKeyVisible = !_isApiKeyVisible;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 24.h),
        
                    _buildLabel('Chế độ in'),
                    SizedBox(height: 8.h),
                    _buildPrintModeSegmentedControl(),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildBankGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.0,
      ),
      itemCount: 8, // Placeholder for 8 banks
      itemBuilder: (context, index) {
        final isSelected = _selectedBankIndex == index;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedBankIndex = index;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            // Placeholder for bank logo
          ),
        );
      },
    );
  }

  Widget _buildPrintModeSegmentedControl() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<int>(
        groupValue: _printModeGroupValue,
        children: {
          0: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Text(
              'Tự động in',
              style: TextStyle(
                fontSize: 14.sp,
                color:
                    _printModeGroupValue == 0 ? Colors.white : Colors.black54,
              ),
            ),
          ),
          1: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Text(
              'Không in',
              style: TextStyle(
                fontSize: 14.sp,
                color:
                    _printModeGroupValue == 1 ? Colors.white : Colors.black54,
              ),
            ),
          ),
          2: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Text(
              'Mặc định',
              style: TextStyle(
                fontSize: 14.sp,
                color:
                    _printModeGroupValue == 2 ? Colors.white : Colors.black54,
              ),
            ),
          ),
        },
        onValueChanged: (int? value) {
          if (value != null) {
            setState(() {
              _printModeGroupValue = value;
            });
          }
        },
        thumbColor: Colors.blue,
        backgroundColor: Colors.grey[100]!,
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50.h,
        child: ElevatedButton(
          onPressed: () {
            // TODO: Implement save logic
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 0,
          ),
          child: Text(
            'Lưu',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
