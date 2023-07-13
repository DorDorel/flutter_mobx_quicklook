import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobx/mobx.dart';
import 'package:mobx_tut/auth/auth_error.dart';
import 'package:mobx_tut/provider/auth_provider.dart';
import 'package:mobx_tut/provider/reminders_provider.dart';
import 'package:mobx_tut/state/reminder.dart';

part 'app_state.g.dart';

enum AppScreen { login, register, reminders }

typedef LoginOrRegistrationFunction = Future<bool> Function({
  required String email,
  required String password,
});

class AppState = _AppState with _$AppState;

abstract class _AppState with Store {
  final AuthProvider authProvider;
  final RemindersProvider reminderProvider;
  _AppState({required this.authProvider, required this.reminderProvider});

  @observable
  AppScreen currentScreen = AppScreen.login;
  @observable
  bool isLoading = false;
  @observable
  User? currentUser;
  @observable
  AuthError? authError;
  @observable
  ObservableList<Reminder> reminders = ObservableList<Reminder>();

  @computed
  ObservableList<Reminder> get sortedReminders =>
      ObservableList.of(reminders.shorted());

  @action
  void goTo(AppScreen screen) => currentScreen = screen;

  @action
  Future<bool> delete(Reminder reminder) async {
    isLoading = true;

    final userId = authProvider.userId;
    if (userId == null) {
      isLoading = false;
      return false;
    }

    try {
      // delete from firestore
      await reminderProvider.deleteReminderWithId(reminder.id, userId: userId);
      // delete from locally as well
      reminders.removeWhere((element) => element.id == reminder.id);
      return true;
    } catch (_) {
      return false;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<bool> deleteAccount() async {
    isLoading = true;
    final userId = authProvider.userId;
    if (userId == null) {
      isLoading = false;
      return false;
    }

    try {
      await reminderProvider.deleteAllDocuments(userId: userId);
      reminders.clear();
      await authProvider.deleteAccountAndSignOut();
      currentScreen = AppScreen.login;
      return true;
    } on FirebaseAuthException catch (e) {
      authError = AuthError.from(e);
      return false;
    } catch (_) {
      return false;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> logOut() async {
    isLoading = true;
    await authProvider.signOut();
    reminders.clear();
    currentScreen = AppScreen.login;
    isLoading = false;
  }

  @action
  Future<bool> createReminder(String text) async {
    isLoading = true;
    final userId = authProvider.userId;
    if (userId == null) {
      isLoading = false;
      return false;
    }
    final creationDate = DateTime.now();

    final cloudReminderId = await reminderProvider.createReminder(
      userId: userId,
      text: text,
      creationDate: creationDate,
    );
    // create a local reminder
    final reminder = Reminder(
      id: cloudReminderId,
      creationDate: creationDate,
      text: text,
      isDone: false,
    );
    reminders.add(reminder);
    isLoading = false;
    return true;
  }

  @action
  Future<bool> modifyReminder({
    required String reminderId,
    required bool isDone,
  }) async {
    final userId = authProvider.userId;
    if (userId == null) return false;

    reminderProvider.modify(
      reminderId: reminderId,
      isDone: isDone,
      userId: userId,
    );

    // update locally
    reminders
        .firstWhere((
          element,
        ) =>
            element.id == reminderId)
        .isDone = isDone;

    return true;
  }

  Future<void> initialize() async {
    isLoading = true;
    final userId = authProvider.userId;
    if (userId != null) {
      await _loadReminders();
      currentScreen = AppScreen.reminders;
    } else {
      currentScreen = AppScreen.login;
    }
    isLoading = false;
  }

  @action
  Future<bool> _loadReminders() async {
    final userId = authProvider.userId;
    if (userId == null) return false;

    final reminders = await reminderProvider.loadReminders(userId: userId);
    this.reminders = ObservableList.of(reminders);
    return true;
  }

  @action
  Future<bool> _registerOrLogin({
    required LoginOrRegistrationFunction fn,
    required String email,
    required String password,
  }) async {
    authError = null;
    isLoading = true;
    try {
      final succeeded = await fn(email: email, password: password);
      if (succeeded) await _loadReminders();
      return succeeded;
    } on AuthError catch (e) {
      authError = e;
      return false;
    } finally {
      isLoading = false;
      if (authProvider.userId != null) currentScreen = AppScreen.reminders;
    }
  }

  @action
  Future<bool> register({required email, required String password}) =>
      _registerOrLogin(
        fn: authProvider.register,
        email: email,
        password: password,
      );

  @action
  Future<bool> login({required email, required String password}) =>
      _registerOrLogin(
        fn: authProvider.login,
        email: email,
        password: password,
      );
}

extension ToInt on bool {
  int toInteger() => this ? 1 : 0;
}

extension Shorted on List<Reminder> {
  List<Reminder> shorted() => [...this]..sort(
      (lhs, rhs) {
        final isDone = lhs.isDone.toInteger().compareTo(rhs.isDone.toInteger());
        if (isDone != 0) {
          return isDone;
        }
        return lhs.creationDate.compareTo(rhs.creationDate);
      },
    );
}
