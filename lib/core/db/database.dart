import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';
import 'word_dao.dart';
import 'progress_dao.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Words, WordProgress, Sessions], daos: [WordDao, ProgressDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'vocab_ai.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
