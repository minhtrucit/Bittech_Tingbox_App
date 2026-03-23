import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ting_box/ting_box.dart';

class Auth extends StatefulWidget {
  const Auth({super.key});

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  late final AuthBloc authBloc;
  bool isPhoneValid = true;
  bool isPasswordValid = true;
  String? phoneError;
  String? passwordError;
  bool _isLoadingOverlay = false;
  final String loginFailTitle = 'Đăng nhập thất bại';

  // Remember me feature
  User? savedUser;
  bool isQuickLoginMode = false;

  @override
  void initState() {
    super.initState();
    authBloc = BlocProvider.of<AuthBloc>(context);
    _loadSavedUser();
    debugPrint('[Auth] initState: AuthBloc initialized');
  }

  Future<void> _loadSavedUser() async {
    // Current active session
    final user = await UserRepository.getUser();
    if (user != null) {
      if (!mounted) return;
      setState(() {
        savedUser = user;
        isQuickLoginMode = true;
        if (phoneController.text.isEmpty) {
          phoneController.text = user.phone;
        }
      });
      debugPrint('[Auth] Loaded active session user: ${user.userName}');
      return;
    }

    // No active session, check for last logged in user for quick login UI
    final lastUser = await UserRepository.getLastUser();
    if (lastUser != null) {
      if (!mounted) return;
      setState(() {
        savedUser = lastUser;
        isQuickLoginMode = true;
        if (phoneController.text.isEmpty) {
          phoneController.text = lastUser.phone;
        }
      });
      debugPrint('[Auth] Loaded last remembered user: ${lastUser.userName}');
    } else {
      // If no User data at all, still try to remember the last phone used
      final lastPhone = await UserRepository.getLastPhone();
      if (lastPhone != null && lastPhone.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          if (phoneController.text.isEmpty) {
            phoneController.text = lastPhone;
          }
        });
      }
    }
  }

  void switchLoginMode() {
    setState(() {
      isQuickLoginMode = !isQuickLoginMode;
      if (!isQuickLoginMode) {
        // Switch to full login mode
        phoneController.clear();
        passwordController.clear();
        phoneError = null;
        passwordError = null;
      } else {
        // Switch back to quick login
        if (savedUser != null) {
          phoneController.text = savedUser!.phone;
        }
      }
    });
  }

  void onPhoneChanged(String value) {
    setState(() {
      isPhoneValid = isValidPhone(value);
      if (value.isNotEmpty) {
        phoneError = null; // Clear error when user types
      }
    });
    debugPrint('[Auth] onPhoneChanged: $value, isPhoneValid=$isPhoneValid');
  }

  void onPasswordChanged(String value) {
    setState(() {
      if (value.isNotEmpty) {
        passwordError = null; // Clear error when user types
        isPasswordValid = true;
      }
    });
  }

  bool isValidPhone(String phone) {
    final regex = RegExp(r'^[0-9]{6,15}$');
    return regex.hasMatch(phone);
  }

  void handleSubmit() {
    final phone = phoneController.text.trim();
    final pass = passwordController.text.trim();

    bool hasError = false;

    // Validate phone
    if (phone.isEmpty) {
      setState(() {
        phoneError = 'Vui lòng nhập số điện thoại';
        isPhoneValid = false;
      });
      hasError = true;
    } else if (!isValidPhone(phone)) {
      setState(() {
        phoneError = 'Số điện thoại không hợp lệ';
        isPhoneValid = false;
      });
      hasError = true;
    }

    // Validate password
    if (pass.isEmpty) {
      setState(() {
        passwordError = 'Vui lòng nhập mật khẩu';
        isPasswordValid = false;
      });
      hasError = true;
    }

    if (hasError) {
      debugPrint('[Auth] handleSubmit: Validation failed');
      return;
    }

    debugPrint('[Auth] handleSubmit: Sending LoginEvent phone=$phone');
    authBloc.add(LoginEvent(phone: phone, password: pass));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        debugPrint('[AuthListener] state changed: $state');
        if (!mounted) return;
        if (state is AuthLoading) {
          setState(() => _isLoadingOverlay = true);
          debugPrint('[AuthListener] AuthLoading: show overlay');
        } else {
          setState(() => _isLoadingOverlay = false);
          debugPrint('[AuthListener] AuthLoading finished: hide overlay');
        }

        if (state is AuthSuccess) {
          debugPrint('[AuthListener] AuthSuccess: Navigate to BasePage');

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const BasePage()),
            );
          }
        }
        if (state is AuthLogoutSuccess) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        if (state is AuthFailure) {
          debugPrint('[AuthListener] AuthFailure: ${state.message}');
          if (mounted) {
            DialogUtils.showAppDialog(
              context: context,
              title: loginFailTitle,
              content: state.message,
              onFirstAction: () => Navigator.of(context).pop(),
              firstActionText: 'OK',
            );
          }
        }
      },
      child: Stack(
        children: [
          BlocBuilder<AuthBloc, AuthState>(
            buildWhen: (previous, current) => previous != current,
            builder: (context, state) {
              return AuthPage(
                onPhoneChanged: onPhoneChanged,
                onPasswordChanged: onPasswordChanged,
                onLogin: handleSubmit,
                isPhoneValid: isPhoneValid,
                phoneError: phoneError,
                passwordError: passwordError,
                phoneController: phoneController,
                passwordController: passwordController,
                savedUser: savedUser,
                isQuickLoginMode: isQuickLoginMode,
                onSwitchLoginMode: switchLoginMode,
              );
            },
          ),
          if (_isLoadingOverlay) LoadingOverlay(),
        ],
      ),
    );
  }
}
