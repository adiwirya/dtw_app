import 'dart:async';

import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/router/tenant_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/utils/currency.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_branch_provider.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_order_provider.dart';
import 'package:dtw_app/features/tenant/presentation/widgets/pickup_code_numpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The exact backend message for a wrong pickup code
/// (`api-tenant-busboy-guide.md` §3) — used to tell a wrong-code 422 apart
/// from any other failure (L5: only a wrong code gets the inline
/// clear-and-retry treatment; everything else uses the normal SnackBar).
const String wrongPickupCodeMessage = 'Kode pickup tidak sesuai.';

/// The "Verifikasi Pickup" screen: the tenant enters the 6-digit code the
/// customer gives them in person to complete a self-pickup order
/// (`POST /v1/orders/{order}/complete-pickup`).
///
/// Every value shown is read off the real [tenantOrderBoardProvider] entry for
/// [orderId] — same convention as `TenantRejectOrderScreen`. Unlike a reject,
/// a successful verification never removes the order from the board (it
/// moves to `COMPLETED`, still present), so there is no need for a
/// last-resolved snapshot here.
class VerifikasiPickupScreen extends ConsumerStatefulWidget {
  const VerifikasiPickupScreen({required this.orderId, super.key});

  /// Id of the order being verified.
  final String orderId;

  @override
  ConsumerState<VerifikasiPickupScreen> createState() =>
      _VerifikasiPickupScreenState();
}

class _VerifikasiPickupScreenState
    extends ConsumerState<VerifikasiPickupScreen> {
  static const _codeLength = 6;

  String _code = '';
  String? _error;
  bool _submitting = false;
  bool _verified = false;

  TenantOrder? _findOrder(List<TenantOrder>? orders) {
    if (orders == null) return null;
    for (final order in orders) {
      if (order.id == widget.orderId) return order;
    }
    return null;
  }

  void _onBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(TenantRoutes.order);
    }
  }

  void _onDigit(String digit) {
    if (_submitting || _code.length >= _codeLength) return;
    setState(() {
      _code += digit;
      _error = null;
    });
  }

  void _onBackspace() {
    if (_submitting || _code.isEmpty) return;
    setState(() => _code = _code.substring(0, _code.length - 1));
  }

  Future<void> _onSubmit() async {
    if (_submitting || _code.length != _codeLength) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref
          .read(tenantOrderBoardProvider.notifier)
          .verifyPickup(widget.orderId, pickupCode: _code);
    } on ApiException catch (error) {
      if (!mounted) return;
      final wrongCode = error.message == wrongPickupCodeMessage;
      setState(() {
        _submitting = false;
        _code = wrongCode ? '' : _code;
        _error = wrongCode ? error.message : null;
      });
      if (!wrongCode) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage(error))));
      }
      return;
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage(error))));
      return;
    }

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _verified = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(tenantOrderBoardProvider).valueOrNull;
    final order = _findOrder(board);
    final branch = ref.watch(currentTenantBranchProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _VerifikasiNavBar(title: 'Verifikasi Pickup', onBack: _onBack),
            Expanded(
              child: order == null
                  ? const Center(
                      child: Text(
                        'Pesanan tidak ditemukan di daftar order.',
                        style: TextStyle(color: AppColors.neutral500),
                      ),
                    )
                  : _verified
                  ? _SuccessView(
                      order: order,
                      brandName: branch?.brandName,
                      onDone: _onBack,
                    )
                  : _codeEntryView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _codeEntryView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          const Text(
            'Masukkan kode pickup yang diberikan oleh customer',
            style: TextStyle(color: AppColors.neutral500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              for (var i = 0; i < _codeLength; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _DigitBox(
                    digit: i < _code.length ? _code[i] : null,
                  ),
                ),
              ],
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.dangerRed, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          PickupCodeNumpad(onDigit: _onDigit, onBackspace: _onBackspace),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Cek Kode',
            onPressed: _code.length == _codeLength && !_submitting
                ? () => unawaited(_onSubmit())
                : null,
          ),
        ],
      ),
    );
  }
}

/// White nav bar (back chevron + centered dark title) — same shape as
/// `TenantRejectOrderScreen`'s private `_RejectNavBar`.
class _VerifikasiNavBar extends StatelessWidget {
  const _VerifikasiNavBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.chevron_left,
                color: AppColors.neutral900,
                size: 28,
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.neutral900,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// One digit-display box (visual style matches the forgot-password OTP box —
/// `otpBoxBorder`, 12 radius, 51 tall) but display-only: no `TextField`, no
/// OS keyboard (L4 — entry is exclusively through [PickupCodeNumpad]).
class _DigitBox extends StatelessWidget {
  const _DigitBox({required this.digit});

  final String? digit;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 51,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.otpBoxBorder),
      ),
      alignment: Alignment.center,
      child: Text(
        digit ?? '',
        style: const TextStyle(
          color: AppColors.neutral900,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// The post-verification "Order Ditemukan!" confirmation view.
///
/// No customer name row: `TenantOrder` carries no customer-name field
/// anywhere in this app today (see the Spec's Blocking Questions for the
/// analogous `is_delivery` gap) — showing a fabricated one would be worse
/// than omitting it.
class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.order,
    required this.brandName,
    required this.onDone,
  });

  final TenantOrder order;
  final String? brandName;
  final VoidCallback onDone;

  static const double _ring = 80;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          _checkRing(),
          const SizedBox(height: 24),
          const Text(
            'Order Ditemukan!',
            style: TextStyle(
              color: AppColors.neutral900,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pesanan berhasil diserahkan!',
            style: TextStyle(color: AppColors.neutral500, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _summaryCard(),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Pesanan Selesai', onPressed: onDone),
        ],
      ),
    );
  }

  Widget _checkRing() {
    return Container(
      width: _ring,
      height: _ring,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.successGreen.withValues(alpha: 0.5),
          width: 4,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.check_rounded,
          size: 40,
          color: AppColors.successGreen,
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFF1F4)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            offset: Offset(0, 2),
            blurRadius: 16,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${order.receiptNumber}',
                    style: const TextStyle(
                      color: AppColors.neutral900,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (brandName != null)
                  Text(
                    brandName!,
                    style: const TextStyle(
                      color: AppColors.neutral500,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${order.tableLabel} • Pickup',
              style: const TextStyle(color: AppColors.neutral500, fontSize: 12),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: AppColors.neutral100),
            const SizedBox(height: 12),
            for (final item in order.items) ...[
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${item.qty}x',
                      style: const TextStyle(
                        color: AppColors.neutral500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        color: AppColors.neutral900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    item.price,
                    style: const TextStyle(
                      color: AppColors.neutral900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: AppColors.neutral900,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  formatRupiah(order.grandTotal),
                  style: const TextStyle(
                    color: AppColors.neutral900,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
