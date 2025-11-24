import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../ting_box.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoadingOverlay = false;
  
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(listeners: [
      BlocListener<UserProfileBloc, UserProfileState>(
        listener: (context, state) {
          if (state is UserProfileLoading) {
            setState(() => _isLoadingOverlay = true);
            debugPrint('[UserProfileListener] UserProfileLoading: show overlay');
          } 
          if(state is UserProfileSuccess){
            setState(() => _isLoadingOverlay = false);
            debugPrint('[UserProfileListener] UserProfileLoading finished: hide overlay');

          }
        },
      ),
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
          debugPrint('[AuthListener] AuthLoading: show overlay');
        } else {
          setState(() => _isLoadingOverlay = false);
          debugPrint('[AuthListener] AuthLoading finished: hide overlay');
        }
      },
      ),],
      child: Stack(
        children: [
          AppScaffold(
            backgroundColor: AppColors.white,
            appBar: _buildAppBar(context),
            body: SafeArea(
              child: Column(
                children: [
                  _buildUserInfoSection(),
                  const SizedBox(height: 16),
                  _buildInfoCard(),
                  const Spacer(),
                  const SizedBox(height: 64),
                  _buildLogoutButton(context),
                  const Spacer(),
                ],
              ),
            ),
          ),
          if (_isLoadingOverlay) const LoadingOverlay(),
        ],
      ),
    );
  }
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

Widget _buildUserInfoSection() {
  return Container(
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(vertical: 24),
    decoration: const BoxDecoration(color: Colors.white),
    child: Column(
      children: [
        Stack(
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: Color(0xFFEDE7DB),
              child: Icon(Icons.person, size: 56, color: Colors.black54),
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
        const Text(
          "Tên Người Dùng",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

// ───────────────────────────────────────────
Widget _buildInfoCard() {
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
          subtitle: "user@example.com",
        ),
        const SizedBox(height: 10),
        _buildInfoTile(
          icon: Icons.phone_in_talk_rounded,
          title: "Số điện thoại",
          subtitle: "090xxxxxxx",
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
