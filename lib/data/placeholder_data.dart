import 'dart:math' as math;

import 'package:flutter/material.dart';

class MockCategory {
  final int id;
  final String name;
  final String icon;
  final Color color;
  final bool isDefault;

  const MockCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = true,
  });
}

class MockCategoryBudget {
  final int categoryId;
  final int budgetAmount;

  const MockCategoryBudget({
    required this.categoryId,
    required this.budgetAmount,
  });
}

class MockSavingsGoal {
  final int id;
  final String name;
  final String icon;
  final int targetAmount;
  final int savedAmount;
  final DateTime? deadline;
  final List<MockGoalAllocation> allocations;

  const MockSavingsGoal({
    required this.id,
    required this.name,
    required this.icon,
    required this.targetAmount,
    required this.savedAmount,
    this.deadline,
    this.allocations = const [],
  });

  double get progress => (savedAmount / targetAmount).clamp(0.0, 1.0);
}

class MockGoalAllocation {
  final DateTime date;
  final int amount;
  final String? note;

  const MockGoalAllocation({
    required this.date,
    required this.amount,
    this.note,
  });
}

class MockMerchant {
  final int id;
  final String name;
  final String? displayName;
  final String? vpa;
  final int? categoryId;
  final bool autoCategorize;
  final int transactionCount;
  final int totalSpent;

  const MockMerchant({
    required this.id,
    required this.name,
    this.displayName,
    this.vpa,
    this.categoryId,
    this.autoCategorize = true,
    required this.transactionCount,
    required this.totalSpent,
  });

  String get display => displayName ?? name;
}

class MockTransaction {
  final int id;
  final String direction;
  final int amount;
  final String merchantName;
  final String? vpa;
  final int? categoryId;
  final String? categorySource;
  final String bank;
  final String? accountLast4;
  final DateTime date;
  final bool isP2p;
  final String? upiRef;
  final String rawSms;
  final String smsSender;
  final int? merchantId;

  const MockTransaction({
    required this.id,
    required this.direction,
    required this.amount,
    required this.merchantName,
    this.vpa,
    this.categoryId,
    this.categorySource,
    required this.bank,
    this.accountLast4,
    required this.date,
    this.isP2p = false,
    this.upiRef,
    required this.rawSms,
    required this.smsSender,
    this.merchantId,
  });
}

class PlaceholderData {
  static final categories = <MockCategory>[
    MockCategory(id: 1, name: 'Food', icon: '\u{1F354}', color: Color(0xFFFF6B35)),
    MockCategory(id: 2, name: 'Transport', icon: '\u{1F697}', color: Color(0xFF4ECDC4)),
    MockCategory(id: 3, name: 'Shopping', icon: '\u{1F6CD}', color: Color(0xFFE91E63)),
    MockCategory(id: 4, name: 'Bills', icon: '\u{1F4C4}', color: Color(0xFF607D8B)),
    MockCategory(id: 5, name: 'Entertainment', icon: '\u{1F3AC}', color: Color(0xFF9C27B0)),
    MockCategory(id: 6, name: 'Health', icon: '\u{1F48A}', color: Color(0xFF4CAF50)),
    MockCategory(id: 7, name: 'Education', icon: '\u{1F4DA}', color: Color(0xFF2196F3)),
    MockCategory(id: 8, name: 'Transfers', icon: '\u{1F504}', color: Color(0xFF78909C)),
    MockCategory(id: 9, name: 'Subscriptions', icon: '\u{1F501}', color: Color(0xFFFF9800)),
    MockCategory(id: 10, name: 'Other', icon: '\u{1F4E6}', color: Color(0xFF9E9E9E)),
    MockCategory(id: 11, name: 'Uncategorized', icon: '\u{2753}', color: Color(0xFF9E9E9E)),
  ];

  static const merchants = <MockMerchant>[
    MockMerchant(id: 1, name: 'SWIGGY', displayName: 'Swiggy', vpa: 'swiggy@okaxis', categoryId: 1, transactionCount: 23, totalSpent: 876500),
    MockMerchant(id: 2, name: 'ZOMATO', displayName: 'Zomato', vpa: 'zomato@hdfcbank', categoryId: 1, transactionCount: 18, totalSpent: 654200),
    MockMerchant(id: 3, name: 'UBER INDIA', displayName: 'Uber', vpa: 'uber@ybl', categoryId: 2, transactionCount: 12, totalSpent: 456000),
    MockMerchant(id: 4, name: 'OLA CABS', displayName: 'Ola', vpa: 'olacabs@paytm', categoryId: 2, transactionCount: 8, totalSpent: 324000),
    MockMerchant(id: 5, name: 'AMAZON', displayName: 'Amazon', vpa: 'amazon@apl', categoryId: 3, transactionCount: 15, totalSpent: 1245000),
    MockMerchant(id: 6, name: 'FLIPKART', displayName: 'Flipkart', vpa: 'flipkart@axl', categoryId: 3, transactionCount: 7, totalSpent: 890000),
    MockMerchant(id: 7, name: 'JIO PREPAID', displayName: 'Jio Recharge', vpa: 'jio@hdfcbank', categoryId: 4, transactionCount: 3, totalSpent: 89700),
    MockMerchant(id: 8, name: 'BESCOM', displayName: 'BESCOM', vpa: 'bescom@ybl', categoryId: 4, transactionCount: 3, totalSpent: 456000),
    MockMerchant(id: 9, name: 'NETFLIX', displayName: 'Netflix', vpa: 'netflix@okaxis', categoryId: 9, transactionCount: 3, totalSpent: 194700),
    MockMerchant(id: 10, name: 'SPOTIFY', displayName: 'Spotify', vpa: 'spotify@ybl', categoryId: 9, transactionCount: 3, totalSpent: 35700),
    MockMerchant(id: 11, name: 'APOLLO PHARMACY', displayName: 'Apollo Pharmacy', vpa: 'apollopharmacy@ybl', categoryId: 6, transactionCount: 4, totalSpent: 234500),
    MockMerchant(id: 12, name: 'PVR CINEMAS', displayName: 'PVR Cinemas', vpa: 'pvr@okaxis', categoryId: 5, transactionCount: 2, totalSpent: 156000),
    MockMerchant(id: 13, name: 'BIGBASKET', displayName: 'BigBasket', vpa: 'bigbasket@ybl', categoryId: 1, transactionCount: 6, totalSpent: 456000),
    MockMerchant(id: 14, name: 'RAHUL KUMAR', vpa: '9876543210@ybl', categoryId: null, autoCategorize: false, transactionCount: 5, totalSpent: 1200000),
    MockMerchant(id: 15, name: 'SHELL PETROL', displayName: 'Shell', vpa: 'shell@hdfcbank', categoryId: 2, transactionCount: 4, totalSpent: 800000),
    MockMerchant(id: 16, name: 'DMART', displayName: 'DMart', vpa: 'dmart@ybl', categoryId: null, transactionCount: 1, totalSpent: 178900),
    MockMerchant(id: 17, name: 'PRIYA SHARMA', vpa: 'priya@ybl', categoryId: null, autoCategorize: false, transactionCount: 1, totalSpent: 150000),
    MockMerchant(id: 18, name: 'EMPLOYER SALARY', displayName: 'Salary', categoryId: null, transactionCount: 1, totalSpent: 8500000),
  ];

  static final transactions = <MockTransaction>[
    MockTransaction(
      id: 1, direction: 'credit', amount: 8500000,
      merchantName: 'Salary', vpa: null,
      categoryId: null, bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 1, 9, 0),
      rawSms: 'Rs.85,000.00 credited to A/c xx1234 on 01-03-26 by NEFT-EMPLOYER SALARY',
      smsSender: 'HDFCBK', merchantId: 18,
    ),
    MockTransaction(
      id: 2, direction: 'debit', amount: 38700,
      merchantName: 'Swiggy', vpa: 'swiggy@okaxis',
      categoryId: 1, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 2, 20, 15),
      upiRef: '612345678901',
      rawSms: 'Rs.387.00 debited from A/c xx1234 on 02-03-26 to VPA swiggy@okaxis (UPI Ref: 612345678901)',
      smsSender: 'HDFCBK', merchantId: 1,
    ),
    MockTransaction(
      id: 3, direction: 'debit', amount: 23400,
      merchantName: 'Uber', vpa: 'uber@ybl',
      categoryId: 2, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 3, 8, 45),
      rawSms: 'Rs.234.00 debited from A/c xx1234 on 03-03-26 to VPA uber@ybl',
      smsSender: 'HDFCBK', merchantId: 3,
    ),
    MockTransaction(
      id: 4, direction: 'debit', amount: 287600,
      merchantName: 'Shell', vpa: 'shell@hdfcbank',
      categoryId: 2, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 3, 18, 30),
      rawSms: 'Rs.2,876.00 debited from A/c xx1234 on 03-03-26 to VPA shell@hdfcbank',
      smsSender: 'HDFCBK', merchantId: 15,
    ),
    MockTransaction(
      id: 5, direction: 'debit', amount: 123400,
      merchantName: 'BigBasket', vpa: 'bigbasket@ybl',
      categoryId: 1, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 5, 11, 20),
      rawSms: 'Rs.1,234.00 debited from A/c xx1234 on 05-03-26 to VPA bigbasket@ybl',
      smsSender: 'HDFCBK', merchantId: 13,
    ),
    MockTransaction(
      id: 6, direction: 'debit', amount: 56000,
      merchantName: 'Apollo Pharmacy', vpa: 'apollopharmacy@ybl',
      categoryId: 6, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 5, 16, 10),
      rawSms: 'Rs.560.00 debited from A/c xx1234 on 05-03-26 to VPA apollopharmacy@ybl',
      smsSender: 'HDFCBK', merchantId: 11,
    ),
    MockTransaction(
      id: 7, direction: 'debit', amount: 56000,
      merchantName: 'Zomato', vpa: 'zomato@hdfcbank',
      categoryId: 1, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 6, 13, 30),
      rawSms: 'Rs.560.00 debited from A/c xx1234 on 06-03-26 to VPA zomato@hdfcbank',
      smsSender: 'HDFCBK', merchantId: 2,
    ),
    MockTransaction(
      id: 8, direction: 'debit', amount: 89000,
      merchantName: 'Unknown Merchant', vpa: null,
      categoryId: null, bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 6, 17, 0),
      rawSms: 'Rs.890.00 debited from A/c xx1234 on 06-03-26 at POS MERCHANT',
      smsSender: 'HDFCBK', merchantId: null,
    ),
    MockTransaction(
      id: 9, direction: 'debit', amount: 299900,
      merchantName: 'Amazon', vpa: 'amazon@apl',
      categoryId: 3, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 7, 22, 15),
      rawSms: 'Rs.2,999.00 debited from A/c xx1234 on 07-03-26 to VPA amazon@apl',
      smsSender: 'HDFCBK', merchantId: 5,
    ),
    MockTransaction(
      id: 35, direction: 'debit', amount: 178900,
      merchantName: 'DMart', vpa: 'dmart@ybl',
      categoryId: null, bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 7, 11, 0),
      rawSms: 'Rs.1,789.00 debited from A/c xx1234 on 07-03-26 to VPA dmart@ybl',
      smsSender: 'HDFCBK', merchantId: 16,
    ),
    MockTransaction(
      id: 10, direction: 'debit', amount: 300000,
      merchantName: 'Rahul Kumar', vpa: '9876543210@ybl',
      categoryId: null, bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 8, 10, 0), isP2p: true,
      rawSms: 'Rs.3,000.00 debited from A/c xx1234 on 08-03-26 to VPA 9876543210@ybl',
      smsSender: 'HDFCBK', merchantId: 14,
    ),
    MockTransaction(
      id: 11, direction: 'debit', amount: 44500,
      merchantName: 'Ola', vpa: 'olacabs@paytm',
      categoryId: 2, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 8, 19, 45),
      rawSms: 'Rs.445.00 debited from A/c xx1234 on 08-03-26 to VPA olacabs@paytm',
      smsSender: 'HDFCBK', merchantId: 4,
    ),
    MockTransaction(
      id: 12, direction: 'debit', amount: 44500,
      merchantName: 'Swiggy', vpa: 'swiggy@okaxis',
      categoryId: 1, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 9, 21, 0),
      rawSms: 'Rs.445.00 debited from A/c xx1234 on 09-03-26 to VPA swiggy@okaxis',
      smsSender: 'HDFCBK', merchantId: 1,
    ),
    MockTransaction(
      id: 13, direction: 'debit', amount: 31200,
      merchantName: 'Ola', vpa: 'olacabs@paytm',
      categoryId: 2, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 10, 7, 30),
      rawSms: 'Rs.312.00 debited from A/c xx1234 on 10-03-26 to VPA olacabs@paytm',
      smsSender: 'HDFCBK', merchantId: 4,
    ),
    MockTransaction(
      id: 14, direction: 'debit', amount: 120000,
      merchantName: 'Unknown Merchant', vpa: null,
      categoryId: null, bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 10, 14, 0),
      rawSms: 'Rs.1,200.00 debited from A/c xx1234 on 10-03-26 at POS MERCHANT',
      smsSender: 'HDFCBK', merchantId: null,
    ),
    MockTransaction(
      id: 15, direction: 'debit', amount: 64900,
      merchantName: 'Netflix', vpa: 'netflix@okaxis',
      categoryId: 9, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 11, 0, 5),
      rawSms: 'Rs.649.00 debited from A/c xx1234 on 11-03-26 to VPA netflix@okaxis',
      smsSender: 'HDFCBK', merchantId: 9,
    ),
    MockTransaction(
      id: 16, direction: 'debit', amount: 18900,
      merchantName: 'Uber', vpa: 'uber@ybl',
      categoryId: 2, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 12, 9, 15),
      rawSms: 'Rs.189.00 debited from A/c xx1234 on 12-03-26 to VPA uber@ybl',
      smsSender: 'HDFCBK', merchantId: 3,
    ),
    MockTransaction(
      id: 17, direction: 'debit', amount: 349900,
      merchantName: 'Flipkart', vpa: 'flipkart@axl',
      categoryId: 3, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 12, 15, 30),
      rawSms: 'Rs.3,499.00 debited from A/c xx1234 on 12-03-26 to VPA flipkart@axl',
      smsSender: 'HDFCBK', merchantId: 6,
    ),
    MockTransaction(
      id: 18, direction: 'debit', amount: 42300,
      merchantName: 'Zomato', vpa: 'zomato@hdfcbank',
      categoryId: 1, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 13, 20, 45),
      rawSms: 'Rs.423.00 debited from A/c xx1234 on 13-03-26 to VPA zomato@hdfcbank',
      smsSender: 'HDFCBK', merchantId: 2,
    ),
    MockTransaction(
      id: 19, direction: 'debit', amount: 29900,
      merchantName: 'Jio Recharge', vpa: 'jio@hdfcbank',
      categoryId: 4, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 14, 10, 0),
      rawSms: 'Rs.299.00 debited from A/c xx1234 on 14-03-26 to VPA jio@hdfcbank',
      smsSender: 'HDFCBK', merchantId: 7,
    ),
    MockTransaction(
      id: 20, direction: 'debit', amount: 11900,
      merchantName: 'Spotify', vpa: 'spotify@ybl',
      categoryId: 9, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 14, 0, 1),
      rawSms: 'Rs.119.00 debited from A/c xx1234 on 14-03-26 to VPA spotify@ybl',
      smsSender: 'HDFCBK', merchantId: 10,
    ),
    MockTransaction(
      id: 21, direction: 'debit', amount: 78000,
      merchantName: 'PVR Cinemas', vpa: 'pvr@okaxis',
      categoryId: 5, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 15, 18, 0),
      rawSms: 'Rs.780.00 debited from A/c xx1234 on 15-03-26 to VPA pvr@okaxis',
      smsSender: 'HDFCBK', merchantId: 12,
    ),
    MockTransaction(
      id: 22, direction: 'debit', amount: 26700,
      merchantName: 'Uber', vpa: 'uber@ybl',
      categoryId: 2, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 15, 22, 30),
      rawSms: 'Rs.267.00 debited from A/c xx1234 on 15-03-26 to VPA uber@ybl',
      smsSender: 'HDFCBK', merchantId: 3,
    ),
    MockTransaction(
      id: 23, direction: 'debit', amount: 51200,
      merchantName: 'Swiggy', vpa: 'swiggy@okaxis',
      categoryId: 1, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 16, 13, 0),
      rawSms: 'Rs.512.00 debited from A/c xx1234 on 16-03-26 to VPA swiggy@okaxis',
      smsSender: 'HDFCBK', merchantId: 1,
    ),
    MockTransaction(
      id: 24, direction: 'debit', amount: 29000,
      merchantName: 'Swiggy', vpa: 'swiggy@okaxis',
      categoryId: 1, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 16, 21, 0),
      rawSms: 'Rs.290.00 debited from A/c xx1234 on 16-03-26 to VPA swiggy@okaxis',
      smsSender: 'HDFCBK', merchantId: 1,
    ),
    MockTransaction(
      id: 25, direction: 'debit', amount: 187600,
      merchantName: 'BESCOM', vpa: 'bescom@ybl',
      categoryId: 4, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 17, 10, 30),
      rawSms: 'Rs.1,876.00 debited from A/c xx1234 on 17-03-26 to VPA bescom@ybl',
      smsSender: 'HDFCBK', merchantId: 8,
    ),
    MockTransaction(
      id: 26, direction: 'debit', amount: 149900,
      merchantName: 'Amazon', vpa: 'amazon@apl',
      categoryId: 3, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 17, 23, 15),
      rawSms: 'Rs.1,499.00 debited from A/c xx1234 on 17-03-26 to VPA amazon@apl',
      smsSender: 'HDFCBK', merchantId: 5,
    ),
    MockTransaction(
      id: 27, direction: 'debit', amount: 500000,
      merchantName: 'Rahul Kumar', vpa: '9876543210@ybl',
      categoryId: null, bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 18, 11, 0), isP2p: true,
      rawSms: 'Rs.5,000.00 debited from A/c xx1234 on 18-03-26 to VPA 9876543210@ybl',
      smsSender: 'HDFCBK', merchantId: 14,
    ),
    MockTransaction(
      id: 28, direction: 'debit', amount: 98700,
      merchantName: 'BigBasket', vpa: 'bigbasket@ybl',
      categoryId: 1, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 18, 16, 45),
      rawSms: 'Rs.987.00 debited from A/c xx1234 on 18-03-26 to VPA bigbasket@ybl',
      smsSender: 'HDFCBK', merchantId: 13,
    ),
    MockTransaction(
      id: 29, direction: 'debit', amount: 45600,
      merchantName: 'Swiggy', vpa: 'swiggy@okaxis',
      categoryId: 1, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 19, 13, 24),
      rawSms: 'Rs.456.00 debited from A/c xx1234 on 19-03-26 to VPA swiggy@okaxis',
      smsSender: 'HDFCBK', merchantId: 1,
    ),
    MockTransaction(
      id: 30, direction: 'debit', amount: 34500,
      merchantName: 'Uber', vpa: 'uber@ybl',
      categoryId: 2, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 19, 9, 0),
      rawSms: 'Rs.345.00 debited from A/c xx1234 on 19-03-26 to VPA uber@ybl',
      smsSender: 'HDFCBK', merchantId: 3,
    ),
    MockTransaction(
      id: 31, direction: 'debit', amount: 38900,
      merchantName: 'Zomato', vpa: 'zomato@hdfcbank',
      categoryId: 1, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 19, 20, 0),
      rawSms: 'Rs.389.00 debited from A/c xx1234 on 19-03-26 to VPA zomato@hdfcbank',
      smsSender: 'HDFCBK', merchantId: 2,
    ),
    MockTransaction(
      id: 32, direction: 'credit', amount: 150000,
      merchantName: 'Priya Sharma', vpa: 'priya@ybl',
      categoryId: null, bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 19, 15, 30), isP2p: true,
      rawSms: 'Rs.1,500.00 credited to A/c xx1234 on 19-03-26 by VPA priya@ybl',
      smsSender: 'HDFCBK', merchantId: 17,
    ),
    MockTransaction(
      id: 33, direction: 'debit', amount: 67800,
      merchantName: 'Zomato', vpa: 'zomato@hdfcbank',
      categoryId: 1, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 19, 21, 30),
      rawSms: 'Rs.678.00 debited from A/c xx1234 on 19-03-26 to VPA zomato@hdfcbank',
      smsSender: 'HDFCBK', merchantId: 2,
    ),
    MockTransaction(
      id: 34, direction: 'debit', amount: 245600,
      merchantName: 'Shell', vpa: 'shell@hdfcbank',
      categoryId: 2, categorySource: 'auto_vpa',
      bank: 'HDFC Bank', accountLast4: '1234',
      date: DateTime(2026, 3, 4, 17, 0),
      rawSms: 'Rs.2,456.00 debited from A/c xx1234 on 04-03-26 to VPA shell@hdfcbank',
      smsSender: 'HDFCBK', merchantId: 15,
    ),
  ];

  static MockCategory? categoryById(int? id) {
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  static MockMerchant? merchantById(int? id) {
    if (id == null) return null;
    for (final m in merchants) {
      if (m.id == id) return m;
    }
    return null;
  }

  static List<MockTransaction> transactionsForMonth(int year, int month) {
    return transactions
        .where((t) => t.date.year == year && t.date.month == month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static int totalSpentForMonth(int year, int month) {
    return transactionsForMonth(year, month)
        .where((t) => t.direction == 'debit' && !t.isP2p)
        .fold(0, (sum, t) => sum + t.amount);
  }

  static int totalReceivedForMonth(int year, int month) {
    return transactionsForMonth(year, month)
        .where((t) => t.direction == 'credit' && !t.isP2p)
        .fold(0, (sum, t) => sum + t.amount);
  }

  static int totalP2pForMonth(int year, int month) {
    return transactionsForMonth(year, month)
        .where((t) => t.isP2p)
        .fold(0, (sum, t) => sum + t.amount);
  }

  static int transactionCountForMonth(int year, int month) {
    return transactionsForMonth(year, month).length;
  }

  static int debitCountForMonth(int year, int month) {
    return transactionsForMonth(year, month)
        .where((t) => t.direction == 'debit')
        .length;
  }

  static int creditCountForMonth(int year, int month) {
    return transactionsForMonth(year, month)
        .where((t) => t.direction == 'credit')
        .length;
  }

  static List<({MockCategory category, int total})> spendByCategoryForMonth(
      int year, int month) {
    final txns = transactionsForMonth(year, month)
        .where((t) => t.direction == 'debit' && !t.isP2p && t.categoryId != null);
    final map = <int, int>{};
    for (final t in txns) {
      map.update(t.categoryId!, (v) => v + t.amount, ifAbsent: () => t.amount);
    }
    final result = map.entries
        .map((e) => (category: categoryById(e.key)!, total: e.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return result;
  }

  static List<({MockMerchant merchant, int total, int count})>
      topMerchantsForMonth(int year, int month, {int limit = 5}) {
    final txns = transactionsForMonth(year, month)
        .where((t) => t.direction == 'debit' && !t.isP2p && t.merchantId != null);
    final totals = <int, int>{};
    final counts = <int, int>{};
    for (final t in txns) {
      totals.update(t.merchantId!, (v) => v + t.amount,
          ifAbsent: () => t.amount);
      counts.update(t.merchantId!, (v) => v + 1, ifAbsent: () => 1);
    }
    final result = totals.entries
        .map((e) => (
              merchant: merchantById(e.key)!,
              total: e.value,
              count: counts[e.key]!
            ))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return result.take(limit).toList();
  }

  static ({int p2p, int incomplete, int merchants}) get reviewCounts {
    final p2p =
        transactions.where((t) => t.isP2p && t.categoryId == null).length;
    final incomplete =
        transactions.where((t) => t.merchantId == null).length;
    final uncatMerchants =
        merchants.where((m) => m.categoryId == null).length;
    return (p2p: p2p, incomplete: incomplete, merchants: uncatMerchants);
  }

  static int get totalReviewCount {
    final counts = reviewCounts;
    return counts.p2p + counts.incomplete + counts.merchants;
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static const _fullMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static String dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == DateTime(today.year, today.month, today.day - 1)) {
      return 'Yesterday';
    }
    return '${date.day} ${_months[date.month - 1]}';
  }

  static String monthLabel(DateTime date) {
    return '${_fullMonths[date.month - 1]} ${date.year}';
  }

  static String shortDate(DateTime date) {
    return '${date.day} ${_months[date.month - 1]}';
  }

  static Map<int, int> dailySpendForMonth(int year, int month) {
    final txns = transactionsForMonth(year, month)
        .where((t) => t.direction == 'debit');
    final daily = <int, int>{};
    for (final t in txns) {
      daily.update(t.date.day, (v) => v + t.amount, ifAbsent: () => t.amount);
    }
    return daily;
  }

  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  static final _today = DateTime(2026, 3, 19);

  static List<MockTransaction> transactionsForToday() {
    return transactions
        .where((t) =>
            t.date.year == _today.year &&
            t.date.month == _today.month &&
            t.date.day == _today.day)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static int totalSpentToday() {
    return transactionsForToday()
        .where((t) => t.direction == 'debit')
        .fold(0, (sum, t) => sum + t.amount);
  }

  static int transactionCountToday() {
    return transactionsForToday().length;
  }

  static List<MockTransaction> triageTransactions() {
    return transactions
        .where((t) => t.categoryId == null)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static const int monthlyBudget = 5000000;

  static const categoryBudgets = <MockCategoryBudget>[
    MockCategoryBudget(categoryId: 1, budgetAmount: 1200000),
    MockCategoryBudget(categoryId: 2, budgetAmount: 800000),
    MockCategoryBudget(categoryId: 3, budgetAmount: 1000000),
    MockCategoryBudget(categoryId: 4, budgetAmount: 500000),
    MockCategoryBudget(categoryId: 5, budgetAmount: 300000),
    MockCategoryBudget(categoryId: 9, budgetAmount: 200000),
  ];

  static int spentForCategory(int categoryId, int year, int month) {
    return transactionsForMonth(year, month)
        .where((t) =>
            t.direction == 'debit' &&
            t.categoryId == categoryId)
        .fold(0, (sum, t) => sum + t.amount);
  }

  static final savingsGoals = <MockSavingsGoal>[
    MockSavingsGoal(
      id: 1,
      name: 'Emergency Fund',
      icon: '\u{1F6E1}',
      targetAmount: 10000000,
      savedAmount: 6500000,
      deadline: DateTime(2026, 9, 30),
      allocations: [
        MockGoalAllocation(date: DateTime(2026, 1, 5), amount: 2000000, note: 'January savings'),
        MockGoalAllocation(date: DateTime(2026, 2, 3), amount: 2000000, note: 'February savings'),
        MockGoalAllocation(date: DateTime(2026, 3, 2), amount: 1500000, note: 'March savings'),
        MockGoalAllocation(date: DateTime(2026, 3, 15), amount: 1000000),
      ],
    ),
    MockSavingsGoal(
      id: 2,
      name: 'Goa Trip',
      icon: '\u{1F3D6}',
      targetAmount: 3000000,
      savedAmount: 1200000,
      deadline: DateTime(2026, 6, 15),
      allocations: [
        MockGoalAllocation(date: DateTime(2026, 2, 10), amount: 500000),
        MockGoalAllocation(date: DateTime(2026, 3, 1), amount: 400000),
        MockGoalAllocation(date: DateTime(2026, 3, 12), amount: 300000),
      ],
    ),
    MockSavingsGoal(
      id: 3,
      name: 'New Laptop',
      icon: '\u{1F4BB}',
      targetAmount: 8000000,
      savedAmount: 2000000,
      deadline: DateTime(2026, 12, 31),
      allocations: [
        MockGoalAllocation(date: DateTime(2026, 1, 15), amount: 1000000),
        MockGoalAllocation(date: DateTime(2026, 2, 15), amount: 1000000),
      ],
    ),
  ];

  static Map<String, List<MockTransaction>> groupByDate(
      List<MockTransaction> txns) {
    final grouped = <String, List<MockTransaction>>{};
    for (final tx in txns) {
      final key = dateLabel(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return grouped;
  }

  static List<({DateTime month, int spent, int income})> monthlyTrend() {
    return [
      (month: DateTime(2025, 10), spent: 4200000, income: 8500000),
      (month: DateTime(2025, 11), spent: 4850000, income: 8500000),
      (month: DateTime(2025, 12), spent: 5600000, income: 8700000),
      (month: DateTime(2026, 1), spent: 4100000, income: 8500000),
      (month: DateTime(2026, 2), spent: 3950000, income: 8500000),
      (month: DateTime(2026, 3), spent: totalSpentForMonth(2026, 3), income: totalReceivedForMonth(2026, 3)),
    ];
  }

  static Map<int, int> cumulativeDailySpend(int year, int month) {
    final daily = dailySpendForMonth(year, month);
    final days = daysInMonth(year, month);
    final cumulative = <int, int>{};
    int running = 0;
    for (int d = 1; d <= days; d++) {
      running += daily[d] ?? 0;
      cumulative[d] = running;
    }
    return cumulative;
  }

  static Map<int, int> dayOfWeekTotals(int year, int month) {
    final txns = transactionsForMonth(year, month)
        .where((t) => t.direction == 'debit');
    final totals = <int, int>{};
    for (final t in txns) {
      final dow = t.date.weekday;
      totals.update(dow, (v) => v + t.amount, ifAbsent: () => t.amount);
    }
    return totals;
  }

  static Map<int, int> syntheticDailySpend(int year, int month) {
    if (year == 2026 && month == 3) return dailySpendForMonth(year, month);
    final days = daysInMonth(year, month);
    final trend = monthlyTrend();
    final monthData = trend.where((t) => t.month.year == year && t.month.month == month);
    final totalTarget = monthData.isNotEmpty ? monthData.first.spent : 4000000;
    final rng = math.Random(year * 100 + month);
    final daily = <int, int>{};
    var remaining = totalTarget;
    for (int d = 1; d <= days; d++) {
      if (d == days) {
        daily[d] = remaining.clamp(0, remaining);
      } else {
        final avg = remaining ~/ (days - d + 1);
        final variance = (avg * 0.5).toInt();
        final spend = variance > 0
            ? (avg + rng.nextInt(variance * 2) - variance).clamp(0, remaining)
            : avg.clamp(0, remaining);
        daily[d] = spend;
        remaining -= spend;
      }
    }
    return daily;
  }

  static Map<int, int> syntheticCumulativeDailySpend(int year, int month) {
    final daily = syntheticDailySpend(year, month);
    final days = daysInMonth(year, month);
    final cumulative = <int, int>{};
    int running = 0;
    for (int d = 1; d <= days; d++) {
      running += daily[d] ?? 0;
      cumulative[d] = running;
    }
    return cumulative;
  }
}
