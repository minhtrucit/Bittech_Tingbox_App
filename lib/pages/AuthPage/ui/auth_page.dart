import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../ting_box.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    required this.onLogin,
    required this.phoneController,
    required this.passwordController,
    required this.isPhoneValid,
    required this.onPhoneChanged,
  });

  final VoidCallback onLogin;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final bool isPhoneValid;
  final void Function(String) onPhoneChanged;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8.w,
          children: [
            Icon(
              CupertinoIcons.chart_bar_alt_fill,
              size: 32,
              color: AppColors.primaryBlue,
            ),
            TitleAppbarText(title: 'Sổ chi phí'),
          ],
        ),
      ),
      backgroundColor: AppColors.white,
      body: SizedBox.expand(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 28.h,
              children: [
                buildMainTitle(context),
                buildLoginForm(context),
                buildButtonSubmit(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildButtonSubmit() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          debugPrint("Đăng nhập");
          onLogin();
        },
        child: const Text(
          "Đăng nhập",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget buildLoginForm(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Số điện thoại",
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: phoneController,
            onChanged: onPhoneChanged,
            decoration: InputDecoration(
              hintText: "Nhập sđt của bạn",
              errorText: isPhoneValid ? null : "Số điện thoại không hợp lệ",
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: isPhoneValid ? AppColors.primaryBlue : Colors.red,
                  width: 2,
                ),
              ),
            ),
          ),

          SizedBox(height: 28.h),

          Text(
            "Mật khẩu",
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextField(
            obscureText: true,
            controller: passwordController,
            decoration: InputDecoration(
              hintText: "Nhập mật khẩu",
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: const Icon(Icons.visibility_off_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Quên mật khẩu?",
              style: TextStyle(
                color: Colors.blue.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMainTitle(BuildContext context) {
    return Flexible(
      child: Column(
        spacing: 8.h,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Chào mừng trở lại",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 32.sp,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            "Đăng nhập để tiếp tục quản lý chi phí của bạn.",
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
