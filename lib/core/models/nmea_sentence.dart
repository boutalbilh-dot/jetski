class NmeaSentence {
  final String talker;
  final String type;
  final List<String> fields;

  const NmeaSentence({
    required this.talker,
    required this.type,
    required this.fields,
  });

  static NmeaSentence? tryParse(String raw) {
    final line = raw.trim();
    if (line.isEmpty || !line.startsWith(r'$')) return null;
    final star = line.indexOf('*');
    if (star == -1 || star + 3 > line.length) return null;

    final body = line.substring(1, star);
    final checksumHex = line.substring(star + 1, star + 3).toUpperCase();
    final expected = int.tryParse(checksumHex, radix: 16);
    if (expected == null) return null;

    int xor = 0;
    for (final c in body.codeUnits) {
      xor ^= c;
    }
    if (xor != expected) return null;

    final parts = body.split(',');
    if (parts.isEmpty || parts.first.length < 5) return null;
    final header = parts.first;
    final talker = header.substring(0, 2);
    final type = header.substring(2);
    final fields = parts.sublist(1);
    return NmeaSentence(talker: talker, type: type, fields: fields);
  }
}
