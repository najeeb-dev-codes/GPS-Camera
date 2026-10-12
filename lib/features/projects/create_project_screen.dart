import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_input_limits.dart';
import '../../core/constants/project_cover_layout.dart';
import '../../core/services/app_settings_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/project_cover_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import '../notifications/models/app_notification.dart';
import '../notifications/services/notification_repository.dart';
import 'project_cover_crop_screen.dart';
import 'project_data.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key, this.project});

  final ProjectData? project;

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  static const List<int> _projectColors = <int>[
    0xFF6D28D9,
    0xFF16A34A,
    0xFFF97316,
    0xFF2563EB,
    0xFFEF4444,
    0xFFDB2777,
    0xFF0D9488,
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _client;
  late final TextEditingController _location;
  late final TextEditingController _description;
  String? _coverImagePath;
  late int _selectedColorValue;
  bool _pickingCover = false;
  bool _saving = false;

  bool get _editing => widget.project != null;

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    _name = TextEditingController(text: project?.name ?? '');
    _code = TextEditingController(text: project?.code ?? '');
    _client = TextEditingController(text: project?.client ?? '');
    _location = TextEditingController(text: project?.location ?? '');
    _description = TextEditingController(text: project?.description ?? '');
    _coverImagePath = project?.coverImagePath;
    _selectedColorValue = project?.colorValue ?? _projectColors.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _client.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      );

  Future<void> _showCoverSourcePicker() async {
    if (_pickingCover || _saving) return;
    final source = await showModalBottomSheet<ProjectCoverSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.of(sheetContext).pop(
                ProjectCoverSource.camera,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(sheetContext).pop(
                ProjectCoverSource.gallery,
              ),
            ),
          ],
        ),
      ),
    );
    if (source != null && mounted) await _pickCover(source);
  }

  Future<void> _pickCover(ProjectCoverSource source) async {
    if (_pickingCover || _saving) return;
    setState(() => _pickingCover = true);
    try {
      final selectedPath = await ProjectCoverPicker.pick(source: source);
      if (selectedPath == null || selectedPath.isEmpty) return;
      if (!mounted) {
        await _deleteTemporaryCover(selectedPath);
        return;
      }

      final croppedPath = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => ProjectCoverCropScreen(imagePath: selectedPath),
        ),
      );
      if (croppedPath != selectedPath) {
        await _deleteTemporaryCover(selectedPath);
      }
      if (croppedPath != null && croppedPath.isNotEmpty && mounted) {
        setState(() => _coverImagePath = croppedPath);
      }
    } catch (error) {
      if (!mounted) return;
      AppTopToast.show(
        context,
        message: 'Unable to select cover image: $error',
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _pickingCover = false);
    }
  }

  Future<void> _deleteTemporaryCover(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // A temporary picker copy can be cleaned by the operating system later.
    }
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      var coverPath = _coverImagePath;
      if (coverPath == null || !File(coverPath).existsSync()) {
        coverPath = await _createProjectNameCover(_name.text.trim());
      }
      final repository = ProjectRepository.instance;
      final existing = widget.project;
      late final ProjectData project;
      if (existing == null) {
        project = ProjectData(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: _name.text.trim(),
          code: _code.text.trim(),
          client: _client.text.trim(),
          location: _location.text.trim(),
          description: _description.text.trim(),
          coverImagePath: coverPath,
          colorValue: _selectedColorValue,
          status: ProjectStatus.active,
          updatedAt: DateTime.now(),
        );
        await repository.add(project);
        await _notifyProjectCreated(project);
      } else {
        project = existing
          ..name = _name.text.trim()
          ..code = _code.text.trim()
          ..client = _client.text.trim()
          ..location = _location.text.trim()
          ..description = _description.text.trim()
          ..coverImagePath = coverPath
          ..colorValue = _selectedColorValue;
        await repository.update(project);
      }
      if (!mounted) return;
      AppTopToast.show(
        context,
        message: existing == null
            ? 'Project “${project.name}” created successfully.'
            : 'Project “${project.name}” updated successfully.',
        icon: existing == null
            ? Icons.create_new_folder_outlined
            : Icons.edit_outlined,
      );
      Navigator.of(context).pop(project);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppTopToast.show(
        context,
        message: 'Unable to save project: $error',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<String> _createProjectNameCover(String projectName) async {
    final words = projectName.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    final initials = words
        .map((word) => String.fromCharCode(word.runes.first).toUpperCase())
        .join();
    final coverText = initials.isEmpty ? 'P' : initials;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final size = ui.Size(
      ProjectCoverLayout.outputWidth.toDouble(),
      ProjectCoverLayout.outputHeight.toDouble(),
    );

    canvas.drawRect(
      ui.Offset.zero & size,
      ui.Paint()..color = Color(_selectedColorValue),
    );

    final titleStyle = (Theme.of(context).textTheme.headlineMedium ??
            const TextStyle())
        .copyWith(
      color: Colors.white,
      fontSize: 120,
      height: 1.1,
      fontWeight: FontWeight.w700,
    );
    final painter = TextPainter(
      text: TextSpan(text: coverText, style: titleStyle),
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 220);

    painter.paint(
      canvas,
      Offset(
        (size.width - painter.width) / 2,
        (size.height - painter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      ProjectCoverLayout.outputWidth,
      ProjectCoverLayout.outputHeight,
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      throw Exception('Unable to create project cover.');
    }

    final directory = await getApplicationDocumentsDirectory();
    final coverDirectory = Directory(
      '${directory.path}/project_covers',
    );
    if (!await coverDirectory.exists()) {
      await coverDirectory.create(recursive: true);
    }

    final id = DateTime.now().microsecondsSinceEpoch;
    final file = File('${coverDirectory.path}/project_$id.png');
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return file.path;
  }

  Future<void> _notifyProjectCreated(ProjectData project) async {
    try {
      final settings = AppSettingsService.instance;
      await settings.ensureNotificationSettingsLoaded();
      if (!settings.masterNotifications || !settings.notifyProjectCreated) {
        return;
      }

      final message = '${project.name} was created successfully.';
      await NotificationRepository.instance.add(
        title: 'Project created',
        message: message,
        type: AppNotificationType.project,
        createdAt: DateTime.now(),
      );
      await NotificationService.instance.showAppNotification(
        title: 'Project created',
        body: message,
        payload: <String, dynamic>{
          'type': 'projectCreated',
          'projectId': project.id,
        },
      );
    } catch (error) {
      debugPrint('Project created notification skipped: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(title: _editing ? 'Edit Project' : 'Create Project'),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 700;
            final padding = wide ? 32.0 : AppSpacing.screenPadding;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(padding, 16, padding, 24),
                          children: [
                            _buildCoverPicker(),
                            const SizedBox(height: 18),
                            _field(
                              _name,
                              'Project Name',
                              maxLength: AppInputLimits.projectName,
                            ),
                            const SizedBox(height: 14),
                            _field(
                              _code,
                              'Project Code',
                              maxLength: AppInputLimits.projectCode,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Za-z0-9 _-]'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _field(
                              _client,
                              'Client / Company',
                              maxLength: AppInputLimits.clientCompany,
                            ),
                            const SizedBox(height: 14),
                            _buildLocationAndColor(),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _description,
                              minLines: 4,
                              maxLines: 7,
                              maxLength: AppInputLimits.description,
                              decoration: _decoration('Description'),
                            ),
                          ],
                        ),
                      ),
                      const AdBannerWidget(),
                      Padding(
                        padding: EdgeInsets.fromLTRB(padding, 8, padding, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppSecondaryButton(
                                label: 'Cancel',
                                onPressed: _saving
                                    ? null
                                    : () => Navigator.of(context).pop(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AppPrimaryButton(
                                label: _saving
                                    ? 'Saving…'
                                    : _editing
                                        ? 'Save Changes'
                                        : 'Create Project',
                                onPressed: _saving ? null : _save,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    required int maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: _required,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      decoration: _decoration(label).copyWith(counterText: ''),
    );
  }

  Widget _buildLocationAndColor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(
          _location,
          'Location',
          maxLength: AppInputLimits.location,
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: _buildColorField(),
        ),
      ],
    );
  }

  Widget _buildColorField() {
    return InputDecorator(
      decoration: _decoration('Project Colour').copyWith(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 17,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 240.0;
          final dotSize =
              (available / ((_projectColors.length + 1) * 1.35))
                  .clamp(14.0, 20.0)
                  .toDouble();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final value in _projectColors)
                _projectColorChoice(
                  value: value,
                  size: dotSize,
                ),
              _customProjectColorChoice(dotSize),
            ],
          );
        },
      ),
    );
  }

  Widget _projectColorChoice({
    required int value,
    required double size,
  }) {
    final selected = value == _selectedColorValue;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Select project colour',
      child: GestureDetector(
        onTap: () => setState(() => _selectedColorValue = value),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(value),
            border: Border.all(
              color: selected
                  ? AppColors.textPrimary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: selected
              ? Icon(
                  Icons.check,
                  size: size * 0.65,
                  color: Color(value).computeLuminance() > 0.55
                      ? Colors.black
                      : Colors.white,
                )
              : null,
        ),
      ),
    );
  }

  Widget _customProjectColorChoice(double size) {
    final customSelected = !_projectColors.contains(_selectedColorValue);
    final color = customSelected
        ? Color(_selectedColorValue)
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    return Semantics(
      button: true,
      selected: customSelected,
      label: 'Pick a custom project colour',
      child: GestureDetector(
        onTap: _pickCustomProjectColor,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: customSelected
                  ? AppColors.textPrimary
                  : AppColors.border,
              width: customSelected ? 2 : 1,
            ),
          ),
          child: customSelected
              ? Icon(
                  Icons.check,
                  size: size * 0.65,
                  color: color.computeLuminance() > 0.55
                      ? Colors.black
                      : Colors.white,
                )
              : Icon(
                  Icons.colorize_rounded,
                  size: size * 0.62,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
        ),
      ),
    );
  }

  Future<void> _pickCustomProjectColor() async {
    final selected = await showDialog<Color>(
      context: context,
      builder: (_) => _ProjectCustomColorDialog(
        initialColor: Color(_selectedColorValue),
      ),
    );
    if (selected == null || !mounted) return;

    setState(() => _selectedColorValue = selected.toARGB32());
  }

  /// Round button pinned to the bottom-right corner of the selected cover.
  /// Tapping it lets the user replace the image from the camera or gallery.
  /// It is white with a shadow so it stays visible on any photo.
  Widget _buildReplaceCoverButton() {
    final enabled = !_pickingCover && !_saving;
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Replace cover image',
      child: Material(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black54,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? _showCoverSourcePicker : null,
          child: const SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              Icons.cached_rounded,
              size: 18,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPicker() {
    final path = _coverImagePath;
    final available = path != null && File(path).existsSync();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Project cover image', style: AppTypography.h3),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: ProjectCoverLayout.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Material(
                  color: AppColors.mutedSurface,
                  child: InkWell(
                    // Before a cover exists the whole area is the upload
                    // target. Once an image is selected, only the replace
                    // button opens the picker so accidental taps do not
                    // reopen it.
                    onTap: (available || _pickingCover)
                        ? null
                        : _showCoverSourcePicker,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (available)
                          Image.file(File(path!), fit: BoxFit.cover)
                        else
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 42,
                                  color: AppColors.neutral400,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap to upload',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'JPG, JPEG, PNG or WEBP',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.neutral400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_pickingCover)
                          const ColoredBox(
                            color: Colors.black38,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (available && !_pickingCover)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: _buildReplaceCoverButton(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Project-specific copy of the custom picker interaction used by Theme.
/// Keeping it in this file makes Create Project self-contained.
class _ProjectCustomColorDialog extends StatefulWidget {
  const _ProjectCustomColorDialog({required this.initialColor});

  final Color initialColor;

  @override
  State<_ProjectCustomColorDialog> createState() =>
      _ProjectCustomColorDialogState();
}

class _ProjectCustomColorDialogState
    extends State<_ProjectCustomColorDialog> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor.withValues(alpha: 1));
  }

  void _updateColor(Offset position, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final saturation = (position.dx / size.width).clamp(0.0, 1.0);
    final brightness = (1 - position.dy / size.height).clamp(0.0, 1.0);

    setState(() {
      _hsv = _hsv
          .withSaturation(saturation.toDouble())
          .withValue(brightness.toDouble());
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsv.toColor().withValues(alpha: 1);
    final pickerSide = (MediaQuery.sizeOf(context).width - 96)
        .clamp(160.0, 300.0)
        .toDouble();
    final pickerSize = Size.square(pickerSide);

    return AlertDialog(
      title: const Text('Pick a color'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) =>
                      _updateColor(details.localPosition, pickerSize),
                  onPanStart: (details) =>
                      _updateColor(details.localPosition, pickerSize),
                  onPanUpdate: (details) =>
                      _updateColor(details.localPosition, pickerSize),
                  child: CustomPaint(
                    size: pickerSize,
                    painter: _ProjectColorAreaPainter(hsv: _hsv),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF0000),
                            Color(0xFFFFFF00),
                            Color(0xFF00FF00),
                            Color(0xFF00FFFF),
                            Color(0xFF0000FF),
                            Color(0xFFFF00FF),
                            Color(0xFFFF0000),
                          ],
                        ),
                      ),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 0,
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.transparent,
                          thumbColor: HSVColor.fromAHSV(
                            1,
                            _hsv.hue,
                            1,
                            1,
                          ).toColor(),
                        ),
                        child: Slider(
                          value: _hsv.hue,
                          min: 0,
                          max: 360,
                          onChanged: (value) {
                            setState(() => _hsv = _hsv.withHue(value));
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _ProjectColorValues(color: color),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(color),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _ProjectColorAreaPainter extends CustomPainter {
  const _ProjectColorAreaPainter({required this.hsv});

  final HSVColor hsv;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hue = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, hue],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );

    final position = Offset(
      hsv.saturation * size.width,
      (1 - hsv.value) * size.height,
    );
    canvas.drawCircle(
      position,
      9,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }

  @override
  bool shouldRepaint(covariant _ProjectColorAreaPainter oldDelegate) {
    return oldDelegate.hsv != hsv;
  }
}

class _ProjectColorValues extends StatelessWidget {
  const _ProjectColorValues({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final argb = color.toARGB32();
    final red = (argb >> 16) & 0xFF;
    final green = (argb >> 8) & 0xFF;
    final blue = argb & 0xFF;
    final hex = argb
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2)
        .toUpperCase();

    return Row(
      children: [
        _ProjectColorValue(label: 'HEX', value: '#$hex'),
        _ProjectColorValue(label: 'R', value: '$red'),
        _ProjectColorValue(label: 'G', value: '$green'),
        _ProjectColorValue(label: 'B', value: '$blue'),
        const _ProjectColorValue(label: 'A', value: '100%'),
      ],
    );
  }
}

class _ProjectColorValue extends StatelessWidget {
  const _ProjectColorValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.tiny.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: AppTypography.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}