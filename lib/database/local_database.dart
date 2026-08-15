import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import '../models/member.dart';
import '../models/payment.dart';
import '../models/gym_settings.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('surbhi_gym.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      // Use web-specific factory
      var factory = databaseFactoryFfiWeb;
      return await factory.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: _createDB,
          onUpgrade: _upgradeDB,
        ),
      );
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      return await openDatabase(
        path,
        version: 2,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE members (
        id $idType,
        name $textType,
        mobile $textType,
        parentMobile $textNullableType,
        address $textType,
        college $textNullableType,
        shift $textType,
        joiningDate $textType,
        membershipDuration $intType,
        feeAmount $realType,
        totalBilled $realType,
        photoPath $textNullableType
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id $idType,
        memberId $textType,
        amount $realType,
        paymentDate $textType,
        paymentMethod $textType,
        notes $textNullableType,
        FOREIGN KEY (memberId) REFERENCES members (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY,
        gymName $textType,
        ownerName $textType,
        phone $textNullableType,
        address $textNullableType,
        defaultMembershipDuration $intType,
        defaultFee $realType,
        dueSoonAlerts INTEGER NOT NULL,
        overdueAlerts INTEGER NOT NULL,
        isDarkMode INTEGER NOT NULL
      )
    ''');
    
    // Insert default settings
    await db.insert('settings', GymSettings().toMap());
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE members ADD COLUMN totalBilled REAL DEFAULT 0.0');
      await db.execute('UPDATE members SET totalBilled = feeAmount');
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // --- Members CRUD ---
  Future<Member> createMember(Member member) async {
    final db = await instance.database;
    await db.insert('members', member.toMap());
    return member;
  }

  Future<Member?> readMember(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'members',
      columns: null,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Member.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Member>> readAllMembers() async {
    final db = await instance.database;
    final result = await db.query('members', orderBy: 'joiningDate DESC');
    return result.map((json) => Member.fromMap(json)).toList();
  }

  Future<int> updateMember(Member member) async {
    final db = await instance.database;
    return db.update(
      'members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<int> deleteMember(String id) async {
    final db = await instance.database;
    return await db.delete(
      'members',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Payments CRUD ---
  Future<Payment> createPayment(Payment payment) async {
    final db = await instance.database;
    await db.insert('payments', payment.toMap());
    return payment;
  }

  Future<List<Payment>> readPaymentsForMember(String memberId) async {
    final db = await instance.database;
    final result = await db.query(
      'payments',
      where: 'memberId = ?',
      whereArgs: [memberId],
      orderBy: 'paymentDate DESC',
    );
    return result.map((json) => Payment.fromMap(json)).toList();
  }

  Future<List<Payment>> readAllPayments() async {
    final db = await instance.database;
    final result = await db.query('payments', orderBy: 'paymentDate DESC');
    return result.map((json) => Payment.fromMap(json)).toList();
  }

  Future<int> deletePayment(String id) async {
    final db = await instance.database;
    return await db.delete(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Settings CRUD ---
  Future<GymSettings> readSettings() async {
    final db = await instance.database;
    final maps = await db.query('settings', where: 'id = 1');
    if (maps.isNotEmpty) {
      return GymSettings.fromMap(maps.first);
    } else {
      return GymSettings();
    }
  }

  Future<int> updateSettings(GymSettings settings) async {
    final db = await instance.database;
    return db.update(
      'settings',
      settings.toMap(),
      where: 'id = 1',
    );
  }
}

