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

    expect(find.text('Alex Morgan'), findsOneWidget);
    expect(find.text('View portfolio'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Skills'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
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

    await tester.scrollUntilVisible(
      find.text('About'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('A little about me'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Contact'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Contact'));
    await tester.pumpAndSettle();

    expect(find.text('Let’s connect'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('LinkedIn'), findsOneWidget);
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
    expect(find.text('Alex Morgan'), findsOneWidget);
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
    await tester.enterText(nameField, '');
    await tester.scrollUntilVisible(
      find.text('Save profile'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required.'), findsOneWidget);
    expect(repository.savedProfile, isNull);

    await tester.scrollUntilVisible(
      nameField,
      -280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(nameField, 'Taylor Swift');
    await tester.scrollUntilVisible(
      find.text('Save profile'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(repository.savedProfile?.fullName, 'Taylor Swift');
    expect(find.text('Taylor Swift'), findsOneWidget);
  });
}
