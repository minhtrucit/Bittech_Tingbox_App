import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../../ting_box.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    required this.onLogin,
    required this.phoneController,
    required this.passwordController,
    required this.isPhoneValid,
    required this.onPhoneChanged,
    required this.onPasswordChanged,
    required this.onSwitchLoginMode,
    this.phoneError,
    this.passwordError,
    this.savedUser,
    this.isQuickLoginMode = false,
  });

  final VoidCallback onLogin;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final bool isPhoneValid;
  final void Function(String) onPhoneChanged;
  final void Function(String) onPasswordChanged;
  final VoidCallback onSwitchLoginMode;
  final String? phoneError;
  final String? passwordError;
  final User? savedUser;
  final bool isQuickLoginMode;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isShowPassword = false;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      hasSafeArea: false,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).systemGestureInsets.bottom),
        child: Column(
          children: [
            Expanded(child: Stack(children: [_buildLogo(), _buildLoginCard()])),
            _buildHotline(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 295.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SvgPicture.asset(
              'assets/icons/bg-login.svg',
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.fitWidth,
            ),
          ),

           Center(
            child: Image.asset(
              'assets/images/tingbox_login/tingbox_logo_login.png',
              fit: BoxFit.contain,
              width: 140,
              height: 140,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Positioned(
      top: 250.h - MediaQuery.of(context).viewInsets.bottom * 0.60,
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.symmetric(horizontal: 8.w),

        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back!',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Login to continue',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp),
              ),
              SizedBox(height: 24.h),
              if (widget.isQuickLoginMode && widget.savedUser != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      spacing: 8.w,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 16.r,
                          backgroundImage:
                              widget.savedUser?.avatar != null
                                  ? NetworkImage(widget.savedUser!.avatar ?? '')
                                  : null,
                          child:
                              widget.savedUser?.avatar != null
                                  ? null
                                  : Icon(
                                    Icons.person,
                                    size: 24.r,
                                    color: AppColors.primaryBlue,
                                  ),
                        ),
                        Text.rich(
                          TextSpan(
                            text: 'Xin chào, ',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.normal,
                            ),
                            children: [
                              TextSpan(
                                text: '${widget.savedUser!.userName}!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: widget.onSwitchLoginMode,
                      child: Icon(
                        CupertinoIcons.refresh_bold,
                        color: Colors.grey,
                        size: 24.r,
                      ),
                    ),
                  ],
                )
              else
                _buildTextField(
                  controller: widget.phoneController,
                  label: 'Tên đăng nhập',
                  hint: '',
                  onChanged: widget.onPhoneChanged,
                  errorText: widget.phoneError,
                ),
              SizedBox(height: 16.h),
              _buildTextField(
                controller: widget.passwordController,
                label: 'Mật khẩu',
                hint: '',
                isPassword: true,
                onChanged: widget.onPasswordChanged,
                errorText: widget.passwordError,
              ),
              SizedBox(height: 32.h),
              _buildLoginButton(),
              SizedBox(height: 16.h),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Quên mật khẩu?',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isPassword = false,
    void Function(String)? onChanged,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          obscureText: isPassword && !isShowPassword,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            filled: true,
            fillColor: Colors.grey.shade50,
            suffixIcon:
                isPassword
                    ? IconButton(
                      onPressed: () {
                        setState(() {
                          isShowPassword = !isShowPassword;
                        });
                      },
                      icon: Icon(
                        isShowPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey.shade400,
                      ),
                    )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : Colors.grey.shade200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : AppColors.primaryBlue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: widget.onLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child: Text(
          'ĐĂNG NHẬP',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildHotline() {
    return Stack(
      children: [
        CustomPaint(size: Size(double.infinity, 80.h), painter: WavePainter()),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Text(
            'Hotline: 0939 46 7080',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.primaryBlue
          ..style = PaintingStyle.fill;

    final path = Path();

    // Start from bottom left
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);

    // Create wave curve at the top
    path.quadraticBezierTo(
      size.width * 0.75, // control point x
      -20, // control point y (negative for upward curve)
      size.width * 0.5, // end point x
      0, // end point y
    );

    path.quadraticBezierTo(
      size.width * 0.25, // control point x
      20, // control point y (positive for downward curve)
      0, // end point x
      0, // end point y
    );

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
