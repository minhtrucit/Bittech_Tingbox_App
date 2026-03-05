import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ting_box/ting_box.dart';

class AccountInfoPage extends StatefulWidget {
  final User user;

  const AccountInfoPage({super.key, required this.user});

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  bool _isLoadingOverlay = false;

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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLogoutSuccess) {
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
      child: Stack(
        children: [
          AppScaffold(
            backgroundColor: AppColors.white,
            appBar: AppAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              title: const TitleAppbarText(title: "Thông tin tài khoản"),
              leading: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black,
                size: 20,
              ),
              onLeadingClick: () => Navigator.pop(context),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildAvatarSection(context),
                    const SizedBox(height: 24),
                    _buildDetailsSection(),
                    const SizedBox(height: 40),
                    _buildLogoutButton(context),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoadingOverlay) const LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context) {
    return BlocBuilder<UserProfileBloc, UserProfileState>(
      builder: (context, state) {
        bool isAvatarLoading =
            state is UserProfileSuccess && state.isAvatarUpdating;
        final user = state is UserProfileSuccess ? state.user : widget.user;

        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 24),
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
                          decoration: const BoxDecoration(
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
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.blue,
                        child: Icon(
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

  Widget _buildDetailsSection() {
    return BlocBuilder<UserProfileBloc, UserProfileState>(
      builder: (context, state) {
        final user = state is UserProfileSuccess ? state.user : widget.user;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildInfoTile(
                icon: Icons.email_rounded,
                title: "Email",
                subtitle: user.email,
              ),
              const SizedBox(height: 12),
              _buildInfoTile(
                icon: Icons.phone_in_talk_rounded,
                title: "Số điện thoại",
                subtitle: user.phone,
              ),
              const SizedBox(height: 12),
              _buildInfoTile(
                icon: Icons.badge_outlined,
                title: "Chức vụ",
                subtitle: user.role.name,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade50,
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: AppTextButton(
          onPressed: () {
            _showLogoutConfirmation(context);
          },
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFFFE5E5),
            foregroundColor: Colors.red,
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

  void _showLogoutConfirmation(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: Text(
            "Xác nhận đăng xuất",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          message: const Text(
            "Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?",
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(LogoutEvent());
              },
              isDestructiveAction: true,
              child: const Text(
                "Đăng xuất",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Hủy", style: TextStyle(color: AppColors.primaryBlue)),
          ),
        );
      },
    );
  }
}
