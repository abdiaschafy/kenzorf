import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/address.dart';
import '../../../core/models/enums.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_localizer.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/price_text.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../cart/application/cart_controller.dart';
import '../../profile/application/addresses_controller.dart';
import '../application/checkout_controller.dart';

/// Checkout : choix de l'adresse (existante ou nouvelle), du moyen de paiement,
/// récapitulatif, puis création de la commande et redirection KPay.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedAddressId; // null => nouvelle adresse (formulaire)
  PaymentMethod _paymentMethod = PaymentMethod.orangeMoney;
  final _note = TextEditingController();

  // Champs adresse inline (mode nouvelle adresse).
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _region = TextEditingController();
  final _country = TextEditingController();
  final _landmark = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _note,
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

  AddressRequest? _resolveAddress(List<Address> addresses) {
    if (_selectedAddressId != null) {
      final match = addresses.where((a) => a.id == _selectedAddressId);
      if (match.isNotEmpty) return AddressRequest.fromAddress(match.first);
      return null;
    }
    // Nouvelle adresse depuis le formulaire inline.
    return AddressRequest(
      fullName: _fullName.text.trim(),
      phoneNumber: _phone.text.trim(),
      line1: _line1.text.trim(),
      line2: _line2.text.trim().isEmpty ? null : _line2.text.trim(),
      city: _city.text.trim(),
      region: _region.text.trim().isEmpty ? null : _region.text.trim(),
      country: _country.text.trim(),
      landmark: _landmark.text.trim().isEmpty ? null : _landmark.text.trim(),
    );
  }

  Future<void> _placeOrder(List<Address> addresses) async {
    final l10n = context.l10n;
    // Valider le formulaire seulement en mode nouvelle adresse.
    if (_selectedAddressId == null && !_formKey.currentState!.validate()) {
      return;
    }
    final address = _resolveAddress(addresses);
    if (address == null) return;

    FocusScope.of(context).unfocus();

    final order = await ref
        .read(checkoutControllerProvider.notifier)
        .placeOrder(
          shippingAddress: address,
          customerNote: _note.text.trim().isEmpty ? null : _note.text.trim(),
          paymentMethod: _paymentMethod,
        );

    if (!mounted) return;

    if (order == null) {
      final error = ref.read(checkoutControllerProvider).error;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.describeError(error))));
      return;
    }

    // Rafraîchit le panier (vidé côté serveur après création) puis ouvre la
    // page de paiement KPay.
    ref.read(cartControllerProvider.notifier).refresh();
    context.push(AppRoutes.payment, extra: order);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cart = ref.watch(cartControllerProvider);
    final addresses = ref.watch(addressesControllerProvider);
    final checkoutState = ref.watch(checkoutControllerProvider);
    final isPlacing = checkoutState.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('checkout.title'))),
      body: cart.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: l10n.describeError(e)),
        data: (cartData) {
          if (cartData.isEmpty) {
            return EmptyView(
              icon: Icons.shopping_bag_outlined,
              title: l10n.t('cart.empty.title'),
              actionLabel: l10n.t('cart.empty.cta'),
              onAction: () => context.go(AppRoutes.catalog),
            );
          }

          final addressList = addresses.maybeWhen(
            data: (list) => list,
            orElse: () => <Address>[],
          );

          // Présélection de l'adresse par défaut au premier rendu.
          if (_selectedAddressId == null && addressList.isNotEmpty) {
            final defaults = addressList.where((a) => a.isDefault);
            _selectedAddressId = defaults.isNotEmpty
                ? defaults.first.id
                : addressList.first.id;
          }

          return Stack(
            children: [
              Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  children: [
                    _AddressSection(
                      addresses: addressList,
                      addressesState: addresses,
                      selectedId: _selectedAddressId,
                      onSelect: (id) => setState(() => _selectedAddressId = id),
                      onNew: () => setState(() => _selectedAddressId = null),
                      newAddressForm: _NewAddressForm(
                        fullName: _fullName,
                        phone: _phone,
                        line1: _line1,
                        line2: _line2,
                        city: _city,
                        region: _region,
                        country: _country,
                        landmark: _landmark,
                        validators: Validators(l10n),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _PaymentSection(
                      selected: _paymentMethod,
                      onChanged: (m) => setState(() => _paymentMethod = m),
                    ),
                    const SizedBox(height: 24),
                    _NoteField(controller: _note),
                    const SizedBox(height: 24),
                    _SummarySection(cart: cartData),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(top: BorderSide(color: AppColors.line)),
                    ),
                    child: PrimaryButton(
                      label: l10n.t('checkout.place'),
                      icon: Icons.lock_outline,
                      loading: isPlacing,
                      onPressed: () => _placeOrder(addressList),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AddressSection extends StatelessWidget {
  const _AddressSection({
    required this.addresses,
    required this.addressesState,
    required this.selectedId,
    required this.onSelect,
    required this.onNew,
    required this.newAddressForm,
  });

  final List<Address> addresses;
  final AsyncValue<List<Address>> addressesState;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onNew;
  final Widget newAddressForm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.t('checkout.address.title')),
        if (addressesState.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
        for (final a in addresses)
          RadioListTile<String>(
            value: a.id,
            // ignore: deprecated_member_use
            groupValue: selectedId,
            // ignore: deprecated_member_use
            onChanged: (v) => v == null ? null : onSelect(v),
            contentPadding: EdgeInsets.zero,
            title: Text(
              a.fullName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${a.phoneNumber}\n${a.oneLine}'),
            isThreeLine: true,
          ),
        RadioListTile<String?>(
          value: null,
          // ignore: deprecated_member_use
          groupValue: selectedId,
          // ignore: deprecated_member_use
          onChanged: (_) => onNew(),
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.t('checkout.address.new'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (selectedId == null) ...[const SizedBox(height: 8), newAddressForm],
      ],
    );
  }
}

class _NewAddressForm extends StatelessWidget {
  const _NewAddressForm({
    required this.fullName,
    required this.phone,
    required this.line1,
    required this.line2,
    required this.city,
    required this.region,
    required this.country,
    required this.landmark,
    required this.validators,
  });

  final TextEditingController fullName;
  final TextEditingController phone;
  final TextEditingController line1;
  final TextEditingController line2;
  final TextEditingController city;
  final TextEditingController region;
  final TextEditingController country;
  final TextEditingController landmark;
  final Validators validators;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        AppTextField(
          label: l10n.t('address.field.fullName'),
          controller: fullName,
          validator: validators.required(),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: l10n.t('address.field.phone'),
          controller: phone,
          keyboardType: TextInputType.phone,
          validator: validators.phone(),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: l10n.t('address.field.line1'),
          controller: line1,
          validator: validators.required(),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label:
              '${l10n.t('address.field.line2')} (${l10n.t('common.optional')})',
          controller: line2,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: l10n.t('address.field.city'),
          controller: city,
          validator: validators.required(),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label:
              '${l10n.t('address.field.region')} (${l10n.t('common.optional')})',
          controller: region,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: l10n.t('address.field.country'),
          controller: country,
          validator: validators.required(),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label:
              '${l10n.t('address.field.landmark')} (${l10n.t('common.optional')})',
          controller: landmark,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}

class _PaymentSection extends StatelessWidget {
  const _PaymentSection({required this.selected, required this.onChanged});
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.t('checkout.payment.title')),
        for (final method in PaymentMethod.values)
          RadioListTile<PaymentMethod>(
            value: method,
            // ignore: deprecated_member_use
            groupValue: selected,
            // ignore: deprecated_member_use
            onChanged: (m) => m == null ? null : onChanged(m),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.t(method.l10nKey)),
            secondary: Icon(_iconFor(method)),
          ),
      ],
    );
  }

  IconData _iconFor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return Icons.credit_card;
      default:
        return Icons.phone_android;
    }
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppTextField(
      label: l10n.t('checkout.note.label'),
      controller: controller,
      hintText: l10n.t('checkout.note.hint'),
      maxLines: 3,
      textInputAction: TextInputAction.newline,
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.cart});
  final dynamic cart; // Cart

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.t('checkout.summary.title')),
        _row(
          context,
          l10n.t('checkout.summary.subtotal'),
          cart.subtotal as int,
        ),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.t('checkout.summary.total'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            PriceText(
              amount: cart.subtotal as int,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, int amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          PriceText(
            amount: amount,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
