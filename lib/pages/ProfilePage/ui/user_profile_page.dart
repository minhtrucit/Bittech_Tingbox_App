import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ting_box/models/bank.dart';
import 'package:ting_box/pages/ConfigPage/bloc/config_bloc.dart';
import 'package:ting_box/pages/ConfigPage/bloc/config_event.dart';

import '../../../ting_box.dart';
import '../../ConfigPage/bloc/config_state.dart';
import 'user_profile_skeleton.dart';
import '../../ConfigPage/ui/config_page.dart';
import '../../MyQrPage/ui/my_qr_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  ConfigModel? config;
  List<Bank> bankList = [];
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(UserRepository.keyUserId);
      debugPrint("👤 UserProfilePage: userId from prefs: $userId");

      if (userId != null) {
        if (mounted) {
          context.read<UserProfileBloc>().add(GetUserEvent(userId: userId));
          context.read<ConfigBloc>().add(GetConfigEvent(userId: userId));
        }
      } else {
        debugPrint("⚠️ UserProfilePage: userId is null");
      }
    } catch (e) {
      debugPrint("❌ UserProfilePage: Error loading user: $e");
    }
  }

  Future<void> _onRefresh() async {
    await _loadUser();
  }

  bool _isLoadingOverlay = false;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthLogoutSuccess) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const Auth()),
              );
            }

            if (state is AuthLoading) {
              setState(() => _isLoadingOverlay = true);
            } else {
              setState(() => _isLoadingOverlay = false);
            }
          },
        ),
        BlocListener<ConfigBloc, ConfigState>(
          listener: (context, state) {
            debugPrint("👤 UserProfilePage: Config state: $state");
            if (state is ConfigLoaded) {
              debugPrint("👤 UserProfilePage: Config loaded: ${state.config}");
              config = state.config;
            } else {
              config = null;
            }
          },
        ),
        BlocListener<UserProfileBloc, UserProfileState>(
          listener: (context, state) {
            if (state is UserProfileSuccess) {
              setState(() {
                _currentUser = state.user;
              });
            } else if (state is UserProfileFailure) {}
          },
        ),
      ],
      child: BlocBuilder<UserProfileBloc, UserProfileState>(
        builder: (context, state) {
          // If we have data, show it (even if loading)
          // If we don't have data AND it's loading, show skeleton
          if (state is UserProfileLoading) {
            return const UserProfileSkeleton();
          }

          if (_currentUser != null) {
            final user = _currentUser!;
            return Stack(
              children: [
                AppScaffold(
                  backgroundColor: AppColors.white,
                  appBar: _buildAppBar(context),
                  body: SafeArea(
                    child: RefreshIndicator(
                      color: AppColors.primaryBlue,
                      backgroundColor: Colors.white,
                      onRefresh: _onRefresh,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            _buildUserInfoSection(user),
                            _buildInfoCard(user),
                            SizedBox(height: 40.h),
                            _buildLogoutButton(context),
                            SizedBox(height: 60.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isLoadingOverlay) const LoadingOverlay(),
              ],
            );
          }
          // Fallback if not loading and no user (e.g. failure initial load)
          return const UserProfileSkeleton();
        },
      ),
    );
  }

  // ───────────────────────────────────────────
  // 1️⃣ AppBar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: TitleAppbarText(title: "Tài khoản của tôi"),
    );
  }

  // ───────────────────────────────────────────

  Future<void> _pickImage(ImageSource source, String userId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      if (mounted) {
        context.read<UserProfileBloc>().add(
          UpdateAvatarEvent(userId: userId, filePath: pickedFile.path),
        );
      }
    }
  }

  void _showAvatarOptions(BuildContext context, String userId) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: Text(
              'Cập nhật ảnh đại diện',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, userId);
                },
                child: Text(
                  'Chụp ảnh',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.black),
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, userId);
                },
                child: Text(
                  'Chọn từ thư viện',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.black),
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Hủy',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.red),
              ),
            ),
          ),
    );
  }

  Widget _buildUserInfoSection(User user) {
    return BlocBuilder<UserProfileBloc, UserProfileState>(
      builder: (context, state) {
        bool isAvatarLoading =
            state is UserProfileSuccess && state.isAvatarUpdating;

        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: const BoxDecoration(color: Colors.white),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _showAvatarOptions(context, user.id.toString()),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: const Color(0xFFEDE7DB),
                      backgroundImage:
                          user.avatar != null
                              ? NetworkImage(user.avatar!)
                              : null,
                      child:
                          user.avatar == null
                              ? const Icon(
                                Icons.person,
                                size: 56,
                                color: Colors.black54,
                              )
                              : null,
                    ),
                    if (isAvatarLoading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.blue,
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user.userName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────
  Widget _buildInfoCard(User user) {
    debugPrint("user.qrCode user profile: ${user.qrCode}");
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MyQrPage(user: user, config: config!,)),
              );
            },
            child: _buildInfoTile(
              icon: Icons.qr_code_scanner_outlined,
              title: "QR của tôi",
              subtitle: "Thông tin QR của bạn",
            ),
          ),
          const SizedBox(height: 10),
          _buildInfoTile(
            icon: Icons.email_rounded,
            title: "Email",
            subtitle: user.email,
          ),
          const SizedBox(height: 10),
          _buildInfoTile(
            icon: Icons.phone_in_talk_rounded,
            title: "Số điện thoại",
            subtitle: user.phone,
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ConfigPage(config: config)),
              );
            },
            child: _buildInfoTile(
              icon: Icons.settings,
              title: "Cấu hình",
              subtitle: "Thiết lập máy in, ngân hàng...",
            ),
          ),
        ],
      ),
    );
  }

  // Item trong Card
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: AppTextButton(
          onPressed: () {
            showCupertinoModalPopup(
              context: context,
              builder: (context) {
                return CupertinoActionSheet(
                  title: Text(
                    "Xác nhận đăng xuất",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  message: const Text(
                    "Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?",
                  ),
                  actions: [
                    CupertinoActionSheetAction(
                      onPressed: () {
                        Navigator.pop(context);
                        BlocProvider.of<AuthBloc>(context).add(LogoutEvent());
                      },
                      isDestructiveAction: true,
                      child: Text(
                        "Đăng xuất",
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.red),
                      ),
                    ),
                  ],
                  cancelButton: CupertinoActionSheetAction(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Hủy",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                );
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFE5E5),
            foregroundColor: Colors.red.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          label: const Text(
            "Đăng xuất",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
  }
}
