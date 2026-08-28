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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _client;
  late final TextEditingController _location;
  late final TextEditingController _description;
  late String _coverAsset;
  late Color _color;
  late bool _useStampPreset;
  late bool _autoSave;
  late String _template;

  static const _covers = [
    'assets/images/projects/highway_project.jpg',
    'assets/images/captures/site_inspection.jpg',
    'assets/images/captures/road_work.jpg',
    'assets/images/captures/site_visit.jpg',
  ];
  static const _colors = [
    Color(0xFF4F21C8),
    Color(0xFF169C48),
    Color(0xFFFF6A00),
    Color(0xFF1473E6),
    Color(0xFFE01E37),
    Color(0xFF9E9E9E),
  ];
  static const _templates = [
    'Classic',
    'Compact',
    'Map Card',
    'Field Work',
    'Minimal'
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
    _coverAsset = project?.coverAsset ?? _covers.first;
    _color = project?.color ?? _colors.first;
    _useStampPreset = project?.useStampPreset ?? true;
    _autoSave = project?.autoSaveCaptures ?? true;
    _template = project?.defaultStampTemplate ?? 'Field Work';
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

  InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm)),
      );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final repository = ProjectRepository.instance;
    final existing = widget.project;
    if (existing != null) {
      existing
        ..name = _name.text.trim()
        ..code = _code.text.trim()
        ..client = _client.text.trim()
        ..location = _location.text.trim()
        ..description = _description.text.trim()
        ..coverAsset = _coverAsset
        ..color = _color
        ..useStampPreset = _useStampPreset
        ..autoSaveCaptures = _autoSave
        ..defaultStampTemplate = _template;
      repository.update(existing);
      Navigator.of(context).pop(existing);
      return;
    }
    final project = ProjectData(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      name: _name.text.trim(),
      code: _code.text.trim(),
      client: _client.text.trim(),
      location: _location.text.trim(),
      description: _description.text.trim(),
      coverAsset: _coverAsset,
      color: _color,
      status: ProjectStatus.active,
      photos: const [],
      locationCount: 0,
      storageBytes: 0,
      updatedAt: DateTime.now(),
      useStampPreset: _useStampPreset,
      autoSaveCaptures: _autoSave,
      defaultStampTemplate: _template,
    );
    repository.add(project);
    Navigator.of(context).pop(project);
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
                          padding:
                              EdgeInsets.fromLTRB(padding, 16, padding, 24),
                          children: [
                            if (wide)
                              Row(children: [
                                Expanded(
                                    child: TextFormField(
                                        controller: _name,
                                        validator: _required,
                                        decoration:
                                            _decoration('Project Name'))),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: TextFormField(
                                        controller: _code,
                                        validator: _required,
                                        decoration:
                                            _decoration('Project Code'))),
                              ])
                            else ...[
                              TextFormField(
                                  controller: _name,
                                  validator: _required,
                                  decoration: _decoration('Project Name')),
                              const SizedBox(height: 14),
                              TextFormField(
                                  controller: _code,
                                  validator: _required,
                                  decoration: _decoration('Project Code')),
                            ],
                            const SizedBox(height: 14),
                            TextFormField(
                                controller: _client,
                                validator: _required,
                                decoration: _decoration('Client / Company')),
                            const SizedBox(height: 14),
                            TextFormField(
                                controller: _location,
                                validator: _required,
                                decoration: _decoration('Location')),
                            const SizedBox(height: 14),
                            TextFormField(
                                controller: _description,
                                minLines: 3,
                                maxLines: 5,
                                decoration: _decoration('Description')),
                            const SizedBox(height: 18),
                            Text('Cover',
                                style: AppTypography.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 76,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _covers.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final cover = _covers[index];
                                  final selected = cover == _coverAsset;
                                  return InkWell(
                                    onTap: () =>
                                        setState(() => _coverAsset = cover),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.sm),
                                          child: Image.asset(
                                            cover,
                                            width: 92,
                                            height: 76,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                width: 92,
                                                height: 76,
                                                color: AppColors.border,
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                    Icons.landscape_outlined),
                                              );
                                            },
                                          ),
                                        ),
                                        if (selected)
                                          Positioned.fill(
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppRadius.sm),
                                                border: Border.all(
                                                  color: AppColors.primary,
                                                  width: 3,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 14,
                              runSpacing: 10,
                              children: _colors
                                  .map((color) => InkWell(
                                        onTap: () =>
                                            setState(() => _color = color),
                                        borderRadius: BorderRadius.circular(30),
                                        child: Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: _color == color
                                                      ? AppColors.textPrimary
                                                      : Colors.transparent,
                                                  width: 3)),
                                          child: _color == color
                                              ? const Icon(Icons.check,
                                                  color: Colors.white, size: 18)
                                              : null,
                                        ),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 12),
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
                              title:
                                  const Text('Auto-save captures to project'),
                              value: _autoSave,
                              activeColor: AppColors.primary,
                              onChanged: (value) =>
                                  setState(() => _autoSave = value),
                            ),
                            DropdownButtonFormField<String>(
                              value: _template,
                              decoration: _decoration('Default Stamp Template'),
                              items: _templates
                                  .map((item) => DropdownMenuItem(
                                      value: item, child: Text(item)))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null)
                                  setState(() => _template = value);
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(padding, 8, padding, 16),
                        child: Row(children: [
                          Expanded(
                              child: AppSecondaryButton(
                                  label: 'Cancel',
                                  icon: Icons.close,
                                  onPressed: () =>
                                      Navigator.of(context).pop())),
                          const SizedBox(width: 12),
                          Expanded(
                              child: AppPrimaryButton(
                                  label: _editing
                                      ? 'Save Changes'
                                      : 'Create Project',
                                  onPressed: _save)),
                        ]),
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
}
