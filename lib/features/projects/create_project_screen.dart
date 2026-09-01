import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import 'project_data.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key, this.project});

  final ProjectData? project;

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _client;
  late final TextEditingController _location;
  late final TextEditingController _description;
  late Color _color;
  late bool _useStampPreset;
  late bool _autoSave;
  late String _template;
  bool _saving = false;

  static const List<Color> _colors = <Color>[
    Color(0xFF4F21C8),
    Color(0xFF169C48),
    Color(0xFFFF6A00),
    Color(0xFF1473E6),
    Color(0xFFE01E37),
    Color(0xFF9E9E9E),
  ];
  static const List<String> _templates = <String>[
    'Map Proof',
    'Location Card',
    'QR Split',
    'Time & Place',
    'Minimal Proof',
    'Custom Style',
  ];

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
    _color = project?.color ?? _colors.first;
    _useStampPreset = project?.useStampPreset ?? true;
    _autoSave = project?.autoSaveCaptures ?? false;
    _template = project?.defaultStampTemplate ?? _templates.first;
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
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      );

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
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
          color: _color,
          status: ProjectStatus.active,
          updatedAt: DateTime.now(),
          useStampPreset: _useStampPreset,
          autoSaveCaptures: _autoSave,
          defaultStampTemplate: _template,
        );
        await repository.add(project);
      } else {
        project = existing
          ..name = _name.text.trim()
          ..code = _code.text.trim()
          ..client = _client.text.trim()
          ..location = _location.text.trim()
          ..description = _description.text.trim()
          ..color = _color
          ..useStampPreset = _useStampPreset
          ..autoSaveCaptures = _autoSave
          ..defaultStampTemplate = _template;
        await repository.update(project);
      }
      if (mounted) Navigator.of(context).pop(project);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save project: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                            if (wide)
                              Row(
                                children: [
                                  Expanded(child: _field(_name, 'Project Name')),
                                  const SizedBox(width: 14),
                                  Expanded(child: _field(_code, 'Project Code')),
                                ],
                              )
                            else ...[
                              _field(_name, 'Project Name'),
                              const SizedBox(height: 14),
                              _field(_code, 'Project Code'),
                            ],
                            const SizedBox(height: 14),
                            _field(_client, 'Client / Company'),
                            const SizedBox(height: 14),
                            _field(_location, 'Location'),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _description,
                              minLines: 3,
                              maxLines: 5,
                              decoration: _decoration('Description'),
                            ),
                            const SizedBox(height: 18),
                            Text('Project color', style: AppTypography.h3),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 14,
                              runSpacing: 10,
                              children: _colors.map((color) {
                                final selected = color == _color;
                                return InkWell(
                                  onTap: () => setState(() => _color = color),
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selected
                                            ? AppColors.textPrimary
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                    child: selected
                                        ? const Icon(Icons.check,
                                            size: 19, color: Colors.white)
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 10),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Use project stamp preset'),
                              value: _useStampPreset,
                              activeColor: AppColors.primary,
                              onChanged: (value) =>
                                  setState(() => _useStampPreset = value),
                            ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Auto-save captures to project'),
                              value: _autoSave,
                              activeColor: AppColors.primary,
                              onChanged: (value) =>
                                  setState(() => _autoSave = value),
                            ),
                            DropdownButtonFormField<String>(
                              value: _template,
                              decoration: _decoration('Default Stamp Template'),
                              items: _templates
                                  .map((value) => DropdownMenuItem(
                                      value: value, child: Text(value)))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _template = value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
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

  Widget _field(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      validator: _required,
      decoration: _decoration(label),
    );
  }
}
