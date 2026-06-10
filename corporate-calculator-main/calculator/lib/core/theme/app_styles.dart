import 'package:flutter/material.dart';

class AppStyles {
  AppStyles._();

  static const Color background = Color(0xFFF1F5F9);
  static const Color appBarBg = Colors.white;
  static const Color appBarFg = Colors.black87;
  static const Color primary = Colors.blue;
  static const Color danger = Colors.red;
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;

  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  static Color statusColor(String status, {bool isDraft = false}) {
    switch (status) {
      case 'DRAFT':
        return isDraft ? Colors.grey : Colors.green;
      case 'PENDING':
        return Colors.grey;
      case 'IN_REVIEW':
        return Colors.orange;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static String statusText(String status, {bool isDraft = false}) {
    switch (status) {
      case 'DRAFT':
        return isDraft ? 'Черновик' : 'Подтверждён';
      case 'PENDING':
        return 'Не подтверждён';
      case 'IN_REVIEW':
        return 'На модерации';
      case 'APPROVED':
        return 'Одобрен';
      case 'REJECTED':
        return 'Отклонён';
      default:
        return status;
    }
  }

  static BorderRadius get radiusXS => BorderRadius.circular(6);
  static BorderRadius get radiusS => BorderRadius.circular(8);
  static BorderRadius get radiusM => BorderRadius.circular(12);
  static BorderRadius get radiusL => BorderRadius.circular(14);
  static BorderRadius get radiusXL => BorderRadius.circular(16);

  static ShapeBorder cardShape([double radius = 12]) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 12.0;
  static const double spaceL = 16.0;
  static const double spaceXL = 24.0;
  static const double spaceXXL = 32.0;

  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(14);
  static const EdgeInsets listPadding = EdgeInsets.all(16);
  static const EdgeInsets cardMargin = EdgeInsets.only(bottom: 12);
  static const EdgeInsets cardMarginSmall = EdgeInsets.only(bottom: 8);

  static const TextStyle titleBold = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 15,
    color: textPrimary,
  );

  static const TextStyle subtitleStyle = TextStyle(
    color: textSecondary,
    fontSize: 13,
  );

  static const TextStyle captionStyle = TextStyle(
    color: textMuted,
    fontSize: 12,
  );

  static const TextStyle amountLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: primary,
  );

  static const TextStyle amountMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: primary,
  );

  static const TextStyle labelBold = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 13,
  );

  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static AppBarTheme get appBarTheme => const AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        elevation: 0,
      );

  static CardThemeData get cardTheme => CardThemeData(
        elevation: 2,
        shape: cardShape(),
      );

  static BoxDecoration statusDecoration(Color color) => BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: radiusXS,
        border: Border.all(color: color.withOpacity(0.4)),
      );

  static BoxDecoration infoBoxDecoration(Color color) => BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: radiusXS,
      );

  static BoxDecoration tintedBoxDecoration(Color color) => BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: radiusS,
        border: Border.all(color: color.withOpacity(0.3)),
      );

  static InputDecoration inputDecoration(
    String label, {
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) =>
      InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      );

  static InputDecoration inputDecorationDense(String label) =>
      InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      );

  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      );

  static ButtonStyle get dangerButton => ElevatedButton.styleFrom(
        backgroundColor: danger,
        foregroundColor: Colors.white,
      );

  static ButtonStyle get successButton => ElevatedButton.styleFrom(
        backgroundColor: success,
        foregroundColor: Colors.white,
      );

  static ButtonStyle get dangerOutlineButton => OutlinedButton.styleFrom(
        foregroundColor: danger,
        side: const BorderSide(color: danger),
      );
}
