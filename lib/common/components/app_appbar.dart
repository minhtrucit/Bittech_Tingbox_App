import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_colors.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.centerTitle,
    this.elevation,
    this.systemOverlayStyle,
    this.onLeadingClick,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final bool? centerTitle;
  final double? elevation;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final VoidCallback? onLeadingClick;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: elevation ?? 0,
      backgroundColor: backgroundColor ?? AppColors.white,

      leading:
          leading != null
              ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onLeadingClick,
                child: leading,
              )
              : null,
      title: title,
      actions: actions,
      centerTitle: centerTitle ?? true,
      systemOverlayStyle: systemOverlayStyle,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
