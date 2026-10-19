import '../constants/app_constants.dart';

/// Reusable form input validation rules.
abstract final class Validators {
  /// Validates notification message title.
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Message title is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < AppConstants.minTitleLength) {
      return 'Title must be at least ${AppConstants.minTitleLength} characters';
    }
    if (trimmed.length > AppConstants.maxTitleLength) {
      return 'Title cannot exceed ${AppConstants.maxTitleLength} characters';
    }
    return null;
  }

  /// Validates notification message body.
  static String? validateBody(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Message body is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < AppConstants.minBodyLength) {
      return 'Body must be at least ${AppConstants.minBodyLength} characters';
    }
    if (trimmed.length > AppConstants.maxBodyLength) {
      return 'Body cannot exceed ${AppConstants.maxBodyLength} characters';
    }
    return null;
  }

  /// Validates that at least one recipient device has been selected.
  static String? validateDeviceSelection(List<String> selectedDeviceIds) {
    if (selectedDeviceIds.isEmpty) {
      return 'Please select at least one target device';
    }
    return null;
  }
}
