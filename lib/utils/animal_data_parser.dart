/// Utility to extract comparable numeric values from translated animal data
/// strings such as "150-250 kg", "1.7-2.5 meters", "10-14 years", etc.
///
/// When a range is found (e.g. "150-250") the average of the two extremes is
/// returned. When the string contains multiple lines (separated by \n) only
/// the first line is parsed — this avoids mixing unrelated sub-species data.
class AnimalDataParser {
  AnimalDataParser._();

  // Unit words in the app's eight languages. "g" and "m" must follow a digit
  // or stand alone, so the "g" in "Length" or the "m" in "cm" do not count.
  static final _kilogram = RegExp(r'kg|кг|किलो|كغ|كجم');
  static final _gram = RegExp(r'gram|(\d|\s)(g|gr|г)(\s|\.|$|,)|ग्राम|غرام|грамм');
  static final _centimetre = RegExp(r'cm|см|सेमी|سم');
  static final _metre =
      RegExp(r'met(er|re|ro)|метр|मीटर|متر|أمتار|(\d|\s)(m|м)(\s|\.|$|,)');

  // Matches integers and decimals, including comma-separated thousands.
  static final _numberPattern = RegExp(r'[\d][,\d]*\.?\d*');

  /// Extracts a weight value in **kg** from strings like:
  /// - "150-250 kg"
  /// - "Males: 150-250 kg, Females: 120-182 kg"
  /// - "0.1 gram"
  /// - "4,000-7,000 kg"
  ///
  /// Returns 0 when no usable number is found.
  static double parseWeight(String raw) {
    final line = _firstLine(_western(raw));
    final lower = line.toLowerCase();

    // Detect unit: prefer kg; fall back to grams.
    final isGram = !_kilogram.hasMatch(lower) && _gram.hasMatch(lower);

    final numbers = _extractNumbers(line);
    if (numbers.isEmpty) return 0;

    double value;
    if (numbers.length >= 2) {
      value = (numbers[0] + numbers[1]) / 2;
    } else {
      value = numbers[0];
    }

    // Convert grams to kg.
    if (isGram) {
      value = value / 1000;
    }

    return value;
  }

  /// Extracts a size/height value in **cm** from strings like:
  /// - "Males: 1.7-2.5 meters in length"
  /// - "Height: 120-150 cm"
  /// - "1-2.5 cm"
  /// - "Height: 4.3-5.7 metres"
  ///
  /// Returns 0 when no usable number is found.
  static double parseSize(String raw) {
    final line = _firstLine(_western(raw));
    final lower = line.toLowerCase();

    final numbers = _extractNumbers(line);
    if (numbers.isEmpty) return 0;

    double value;
    if (numbers.length >= 2) {
      value = (numbers[0] + numbers[1]) / 2;
    } else {
      value = numbers[0];
    }

    // Determine the unit. Without one, numbers below 50 are taken as metres.
    if (_centimetre.hasMatch(lower)) return value;
    if (_metre.hasMatch(lower) || value < 50) value = value * 100;

    return value;
  }

  /// Extracts a lifespan value in **years** from strings like:
  /// - "10-14 years in the wild"
  /// - "Worker bees: 4-6 weeks\nQueen bee: 3-4 years"
  /// - "50-100 years"
  ///
  /// Returns 0 when no usable number is found.
  static double parseLifespan(String raw) {
    final line = _firstLine(_western(raw));
    final lower = line.toLowerCase();

    final numbers = _extractNumbers(line);
    if (numbers.isEmpty) return 0;

    double value;
    if (numbers.length >= 2) {
      value = (numbers[0] + numbers[1]) / 2;
    } else {
      value = numbers[0];
    }

    // Convert weeks to years if the unit is weeks.
    if (lower.contains('week') || lower.contains('hafta')) {
      value = value / 52;
    }

    return value;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Rewrites Arabic and Hindi digits and the Arabic decimal and thousands
  /// marks as 0-9, "." and ",", so texts written with them can be read.
  static String _western(String raw) {
    final out = StringBuffer();
    for (final rune in raw.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        out.writeCharCode(0x30 + rune - 0x0660);
      } else if (rune >= 0x0966 && rune <= 0x096F) {
        out.writeCharCode(0x30 + rune - 0x0966);
      } else if (rune == 0x066B) {
        out.write('.');
      } else if (rune == 0x066C) {
        out.write(',');
      } else {
        out.writeCharCode(rune);
      }
    }
    return out.toString();
  }

  /// Takes the first line that carries a number, so a heading such as
  /// "Varies by breed:" above the figures is skipped.
  static String _firstLine(String raw) {
    final lines = raw.split('\n');
    return lines.firstWhere(
      (line) => _numberPattern.hasMatch(line),
      orElse: () => lines.first,
    );
  }

  // A comma followed by one or two digits is a decimal comma ("4,3 m"); a
  // comma followed by three digits separates thousands ("4,000 kg").
  static final _decimalComma = RegExp(r'(\d),(\d{1,2})(?!\d)');

  /// Extracts all numeric values found in [text].
  static List<double> _extractNumbers(String text) {
    final normalised = text.replaceAllMapped(
      _decimalComma,
      (m) => '${m.group(1)}.${m.group(2)}',
    );
    return _numberPattern
        .allMatches(normalised)
        .map((m) => double.tryParse(m.group(0)!.replaceAll(',', '')) ?? 0)
        .where((v) => v > 0)
        .toList();
  }
}
