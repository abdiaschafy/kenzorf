import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/address.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_localizer.dart';
import '../../../core/widgets/state_views.dart';
import '../application/addresses_controller.dart';
import 'address_form_screen.dart';

/// Liste des adresses du client, avec ajout / édition / suppression.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final addressesAsync = ref.watch(addressesControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('address.title'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.t('address.add')),
      ),
      body: addressesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: l10n.describeError(e),
          onRetry: () =>
              ref.read(addressesControllerProvider.notifier).refresh(),
        ),
        data: (addresses) {
          if (addresses.isEmpty) {
            return EmptyView(
              icon: Icons.location_off_outlined,
              title: l10n.t('address.empty.title'),
              message: l10n.t('address.empty.message'),
              actionLabel: l10n.t('address.add'),
              onAction: () => _openForm(context),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: addresses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _AddressCard(
              address: addresses[i],
              onEdit: () => _openForm(context, existing: addresses[i]),
              onDelete: () => _confirmDelete(context, ref, addresses[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Address? existing}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => AddressFormScreen(existing: existing),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Address address,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('common.delete')),
        content: Text(address.oneLine),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('common.delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(addressesControllerProvider.notifier)
          .deleteAddress(address.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.t('address.deleted'))));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.describeError(e))));
      }
    }
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
  });

  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          address.label?.isNotEmpty == true
                              ? address.label!
                              : address.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.t('address.default'),
                            style: const TextStyle(
                              color: AppColors.accentDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(address.fullName),
                  Text(
                    address.phoneNumber,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.stone),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address.oneLine,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.stone),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.danger,
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
