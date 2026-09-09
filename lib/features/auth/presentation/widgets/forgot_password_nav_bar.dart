import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Green nav bar shared by the three forgot-password steps (`login-forgot`,
/// `login-forgot-verifikasi`, `login-forgot-password-baru`): white status
/// bar over a back arrow + centered title, on the app's dark green gradient.
///
/// Same shape as `OrderDetailScreen`'s private `_DetailNavBar`, but these
/// three frames use a smaller title (Open Sans SemiBold 16, not 18/Bold).
class ForgotPasswordNavBar extends StatelessWidget {
  const ForgotPasswordNavBar({
    required this.title,
    required this.onBack,
    super.key,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.headerGreenTop, AppColors.headerGreenBottom],
        ),
      ),
      child: Column(
        children: [
          // The OS draws the real status bar here; the header runs behind it.
          SizedBox(height: MediaQuery.paddingOf(context).top),
          SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.chevron_left,
                      color: AppColors.white,
                      size: 28,
                    ),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          // Decorative green space below the title before the white card.
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
