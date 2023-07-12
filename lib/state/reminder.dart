// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:mobx/mobx.dart';

part 'reminder.g.dart';

class Reminder = _Reminder with _$Reminder;

abstract class _Reminder with Store {
  final String id;
  final DateTime creationDate;
  @observable
  String text;
  @observable
  bool isDone;

  _Reminder({
    required this.id,
    required this.creationDate,
    required this.text,
    required this.isDone,
  });

  @override
  bool operator ==(covariant _Reminder other) =>
      id == other.id &&
      creationDate == other.creationDate &&
      text == other.text &&
      isDone == other.isDone;

  @override
  int get hashCode => Object.hash(id, creationDate, text, isDone);
}
