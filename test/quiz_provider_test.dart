import 'package:animal_sounds_flutter/models/quiz_score.dart';
import 'package:animal_sounds_flutter/providers/quiz_provider.dart';
import 'package:animal_sounds_flutter/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saving a quiz score logs quiz_completed with the correct answers', () async {
    SharedPreferences.setMockInitialValues({});
    final events = <(String, Map<String, Object>?)>[];
    AnalyticsService().setBackend((name, params) async => events.add((name, params)));
    addTearDown(() => AnalyticsService().setBackend(null));
    final provider = QuizProvider();
    await Future<void>.delayed(Duration.zero);

    await provider.saveScore(QuizScore(
      correctAnswers: 4,
      totalQuestions: 5,
      dateTime: DateTime(2026, 10, 30),
    ));

    final event = events.where((e) => e.$1 == 'quiz_completed');
    expect(event, hasLength(1));
    expect(event.single.$2, {'score': 4});
  });
}
