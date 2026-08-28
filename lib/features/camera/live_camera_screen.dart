







import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/camera_aspect_ratio.dart';
import '../../core/services/app_settings_service.dart';
import '../../core/services/captured_photo_service.dart';
import '../../core/services/live_location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../shared/widgets/widgets.dart';
import '../settings/photo_quality/models/photo_quality_settings.dart';
import '../settings/photo_quality/services/photo_quality_camera_service.dart';
import '../settings/photo_quality/services/photo_quality_settings_service.dart';
import '../gallery/gallery_screen.dart';
import '../stamp_templates/stamp_templates_screen.dart';
import 'capture_preview_screen.dart';
import 'services/camera_exposure_service.dart';
import 'services/camera_orientation_service.dart';
import 'services/captured_image_orientation_service.dart';
import 'widgets/camera_brightness_control.dart';
import 'widgets/camera_ratio_frame.dart';
import 'widgets/responsive_camera_stamp.dart';

class LiveCameraScreen extends StatefulWidget {
  const LiveCameraScreen({super.key});

  @override
  State<LiveCameraScreen> createState() => _LiveCameraScreenState();
}

class _LiveCameraScreenState extends State<LiveCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;

  List<CameraDescription> _cameras = [];

  int _currentCameraIndex = 0;
  int _selectedTemplateIndex = 0;

  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _flashOn = false;
  bool _showBrightness = false;
  Timer? _brightnessHideTimer;

  final CameraExposureService _exposureService = CameraExposureService();
  double _brightnessPercentage = 50;

  final CameraOrientationService _orientationService =
      CameraOrientationService();
  StreamSubscription<DeviceOrientation>? _orientationSubscription;
  DeviceOrientation _deviceOrientation = DeviceOrientation.portraitUp;


  final AppSettingsService _settings = AppSettingsService.instance;
  final PhotoQualitySettingsService _photoQuality =
      PhotoQualitySettingsService.instance;
  PhotoResolutionOption? _activePhotoResolution;

  CapturedPhoto? _recentPhoto;

  CameraAspectRatioOption get _selectedRatio =>
      CameraAspectRatioOption.fromLabel(_settings.aspectRatio);

  bool get _gridOn => _settings.gridLines;


  // ===========================================================================
  // LIVE GPS STAMP
  // ===========================================================================

  final LiveLocationService _locationService = LiveLocationService();
  StreamSubscription<GpsStampData>? _locationSubscription;

  GpsStampData? _liveStampData;
  String? _locationError;

  GpsStampData get _stampData =>
      _liveStampData ??
      GpsStampData(
        address: _locationError ?? 'Locating…',
        title: _locationError == null ? 'Locating…' : 'Location unavailable',
        dateTime: LiveLocationService.formatDateTime(DateTime.now()),
      );

  Future<void> _startLiveLocation() async {
    await _locationSubscription?.cancel();

    _locationSubscription = _locationService.stream.listen(
      (data) {
        if (!mounted) return;

        setState(() {
          _liveStampData = data;
          _locationError = null;
        });
      },
      onError: (Object error) {
        if (!mounted) return;

        setState(() {
          _locationError = error.toString();
        });
      },
    );

    try {
      await _locationService.start();
    } catch (e) {
      debugPrint('Live location start error: $e');

      if (!mounted) return;

      setState(() {
        _locationError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _settings.addListener(_onSettingsChanged);
    _photoQuality.addListener(_onPhotoQualityChanged);

    _initializeCamera();
    _loadRecentPhoto();
    _startLiveLocation();
    _startOrientationListener();
  }


  void _onSettingsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onPhotoQualityChanged() {
    if (!mounted || _cameras.isEmpty || _isInitializing) return;

    final selected = _photoQuality.current.resolution;
    if (selected == _activePhotoResolution) return;

    unawaited(_startCamera(_currentCameraIndex));
  }

  void _changeAspectRatio() {
    final next = _selectedRatio.next;
    _settings.set(() => _settings.aspectRatio = next.label);
  }

  void _toggleGrid() {
    _settings.set(() => _settings.gridLines = !_settings.gridLines);
  }

  void _startOrientationListener() {
    _orientationSubscription?.cancel();
    _orientationSubscription = _orientationService.orientationStream.listen(
      (orientation) {
        if (!mounted || orientation == _deviceOrientation) return;
        setState(() => _deviceOrientation = orientation);
      },
      onError: (Object error) {
        debugPrint('Device orientation sensor error: $error');
      },
    );
  }

  // ===========================================================================
  // LOAD RECENT PHOTO
  // ===========================================================================

  Future<void> _loadRecentPhoto() async {
    try {
      final photos = await CapturedPhotoService.loadPhotos();

      if (!mounted) return;

      setState(() {
        _recentPhoto = photos.isNotEmpty ? photos.first : null;
      });
    } catch (e) {
      debugPrint('Recent photo load error: $e');
    }
  }

  // ===========================================================================
  // CAMERA INITIALIZATION
  // ===========================================================================

  Future<void> _initializeCamera() async {
    try {
      await _photoQuality.ensureLoaded();
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        if (!mounted) return;

        setState(() {
          _isInitializing = false;
        });

        return;
      }

      await _startCamera(_currentCameraIndex);
    } catch (e) {
      debugPrint('Camera initialization error: $e');

      if (!mounted) return;

      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _startCamera(int cameraIndex) async {
    if (_cameras.isEmpty) return;

    if (mounted) {
      setState(() {
        _isInitializing = true;
      });
    }

    await _cameraController?.dispose();

    final selectedResolution = _photoQuality.current.resolution;

    final controller = CameraController(
      _cameras[cameraIndex],
      PhotoQualityCameraService.resolutionPreset(selectedResolution),
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _cameraController = controller;

    try {
      await controller.initialize();

      await controller.setFlashMode(
        _flashOn ? FlashMode.torch : FlashMode.off,
      );

      try {
        await _exposureService.initialize(
          controller,
          percentage: _brightnessPercentage,
        );
        _brightnessPercentage = _exposureService.percentage;
      } catch (e) {
        debugPrint('Exposure is unavailable on this camera: $e');
        _showBrightness = false;
      }

      if (!mounted) return;

      setState(() {
        _activePhotoResolution = selectedResolution;
        _isInitializing = false;
      });
    } catch (e) {
      debugPrint('Camera start error: $e');

      if (!mounted) return;

      setState(() {
        _isInitializing = false;
      });
    }
  }

  // ===========================================================================
  // BRIGHTNESS / EXPOSURE
  // ===========================================================================

  void _showBrightnessControl() {
    _brightnessHideTimer?.cancel();
    if (!_showBrightness) setState(() => _showBrightness = true);
    _scheduleBrightnessHide();
  }

  void _scheduleBrightnessHide() {
    _brightnessHideTimer?.cancel();
    _brightnessHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showBrightness = false);
    });
  }

  void _pauseBrightnessHide() {
    _brightnessHideTimer?.cancel();
  }

  Future<void> _setExposure(double percentage) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    // Update the UI immediately, while the camera applies the value.
    setState(() => _brightnessPercentage = percentage);

    try {
      final applied =
          await _exposureService.setPercentage(controller, percentage);
      if (mounted) setState(() => _brightnessPercentage = applied);
    } catch (e) {
      debugPrint('Exposure adjustment error: $e');
    }
  }

  // ===========================================================================
  // APP LIFECYCLE
  // ===========================================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (controller != null &&
          controller.value.isInitialized) {
        controller.dispose();
        _cameraController = null;
      }

      _locationService.stopListeningOnly();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _loadRecentPhoto();
      _startLiveLocation();

      if (_cameras.isNotEmpty) {
        _startCamera(_currentCameraIndex);
      }
    }
  }

  // ===========================================================================
  // FLASH
  // ===========================================================================

  Future<void> _toggleFlash() async {
    final controller = _cameraController;

    if (controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    try {
      final newValue = !_flashOn;

      await controller.setFlashMode(
        newValue ? FlashMode.torch : FlashMode.off,
      );

      if (!mounted) return;

      setState(() {
        _flashOn = newValue;
      });
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  // ===========================================================================
  // TEMPLATES
  // ===========================================================================

  Future<void> _openTemplates() async {
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => StampTemplatesScreen(
          selectionMode: true,
          initialSelectedIndex: _selectedTemplateIndex,
          stampData: _stampData,
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _selectedTemplateIndex = result;
    });
  }

  // ===========================================================================
  // CAPTURE
  // ===========================================================================

  Future<void> _capture() async {
    final controller = _cameraController;

    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      // Freeze dynamic capture data at shutter time. The camera image itself is
      // normalized immediately after capture, so later phone rotation cannot
      // change the review or final saved orientation.
      final capturedAt = DateTime.now();
      final captureOrientation = _deviceOrientation;

      GpsStampData frozenStamp;

      if (_liveStampData != null) {
        frozenStamp = _locationService.freeze(capturedAt);
      } else {
        frozenStamp = await _locationService.getCurrentStampData();
        frozenStamp = frozenStamp.copyWith(
          dateTime: LiveLocationService.formatDateTime(capturedAt),
        );
      }

      final XFile capturedPhoto = await controller.takePicture();

      // Normalize the camera JPEG before preview. Android camera files can
      // keep sensor pixels sideways and rely on EXIF Orientation. Baking that
      // orientation here gives Capture Preview, saved output and Photo Details
      // one identical upright pixel source.
      final normalizedCapture =
          await CapturedImageOrientationService.normalize(
        sourcePath: capturedPhoto.path,
        deviceOrientation: captureOrientation,
      );

      if (!mounted) {
        await _deleteTemporaryCaptureFiles(
          capturedPhoto.path,
          normalizedCapture.path,
        );
        return;
      }

      final result = await Navigator.of(context).push<int>(
        MaterialPageRoute(
          builder: (_) => CapturePreviewScreen(
            imagePath: normalizedCapture.path,
            originalCameraPath: capturedPhoto.path,
            templateIndex: _selectedTemplateIndex,
            stampData: frozenStamp,
            capturedAt: capturedAt,
            photoAspectRatio: normalizedCapture.aspectRatio,
            photoQualitySettings: _photoQuality.current,
          ),
        ),
      );

      if (!mounted) return;

      if (result != null) {
        setState(() {
          _selectedTemplateIndex = result;
        });
      }

      // Refresh the thumbnail after returning from preview/gallery.
      await _loadRecentPhoto();
    } catch (e) {
      debugPrint('Capture error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to capture photo. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _deleteTemporaryCaptureFiles(
    String originalPath,
    String normalizedPath,
  ) async {
    for (final path in <String>{originalPath, normalizedPath}) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (error) {
        debugPrint('Temporary capture cleanup error: $error');
      }
    }
  }


  // ===========================================================================
  // FLIP CAMERA
  // ===========================================================================

  Future<void> _flipCamera() async {
    if (_cameras.length < 2 || _isInitializing) {
      return;
    }

    int nextIndex = _currentCameraIndex + 1;

    if (nextIndex >= _cameras.length) {
      nextIndex = 0;
    }

    _currentCameraIndex = nextIndex;

    await _startCamera(_currentCameraIndex);
  }

  // ===========================================================================
  // OPEN GALLERY
  // ===========================================================================

  Future<void> _openGallery() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const GalleryScreen(),
      ),
    );

    if (!mounted) return;

    await _loadRecentPhoto();
  }

  // ===========================================================================
  // RECENT PHOTO THUMBNAIL
  // ===========================================================================

  Widget _buildRecentPhotoThumbnail() {
    final photo = _recentPhoto;

    if (photo == null) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF27272A),
          borderRadius: BorderRadius.circular(
            AppRadius.sm,
          ),
          border: Border.all(
            color: Colors.white.withValues(
              alpha: 0.25,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.photo_library_outlined,
          color: Colors.white,
          size: 23,
        ),
      );
    }

    final file = File(photo.path);

    if (!file.existsSync()) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF27272A),
          borderRadius: BorderRadius.circular(
            AppRadius.sm,
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.photo_library_outlined,
          color: Colors.white,
          size: 23,
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          AppRadius.sm,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.30,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          AppRadius.sm - 1,
        ),
        child: Image.file(
          file,
          fit: BoxFit.cover,
          width: 48,
          height: 48,
        ),
      ),
    );
  }

  // ===========================================================================
  // CAMERA PREVIEW
  // ===========================================================================

  Widget _buildCameraPreview(
    CameraController controller,
  ) {
    final previewSize = controller.value.previewSize;

    if (previewSize == null) {
      return CameraPreview(controller);
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final horizontalPadding =
                width >= 600
                    ? 32.0
                    : AppSpacing.screenPadding;

            final shutterSize =
                width >= 600 ? 84.0 : 72.0;

            return Column(
              children: [
                // =============================================================
                // TOP TOOLBAR
                // =============================================================

                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      AppIconButton(
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),

                      AppIconButton(
                        icon: _flashOn
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        isActive: _flashOn,
                        onPressed: _toggleFlash,
                      ),

                      AppIconButton(
                        icon: Icons.grid_3x3_rounded,
                        isActive: _gridOn,
                        onPressed: _toggleGrid,
                      ),

                      GestureDetector(
                        onTap: _changeAspectRatio,
                        child: Container(
                          height: 42,
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Text(
                            _selectedRatio.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      AppIconButton(
                        icon: Icons
                            .dashboard_customize_outlined,
                        onPressed: _openTemplates,
                      ),
                    ],
                  ),
                ),

                // =============================================================
                // CAMERA VIEW
                // =============================================================

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding * 0.4,
                    ),
                    child: LayoutBuilder(
                      builder: (context, cameraConstraints) {
                        final nativeRatio = controller != null &&
                                controller.value.isInitialized
                            ? controller.value.aspectRatio
                            : 4 / 3;
                        final frameRatio = _selectedRatio.resolve(
                          // Do not rotate/flip the camera frame when the phone
                          // turns. Only stamp + brightness follow orientation.
                          isLandscape: false,
                          nativeCameraRatio: nativeRatio,
                        );

                        return CameraRatioFrame(
                          aspectRatio: frameRatio,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _showBrightnessControl,
                            child: Stack(
                                fit: StackFit.expand,
                                children: [
                          if (_isInitializing ||
                              controller == null ||
                              !controller
                                  .value.isInitialized)
                            const ColoredBox(
                              color: Colors.black,
                              child: Center(
                                child:
                                    CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            )
                          else
                            _buildCameraPreview(
                              controller,
                            ),

                          // GRID
                          if (_gridOn)
                            const Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter:
                                      _CameraGridPainter(),
                                ),
                              ),
                            ),

                          // LIVE STAMP
                          if (controller != null &&
                              controller.value.isInitialized)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: ResponsiveCameraStamp(
                                  data: _stampData,
                                  deviceOrientation: _deviceOrientation,
                                  rotateWithDevice: true,
                                ),
                              ),
                            ),

                          if (_showBrightness &&
                              !_isInitializing &&
                              controller != null &&
                              controller.value.isInitialized &&
                              _exposureService.isSupported)
                            Positioned.fill(
                              child: CameraBrightnessControl(
                                percentage: _brightnessPercentage,
                                onChanged: _setExposure,
                                onInteractionStart: _pauseBrightnessHide,
                                onInteractionEnd: _scheduleBrightnessHide,
                                deviceOrientation: _deviceOrientation,
                              ),
                            ),

                          if (_isCapturing)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black
                                    .withValues(
                                  alpha: 0.20,
                                ),
                                alignment:
                                    Alignment.center,
                                child:
                                    const CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                                ],
                              ),
                            ),
                        );
                      },
                    ),
                  ),
                ),

                // =============================================================
                // BOTTOM CONTROLS
                // Recent Photo | Shutter | Flip
                // =============================================================

                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.lg,
                    horizontalPadding,
                    AppSpacing.lg,
                  ),
                  child: SizedBox(
                    height: shutterSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // RECENT PHOTO - LEFT
                        Align(
                          alignment:
                              Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: _openGallery,
                            child:
                                _buildRecentPhotoThumbnail(),
                          ),
                        ),

                        // SHUTTER - CENTER
                        GestureDetector(
                          onTap: _isCapturing
                              ? null
                              : _capture,
                          child: AnimatedContainer(
                            duration:
                                const Duration(
                              milliseconds: 120,
                            ),
                            width: shutterSize,
                            height: shutterSize,
                            padding:
                                const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: _isCapturing
                                  ? Colors.white54
                                  : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                shape:
                                    BoxShape.circle,
                                border:
                                    Border.all(
                                  color:
                                      AppColors.primary,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // FLIP - RIGHT
                        Align(
                          alignment:
                              Alignment.centerRight,
                          child: AppIconButton(
                            icon: Icons
                                .cameraswitch_outlined,
                            onPressed: _flipCamera,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settings.removeListener(_onSettingsChanged);
    _photoQuality.removeListener(_onPhotoQualityChanged);

    _cameraController?.dispose();
    _locationSubscription?.cancel();
    _orientationSubscription?.cancel();
    _brightnessHideTimer?.cancel();
    _locationService.dispose();

    super.dispose();
  }
}

// =============================================================================
// CAMERA GRID
// =============================================================================

class _CameraGridPainter extends CustomPainter {
  const _CameraGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          Colors.white.withValues(alpha: 0.40)
      ..strokeWidth = 1;

    final firstVertical = size.width / 3;
    final secondVertical =
        size.width * 2 / 3;

    final firstHorizontal =
        size.height / 3;
    final secondHorizontal =
        size.height * 2 / 3;

    canvas.drawLine(
      Offset(firstVertical, 0),
      Offset(firstVertical, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(secondVertical, 0),
      Offset(secondVertical, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(0, firstHorizontal),
      Offset(size.width, firstHorizontal),
      paint,
    );

    canvas.drawLine(
      Offset(0, secondHorizontal),
      Offset(size.width, secondHorizontal),
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}
