import 'package:drift/drift.dart';

class Templates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get senderKey => text()();
  TextColumn get bankName => text()();
  TextColumn get direction => text()();
  TextColumn get pattern => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get source => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
