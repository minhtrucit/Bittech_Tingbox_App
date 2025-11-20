import 'package:flutter/material.dart';

import '../app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ModalBarrier(
          dismissible: false,
          color: Colors.black38,
        ),
        const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue,),
        ),
      ],
    );
  }
}
