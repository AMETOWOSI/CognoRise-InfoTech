import 'package:digital_visiting_card/app/app.dart';
import 'package:digital_visiting_card/profile/data/profile_repository.dart';
import 'package:digital_visiting_card/profile/models/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsAction;
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

class _RetryProfileRepository implements ProfileRepository {
  var shouldFail = true;

  @override
  Future<Profile?> load() async {
    if (shouldFail) {
      shouldFail = false;
      throw Exception('Private storage details.');
    }
    return Profile.sample;
  }

  @override
  Future<void> save(Profile profile) async {}
}

void main() {
  testWidgets('shows the profile card and navigates to skills', (tester) async {
    final repository = _MemoryProfileRepository();
    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Ama KWATCHA'), findsOneWidget);
    expect(find.text('View portfolio'), findsNothing);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(
      find.text(
        'Anyone who scans this code can save the profile details and links you have added.',
      ),
      findsOneWidget,
    );

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

  testWidgets('offers a retry when saved profile loading fails', (
    tester,
  ) async {
    await tester.pumpWidget(MyApp(repository: _RetryProfileRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Your saved profile could not be loaded.'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsNothing);
    expect(find.text('Ama KWATCHA'), findsOneWidget);
  });

  testWidgets('empty contact and skills states provide an edit action', (
    tester,
  ) async {
    final repository = _MemoryProfileRepository()
      ..savedProfile = Profile.sample.copyWith(skills: []);
    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Contact'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Contact'));
    await tester.pumpAndSettle();
    expect(find.text('No contact details yet'), findsOneWidget);
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    expect(find.text('Your details'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Skills'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Skills'));
    await tester.pumpAndSettle();
    expect(find.text('No skills added yet'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
  });

  testWidgets('keeps content usable with larger system text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MyApp(repository: _MemoryProfileRepository()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final editButton = find.byTooltip('Edit profile');
    expect(tester.getSize(editButton).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(editButton).height, greaterThanOrEqualTo(48));
    final editButtonSemantics = tester
        .getSemantics(find.bySemanticsLabel('Edit profile'))
        .getSemanticsData();
    expect(editButtonSemantics.label, 'Edit profile');
    expect(editButtonSemantics.hasAction(SemanticsAction.tap), isTrue);

    await tester.scrollUntilVisible(
      find.text('About'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -60));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('A little about me'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
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
