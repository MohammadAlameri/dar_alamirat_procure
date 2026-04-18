import '../localization/app_localizations.dart';
import 'package:flutter/widgets.dart';

class ValidationHelper {
  static String? validateEmail(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.translate('emailRequired');
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return AppLocalizations.of(context)!.translate('invalidEmail');
    }
    
    return null;
  }

  static String? validatePassword(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.translate('passwordRequired');
    }
    
    if (value.length < 6) {
      return AppLocalizations.of(context)!.translate('passwordMinLength');
    }
    
    return null;
  }

  static String? validateRequired(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.translate('requiredField');
    }
    return null;
  }

  static String? validateNumber(BuildContext context, String? value, {bool allowZero = false}) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.translate('requiredField');
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return AppLocalizations.of(context)!.translate('validNumber');
    }
    
    if (!allowZero && number <= 0) {
      return AppLocalizations.of(context)!.translate('validNumber'); // Maybe add more specific ones later
    }
    
    if (allowZero && number < 0) {
      return AppLocalizations.of(context)!.translate('validNumber');
    }
    
    return null;
  }
}
