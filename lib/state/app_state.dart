import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobx/mobx.dart';
import 'package:mobx_tut/auth/auth_error.dart';
import 'package:mobx_tut/state/reminder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'app_state.g.dart';

enum AppScreen { login, register, reminders }

typedef LoginOrRegistrationFunction = Future<UserCredential> Function({
  required String email,
  required String password,
});

abstract class _DocumentKeys {
  static const text = 'text';
  static const creationDate = 'creation_date';
  static const isDone = 'is_done';
}

class AppState = _AppState with _$AppState;

abstract class _AppState with Store {
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
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) {
      isLoading = false;
      return false;
    }
    final userId = user.uid;
    final collection =
        await FirebaseFirestore.instance.collection(userId).get();
    try {
      // delete from firestore
      final firebaseReminder =
          collection.docs.firstWhere((element) => element.id == reminder.id);
      await firebaseReminder.reference.delete();
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
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) {
      isLoading = false;
      return false;
    }
    final userId = user.uid;

    try {
      final store = FirebaseFirestore.instance;
      final operation = store.batch();
      final collection = await store.collection(userId).get();
      for (final doc in collection.docs) {
        operation.delete(doc.reference);
      }
      /*
        delete all reminders for this user on firebase
        delete the user 
        sign out
      */
      await operation.commit();
      await user.delete();
      await auth.signOut();
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
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    isLoading = false;
    currentScreen = AppScreen.login;
    reminders.clear();
  }

  @action
  Future<bool> createReminder(String text) async {
    isLoading = true;
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) {
      isLoading = false;
      return false;
    }
    final userId = user.uid;
    final creationDate = DateTime.now();

    final firestoreReminder =
        await FirebaseFirestore.instance.collection(userId).add({
      _DocumentKeys.text: text,
      _DocumentKeys.creationDate: creationDate.toIso8601String(),
      // _DocumentKeys.creationDate: creationDate, // if i want timestamp
      _DocumentKeys.isDone: false,
    });
    // create a local reminder
    final reminder = Reminder(
      id: firestoreReminder.id,
      creationDate: creationDate,
      text: text,
      isDone: false,
    );
    reminders.add(reminder);
    isLoading = false;
    return true;
  }

  @action
  Future<bool> modify({
    required Reminder reminder,
    required bool isDone,
  }) async {
    final userId = currentUser?.uid;
    if (userId == null) return false;

    final collection =
        await FirebaseFirestore.instance.collection(userId).get();
    final firestoreReminder = collection.docs
        .where((element) => element.id == reminder.id)
        .first
        .reference;

    await firestoreReminder.update({_DocumentKeys.isDone: isDone});

    // update locally
    reminders
        .firstWhere((
          element,
        ) =>
            element.id == reminder.id)
        .isDone = isDone;

    return true;
  }

  Future<void> initialize() async {
    isLoading = true;
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _loadReminders();
      currentScreen = AppScreen.reminders;
    } else {
      currentScreen = AppScreen.login;
    }
    isLoading = false;
  }

  @action
  Future<bool> _loadReminders() async {
    final userId = currentUser?.uid;
    if (userId == null) return false;

    final collection =
        await FirebaseFirestore.instance.collection(userId).get();
    final reminders = collection.docs.map(
      (doc) => Reminder(
        id: doc.id,
        creationDate: DateTime.parse([_DocumentKeys.creationDate] as String),
        // creationDate: doc[_DocumentKeys.creationDate].toDate(), // if i want timestamp
        text: doc[_DocumentKeys.text] as String,
        isDone: doc[_DocumentKeys.isDone] as bool,
      ),
    );

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
      await fn(email: email, password: password);
      currentUser = FirebaseAuth.instance.currentUser;
      await _loadReminders();
      return true;
    } on FirebaseAuthException catch (e) {
      currentUser = null;
      authError = AuthError.from(e);
      return false;
    } finally {
      isLoading = false;
      if (currentUser != null) currentScreen = AppScreen.reminders;
    }
  }

  @action
  Future<bool> register({required email, required String password}) =>
      _registerOrLogin(
        fn: FirebaseAuth.instance.createUserWithEmailAndPassword,
        email: email,
        password: password,
      );

  @action
  Future<bool> login({required email, required String password}) =>
      _registerOrLogin(
        fn: FirebaseAuth.instance.signInWithEmailAndPassword,
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
