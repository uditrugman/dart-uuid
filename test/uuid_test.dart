import "package:test/test.dart";
import 'package:uuid/uuid.dart';
import 'package:uuid/uuid_util.dart';

dynamic main() {
  Uuid uuid = new Uuid();
  final int time = 1321644961388;

  group('[Version 1 Tests]', () {
    test('IDs created at same mSec are different', () {
      expect(uuid.v1(options: <String, dynamic>{'mSecs': time}),
          isNot(equals(uuid.v1(options: <String, dynamic>{'mSecs': time}))));
    });

    test('Exception thrown when > 10K ids created in 1 ms', () {
      bool thrown = false;
      try {
        uuid.v1(options: <String, dynamic>{'mSecs': time, 'nSecs': 10000});
      } catch (e) {
        thrown = true;
      }
      expect(thrown, equals(true));
    });

    test('Clock regression by msec increments the clockseq', () {
      String uidt = uuid.v1(options: <String, dynamic>{'mSecs': time});
      String uidtb = uuid.v1(options: <String, dynamic>{'mSecs': time - 1});

      expect(
          (int.parse("0x${uidtb.split('-')[3]}") -
              int.parse("0x${uidt.split('-')[3]}")),
          anyOf(equals(1), equals(-16383)));
    });

    test('Clock regression by nsec increments the clockseq', () {
      String uidt = uuid.v1(options: <String, dynamic>{'mSecs': time, 'nSecs': 10});
      String uidtb = uuid.v1(options: <String, dynamic>{'mSecs': time, 'nSecs': 9});

      expect(
          (int.parse("0x${uidtb.split('-')[3]}") -
              int.parse("0x${uidt.split('-')[3]}")),
          equals(1));
    });

    test('Explicit options produce expected id', () {
      String id = uuid.v1(options: <String, dynamic>{
        'mSecs': 1321651533573,
        'nSecs': 5432,
        'clockSeq': 0x385c,
        'node': [0x61, 0xcd, 0x3c, 0xbb, 0x32, 0x10]
      });

      expect(id, equals('d9428888-f500-11e0-b85c-61cd3cbb3210'));
    });

    test('Ids spanning 1ms boundary are 100ns apart', () {
      String u0 = uuid.v1(options: <String, dynamic>{'mSecs': time, 'nSecs': 9999});
      String u1 = uuid.v1(options: <String, dynamic>{'mSecs': time + 1, 'nSecs': 0});

      String before = u0.split('-')[0], after = u1.split('-')[0];
      int dt = int.parse('0x$after') - int.parse('0x$before');

      expect(dt, equals(1));
    });
  });

  group('[Version 4 Tests]', () {
    test('Check if V4 is consistent using a static seed', () {
      String u0 = uuid.v4(options: <String, dynamic>{
        'rng': UuidUtil.mathRNG,
        'namedArgs': new Map.fromIterables([const Symbol('seed')], [1])
      });
      var u1 = "09a91894-e93f-4141-a3ec-82eb32f2a3ef";
      expect(u0, equals(u1));
    });

    test('Return same output as entered for "random" option', () {
      String u0 = uuid.v4(options: <String, dynamic>{
        'random': [
          0x10,
          0x91,
          0x56,
          0xbe,
          0xc4,
          0xfb,
          0xc1,
          0xea,
          0x71,
          0xb4,
          0xef,
          0xe1,
          0x67,
          0x1c,
          0x58,
          0x36
        ]
      });
      var u1 = "109156be-c4fb-41ea-b1b4-efe1671c5836";
      expect(u0, equals(u1));
    });

    test('Make sure that really fast uuid.v4 doesn\'t produce duplicates', () {
      var list =
          new List.filled(1000, null).map<dynamic>((something) => uuid.v4()).toList();
      var setList = list.toSet();
      expect(list.length, equals(setList.length));
    });
  });

  group('[Version 5 Tests]', () {
    test('Using URL namespace and custom name', () {
      String u0 = uuid.v5(Uuid.namespaceUrl, 'www.google.com');
      String u1 = uuid.v5(Uuid.namespaceUrl, 'www.google.com');

      expect(u0, equals(u1));
    });

    test('Using Random namespace and custom name', () {
      String u0 = uuid.v5(null, 'www.google.com');
      String u1 = uuid.v5(null, 'www.google.com');

      expect(u0, isNot(equals(u1)));
    });
  });

  group('[Parse/Unparse Tests]', () {
    test('Parsing a short/cut-off UUID', () {
      var id = '00112233445566778899aabbccddeeff';
      expect(uuid.unparse(uuid.parse(id.substring(0, 10))),
          equals('00112233-4400-0000-0000-000000000000'));
    });

    test('Parsing a dirty string with a UUID in it', () {
      var id = '00112233445566778899aabbccddeeff';
      expect(uuid.unparse(uuid.parse('(this is the uuid -> $id$id')),
          equals('00112233-4455-6677-8899-aabbccddeeff'));
    });
  });
}
