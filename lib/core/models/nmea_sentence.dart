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
    if (line.length < 8 || line.codeUnitAt(0) != 0x24 /* $ */) return null;
    final star = line.indexOf('*');
    if (star == -1 || star + 3 > line.length) return null;

    // XOR the body in place (between '$' and '*') without allocating a
    // substring, then parse the 2-char hex checksum from fixed positions.
    int xor = 0;
    for (int i = 1; i < star; i++) {
      xor ^= line.codeUnitAt(i);
    }
    final expected = int.tryParse(line.substring(star + 1, star + 3), radix: 16);
    if (expected == null || xor != expected) return null;

    // Find the end of the talker+type header — the first comma in the body,
    // or the '*' if the sentence has no fields.
    var firstComma = line.indexOf(',', 1);
    if (firstComma == -1 || firstComma > star) firstComma = star;
    if (firstComma - 1 < 5) return null; // header must be at least 5 chars
    final talker = line.substring(1, 3);
    final type = line.substring(3, firstComma);
    final fields = firstComma == star
        ? const <String>[]
        : line.substring(firstComma + 1, star).split(',');
    return NmeaSentence(talker: talker, type: type, fields: fields);
  }
}
