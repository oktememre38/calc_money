/// Kayıt tipi: gelir (0) veya gider (1).
enum RecordType { gelir, gider }

extension RecordTypeX on RecordType {
  int get toDb => this == RecordType.gelir ? 0 : 1;

  String get label => this == RecordType.gelir ? 'Gelir' : 'Gider';
}

RecordType recordTypeFromDb(int v) =>
    v == 0 ? RecordType.gelir : RecordType.gider;
