import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/overlay_geometry.dart';

/// The ML Kit adapter: camera frames and still photos in, pure-Dart
/// [BodyLandmarks] out. Everything else about placement is in
/// `overlay_geometry.dart`.
class PoseEngine {
  PoseEngine({required bool stream})
    : _detector = PoseDetector(
        options: PoseDetectorOptions(
          mode: stream ? PoseDetectionMode.stream : PoseDetectionMode.single,
          model: stream ? PoseDetectionModel.base : PoseDetectionModel.accurate,
        ),
      );

  final PoseDetector _detector;

  Future<BodyLandmarks?> detect(InputImage image, Size uprightSize) async {
    final poses = await _detector.processImage(image);
    if (poses.isEmpty) return null;
    return landmarksFromPose(poses.first, uprightSize);
  }

  Future<void> close() => _detector.close();
}

const Map<PoseLandmarkType, BodyPoint> _pointMap = {
  PoseLandmarkType.nose: BodyPoint.nose,
  PoseLandmarkType.leftShoulder: BodyPoint.leftShoulder,
  PoseLandmarkType.rightShoulder: BodyPoint.rightShoulder,
  PoseLandmarkType.leftElbow: BodyPoint.leftElbow,
  PoseLandmarkType.rightElbow: BodyPoint.rightElbow,
  PoseLandmarkType.leftWrist: BodyPoint.leftWrist,
  PoseLandmarkType.rightWrist: BodyPoint.rightWrist,
  PoseLandmarkType.leftHip: BodyPoint.leftHip,
  PoseLandmarkType.rightHip: BodyPoint.rightHip,
  PoseLandmarkType.leftKnee: BodyPoint.leftKnee,
  PoseLandmarkType.rightKnee: BodyPoint.rightKnee,
  PoseLandmarkType.leftAnkle: BodyPoint.leftAnkle,
  PoseLandmarkType.rightAnkle: BodyPoint.rightAnkle,
  PoseLandmarkType.leftHeel: BodyPoint.leftHeel,
  PoseLandmarkType.rightHeel: BodyPoint.rightHeel,
  PoseLandmarkType.leftFootIndex: BodyPoint.leftFootIndex,
  PoseLandmarkType.rightFootIndex: BodyPoint.rightFootIndex,
};

BodyLandmarks landmarksFromPose(Pose pose, Size uprightSize) {
  final points = <BodyPoint, Landmark>{};
  for (final entry in pose.landmarks.entries) {
    final p = _pointMap[entry.key];
    if (p == null) continue;
    final l = entry.value;
    points[p] = Landmark(Pt(l.x, l.y), likelihood: l.likelihood);
  }
  return BodyLandmarks(
    points: points,
    imageWidth: uprightSize.width,
    imageHeight: uprightSize.height,
  );
}

/// A camera frame ready for ML Kit, with the size of the frame once rotated
/// upright (the space ML Kit's landmarks are in).
class CameraFrame {
  const CameraFrame(this.input, this.uprightSize, this.luma);

  final InputImage input;
  final Size uprightSize;

  /// The luminance plane (or the first plane), for the low-light check.
  final Uint8List luma;
}

const _orientations = {
  DeviceOrientation.portraitUp: 0,
  DeviceOrientation.landscapeLeft: 90,
  DeviceOrientation.portraitDown: 180,
  DeviceOrientation.landscapeRight: 270,
};

/// Converts a streamed [image] into an [InputImage]. Android must stream
/// NV21 and iOS BGRA8888 (see [streamFormatGroup]); anything else returns
/// null and the frame is skipped.
CameraFrame? frameFromCameraImage(
  CameraImage image,
  CameraDescription camera,
  DeviceOrientation deviceOrientation,
) {
  final sensor = camera.sensorOrientation;
  InputImageRotation? rotation;
  if (Platform.isIOS) {
    rotation = InputImageRotationValue.fromRawValue(sensor);
  } else if (Platform.isAndroid) {
    final device = _orientations[deviceOrientation] ?? 0;
    final compensation = camera.lensDirection == CameraLensDirection.front
        ? (sensor + device) % 360
        : (sensor - device + 360) % 360;
    rotation = InputImageRotationValue.fromRawValue(compensation);
  }
  if (rotation == null) return null;

  final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
  if (format == null ||
      (Platform.isAndroid && format != InputImageFormat.nv21) ||
      (Platform.isIOS && format != InputImageFormat.bgra8888)) {
    return null;
  }
  if (image.planes.length != 1) return null;
  final plane = image.planes.first;

  final size = Size(image.width.toDouble(), image.height.toDouble());
  final sideways =
      rotation == InputImageRotation.rotation90deg ||
      rotation == InputImageRotation.rotation270deg;
  return CameraFrame(
    InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: size,
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    ),
    sideways ? Size(size.height, size.width) : size,
    // NV21 starts with the full-resolution Y plane; for BGRA the bytes are
    // colour, which is close enough for a "too dark" check.
    plane.bytes,
  );
}

ImageFormatGroup get streamFormatGroup =>
    Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888;
