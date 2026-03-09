import 'package:flutter/material.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';

class NotificationUtils {
  static double _getNotificationWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > 600 ? 320 : screenWidth * 0.75;
  }

  static void showSuccess({
    required BuildContext context,
    required String title,
    required String description,
  }) {
    ElegantNotification.success(
      width: _getNotificationWidth(context),
      position: Alignment.topRight,
      animation: AnimationType.fromTop,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      description: Text(
        description,
        style: const TextStyle(fontSize: 12),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onDismiss: () {},
    ).show(context);
  }

  static void showError({
    required BuildContext context,
    required String title,
    required String description,
  }) {
    ElegantNotification.error(
      width: _getNotificationWidth(context),
      position: Alignment.topRight,
      animation: AnimationType.fromTop,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      description: Text(
        description,
        style: const TextStyle(fontSize: 12),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onDismiss: () {},
    ).show(context);
  }

  static void showInfo({
    required BuildContext context,
    required String title,
    required String description,
  }) {
    ElegantNotification.info(
      width: _getNotificationWidth(context),
      position: Alignment.topRight,
      animation: AnimationType.fromTop,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      description: Text(
        description,
        style: const TextStyle(fontSize: 12),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onDismiss: () {},
    ).show(context);
  }
}
