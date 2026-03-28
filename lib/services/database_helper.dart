import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TemperatureRecord {
  final int? id;
  final DateTime dateTime;
  final double productSize;
  final double masterTemp;
  final double workTemp;
  final double tempDiff;
  final double correctionValue;
  final bool isAbnormal;

  const TemperatureRecord({
    this.id,
    required this.dateTime,
    required this.productSize,
    required this.masterTemp,
    required this.workTemp,
    required this.tempDiff,
    required this.correctionValue,
    required this.isAbnormal,
  });

  TemperatureRecord copyWith({
    int? id,
    DateTime? dateTime,
    double? productSize,
    double? masterTemp,
    double? workTemp,
    double? tempDiff,
    double? correctionValue,
    bool? isAbnormal,
  }) =>
      TemperatureRecord(
        id: id ?? this.id,
        dateTime: dateTime ?? this.dateTime,
        productSize: productSize ?? this.productSize,
        masterTemp: masterTemp ?? this.masterTemp,
        workTemp: workTemp ?? this.workTemp,
        tempDiff: tempDiff ?? this.tempDiff,
        correctionValue: correctionValue ?? this.correctionValue,
        isAbnormal: isAbnormal ?? this.isAbnormal,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'dateTime': dateTime.toIso8601String(),
        'productSize': productSize,
        'masterTemp': masterTemp,
        'workTemp': workTemp,
        'tempDiff': tempDiff,
        'correctionValue': correctionValue,
        'isAbnormal': isAbnormal ? 1 : 0,
      };

  factory TemperatureRecord.fromMap(Map<String, dynamic> map) =>
      TemperatureRecord(
        id: map['id'] as int?,
        dateTime: DateTime.parse(map['dateTime'] as String),
        productSize: (map['productSize'] as num).toDouble(),
        masterTemp: (map['masterTemp'] as num).toDouble(),
        workTemp: (map['workTemp'] as num).toDouble(),
        tempDiff: (map['tempDiff'] as num).toDouble(),
        correctionValue: (map['correctionValue'] as num).toDouble(),
        isAbnormal: (map['isAbnormal'] as int) == 1,
      );
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    _database ??= await _initDB('temperature_records.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dateTime TEXT NOT NULL,
        productSize REAL NOT NULL,
        masterTemp REAL NOT NULL,
        workTemp REAL NOT NULL,
        tempDiff REAL NOT NULL,
        correctionValue REAL NOT NULL,
        isAbnormal INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insert(TemperatureRecord record) async {
    final db = await database;
    return db.insert('records', record.toMap());
  }

  Future<List<TemperatureRecord>> getAll() async {
    final db = await database;
    final maps = await db.query('records', orderBy: 'dateTime DESC');
    return maps.map(TemperatureRecord.fromMap).toList();
  }

  Future<int> update(TemperatureRecord record) async {
    final db = await database;
    return db.update('records', record.toMap(),
        where: 'id = ?', whereArgs: [record.id]);
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAll() async {
    final db = await database;
    return db.delete('records');
  }

  Future<void> deleteByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final placeholders = ids.map((_) => '?').join(',');
    await db.delete('records', where: 'id IN ($placeholders)', whereArgs: ids);
  }
}
