import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';
import 'word_dao.dart';
import 'progress_dao.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Words, WordProgress, Sessions], daos: [WordDao, ProgressDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor dùng riêng cho unit test — inject executor in-memory
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(words, words.definitionNative);
      }
    },
  );

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'vocab_ai.sqlite'));

      // Lần đầu cài app: copy pre-built seed DB từ asset thay vì tạo DB trống.
      // Seed DB đã chứa sẵn ~47k từ English (en-US + en-GB), schema version 2.
      if (!await file.exists()) {
        final byteData = await rootBundle.load('assets/databases/en_seed.db');
        await file.writeAsBytes(
          byteData.buffer.asUint8List(
              byteData.offsetInBytes, byteData.lengthInBytes),
        );
      }

      return NativeDatabase.createInBackground(file);
    });
  }
}
