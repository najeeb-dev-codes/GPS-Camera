import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/models/camera_aspect_ratio.dart';
import '../../core/services/ad_service.dart';
import '../../core/constants/ad_unit_ids.dart';
import '../../core/services/app_settings_service.dart';
import '../../core/services/captured_photo_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/internet_settings_service.dart';
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
import 'services/camera_hardware_service.dart';
import 'services/camera_orientation_service.dart';
import 'widgets/camera_brightness_control.dart';
import 'widgets/camera_level_indicator.dart';
import 'widgets/camera_ratio_frame.dart';
import 'widgets/responsive_camera_stamp.dart';

class LiveCameraScreen extends StatefulWidget {
  const LiveCameraScreen({super.key, this.initialProjectId});

  final String? initialProjectId;

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
  bool _cameraFeaturesStarted = false;
  bool _flashOn = false;
  bool _showBrightness = false;
  Timer? _brightnessHideTimer;
  Timer? _focusHideTimer;
  StreamSubscription<String>? _volumeButtonSubscription;
  StreamSubscription<bool>? _internetSubscription;
  BannerAd? _cameraBannerAd;
  bool _isLoadingCameraBanner = false;
  int? _cameraBannerWidth;
  int _cameraBannerGeneration = 0;
  bool _cameraBannerFailed = false;
  Timer? _cameraBannerRetryTimer;
  StreamSubscription<bool>? _bannerOnlineSubscription;
  final GlobalKey _cameraSurfaceKey = GlobalKey();
  Offset? _focusPoint;
  int _timerSeconds = 0;
  double _zoomLevel = 1;

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

  bool _checkingInternet = false;
  bool _internetDialogVisible = false;
  bool _appIsActive = true;
  int _cameraStartGeneration = 0;
  Future<void> _pendingCameraDisposal = Future<void>.value();


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
    ConnectivityService.instance.start();
    _internetSubscription =
        ConnectivityService.instance.onBackOnline.listen((_) {
      if (!_cameraFeaturesStarted) {
        unawaited(_checkInternetAndStartCamera());
      }
    });
    _bannerOnlineSubscription =
        ConnectivityService.instance.onBackOnline.listen((_) {
      _retryCameraBanner();
    });
    // Start camera initialization as soon as this screen is created. GPS,
    // settings, recent-photo loading, orientation and the banner continue in
    // parallel and never gate the live preview.
    _startCameraFeatures();
    unawaited(ConnectivityService.instance.hasInternetAccess());
  }

  void _ensureCameraBanner(double availableWidth) {
    final width = availableWidth.floor();
    if (!mounted || width <= 0) return;
    if (_cameraBannerWidth == width &&
        (_cameraBannerAd != null ||
            _isLoadingCameraBanner ||
            _cameraBannerFailed)) {
      return;
    }

    _cameraBannerWidth = width;
    _cameraBannerFailed = false;
    _cameraBannerRetryTimer?.cancel();
    final generation = ++_cameraBannerGeneration;
    _cameraBannerAd?.dispose();
    _cameraBannerAd = null;
    _isLoadingCameraBanner = true;
    unawaited(_loadCameraBanner(width, generation));
  }

  /// Retries after a failed banner load (called by a timer or when the
  /// internet comes back). Never called from build().
  void _retryCameraBanner() {
    if (!mounted || _cameraBannerAd != null || _isLoadingCameraBanner) return;
    _cameraBannerFailed = false;
    _cameraBannerRetryTimer?.cancel();
    final width = _cameraBannerWidth;
    if (width == null) return;
    final generation = ++_cameraBannerGeneration;
    _isLoadingCameraBanner = true;
    unawaited(_loadCameraBanner(width, generation));
  }

  /// Loads a banner that is owned exclusively by this screen.
  Future<BannerAd?> _loadOwnBanner(AdSize size) async {
    final completer = Completer<BannerAd?>();
    final ownAd = BannerAd(
      adUnitId: AdUnitIds.banner,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (loadedAd) {
          if (!completer.isCompleted) {
            completer.complete(loadedAd as BannerAd);
          }
        },
        onAdFailedToLoad: (failedAd, error) {
          failedAd.dispose();
          if (!completer.isCompleted) completer.complete(null);
          debugPrint('Live camera banner load failed: $error');
        },
      ),
    );
    ownAd.load();
    final loaded = await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => null,
    );
    if (loaded == null) ownAd.dispose();
    return loaded;
  }

  Future<void> _loadCameraBanner(int width, int generation) async {
    BannerAd? ad;
    try {
      final size = await AdService.instance.adaptiveBannerSize(width);
      if (!mounted || generation != _cameraBannerGeneration) return;
      if (size == null) {
        _onCameraBannerFailed(generation);
        return;
      }

      // 1) Shared AdService banner (claimed exclusively: acquireBanner removes
      //    it from the cache, so no other screen can attach the same ad).
      ad = await AdService.instance.acquireBanner(size);

      // 2) Fallback: AdService can return null when its connectivity flag has
      //    not been verified yet. Load a screen-owned banner instead.
      ad ??= await _loadOwnBanner(size);

      if (!mounted || generation != _cameraBannerGeneration) {
        ad?.dispose();
        return;
      }

      if (ad == null) {
        _onCameraBannerFailed(generation);
        return;
      }

      setState(() {
        _cameraBannerAd = ad;
        _isLoadingCameraBanner = false;
        _cameraBannerFailed = false;
      });
    } catch (error) {
      ad?.dispose();
      debugPrint('Live camera banner load failed: $error');
      if (mounted && generation == _cameraBannerGeneration) {
        _onCameraBannerFailed(generation);
      }
    }
  }

  void _onCameraBannerFailed(int generation) {
    if (!mounted || generation != _cameraBannerGeneration) return;
    setState(() {
      _isLoadingCameraBanner = false;
      _cameraBannerFailed = true;
    });
    _cameraBannerRetryTimer?.cancel();
    _cameraBannerRetryTimer = Timer(
      const Duration(seconds: 20),
      _retryCameraBanner,
    );
  }

  Widget _buildCameraBanner() {
    final ad = _cameraBannerAd;
    if (ad == null) return const SizedBox.shrink();

    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      // GlobalObjectKey lets Flutter move this exact AdWidget element within
      // the same frame instead of mounting a second one for the same ad.
      child: AdWidget(
        key: GlobalObjectKey(ad),
        ad: ad,
      ),
    );
  }

  Future<void> _checkInternetAndStartCamera() async {
    if (!mounted ||
        !_appIsActive ||
        _cameraFeaturesStarted ||
        _checkingInternet ||
        _internetDialogVisible) {
      return;
    }

    _checkingInternet = true;
    final online = await ConnectivityService.instance.hasInternetAccess();
    _checkingInternet = false;
    if (!mounted || _cameraFeaturesStarted) return;

    if (online) {
      _startCameraFeatures();
      return;
    }

    await _showCameraInternetDialog();
  }

  Future<void> _showCameraInternetDialog() async {
    if (!mounted || _internetDialogVisible || _cameraFeaturesStarted) return;

    _internetDialogVisible = true;
    final action = await showInternetRequiredDialog(context);
    _internetDialogVisible = false;
    if (!mounted || _cameraFeaturesStarted) return;

    switch (action) {
      case InternetRequiredAction.connected:
        await _checkInternetAndStartCamera();
        break;
      case InternetRequiredAction.openSettings:
        final opened = await InternetSettingsService.open();
        if (!mounted) return;
        if (!opened) {
          AppTopToast.show(
            context,
            message: 'Unable to open internet settings.',
            icon: Icons.error_outline_rounded,
          );
          await _checkInternetAndStartCamera();
        }
        break;
      case InternetRequiredAction.cancel:
        await Navigator.of(context).maybePop();
        break;
    }
  }

  void _startCameraFeatures() {
    if (!mounted || _cameraFeaturesStarted) return;

    setState(() => _cameraFeaturesStarted = true);
    unawaited(_loadSettingsAndInitialize());
    unawaited(_loadRecentPhoto());
    unawaited(_startLiveLocation());
    _startOrientationListener();
    _startHardwareButtons();
  }

  Future<void> _loadSettingsAndInitialize() async {
    // Start camera discovery immediately while preferences load in parallel.
    // The camera screen should not wait for unrelated stamp/template settings.
    final settingsFuture = Future.wait<void>(<Future<void>>[
      _settings.ensureCameraSettingsLoaded(),
      _settings.ensureStampTemplateSettingsLoaded(),
    ]);
    final cameraFuture = _initializeCamera();
    await settingsFuture;
    if (!mounted) return;
    setState(() {
      _selectedTemplateIndex = _settings.selectedStampTemplateIndex;
    });
    await cameraFuture;
  }


  void _onSettingsChanged() {
    if (!mounted) return;
    unawaited(CameraHardwareService.setVolumeAction(_settings.volumeKeyAction));
    setState(() {});
  }

  void _startHardwareButtons() {
    unawaited(CameraHardwareService.setVolumeAction(_settings.volumeKeyAction));
    _volumeButtonSubscription = CameraHardwareService.volumeButtons.listen(
      (button) {
        if (!mounted) return;
        if (_settings.volumeKeyAction == 'Capture') {
          unawaited(_captureWithTimer());
        } else if (_settings.volumeKeyAction == 'Zoom') {
          unawaited(_changeZoom(button == 'up' ? 0.2 : -0.2));
        }
      },
    );
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
      // Discover available cameras while saved photo-quality preferences load.
      // Running these independent operations together reduces startup delay
      // without changing the user's selected capture resolution.
      final camerasFuture = availableCameras();
      final qualityFuture = _photoQuality.ensureLoaded();
      _cameras = await camerasFuture;
      await qualityFuture;

      if (_cameras.isEmpty) {
        if (!mounted) return;

        setState(() {
          _isInitializing = false;
        });

        return;
      }

      final wantedDirection = _settings.defaultCamera == 'Front Camera'
          ? CameraLensDirection.front
          : CameraLensDirection.back;
      final wantedIndex =
          _cameras.indexWhere((camera) => camera.lensDirection == wantedDirection);
      _currentCameraIndex = wantedIndex < 0 ? 0 : wantedIndex;
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
    if (!mounted || !_appIsActive || _cameras.isEmpty) return;

    // Every start owns a generation. App lifecycle changes increment this
    // value so an older asynchronous initialize call cannot put a disposed
    // controller back into the widget tree after an app-open ad closes.
    final generation = ++_cameraStartGeneration;
    final previousController = _cameraController;
    _cameraController = null;

    setState(() => _isInitializing = true);

    if (previousController != null) {
      await _queueCameraDisposal(previousController);
    } else {
      await _pendingCameraDisposal;
    }

    if (!mounted ||
        !_appIsActive ||
        generation != _cameraStartGeneration) {
      return;
    }

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

      if (!_isCurrentCameraStart(generation, controller)) {
        if (identical(_cameraController, controller)) {
          _cameraController = null;
        }
        await _queueCameraDisposal(controller);
        return;
      }

      _zoomLevel = await controller.getMinZoomLevel();
      await controller.setZoomLevel(_zoomLevel);

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

      if (!_isCurrentCameraStart(generation, controller)) {
        if (identical(_cameraController, controller)) {
          _cameraController = null;
        }
        await _queueCameraDisposal(controller);
        return;
      }

      setState(() {
        _activePhotoResolution = selectedResolution;
        _isInitializing = false;
      });
    } catch (e) {
      debugPrint('Camera start error: $e');

      final ownsController = identical(_cameraController, controller);
      if (ownsController) _cameraController = null;
      await _queueCameraDisposal(controller);

      if (!mounted ||
          !_appIsActive ||
          generation != _cameraStartGeneration) {
        return;
      }

      setState(() => _isInitializing = false);
    }
  }

  bool _isCurrentCameraStart(
    int generation,
    CameraController controller,
  ) {
    return mounted &&
        _appIsActive &&
        generation == _cameraStartGeneration &&
        identical(_cameraController, controller);
  }

  Future<void> _disposeCameraController(CameraController controller) async {
    try {
      await controller.dispose();
    } catch (error) {
      debugPrint('Camera controller disposal error: $error');
    }
  }

  Future<void> _queueCameraDisposal(CameraController controller) {
    final previousDisposal = _pendingCameraDisposal;
    final disposal = () async {
      await previousDisposal;
      await _disposeCameraController(controller);
    }();
    _pendingCameraDisposal = disposal;
    return disposal;
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

  Future<void> _changeZoom(double change) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    final minimum = await controller.getMinZoomLevel();
    final maximum = await controller.getMaxZoomLevel();
    _zoomLevel = (_zoomLevel + change).clamp(minimum, maximum).toDouble();
    await controller.setZoomLevel(_zoomLevel);
    if (mounted) setState(() {});
  }

  Future<void> _focusCamera(Offset localPosition) async {
    final controller = _cameraController;
    final size = _cameraSurfaceKey.currentContext?.size;
    if (!_settings.tapToFocus ||
        controller == null ||
        !controller.value.isInitialized ||
        size == null ||
        size.isEmpty) return;
    final point = Offset(
      (localPosition.dx / size.width).clamp(0, 1).toDouble(),
      (localPosition.dy / size.height).clamp(0, 1).toDouble(),
    );
    try {
      await controller.setFocusPoint(point);
      await controller.setExposurePoint(point);
      _focusHideTimer?.cancel();
      if (mounted) setState(() => _focusPoint = localPosition);
      _focusHideTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _focusPoint = null);
      });
    } catch (error) {
      debugPrint('Tap-to-focus unavailable: $error');
    }
  }

  // ===========================================================================
  // APP LIFECYCLE
  // ===========================================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _appIsActive = false;
      _cameraStartGeneration++;

      // Remove the controller from the UI before disposing it. Keeping the
      // disposed CameraPreview for even one frame is what caused the brief red
      // error screen when an app-open ad was dismissed.
      final controller = _cameraController;
      _cameraController = null;
      if (mounted) {
        setState(() {
          _isInitializing = true;
          _showBrightness = false;
          _focusPoint = null;
        });
      }
      if (controller != null) {
        unawaited(_queueCameraDisposal(controller));
      }

      _locationService.stopListeningOnly();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _appIsActive = true;
      if (!_cameraFeaturesStarted) {
        unawaited(_checkInternetAndStartCamera());
        return;
      }

      unawaited(_loadRecentPhoto());
      unawaited(_startLiveLocation());

      if (_cameras.isNotEmpty) {
        unawaited(_startCamera(_currentCameraIndex));
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
      // Freeze all dynamic data and orientation at shutter time.
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

      if (_settings.shutterSound) {
        await SystemSound.play(SystemSoundType.click);
      }
      final XFile capturedPhoto = await controller.takePicture();

      if (!mounted) {
        await _deleteTemporaryCaptureFiles(capturedPhoto.path);
        return;
      }

      // Open Preview as soon as the camera returns its JPEG. Orientation work
      // runs in Preview's background preparation phase instead of blocking the
      // shutter-to-preview transition.
      final result = await Navigator.of(context).push<int>(
        MaterialPageRoute(
          builder: (_) => CapturePreviewScreen(
            originalCameraPath: capturedPhoto.path,
            captureOrientation: captureOrientation,
            templateIndex: _selectedTemplateIndex,
            stampData: frozenStamp,
            capturedAt: capturedAt,
            photoAspectRatio: _selectedRatio.resolve(
              isLandscape:
                  captureOrientation == DeviceOrientation.landscapeLeft ||
                      captureOrientation == DeviceOrientation.landscapeRight,
              nativeCameraRatio: controller.value.aspectRatio,
            ),
            photoQualitySettings: _photoQuality.current,
            mirrorHorizontally:
                controller.description.lensDirection ==
                        CameraLensDirection.front &&
                    _settings.mirrorSelfies,
            initialProjectId: widget.initialProjectId,
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

      AppTopToast.show(
        context,
        message: 'Unable to capture photo. Please try again.',
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _captureWithTimer() async {
    if (_isCapturing || _timerSeconds > 0) return;
    final seconds = int.tryParse(_settings.timer.replaceAll('s', '')) ?? 0;
    if (seconds == 0) return _capture();
    for (var remaining = seconds; remaining > 0; remaining--) {
      if (!mounted) return;
      setState(() => _timerSeconds = remaining);
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    setState(() => _timerSeconds = 0);
    await _capture();
  }

  Future<void> _deleteTemporaryCaptureFiles(String originalPath) async {
    for (final path in <String>{originalPath}) {
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

  /// Shared live-camera layer used by bounded ratios and edge-to-edge Full.
  Widget _buildCameraSurface(
    CameraController? controller, {
    double stampBottomInset = 0,
  }) {
    final isReady = _appIsActive &&
        controller != null &&
        controller.value.isInitialized;

    return GestureDetector(
      key: _cameraSurfaceKey,
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        _showBrightnessControl();
        unawaited(_focusCamera(details.localPosition));
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isReady)
            _buildCameraPreview(controller!)
          else
            const ColoredBox(
              color: Color(0xFF151515),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_camera_outlined,
                      color: Colors.white70,
                      size: 42,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Opening camera…',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_gridOn)
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _CameraGridPainter()),
              ),
            ),
          if (_settings.levelIndicator)
            const Positioned.fill(child: CameraLevelIndicator()),
          if (_settings.showGpsAccuracyMeter)
            Positioned(
              top: 12,
              right: 12,
              child: _GpsAccuracyMeter(value: _stampData.accuracy),
            ),
          if (_focusPoint case final point?)
            Positioned(
              left: point.dx - 20,
              top: point.dy - 20,
              child: const IgnorePointer(child: _FocusRing()),
            ),
          if (_timerSeconds > 0)
            Center(
              child: Text(
                '$_timerSeconds',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
            ),
          if (isReady)
            Positioned.fill(
              child: IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.only(bottom: stampBottomInset),
                  child: ResponsiveCameraStamp(
                    data: _stampData,
                    templateIndex: _selectedTemplateIndex,
                    deviceOrientation: _deviceOrientation,
                    rotateWithDevice: true,
                  ),
                ),
              ),
            ),
          if (_showBrightness &&
              !_isInitializing &&
              isReady &&
              _exposureService.isSupported)
            Positioned.fill(
              child: CameraBrightnessControl(
                percentage: _brightnessPercentage,
                onChanged: _setExposure,
                onInteractionStart: _pauseBrightnessHide,
                onInteractionEnd: _scheduleBrightnessHide,
                deviceOrientation: _deviceOrientation,
                // Top-right corner as the user sees it (see the control).
                // Full ratio (stampBottomInset > 0): the camera layer runs
                // behind the toolbar and the shutter / banner ad, so keep the
                // control clear of them. Other ratios: stay below the GPS
                // accuracy chip when it is shown.
                safeInsets: stampBottomInset > 0
                    ? EdgeInsets.only(
                        top: 58,
                        bottom: stampBottomInset,
                      )
                    : EdgeInsets.zero,
                topRightExtraInset:
                    stampBottomInset == 0 && _settings.showGpsAccuracyMeter
                        ? 36
                        : 0,
              ),
            ),
          if (_isCapturing)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.20),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
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

            // Resolve the banner first so this frame never builds an AdWidget
            // for an ad that is about to be disposed/replaced.
            _ensureCameraBanner(width);

            final horizontalPadding =
                width >= 600
                    ? 32.0
                    : AppSpacing.screenPadding;

            final shutterSize =
                width >= 600 ? 84.0 : 72.0;

            final isFull =
                _selectedRatio == CameraAspectRatioOption.full;

            // Keep the live GPS stamp above the shutter controls and the
            // bottom banner. Include a small visual gap beneath the stamp.
            // The banner height is dynamic because adaptive banner sizes vary
            // by device width and availability.
            final cameraBannerHeight =
                _cameraBannerAd?.size.height.toDouble() ?? 0.0;
            final fullStampBottomInset = cameraBannerHeight +
                shutterSize +
                (AppSpacing.lg * 2) +
                12.0;

            final controls = Column(
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
                  child: isFull
                      ? const SizedBox.expand()
                      : Padding(
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
                          child: _buildCameraSurface(controller),
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
                              : _captureWithTimer,
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

                // Responsive banner ad anchored below the camera controls.
                // The banner is optional and never blocks camera use.
                _buildCameraBanner(),
              ],
            );

            // IMPORTANT: always return the SAME widget structure (Stack ->
            // [background, controls]) for every ratio. Previously Full wrapped
            // `controls` in a Stack while other ratios returned `controls`
            // directly. That moved the banner's AdWidget to a different spot
            // in the tree, so the new AdWidget was mounted before the old one
            // was disposed -> "This AdWidget is already in the Widget tree".
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: isFull
                      ? _buildCameraSurface(
                          controller,
                          stampBottomInset: fullStampBottomInset,
                        )
                      : const SizedBox.shrink(),
                ),
                controls,
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

    _cameraStartGeneration++;
    _cameraBannerGeneration++;
    _cameraBannerRetryTimer?.cancel();
    _bannerOnlineSubscription?.cancel();
    _cameraBannerAd?.dispose();
    _cameraBannerAd = null;
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      unawaited(_queueCameraDisposal(controller));
    }
    _locationSubscription?.cancel();
    _orientationSubscription?.cancel();
    _volumeButtonSubscription?.cancel();
    _internetSubscription?.cancel();
    _brightnessHideTimer?.cancel();
    _focusHideTimer?.cancel();
    _locationService.dispose();

    super.dispose();
  }
}

class _FocusRing extends StatelessWidget {
  const _FocusRing();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.amber, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _GpsAccuracyMeter extends StatelessWidget {
  const _GpsAccuracyMeter({required this.value});

  final String? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.gps_fixed_rounded, color: Color(0xFF32D74B), size: 15),
          const SizedBox(width: 5),
          Text(
            value ?? 'GPS locating…',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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