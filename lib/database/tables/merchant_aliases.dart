import 'package:drift/drift.dart';

import 'merchants.dart';

class MerchantAliases extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get merchantId => integer().references(Merchants, #id)();
  TextColumn get alias => text().unique()();
}
