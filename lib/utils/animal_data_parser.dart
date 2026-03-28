/// Utility to extract comparable numeric values from translated animal data
/// strings such as "150-250 kg", "1.7-2.5 meters", "10-14 years", etc.
///
/// When a range is found (e.g. "150-250") the average of the two extremes is
/// returned. When the string contains multiple lines (separated by \n) only
/// the first line is parsed — this avoids mixing unrelated sub-species data.
class AnimalDataParser {
  AnimalDataParser._();

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
    final line = _firstLine(raw);
    final lower = line.toLowerCase();

    // Detect unit: prefer kg; fall back to grams.
    final isGram =
        lower.contains('gram') || lower.contains('g') && !lower.contains('kg');

    final numbers = _extractNumbers(line);
    if (numbers.isEmpty) return 0;

    double value;
    if (numbers.length >= 2) {
      value = (numbers[0] + numbers[1]) / 2;
    } else {
      value = numbers[0];
    }

    // Convert grams to kg.
    if (isGram && value < 100) {
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
    final line = _firstLine(raw);
    final lower = line.toLowerCase();

    final numbers = _extractNumbers(line);
    if (numbers.isEmpty) return 0;

    double value;
    if (numbers.length >= 2) {
      value = (numbers[0] + numbers[1]) / 2;
    } else {
      value = numbers[0];
    }

    // Determine the unit.
    final isMeter = lower.contains('metre') || lower.contains('meter');
    if (isMeter || value < 50) {
      // Numbers < 50 with no explicit "cm" likely represent metres.
      if (!lower.contains('cm')) {
        value = value * 100; // metres -> cm
      }
    }

    return value;
  }

  /// Extracts a lifespan value in **years** from strings like:
  /// - "10-14 years in the wild"
  /// - "Worker bees: 4-6 weeks\nQueen bee: 3-4 years"
  /// - "50-100 years"
  ///
  /// Returns 0 when no usable number is found.
  static double parseLifespan(String raw) {
    final line = _firstLine(raw);
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

  /// Takes only the first line of a potentially multi-line string.
  static String _firstLine(String raw) {
    final idx = raw.indexOf('\n');
    return idx >= 0 ? raw.substring(0, idx) : raw;
  }

  /// Extracts all numeric values found in [text], stripping comma separators.
  static List<double> _extractNumbers(String text) {
    return _numberPattern
        .allMatches(text)
        .map((m) => double.tryParse(m.group(0)!.replaceAll(',', '')) ?? 0)
        .where((v) => v > 0)
        .toList();
  }
}
