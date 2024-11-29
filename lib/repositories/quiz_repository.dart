import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:animal_sounds_flutter/models/quiz_question.dart';
import 'package:flutter/material.dart';

class QuizRepository {
  static List<String> _shuffleOptions(
      String correctAnswer, List<String> allOptions) {
    final shuffledOptions = List<String>.from(allOptions)..shuffle();
    final correctIndex = shuffledOptions.indexOf(correctAnswer);
    if (correctIndex == 0) {
      final newIndex = 1 + Random().nextInt(shuffledOptions.length - 1);
      final temp = shuffledOptions[0];
      shuffledOptions[0] = shuffledOptions[newIndex];
      shuffledOptions[newIndex] = temp;
    }
    return shuffledOptions;
  }

  static List<QuizQuestion> getQuestions(BuildContext context) {
    List<QuizQuestion> questions = [
      QuizQuestion(
        id: 1,
        question: "quiz_questions.what_is_animal".tr(),
        correctAnswer: "animal_names.lion".tr(),
        options: _shuffleOptions(
          "animal_names.lion".tr(),
          [
            "animal_names.lion".tr(),
            "animal_names.tiger".tr(),
            "animal_names.cheetah".tr(),
            "animal_names.wolf".tr(),
          ],
        ),
        imagePath: "assets/animal_images/lion.png",
        soundPath: "assets/animal_sounds/lion.mp3",
      ),
      QuizQuestion(
        id: 2,
        question: "quiz_questions.which_animal_shown".tr(),
        correctAnswer: "animal_names.elephant".tr(),
        options: _shuffleOptions(
          "animal_names.elephant".tr(),
          [
            "animal_names.elephant".tr(),
            "animal_names.giraffe".tr(),
            "animal_names.gorilla".tr(),
            "animal_names.bear".tr(),
          ],
        ),
        imagePath: "assets/animal_images/elephant.png",
        soundPath: "assets/animal_sounds/elephant.mp3",
      ),
      QuizQuestion(
        id: 3,
        question: "quiz_questions.which_animal_sound".tr(),
        correctAnswer: "animal_names.cow".tr(),
        options: _shuffleOptions(
          "animal_names.cow".tr(),
          [
            "animal_names.cow".tr(),
            "animal_names.horse".tr(),
            "animal_names.sheep".tr(),
            "animal_names.pig".tr(),
          ],
        ),
        imagePath: "assets/animal_images/cow.png",
        soundPath: "assets/animal_sounds/cow.mp3",
      ),
      QuizQuestion(
        id: 4,
        question: "quiz_questions.what_is_animal".tr(),
        correctAnswer: "animal_names.rooster".tr(),
        options: _shuffleOptions(
          "animal_names.rooster".tr(),
          [
            "animal_names.rooster".tr(),
            "animal_names.duck".tr(),
            "animal_names.owl".tr(),
            "animal_names.penguin".tr(),
          ],
        ),
        imagePath: "assets/animal_images/rooster.png",
        soundPath: "assets/animal_sounds/rooster.mp3",
      ),
      QuizQuestion(
        id: 5,
        question: "quiz_questions.which_animal_shown".tr(),
        correctAnswer: "animal_names.dog".tr(),
        options: _shuffleOptions(
          "animal_names.dog".tr(),
          [
            "animal_names.dog".tr(),
            "animal_names.cat".tr(),
            "animal_names.fox".tr(),
            "animal_names.wolf".tr(),
          ],
        ),
        imagePath: "assets/animal_images/dog.png",
        soundPath: "assets/animal_sounds/dog.mp3",
      ),
      QuizQuestion(
        id: 6,
        question: "quiz_questions.what_is_animal".tr(),
        correctAnswer: "animal_names.monkey".tr(),
        options: _shuffleOptions(
          "animal_names.monkey".tr(),
          [
            "animal_names.monkey".tr(),
            "animal_names.gorilla".tr(),
            "animal_names.koala".tr(),
            "animal_names.kangaroo".tr(),
          ],
        ),
        imagePath: "assets/animal_images/monkey.png",
        soundPath: "assets/animal_sounds/monkey.mp3",
      ),
      QuizQuestion(
        id: 7,
        question: "quiz_questions.which_animal_shown".tr(),
        correctAnswer: "animal_names.crocodile".tr(),
        options: _shuffleOptions(
          "animal_names.crocodile".tr(),
          [
            "animal_names.crocodile".tr(),
            "animal_names.snake".tr(),
            "animal_names.frog".tr(),
            "animal_names.whale".tr(),
          ],
        ),
        imagePath: "assets/animal_images/crocodile.png",
        soundPath: "assets/animal_sounds/crocodile.mp3",
      ),
      QuizQuestion(
        id: 8,
        question: "quiz_questions.what_is_animal".tr(),
        correctAnswer: "animal_names.dolphin".tr(),
        options: _shuffleOptions(
          "animal_names.dolphin".tr(),
          [
            "animal_names.dolphin".tr(),
            "animal_names.whale".tr(),
            "animal_names.penguin".tr(),
            "animal_names.snake".tr(),
          ],
        ),
        imagePath: "assets/animal_images/dolphin.png",
        soundPath: "assets/animal_sounds/dolphin.mp3",
      ),
      QuizQuestion(
        id: 9,
        question: "quiz_questions.which_animal_shown".tr(),
        correctAnswer: "animal_names.giraffe".tr(),
        options: _shuffleOptions(
          "animal_names.giraffe".tr(),
          [
            "animal_names.giraffe".tr(),
            "animal_names.zebra".tr(),
            "animal_names.camel".tr(),
            "animal_names.horse".tr(),
          ],
        ),
        imagePath: "assets/animal_images/giraffe.png",
        soundPath: "assets/animal_sounds/giraffe.mp3",
      ),
      QuizQuestion(
        id: 10,
        question: "quiz_questions.what_is_animal".tr(),
        correctAnswer: "animal_names.bee".tr(),
        options: _shuffleOptions(
          "animal_names.bee".tr(),
          [
            "animal_names.bee".tr(),
            "animal_names.owl".tr(),
            "animal_names.duck".tr(),
            "animal_names.penguin".tr(),
          ],
        ),
        imagePath: "assets/animal_images/bee.png",
        soundPath: "assets/animal_sounds/bee.mp3",
      ),
      QuizQuestion(
        id: 11,
        question: "quiz_questions.what_does_eat".tr(),
        correctAnswer: "animal_facts.lion_diet".tr(),
        options: _shuffleOptions(
          "animal_facts.lion_diet".tr(),
          [
            "animal_facts.lion_diet".tr(),
            "animal_facts.elephant_diet".tr(),
            "animal_facts.monkey_diet".tr(),
            "animal_facts.giraffe_diet".tr(),
          ],
        ),
        imagePath: "assets/animal_images/lion.png",
        soundPath: "assets/animal_sounds/lion.mp3",
      ),
      QuizQuestion(
        id: 12,
        question: "quiz_questions.which_fact_true".tr(),
        correctAnswer: "animal_facts.elephant_fact".tr(),
        options: _shuffleOptions(
          "animal_facts.elephant_fact".tr(),
          [
            "animal_facts.elephant_fact".tr(),
            "animal_facts.giraffe_fact".tr(),
            "animal_facts.dolphin_fact".tr(),
            "animal_facts.penguin_fact".tr(),
          ],
        ),
        imagePath: "assets/animal_images/elephant.png",
      ),
      QuizQuestion(
        id: 13,
        question: "quiz_questions.where_lives".tr(),
        correctAnswer: "animal_facts.giraffe_habitat".tr(),
        options: _shuffleOptions(
          "animal_facts.giraffe_habitat".tr(),
          [
            "animal_facts.giraffe_habitat".tr(),
            "animal_facts.penguin_habitat".tr(),
            "animal_facts.dolphin_habitat".tr(),
            "animal_facts.bear_habitat".tr(),
          ],
        ),
        imagePath: "assets/animal_images/giraffe.png",
      ),
      QuizQuestion(
        id: 14,
        question: "quiz_questions.which_fact_true".tr(),
        correctAnswer: "animal_facts.dolphin_fact".tr(),
        options: _shuffleOptions(
          "animal_facts.dolphin_fact".tr(),
          [
            "animal_facts.dolphin_fact".tr(),
            "animal_facts.crocodile_fact".tr(),
            "animal_facts.snake_fact".tr(),
            "animal_facts.bee_fact".tr(),
          ],
        ),
        imagePath: "assets/animal_images/dolphin.png",
      ),
      QuizQuestion(
        id: 15,
        question: "quiz_questions.what_does_eat".tr(),
        correctAnswer: "animal_facts.monkey_diet".tr(),
        options: _shuffleOptions(
          "animal_facts.monkey_diet".tr(),
          [
            "animal_facts.monkey_diet".tr(),
            "animal_facts.lion_diet".tr(),
            "animal_facts.cow_diet".tr(),
            "animal_facts.snake_diet".tr(),
          ],
        ),
        imagePath: "assets/animal_images/monkey.png",
      ),
      QuizQuestion(
        id: 16,
        question: "quiz_questions.which_fact_true".tr(),
        correctAnswer: "animal_facts.crocodile_fact2".tr(),
        options: _shuffleOptions(
          "animal_facts.crocodile_fact2".tr(),
          [
            "animal_facts.crocodile_fact2".tr(),
            "animal_facts.snake_fact2".tr(),
            "animal_facts.penguin_fact2".tr(),
            "animal_facts.elephant_fact2".tr(),
          ],
        ),
        imagePath: "assets/animal_images/crocodile.png",
      ),
      QuizQuestion(
        id: 17,
        question: "quiz_questions.why_pattern".tr(),
        correctAnswer: "animal_facts.zebra_pattern".tr(),
        options: _shuffleOptions(
          "animal_facts.zebra_pattern".tr(),
          [
            "animal_facts.zebra_pattern".tr(),
            "animal_facts.giraffe_pattern".tr(),
            "animal_facts.tiger_pattern".tr(),
            "animal_facts.cheetah_pattern".tr(),
          ],
        ),
        imagePath: "assets/animal_images/zebra.png",
      ),
      QuizQuestion(
        id: 18,
        question: "quiz_questions.what_does_eat".tr(),
        correctAnswer: "animal_facts.koala_diet".tr(),
        options: _shuffleOptions(
          "animal_facts.koala_diet".tr(),
          [
            "animal_facts.koala_diet".tr(),
            "animal_facts.kangaroo_diet".tr(),
            "animal_facts.monkey_diet".tr(),
            "animal_facts.bear_diet".tr(),
          ],
        ),
        imagePath: "assets/animal_images/koala.png",
      ),
      QuizQuestion(
        id: 19,
        question: "quiz_questions.special_ability".tr(),
        correctAnswer: "animal_facts.kangaroo_ability".tr(),
        options: _shuffleOptions(
          "animal_facts.kangaroo_ability".tr(),
          [
            "animal_facts.kangaroo_ability".tr(),
            "animal_facts.elephant_ability".tr(),
            "animal_facts.giraffe_ability".tr(),
            "animal_facts.monkey_ability".tr(),
          ],
        ),
        imagePath: "assets/animal_images/kangaroo.png",
      ),
      QuizQuestion(
        id: 20,
        question: "quiz_questions.adaptation".tr(),
        correctAnswer: "animal_facts.camel_adaptation".tr(),
        options: _shuffleOptions(
          "animal_facts.camel_adaptation".tr(),
          [
            "animal_facts.camel_adaptation".tr(),
            "animal_facts.penguin_adaptation".tr(),
            "animal_facts.polar_bear_adaptation".tr(),
            "animal_facts.dolphin_adaptation".tr(),
          ],
        ),
        imagePath: "assets/animal_images/camel.png",
      ),
      QuizQuestion(
        id: 21,
        question: "quiz_questions.when_active".tr(),
        correctAnswer: "animal_facts.owl_activity".tr(),
        options: _shuffleOptions(
          "animal_facts.owl_activity".tr(),
          [
            "animal_facts.owl_activity".tr(),
            "animal_facts.lion_activity".tr(),
            "animal_facts.bee_activity".tr(),
            "animal_facts.rooster_activity".tr(),
          ],
        ),
        imagePath: "assets/animal_images/owl.png",
      ),
      QuizQuestion(
        id: 22,
        question: "quiz_questions.which_fact_true".tr(),
        correctAnswer: "animal_facts.bee_fact2".tr(),
        options: _shuffleOptions(
          "animal_facts.bee_fact2".tr(),
          [
            "animal_facts.bee_fact2".tr(),
            "animal_facts.butterfly_fact".tr(),
            "animal_facts.bird_fact".tr(),
            "animal_facts.frog_fact".tr(),
          ],
        ),
        imagePath: "assets/animal_images/bee.png",
      ),
      QuizQuestion(
        id: 23,
        question: "quiz_questions.special_ability".tr(),
        correctAnswer: "animal_facts.horse_ability".tr(),
        options: _shuffleOptions(
          "animal_facts.horse_ability".tr(),
          [
            "animal_facts.horse_ability".tr(),
            "animal_facts.cow_ability".tr(),
            "animal_facts.sheep_ability".tr(),
            "animal_facts.pig_ability".tr(),
          ],
        ),
        imagePath: "assets/animal_images/horse.png",
      ),
      QuizQuestion(
        id: 24,
        question: "quiz_questions.special_feature".tr(),
        correctAnswer: "animal_facts.cheetah_feature".tr(),
        options: _shuffleOptions(
          "animal_facts.cheetah_feature".tr(),
          [
            "animal_facts.cheetah_feature".tr(),
            "animal_facts.lion_feature".tr(),
            "animal_facts.tiger_feature".tr(),
            "animal_facts.wolf_feature".tr(),
          ],
        ),
        imagePath: "assets/animal_images/cheetah.png",
      ),
      QuizQuestion(
        id: 25,
        question: "quiz_questions.size_comparison".tr(),
        correctAnswer: "animal_facts.whale_size".tr(),
        options: _shuffleOptions(
          "animal_facts.whale_size".tr(),
          [
            "animal_facts.whale_size".tr(),
            "animal_facts.elephant_size".tr(),
            "animal_facts.giraffe_size".tr(),
            "animal_facts.crocodile_size".tr(),
          ],
        ),
        imagePath: "assets/animal_images/whale.png",
      ),
      QuizQuestion(
        id: 26,
        question: "quiz_questions.which_animal_sound".tr(),
        correctAnswer: "animal_names.lion".tr(),
        options: _shuffleOptions(
          "animal_names.lion".tr(),
          [
            "animal_names.lion".tr(),
            "animal_names.cow".tr(),
            "animal_names.wolf".tr(),
            "animal_names.bear".tr(),
          ],
        ),
        soundPath: "assets/animal_sounds/lion.mp3",
      ),
      QuizQuestion(
        id: 27,
        question: "quiz_questions.which_animal_sound".tr(),
        correctAnswer: "animal_names.dog".tr(),
        options: _shuffleOptions(
          "animal_names.dog".tr(),
          [
            "animal_names.dog".tr(),
            "animal_names.wolf".tr(),
            "animal_names.fox".tr(),
            "animal_names.cat".tr(),
          ],
        ),
        soundPath: "assets/animal_sounds/dog.mp3",
      ),
      QuizQuestion(
        id: 28,
        question: "quiz_questions.which_animal_sound".tr(),
        correctAnswer: "animal_names.cat".tr(),
        options: _shuffleOptions(
          "animal_names.cat".tr(),
          [
            "animal_names.cat".tr(),
            "animal_names.tiger".tr(),
            "animal_names.lion".tr(),
            "animal_names.dog".tr(),
          ],
        ),
        soundPath: "assets/animal_sounds/cat.mp3",
      ),
      QuizQuestion(
        id: 29,
        question: "quiz_questions.which_animal_sound".tr(),
        correctAnswer: "animal_names.elephant".tr(),
        options: _shuffleOptions(
          "animal_names.elephant".tr(),
          [
            "animal_names.elephant".tr(),
            "animal_names.horse".tr(),
            "animal_names.cow".tr(),
            "animal_names.bear".tr(),
          ],
        ),
        soundPath: "assets/animal_sounds/elephant.mp3",
      ),
      QuizQuestion(
        id: 30,
        question: "quiz_questions.which_animal_sound".tr(),
        correctAnswer: "animal_names.monkey".tr(),
        options: _shuffleOptions(
          "animal_names.monkey".tr(),
          [
            "animal_names.monkey".tr(),
            "animal_names.gorilla".tr(),
            "animal_names.bird".tr(),
            "animal_names.owl".tr(),
          ],
        ),
        soundPath: "assets/animal_sounds/monkey.mp3",
      ),
      QuizQuestion(
        id: 31,
        question: "quiz_questions.which_animal_sound".tr(),
        correctAnswer: "animal_names.rooster".tr(),
        options: _shuffleOptions(
          "animal_names.rooster".tr(),
          [
            "animal_names.rooster".tr(),
            "animal_names.duck".tr(),
            "animal_names.owl".tr(),
            "animal_names.bird".tr(),
          ],
        ),
        soundPath: "assets/animal_sounds/rooster.mp3",
      ),
      QuizQuestion(
        id: 32,
        question: "quiz_questions.which_animal_sound".tr(),
        correctAnswer: "animal_names.wolf".tr(),
        options: _shuffleOptions(
          "animal_names.wolf".tr(),
          [
            "animal_names.wolf".tr(),
            "animal_names.dog".tr(),
            "animal_names.fox".tr(),
            "animal_names.bear".tr(),
          ],
        ),
        soundPath: "assets/animal_sounds/wolf.mp3",
      ),
      QuizQuestion(
        id: 33,
        question: "quiz_questions.which_animal_sound".tr(),
        correctAnswer: "animal_names.snake".tr(),
        options: _shuffleOptions(
          "animal_names.snake".tr(),
          [
            "animal_names.snake".tr(),
            "animal_names.bee".tr(),
            "animal_names.frog".tr(),
            "animal_names.crocodile".tr(),
          ],
        ),
        soundPath: "assets/animal_sounds/snake.mp3",
      ),
      QuizQuestion(
        id: 34,
        question: "quiz_questions.which_animal_sound".tr(),
        correctAnswer: "animal_names.frog".tr(),
        options: _shuffleOptions(
          "animal_names.frog".tr(),
          [
            "animal_names.frog".tr(),
            "animal_names.snake".tr(),
            "animal_names.bee".tr(),
            "animal_names.crocodile".tr(),
          ],
        ),
        soundPath: "assets/animal_sounds/frog.mp3",
      ),
    ];

    questions.shuffle();
    return questions.take(5).toList();
  }
}
