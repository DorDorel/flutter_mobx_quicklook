import 'package:flutter_test/flutter_test.dart';
import 'package:mobx_tut/state/app_state.dart';

import 'mocks/mock_auth_provider.dart';
import 'mocks/mock_reminder_provider.dart';

void main() {
  late AppState appState;
  setUp(() {
    appState = AppState(
      authProvider: MockAuthProvider(),
      reminderProvider: MockReminderProvider(),
    );
  });

  test('Initial state', () {
    expect(appState.currentScreen, AppScreen.login);
    appState.authError.expectNull();
    appState.isLoading.expectFalse();
    appState.reminders.isEmpty.expectTrue();
  });

  test('Going to screen', () {
    appState.goTo(AppScreen.register);
    expect(appState.currentScreen, AppScreen.register);
    appState.goTo(AppScreen.login);
    expect(appState.currentScreen, AppScreen.login);
    appState.goTo(AppScreen.reminders);
    expect(appState.currentScreen, AppScreen.reminders);
  });

  test('Initializing the app state', () async {
    await appState.initialize();
    expect(appState.currentScreen, AppScreen.reminders);
    expect(appState.reminders.length, mockReminders.length);
    appState.reminders.contains(mockReminder1).expectTrue();
    appState.reminders.contains(mockReminder2).expectTrue();
  });

  test('Modifying reminders', () async {
    await appState.initialize();
    final reminder1 = appState.reminders
        .firstWhere((reminder) => reminder.id == mockReminder1Id);
    final reminder2 = appState.reminders
        .firstWhere((reminder) => reminder.id == mockReminder2Id);
    reminder1.isDone.expectTrue();
    reminder2.isDone.expectFalse();
    await appState.modifyReminder(reminderId: mockReminder1Id, isDone: false);
    await appState.modifyReminder(reminderId: mockReminder2Id, isDone: true);
    reminder1.isDone.expectFalse();
    reminder2.isDone.expectTrue();
  });

  test("Creating reminder", () async {
    await appState.initialize();
    const text = 'text';
    final didCreate = await appState.createReminder(text);
    didCreate.expectTrue();
    expect(appState.reminders.length, mockReminders.length + 1);
    final testReminder = appState.reminders
        .firstWhere((element) => element.id == mockReminderId);
    expect(testReminder.text, text);
    testReminder.isDone.expectFalse();
  });
  test('Deleting reminders', () async {
    await appState.initialize();
    final count = appState.reminders.length;
    final reminder = appState.reminders.first;
    final deleted = await appState.delete(reminder);
    deleted.expectTrue();
    expect(appState.reminders.length, count - 1);
  });

  test('Deleting account', () async {
    await appState.initialize();
    final cloudDeleteAccount = await appState.deleteAccount();
    cloudDeleteAccount.expectTrue();
    expect(appState.currentScreen, AppScreen.login);
  });

  test('Logging out', () async {
    await appState.initialize();
    await appState.logOut();
    appState.reminders.isEmpty.expectTrue();
    expect(appState.currentScreen, AppScreen.login);
  });
}

extension Expectations on Object? {
  void expectNull() => expect(this, isNull);
  void expectNotNull() => expect(this, isNotNull);
}

extension BoolExpectations on bool {
  void expectTrue() => expect(this, true);
  void expectFalse() => expect(this, false);
}
