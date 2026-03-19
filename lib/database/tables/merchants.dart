import 'package:drift/drift.dart';

import 'categories.dart';

class Merchants extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get vpa => text().unique().nullable()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  TextColumn get displayName => text().nullable()();
  BoolColumn get isP2p => boolean().withDefault(const Constant(false))();
  TextColumn get source => text().withDefault(const Constant('auto'))();
  BoolColumn get isConfirmed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSeen => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
