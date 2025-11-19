import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class CameraUtils {
  CameraUtils._();

  static Future<CameraDescription> getCamera(CameraLensDirection dir) async {
    final cameras = await availableCameras();
    return cameras.firstWhere(
          (camera) => camera.lensDirection == dir,
    );
  }


  static Future<void> lockCaptureOrientation(
      CameraController controller,
      ) async {
    await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
  }

  static Widget buildCameraPreview(CameraController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final deviceRatio = size.width / size.height;
        final xScale = (controller.value.description.sensorOrientation == 90 ||
            controller.value.description.sensorOrientation == 270
            ? (1 / controller.value.aspectRatio)
            : controller.value.aspectRatio) /
            deviceRatio;
        const yScale = 1.0;
        final transform = Matrix4.diagonal3Values(xScale, yScale, 1);
        // if (Platform.isAndroid &&
        //     controller.value.description.lensDirection ==
        //         CameraLensDirection.front) {
        //   transform.rotateY(math.pi);
        // }
        return AspectRatio(
          aspectRatio: deviceRatio,
          child: Transform(
            alignment: Alignment.center,
            transform: transform,
            child: CameraPreview(controller),
          ),
        );
      },
    );
  }

  static int getPhotoRotation(
      int sensorOrientation,
      DeviceOrientation deviceOrientation,
      ) {
    if (deviceOrientation == DeviceOrientation.portraitUp) {
      return 0;
    }
    if (sensorOrientation == 90 &&
        deviceOrientation == DeviceOrientation.landscapeLeft) {
      return -90;
    }
    if (sensorOrientation == 90 &&
        deviceOrientation == DeviceOrientation.landscapeRight) {
      return 90;
    }
    if (sensorOrientation == 270 &&
        deviceOrientation == DeviceOrientation.landscapeLeft) {
      return -90;
    }
    if (sensorOrientation == 270 &&
        deviceOrientation == DeviceOrientation.landscapeRight) {
      return 90;
    }
    if (deviceOrientation == DeviceOrientation.portraitDown) {
      return 180;
    }
    return 0;
  }
}
