import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ting_box/models/bank.dart';
import 'package:ting_box/pages/ConfigPage/bloc/config_bloc.dart';
import 'package:ting_box/pages/ConfigPage/bloc/config_event.dart';

import '../../../models/config_model.dart';
import '../../../ting_box.dart';
import '../../ConfigPage/bloc/config_state.dart';
import 'user_profile_skeleton.dart';
import '../../ConfigPage/ui/config_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  ConfigModel? config;
  List<Bank> bankList = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      // Check if data is already loaded
      final currentState = context.read<UserProfileBloc>().state;
      if (currentState is UserProfileSuccess) {
        debugPrint("👤 UserProfilePage: User already loaded, skipping fetch.");
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(UserRepository.keyUserId);
      debugPrint("👤 UserProfilePage: userId from prefs: $userId");

      if (userId != null && mounted) {
        context.read<UserProfileBloc>().add(GetUserEvent(userId: userId));
        context.read<ConfigBloc>().add(GetConfigEvent(userId: userId));
      } else {
        debugPrint("⚠️ UserProfilePage: userId is null");
      }
    } catch (e) {
      debugPrint("❌ UserProfilePage: Error loading user: $e");
    }
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
      ],
      child: BlocBuilder<UserProfileBloc, UserProfileState>(
        builder: (context, state) {
          if (state is UserProfileLoading) {
            return const UserProfileSkeleton();
          }
          if (state is UserProfileFailure) {
            return const UserProfileSkeleton();
          }
          if (state is UserProfileSuccess) {
            final user = state.user;
            return Stack(
              children: [
                AppScaffold(
                  backgroundColor: AppColors.white,
                  appBar: _buildAppBar(context),
                  body: SafeArea(
                    child: Column(
                      children: [
                        _buildUserInfoSection(user),
                        _buildInfoCard(user),
                        const Spacer(),
                        SizedBox(height: 40.h),
                        _buildLogoutButton(context),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
                if (_isLoadingOverlay) const LoadingOverlay(),
              ],
            );
          }
          return const UserProfileSkeleton();
        },
      ),
    );
  }

  // ───────────────────────────────────────────
  // 1️⃣ AppBar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: TitleAppbarText(title: "Tài khoản của tôi"),
    );
  }

  // ───────────────────────────────────────────

  Widget _buildUserInfoSection(User user) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFFEDE7DB),
                backgroundImage:
                    user.avatar != null ? NetworkImage(user.avatar!) : null,
                child:
                    user.avatar == null
                        ? const Icon(
                          Icons.person,
                          size: 56,
                          color: Colors.black54,
                        )
                        : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user.userName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────
  Widget _buildInfoCard(User user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
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
