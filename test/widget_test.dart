import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_notification_apps/core/theme/app_theme.dart';
import 'package:push_notification_apps/core/utils/validators.dart';
import 'package:push_notification_apps/core/widgets/app_button.dart';
import 'package:push_notification_apps/core/widgets/app_error_view.dart';
import 'package:push_notification_apps/core/widgets/app_text_field.dart';

void main() {
  group('Design System & UI Widgets Tests', () {
    testWidgets('AppButton renders with text and triggers callback', (
      tester,
    ) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(text: 'Send Push', onPressed: () => pressed = true),
          ),
        ),
      );

      expect(find.text('Send Push'), findsOneWidget);
      await tester.tap(find.byType(AppButton));
      expect(pressed, isTrue);
    });

    testWidgets('AppTextField renders label and hint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppTextField(
              label: 'Message Title',
              hint: 'Enter title here',
            ),
          ),
        ),
      );

      expect(find.text('Message Title'), findsOneWidget);
      expect(find.text('Enter title here'), findsOneWidget);
    });

    testWidgets('AppErrorView renders message and retry button', (
      tester,
    ) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppErrorView(
              title: 'Connection Error',
              message: 'Failed to connect to Firebase',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Connection Error'), findsOneWidget);
      expect(find.text('Failed to connect to Firebase'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);
    });
  });

  group('Validators Unit Tests', () {
    test('Title validator enforces length limits', () {
      expect(Validators.validateTitle(''), isNotNull);
      expect(Validators.validateTitle('ab'), isNotNull);
      expect(Validators.validateTitle('Valid Title'), isNull);
    });

    test('Body validator enforces length limits', () {
      expect(Validators.validateBody(''), isNotNull);
      expect(Validators.validateBody('123'), isNotNull);
      expect(Validators.validateBody('Valid notification body text'), isNull);
    });

    test('Device selection validator requires at least one device', () {
      expect(Validators.validateDeviceSelection([]), isNotNull);
      expect(Validators.validateDeviceSelection(['dev_123']), isNull);
    });
  });
}
