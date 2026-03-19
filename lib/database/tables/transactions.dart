import 'package:drift/drift.dart';

import 'categories.dart';
import 'merchants.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get smsId => integer().unique()();
  TextColumn get direction => text()();
  IntColumn get amount => integer()();
  TextColumn get bank => text()();
  IntColumn get merchantId => integer().nullable().references(Merchants, #id)();
  TextColumn get merchantRaw => text().nullable()();
  TextColumn get accountLast4 => text().nullable()();
  TextColumn get vpa => text().nullable()();
  TextColumn get upiRef => text().nullable()();
  DateTimeColumn get transactionDate => dateTime()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  TextColumn get categorySource => text().nullable()();
  TextColumn get rawSms => text()();
  TextColumn get smsSender => text()();
  DateTimeColumn get smsReceivedAt => dateTime()();
  BoolColumn get isP2p => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
