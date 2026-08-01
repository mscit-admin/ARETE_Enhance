import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/l10n/enum_labels.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/body_metrics.dart';
import '../../data/models/member.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/section_label.dart';
import '../../state/profile_controller.dart';

/// Editable form for the member's personal details and body metrics.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.member});

  final Member member;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name =
      TextEditingController(text: widget.member.fullName);
  late final TextEditingController _phone =
      TextEditingController(text: widget.member.phone ?? '');
  late final TextEditingController _weight = TextEditingController(
      text: widget.member.metrics.weightKg.toStringAsFixed(1));
  late final TextEditingController _height = TextEditingController(
      text: widget.member.metrics.heightCm.toStringAsFixed(0));

  late Gender _gender = widget.member.gender;
  late FitnessGoal _goal = widget.member.goal;
  late ExperienceLevel _experience = widget.member.experience;
  late DateTime _dob = widget.member.dateOfBirth;

  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final updated = widget.member.copyWith(
      fullName: _name.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      gender: _gender,
      goal: _goal,
      experience: _experience,
      dateOfBirth: _dob,
      metrics: widget.member.metrics.copyWith(
        weightKg: double.tryParse(_weight.text) ?? widget.member.metrics.weightKg,
        heightCm: double.tryParse(_height.text) ?? widget.member.metrics.heightCm,
      ),
    );

    await context.read<ProfileController>().save(updated);

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.editProfileUpdated)),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.editTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            SectionLabel(l.editPersonal),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l.fieldFullName),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.editNameRequired : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phone,
              decoration: InputDecoration(labelText: l.editPhoneOptional),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.md),
            _GenderDropdown(
              value: _gender,
              onChanged: (g) => setState(() => _gender = g),
            ),
            const SizedBox(height: AppSpacing.md),
            _DobField(
              value: _dob,
              onChanged: (d) => setState(() => _dob = d),
            ),

            const SizedBox(height: AppSpacing.xl),
            SectionLabel(l.editBodyMetrics),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weight,
                    decoration: InputDecoration(
                        labelText: l.editWeightKg, suffixText: 'kg'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (v) => _positiveNumber(v, l),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _height,
                    decoration: InputDecoration(
                        labelText: l.editHeightCm, suffixText: 'cm'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (v) => _positiveNumber(v, l),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),
            SectionLabel(l.editTraining),
            const SizedBox(height: AppSpacing.md),
            _GoalDropdown(
              value: _goal,
              onChanged: (g) => setState(() => _goal = g),
            ),
            const SizedBox(height: AppSpacing.md),
            _ExperienceDropdown(
              value: _experience,
              onChanged: (e) => setState(() => _experience = e),
            ),

            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l.editSaveChanges),
            ),
          ],
        ),
      ),
    );
  }

  String? _positiveNumber(String? v, AppLocalizations l) {
    final n = double.tryParse(v ?? '');
    if (n == null || n <= 0) return l.editValidNumber;
    return null;
  }
}

class _GenderDropdown extends StatelessWidget {
  const _GenderDropdown({required this.value, required this.onChanged});
  final Gender value;
  final ValueChanged<Gender> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return DropdownButtonFormField<Gender>(
      value: value,
      decoration: InputDecoration(labelText: l.editGender),
      items: [
        for (final g in Gender.values)
          DropdownMenuItem(value: g, child: Text(g.localized(l))),
      ],
      onChanged: (g) => g == null ? null : onChanged(g),
    );
  }
}

class _GoalDropdown extends StatelessWidget {
  const _GoalDropdown({required this.value, required this.onChanged});
  final FitnessGoal value;
  final ValueChanged<FitnessGoal> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return DropdownButtonFormField<FitnessGoal>(
      value: value,
      decoration: InputDecoration(labelText: l.editPrimaryGoal),
      items: [
        for (final g in FitnessGoal.values)
          DropdownMenuItem(value: g, child: Text(g.localized(l))),
      ],
      onChanged: (g) => g == null ? null : onChanged(g),
    );
  }
}

class _ExperienceDropdown extends StatelessWidget {
  const _ExperienceDropdown({required this.value, required this.onChanged});
  final ExperienceLevel value;
  final ValueChanged<ExperienceLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return DropdownButtonFormField<ExperienceLevel>(
      value: value,
      decoration: InputDecoration(labelText: l.editExperienceLevel),
      items: [
        for (final e in ExperienceLevel.values)
          DropdownMenuItem(value: e, child: Text(e.localized(l))),
      ],
      onChanged: (e) => e == null ? null : onChanged(e),
    );
  }
}

class _DobField extends StatelessWidget {
  const _DobField({required this.value, required this.onChanged});
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(1940),
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: l.editDob),
        child: Text(
          '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
          style: context.textStyles.bodyLarge?.copyWith(color: p.text),
        ),
      ),
    );
  }
}
