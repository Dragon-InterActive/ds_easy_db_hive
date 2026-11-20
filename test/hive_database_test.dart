import 'dart:io';

import 'package:ds_easy_db/ds_easy_db.dart';
import 'package:ds_easy_db_hive/ds_easy_db_hive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory directory;
  late HiveDatabase db;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('ds_easy_db_hive_test');
    db = HiveDatabase(path: directory.path);
    await db.init();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await directory.delete(recursive: true);
  });

  test('nested maps come back as Map<String, dynamic>', () async {
    await db.set('users', 'u1', {
      'address': {
        'city': 'Berlin',
        'geo': {'lat': 1.0}
      },
      'tags': [
        {'name': 'a'},
      ],
    });

    final user = (await db.get('users', 'u1'))!;
    expect(user['address'], isA<Map<String, dynamic>>());
    expect(user['address']['geo'], isA<Map<String, dynamic>>());
    expect((user['tags'] as List).single, isA<Map<String, dynamic>>());

    final fromQuery = (await db.query('users')).single;
    expect(fromQuery['address'], isA<Map<String, dynamic>>());
  });

  test('query adds the document id and filters', () async {
    await db.set('users', 'u1', {'age': 30});
    await db.set('users', 'u2', {'age': 40});

    expect(await db.query('users', where: {'age': 30}), [
      {'id': 'u1', 'age': 30},
    ]);
  });

  test('a document with its own "id" field keeps it', () async {
    await db.set('users', 'u1', {'id': 'custom'});

    expect((await db.query('users')).single['id'], 'custom');
  });

  test('foreign non-map values in the box are skipped, not thrown on',
      () async {
    await db.set('users', 'u1', {'age': 30});
    await Hive.box('users').put('stray', 'not a document');

    expect(await db.get('users', 'stray'), isNull);
    expect(await db.get('users', 'stray', defaultValue: {'x': 1}), {'x': 1});
    expect((await db.query('users')).map((d) => d['id']), ['u1']);
    expect(await db.existsWhere('users', where: {'age': 30}), isTrue);
    expect((await db.getAll('users'))!.keys, ['u1']);
  });

  test('update merges into nested-map documents', () async {
    await db.set('users', 'u1', {
      'address': {'city': 'Berlin'},
    });
    await db.update('users', 'u1', {'name': 'Ann'});

    expect(await db.get('users', 'u1'), {
      'address': {'city': 'Berlin'},
      'name': 'Ann',
    });
  });

  test('getAll returns null for an empty collection', () async {
    expect(await db.getAll('empty'), isNull);
  });

  test('serverTS becomes a DateTime', () async {
    await db.set('users', 'u1', {'at': DatabaseRepository.serverTS});

    expect((await db.get('users', 'u1'))!['at'], isA<DateTime>());
  });
}
