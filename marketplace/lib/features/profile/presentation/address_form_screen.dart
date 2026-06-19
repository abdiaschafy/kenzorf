import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/address.dart';
import '../../../core/utils/error_localizer.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/addresses_controller.dart';

/// Formulaire de création / édition d'adresse.
///
/// Si [existing] est fourni, le formulaire est en mode édition.
class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.existing});

  final Address? existing;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _line1;
  late final TextEditingController _line2;
  late final TextEditingController _city;
  late final TextEditingController _region;
  late final TextEditingController _country;
  late final TextEditingController _landmark;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _label = TextEditingController(text: a?.label ?? '');
    _fullName = TextEditingController(text: a?.fullName ?? '');
    _phone = TextEditingController(text: a?.phoneNumber ?? '');
    _line1 = TextEditingController(text: a?.line1 ?? '');
    _line2 = TextEditingController(text: a?.line2 ?? '');
    _city = TextEditingController(text: a?.city ?? '');
    _region = TextEditingController(text: a?.region ?? '');
    _country = TextEditingController(text: a?.country ?? '');
    _landmark = TextEditingController(text: a?.landmark ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _label,
      _fullName,
      _phone,
      _line1,
      _line2,
      _city,
      _region,
      _country,
      _landmark,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  AddressRequest _buildRequest() => AddressRequest(
    label: _label.text.trim().isEmpty ? null : _label.text.trim(),
    fullName: _fullName.text.trim(),
    phoneNumber: _phone.text.trim(),
    line1: _line1.text.trim(),
    line2: _line2.text.trim().isEmpty ? null : _line2.text.trim(),
    city: _city.text.trim(),
    region: _region.text.trim().isEmpty ? null : _region.text.trim(),
    country: _country.text.trim(),
    landmark: _landmark.text.trim().isEmpty ? null : _landmark.text.trim(),
  );

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final controller = ref.read(addressesControllerProvider.notifier);
      final request = _buildRequest();
      if (widget.existing != null) {
        await controller.updateAddress(widget.existing!.id, request);
      } else {
        await controller.create(request);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.t('address.saved'))));
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.describeError(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final v = Validators(l10n);
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.t('address.edit') : l10n.t('address.add')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label:
                      '${l10n.t('address.field.label')} (${l10n.t('common.optional')})',
                  controller: _label,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: l10n.t('address.field.fullName'),
                  controller: _fullName,
                  validator: v.required(),
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: l10n.t('address.field.phone'),
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  validator: v.phone(),
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: l10n.t('address.field.line1'),
                  controller: _line1,
                  validator: v.required(),
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.streetAddressLine1],
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label:
                      '${l10n.t('address.field.line2')} (${l10n.t('common.optional')})',
                  controller: _line2,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: l10n.t('address.field.city'),
                  controller: _city,
                  validator: v.required(),
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.addressCity],
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label:
                      '${l10n.t('address.field.region')} (${l10n.t('common.optional')})',
                  controller: _region,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: l10n.t('address.field.country'),
                  controller: _country,
                  validator: v.required(),
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.countryName],
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label:
                      '${l10n.t('address.field.landmark')} (${l10n.t('common.optional')})',
                  controller: _landmark,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: l10n.t('common.save'),
                  loading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
