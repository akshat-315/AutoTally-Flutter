import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autotally_flutter/database/database.dart';
import 'package:autotally_flutter/services/merchant_resolver/merchant_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MerchantResolver resolver;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    resolver = MerchantResolver(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('normalizeMerchantName', () {
    test('uppercases and trims', () {
      expect(normalizeMerchantName('  swiggy  '), 'SWIGGY');
    });

    test('strips common suffixes', () {
      expect(normalizeMerchantName('Bundl Technologies Pvt Ltd'), 'BUNDL');
    });

    test('strips punctuation', () {
      expect(normalizeMerchantName('RADHA DEVI.'), 'RADHA DEVI');
    });

    test('handles multiple spaces', () {
      expect(normalizeMerchantName('RADHA   DEVI'), 'RADHA DEVI');
    });
  });

  group('resolve - exact match', () {
    test('returns existing merchant when alias matches exactly', () async {
      final firstId = await resolver.resolve('SWIGGY');
      final secondId = await resolver.resolve('SWIGGY');
      expect(secondId, firstId);
    });

    test('matches regardless of case and whitespace', () async {
      final firstId = await resolver.resolve('Swiggy');
      final secondId = await resolver.resolve('  SWIGGY  ');
      expect(secondId, firstId);
    });

    test('strips suffixes before matching', () async {
      final firstId = await resolver.resolve('Bundl Technologies Pvt Ltd');
      final secondId = await resolver.resolve('BUNDL');
      expect(secondId, firstId);
    });
  });

  group('resolve - fuzzy match', () {
    test('creates new merchant but copies category from fuzzy match', () async {
      final foodCategory = await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              name: 'TestFood',
              icon: '🍔',
              color: '#FF6B35',
            ),
          );

      final originalId = await resolver.resolve('DOMINOS PIZZA');
      await (db.update(db.merchants)..where((m) => m.id.equals(originalId)))
          .write(MerchantsCompanion(categoryId: Value(foodCategory)));

      final variantId = await resolver.resolve('DOMINOS PIZZAS');

      expect(variantId, isNot(originalId));

      final variant = await (db.select(db.merchants)
            ..where((m) => m.id.equals(variantId)))
          .getSingle();
      expect(variant.categoryId, foodCategory);
      expect(variant.source, 'fuzzy');
    });

    test('does not fuzzy match when names are too different', () async {
      await resolver.resolve('SWIGGY');
      final amazonId = await resolver.resolve('AMAZON');

      final merchants = await db.select(db.merchants).get();
      expect(merchants.length, 2);
      expect(amazonId, isNot(equals(1)));
    });
  });

  group('resolve - create new', () {
    test('creates merchant with source auto when no match found', () async {
      final id = await resolver.resolve('RADHA DEVI');
      final merchant = await (db.select(db.merchants)
            ..where((m) => m.id.equals(id)))
          .getSingle();

      expect(merchant.name, 'RADHA DEVI');
      expect(merchant.source, 'auto');
      expect(merchant.isConfirmed, false);
      expect(merchant.categoryId, isNull);
    });

    test('creates alias for new merchant', () async {
      final id = await resolver.resolve('RADHA DEVI');
      final aliases = await (db.select(db.merchantAliases)
            ..where((a) => a.merchantId.equals(id)))
          .get();

      expect(aliases.length, 1);
      expect(aliases.first.alias, 'RADHA DEVI');
    });

    test('handles null merchantRaw', () async {
      final id = await resolver.resolve(null);
      final merchant = await (db.select(db.merchants)
            ..where((m) => m.id.equals(id)))
          .getSingle();
      expect(merchant.name, 'Unknown');
    });
  });

  group('resolve - updates lastSeen', () {
    test('updates lastSeen on exact match', () async {
      final id = await resolver.resolve('SWIGGY');
      final before = (await (db.select(db.merchants)
                ..where((m) => m.id.equals(id)))
            .getSingle())
          .lastSeen;

      await Future.delayed(const Duration(seconds: 2));
      await resolver.resolve('SWIGGY');

      final after = (await (db.select(db.merchants)
                ..where((m) => m.id.equals(id)))
            .getSingle())
          .lastSeen;

      expect(after!.isAfter(before!), isTrue);
    });
  });
}
