import 'package:digital_visiting_card/app/app.dart';
import 'package:digital_visiting_card/profile/data/profile_repository.dart';
import 'package:digital_visiting_card/profile/models/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

class _MemoryProfileRepository implements ProfileRepository {
  Profile? savedProfile;

  @override
  Future<Profile?> load() async => savedProfile;

  @override
  Future<void> save(Profile profile) async {
    savedProfile = profile;
  }
}

void main() {
  testWidgets('shows the profile card and navigates to skills', (tester) async {
    final repository = _MemoryProfileRepository();
    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Ama KWATCHA'), findsOneWidget);
    expect(find.text('View portfolio'), findsNothing);
    expect(find.byType(QrImageView), findsOneWidget);

    await tester.ensureVisible(find.text('Skills'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skills'));
    await tester.pumpAndSettle();

    expect(find.text('What I bring'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
  });

  testWidgets('opens About and Contact and omits empty social links', (
    tester,
  ) async {
    final repository = _MemoryProfileRepository();
    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('About'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('A little about me'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Contact'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contact'));
    await tester.pumpAndSettle();

    expect(find.text('Let’s connect'), findsOneWidget);
    expect(find.text('WhatsApp'), findsNothing);
    expect(find.text('LinkedIn'), findsNothing);
    expect(find.text('Facebook'), findsNothing);
    expect(find.text('Instagram'), findsNothing);
  });

  testWidgets('home layout fits a narrow mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MyApp(repository: _MemoryProfileRepository()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Ama KWATCHA'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(QrImageView),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(QrImageView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('validates and saves edited profile data', (tester) async {
    final repository = _MemoryProfileRepository();
    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit profile'));
    await tester.pumpAndSettle();

    final nameField = find.byType(TextFormField).first;
    final formScroll = find
        .descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          ),
        )
        .first;
    await tester.enterText(nameField, '');
    await tester.scrollUntilVisible(
      find.text('Save profile'),
      280,
      scrollable: formScroll,
    );
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required.'), findsOneWidget);
    expect(repository.savedProfile, isNull);

    await tester.scrollUntilVisible(nameField, -280, scrollable: formScroll);
    await tester.enterText(nameField, 'Ama KWATCHA');
    final phoneField = find.byKey(const ValueKey<String>('phone'));
    await tester.scrollUntilVisible(phoneField, 280, scrollable: formScroll);
    await tester.enterText(phoneField, '+228 90 00 ABC');
    await tester.scrollUntilVisible(
      find.text('Save profile'),
      280,
      scrollable: formScroll,
    );
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid phone number.'), findsOneWidget);
    expect(repository.savedProfile, isNull);

    await tester.scrollUntilVisible(phoneField, -280, scrollable: formScroll);
    await tester.enterText(phoneField, '+228 90 00 00 00');
    await tester.scrollUntilVisible(
      find.text('Save profile'),
      280,
      scrollable: formScroll,
    );
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(repository.savedProfile?.fullName, 'Ama KWATCHA');
    expect(repository.savedProfile?.phone, '+228 90 00 00 00');
    expect(find.text('Ama KWATCHA'), findsOneWidget);
  });
}
