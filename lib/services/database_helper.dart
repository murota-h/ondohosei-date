import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _key = 'temperature_records';

  DatabaseHelper._init();

  Future<List<TemperatureRecord>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return [];
    final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((m) => TemperatureRecord.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  Future<int> insert(TemperatureRecord record) async {
    final records = await getAll();
    final newId = records.isEmpty
        ? 1
        : records.map((r) => r.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
    records.add(record.copyWith(id: newId));
    await _save(records);
    return newId;
  }

  Future<int> update(TemperatureRecord record) async {
    final records = await getAll();
    final idx = records.indexWhere((r) => r.id == record.id);
    if (idx == -1) return 0;
    records[idx] = record;
    await _save(records);
    return 1;
  }

  Future<int> delete(int id) async {
    final records = await getAll();
    final before = records.length;
    records.removeWhere((r) => r.id == id);
    await _save(records);
    return before - records.length;
  }

  Future<int> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    return 1;
  }

  Future<void> deleteByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    final records = await getAll();
    records.removeWhere((r) => ids.contains(r.id));
    await _save(records);
  }

  Future<void> _save(List<TemperatureRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(records.map((r) => r.toMap()).toList()),
    );
  }
}
