import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/akun/data/models/busboy_profile.dart';
import 'package:dtw_app/features/akun/presentation/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:obra_icons/obra_icons.dart';

/// The `profile-saya` frame: the busboy's editable profile detail, reached from
/// the Akun account menu ("Profil Saya"). A white nav bar over a scrollable
/// body of grouped cards — an avatar/upload card, a "Informasi Pribadi" field
/// group, and a "Informasi Pekerjaan" field group — with a pinned "Simpan" CTA.
///
/// Data comes from [busboyProfileProvider] (in-memory mock; Open Question 1).
/// Editing and Simpan are UI-only stubs (Open Question 2).
class ProfileSayaScreen extends ConsumerWidget {
  const ProfileSayaScreen({super.key});

  void _onBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.akun);
    }
  }

  void _onSave(BuildContext context) {
    // TODO(open-question): Simpan is a UI-only stub (Open Question 2). Wire to
    // the real profile-update mutation once the endpoint is specified.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Perubahan disimpan (mock)')),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(busboyProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileNavBar(
            title: 'Profile Saya',
            onBack: () => _onBack(context),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const _AvatarCard(),
                const SizedBox(height: 16),
                _PersonalInfoCard(profile: profile),
                const SizedBox(height: 16),
                _WorkInfoCard(profile: profile),
              ],
            ),
          ),
          _BottomAction(onPressed: () => _onSave(context)),
        ],
      ),
    );
  }
}

/// White nav bar: dark status bar over a dark back arrow + centered title.
/// (`profile-saya` Navigation Bar — a light variant of the app's headers.)
class _ProfileNavBar extends StatelessWidget {
  const _ProfileNavBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: Column(
        children: [
          const _DarkStatusBar(),
          SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: onBack,
                    icon: const Icon(
                      ObraIcons.chevron_left,
                      color: AppColors.neutral900,
                      size: 24,
                    ),
                  ),
                ),
                Text(
                  title,
                  // TODO(open-question): Open Sans Bold in the cache; not
                  // bundled, so this falls back to the default family.
                  style: const TextStyle(
                    color: AppColors.neutral900,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The avatar / photo-upload card (`Frame 2619`): a centered 80px avatar with a
/// camera badge over a grey "JPG, PNG Maksimal 2 MB" caption.
class _AvatarCard extends StatelessWidget {
  const _AvatarCard();

  @override
  Widget build(BuildContext context) {
    return const _Card(
      child: Column(
        children: [
          _Avatar(),
          SizedBox(height: 8),
          Text(
            'JPG, PNG Maksimal 2 MB',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.neutral500,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// 80px circular avatar with a camera badge at the bottom-right.
// TODO(open-question): the avatar raster ("ChatGPT Image ..." 80x80) was not
// exported to the asset cache; approximated with a tinted user glyph (mirrors
// the Akun profile card's placeholder).
class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.successTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              ObraIcons.user,
              size: 40,
              color: AppColors.success700,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 8,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                ObraIcons.camera,
                size: 14,
                color: AppColors.neutral500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Informasi Pribadi" card (`Frame 2620`): the read-only Busboy ID plus the
/// editable name / phone / (optional) email fields.
class _PersonalInfoCard extends StatelessWidget {
  const _PersonalInfoCard({required this.profile});

  final BusboyProfile profile;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SectionTitle('Informasi Pribadi'),
          const SizedBox(height: 16),
          _ProfileField(
            label: 'Busboy ID',
            value: profile.busboyId,
            enabled: false,
          ),
          const SizedBox(height: 16),
          _ProfileField(
            label: 'Nama Lengkap',
            value: profile.namaLengkap,
          ),
          const SizedBox(height: 16),
          _ProfileField(
            label: 'No. Telepon',
            value: profile.noTelepon,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _ProfileField(
            label: 'Email',
            optionalHint: '(Opsional)',
            value: profile.email,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }
}

/// "Informasi Pekerjaan" card (`Frame 2621`): the outlet + shift selectors,
/// rendered as read-only dropdown affordances.
class _WorkInfoCard extends StatelessWidget {
  const _WorkInfoCard({required this.profile});

  final BusboyProfile profile;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SectionTitle('Informasi Pekerjaan'),
          const SizedBox(height: 16),
          _ProfileField(
            label: 'Outlet / Lokasi',
            value: profile.outlet,
            asDropdown: true,
          ),
          const SizedBox(height: 16),
          _ProfileField(
            label: 'Shift',
            value: profile.shift,
            asDropdown: true,
          ),
        ],
      ),
    );
  }
}

/// Bold section header, e.g. "Informasi Pribadi" (Body 16/Bold).
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      // TODO(open-question): Open Sans Bold in the cache; not bundled.
      style: const TextStyle(
        color: AppColors.neutral900,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }
}

/// A labelled profile input row (`Input` component): a bold label (with an
/// optional grey `(Opsional)` suffix) over a 40px field box.
///
/// Three visual variants, all sharing the box metrics of the app's `AppInput`
/// (40h, `#D0D3D9` border, 14pt text):
/// - editable text (default) — a seeded [TextField];
/// - read-only ([enabled] false) — grey `#F2F4F7` fill + muted text;
/// - dropdown ([asDropdown]) — read-only value with a trailing chevron.
///
/// Editing is a UI-only stub (Open Question 2): the field accepts input but
/// nothing is persisted.
class _ProfileField extends StatefulWidget {
  const _ProfileField({
    required this.label,
    required this.value,
    this.optionalHint,
    this.enabled = true,
    this.asDropdown = false,
    this.keyboardType,
  });

  final String label;
  final String value;
  final String? optionalHint;
  final bool enabled;
  final bool asDropdown;
  final TextInputType? keyboardType;

  @override
  State<_ProfileField> createState() => _ProfileFieldState();
}

class _ProfileFieldState extends State<_ProfileField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _muted => !widget.enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _label(),
        const SizedBox(height: 8),
        _field(),
      ],
    );
  }

  Widget _label() {
    const labelStyle = TextStyle(
      color: AppColors.neutral900,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      height: 1.15,
    );
    if (widget.optionalHint == null) {
      return Text(widget.label, style: labelStyle);
    }
    return Text.rich(
      TextSpan(
        text: '${widget.label} ',
        style: labelStyle,
        children: [
          TextSpan(
            text: widget.optionalHint,
            style: const TextStyle(
              color: AppColors.neutral500,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field() {
    final textStyle = TextStyle(
      color: _muted ? AppColors.neutral500 : AppColors.neutral900,
      fontSize: 14,
      height: 1,
    );

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: _muted ? AppColors.neutralTint : AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neutral100),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: widget.asDropdown
                ? Text(
                    widget.value,
                    style: textStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : TextField(
                    controller: _controller,
                    enabled: widget.enabled,
                    keyboardType: widget.keyboardType,
                    style: textStyle,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
          ),
          if (widget.asDropdown) ...[
            const SizedBox(width: 8),
            const Icon(
              ObraIcons.chevron_down,
              size: 20,
              color: AppColors.neutral500,
            ),
          ],
        ],
      ),
    );
  }
}

/// Shared white rounded card used by every section of the screen (`Card
/// Shadow` token, 16 radius, 16 padding).
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

/// Pinned bottom "Simpan" CTA bar.
class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: PrimaryButton(label: 'Simpan', onPressed: onPressed),
        ),
      ),
    );
  }
}

/// Dark-on-white status bar (`9:41`). Light variant of the app's headers.
// TODO(open-question): pixel-exact SVG glyphs are approximated with Material
// icons until flutter_svg is available.
class _DarkStatusBar extends StatelessWidget {
  const _DarkStatusBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 44,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '9:41',
              style: TextStyle(
                color: AppColors.neutral900,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.signal_cellular_alt,
                  size: 17,
                  color: AppColors.neutral900,
                ),
                SizedBox(width: 6),
                Icon(Icons.wifi, size: 17, color: AppColors.neutral900),
                SizedBox(width: 6),
                Icon(
                  Icons.battery_full,
                  size: 22,
                  color: AppColors.neutral900,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
