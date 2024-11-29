import 'package:animal_sounds_flutter/models/achievement.dart';
import 'package:animal_sounds_flutter/providers/quiz_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('achievements'.tr()),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: quizProvider.achievements.length,
            itemBuilder: (context, index) {
              final achievement = quizProvider.achievements[index];
              return _buildAchievementCard(achievement);
            },
          );
        },
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            achievement.iconPath,
            height: 64,
            color: achievement.isUnlocked ? null : Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: achievement.isUnlocked ? Colors.black : Colors.grey,
            ),
          ),
          Text(
            achievement.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: achievement.isUnlocked ? Colors.black54 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
