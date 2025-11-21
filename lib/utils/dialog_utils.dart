import 'package:flutter/material.dart';

class DialogUtils {
  static void showAppDialog({
    required BuildContext context,
    required String title,
    required String content,
    required void Function() onFirstAction,
    void Function()? onSecondAction,
    required String firstActionText,
    String? secondActionText,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Text(content),
          actions: <Widget>[

            TextButton(
              onPressed: onFirstAction,
              child: Text(firstActionText, style: Theme.of(context).textTheme.bodyLarge),
            ),
            if(onSecondAction != null && secondActionText != null)
              TextButton(
                onPressed: onSecondAction,
                child: Text(secondActionText, style: Theme.of(context).textTheme.bodyLarge),
              ),
          ],
        );
      },
    );
  }
}
