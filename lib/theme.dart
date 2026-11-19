import 'package:flutter/material.dart';

/// Shared "Navy teal" look for the Product Enquiry Demo (Round 5).
///
/// Visuals only: every screen reads its colours, gradient, cards and
/// buttons from here, so the whole app matches. Nothing in this file
/// touches data, auth, push or navigation.
class AppTheme {
  /// Deep navy — start of the brand gradient, headings, primary buttons.
  static const Color navy = Color(0xFF0A1F44);

  /// Teal — end of the brand gradient, accents, customer bubbles.
  static const Color teal = Color(0xFF018085);

  /// Light grey page background (was plain white).
  static const Color pageBackground = Color(0xFFF4F6F8);

  /// Dark navy headings.
  static const Color heading = Color(0xFF0F1E33);

  /// Muted grey body text.
  static const Color body = Color(0xFF5A6B7C);

  /// Navy -> teal, used for AppBars, header cards and primary buttons.
  static const LinearGradient headerGradient = LinearGradient(
    colors: [navy, teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// White card: radius 16, soft shadow.
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  /// AppBar with the navy -> teal gradient background.
  static AppBar gradientAppBar({
    required Widget title,
    List<Widget>? actions,
  }) {
    return AppBar(
      title: title,
      actions: actions,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      foregroundColor: Colors.white,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: headerGradient),
      ),
    );
  }

  static ThemeData get theme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: navy,
        primary: navy,
        secondary: teal,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: pageBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: heading, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(color: body),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          side: const BorderSide(color: navy),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: navy,
        checkmarkColor: Colors.white,
        labelStyle: const TextStyle(color: body),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: body),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: teal, width: 1.5),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(backgroundColor: navy),
    );
  }
}

/// Primary action button: navy -> teal gradient, white label,
/// rounded corners. Use for the main action on each screen.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  /// While busy, shows a spinner instead of the label.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.headerGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
