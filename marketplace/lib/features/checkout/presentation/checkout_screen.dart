import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/address.dart';
import '../../../core/models/cart.dart';
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

/// Checkout : adresse (existante ou nouvelle), moyen de paiement,
/// récapitulatif, création de commande + redirection KPay.
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

          if (_selectedAddressId == null && addressList.isNotEmpty) {
            final defaults = addressList.where((a) => a.isDefault);
            _selectedAddressId = defaults.isNotEmpty
                ? defaults.first.id
                : addressList.first.id;
          }

          return Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    children: [
                      _SectionTitle(l10n.t('checkout.address.title')),
                      _AddressSection(
                        addresses: addressList,
                        loading: addresses.isLoading,
                        selectedId: _selectedAddressId,
                        onSelect: (id) =>
                            setState(() => _selectedAddressId = id),
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
                      const SizedBox(height: AppSpacing.xl),
                      _SectionTitle(l10n.t('checkout.payment.title')),
                      _PaymentSection(
                        selected: _paymentMethod,
                        onChanged: (m) => setState(() => _paymentMethod = m),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionTitle(l10n.t('checkout.note.label')),
                      AppTextField(
                        label: '',
                        controller: _note,
                        hintText: l10n.t('checkout.note.hint'),
                        maxLines: 3,
                        textInputAction: TextInputAction.newline,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionTitle(l10n.t('checkout.summary.title')),
                      _Summary(cart: cartData),
                    ],
                  ),
                ),
              ),
              _PayBar(
                total: cartData.subtotal,
                loading: isPlacing,
                onPay: () => _placeOrder(addressList),
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
    required this.loading,
    required this.selectedId,
    required this.onSelect,
    required this.onNew,
    required this.newAddressForm,
  });

  final List<Address> addresses;
  final bool loading;
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
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(color: AppColors.gold),
          ),
        for (final a in addresses)
          _SelectableTile(
            selected: selectedId == a.id,
            onTap: () => onSelect(a.id),
            title: a.fullName,
            subtitle: '${a.phoneNumber}\n${a.oneLine}',
            leadingIcon: Icons.location_on_outlined,
          ),
        _SelectableTile(
          selected: selectedId == null,
          onTap: onNew,
          title: l10n.t('checkout.address.new'),
          leadingIcon: Icons.add_location_alt_outlined,
        ),
        if (selectedId == null) ...[
          const SizedBox(height: AppSpacing.md),
          newAddressForm,
        ],
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
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: l10n.t('address.field.phone'),
          controller: phone,
          keyboardType: TextInputType.phone,
          validator: validators.phone(),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: l10n.t('address.field.line1'),
          controller: line1,
          validator: validators.required(),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label:
              '${l10n.t('address.field.line2')} (${l10n.t('common.optional')})',
          controller: line2,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: l10n.t('address.field.city'),
          controller: city,
          validator: validators.required(),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label:
              '${l10n.t('address.field.region')} (${l10n.t('common.optional')})',
          controller: region,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: l10n.t('address.field.country'),
          controller: country,
          validator: validators.required(),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
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
      children: [
        for (final method in PaymentMethod.values)
          _SelectableTile(
            selected: selected == method,
            onTap: () => onChanged(method),
            title: l10n.t(method.l10nKey),
            leadingIcon: _iconFor(method),
          ),
      ],
    );
  }

  IconData _iconFor(PaymentMethod method) =>
      method == PaymentMethod.card ? Icons.credit_card : Icons.phone_android;
}

/// Tuile sélectionnable premium (radio implicite) : bordure dorée si choisie.
class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.selected,
    required this.onTap,
    required this.title,
    required this.leadingIcon,
    this.subtitle,
  });

  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String? subtitle;
  final IconData leadingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: AnimatedContainer(
          duration: AppMotion.micro,
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.gold.withValues(alpha: 0.07)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.line,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                leadingIcon,
                size: 22,
                color: selected ? AppColors.gold : AppColors.taupe,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.taupe,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: selected ? AppColors.gold : AppColors.line,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.cart});
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.t('checkout.summary.subtotal'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.taupe,
                ),
              ),
              PriceText(amount: cart.subtotal, style: theme.textTheme.bodyLarge),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.t('checkout.summary.total'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              PriceText(
                amount: cart.subtotal,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayBar extends StatelessWidget {
  const _PayBar({
    required this.total,
    required this.loading,
    required this.onPay,
  });

  final int total;
  final bool loading;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.t('checkout.summary.total').toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.taupe,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  PriceText(
                    amount: total,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PrimaryButton(
                  label: l10n.t('checkout.place'),
                  icon: Icons.lock_outline,
                  variant: ButtonVariant.gold,
                  loading: loading,
                  onPressed: onPay,
                ),
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 1.6,
          color: AppColors.taupe,
        ),
      ),
    );
  }
}
