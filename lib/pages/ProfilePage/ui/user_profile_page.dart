import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ting_box/models/bank.dart';
import 'package:ting_box/pages/ConfigPage/bloc/config_bloc.dart';
import 'package:ting_box/pages/ConfigPage/bloc/config_event.dart';

import '../../../ting_box.dart';
import '../../ConfigPage/bloc/config_state.dart';
import 'user_profile_skeleton.dart';
import '../../ConfigPage/ui/config_page.dart';
import '../../MyQrPage/ui/my_qr_page.dart';
import '../../PrintPage/print_page.dart';
import 'account_info_page.dart';

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

      if (userId != null) {
        if (mounted) {
          context.read<UserProfileBloc>().add(GetUserEvent(userId: userId));
          context.read<ConfigBloc>().add(GetConfigEvent(userId: userId));
        }
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
            if (state is AuthLogoutSuccess && mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const Auth()),
                (route) => false,
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
            if (state is ConfigLoaded) {
              config = state.config;
            } else if (state is ConfigUpdateSuccess) {
              config = state.config;
            } else if (state is ConfigCreateSuccess) {
              config = state.config;
            }
          },
        ),
        BlocListener<UserProfileBloc, UserProfileState>(
          listener: (context, state) {
            if (state is UserProfileSuccess) {
              setState(() {
                _currentUser = state.user;
              });
            }
          },
        ),
      ],
      child: BlocBuilder<UserProfileBloc, UserProfileState>(
        builder: (context, state) {
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
                            _buildUserInfoHeader(user),
                            _buildInfoCard(user),
                            SizedBox(
                              height:
                                  60.h +
                                  MediaQuery.of(
                                    context,
                                  ).systemGestureInsets.bottom,
                            ),
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
          return const UserProfileSkeleton();
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: const TitleAppbarText(title: "Tài khoản của tôi"),
    );
  }

  Widget _buildUserInfoHeader(User user) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: const Color(0xFFEDE7DB),
            backgroundImage:
                user.avatar != null ? NetworkImage(user.avatar!) : null,
            child:
                user.avatar == null
                    ? const Icon(Icons.person, size: 56, color: Colors.black54)
                    : null,
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

  Widget _buildInfoCard(User user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        spacing: 10,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AccountInfoPage(user: user)),
              );
            },
            child: _buildInfoTile(
              icon: Icons.person_outline_rounded,
              title: "Thông tin tài khoản",
              subtitle: "Cài đặt thông tin tài khoản",
              isLink: true,
            ),
          ),
          if (config != null &&
              !(user.roleId == 4 &&
                  config?.subscriptionPlan == SubscriptionPlan.basic)) ...[
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyQrPage(user: user, config: config!),
                  ),
                );
              },
              child: _buildInfoTile(
                icon: Icons.qr_code_scanner_outlined,
                title: "QR của tôi",
                subtitle: "Thông tin QR của bạn",
                isLink: true,
              ),
            ),
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
                isLink: true,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrintPage()),
                );
              },
              child: _buildInfoTile(
                icon: Icons.print_outlined,
                title: "Kết nối máy in",
                subtitle: "Kết nối máy in và in thử",
                isLink: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isLink = false,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          if (isLink) const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        ],
      ),
    );
  }
}
