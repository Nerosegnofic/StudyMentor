// test/widgets/garden_subject_card_test.dart
//
// Widget tests for GardenSubjectCard — stage badge, labels, progress bar, tap.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studymentor/src/domain/models/garden_plant_model.dart';
import 'package:studymentor/src/presentation/widgets/garden_subject_card.dart';
import 'package:studymentor/src/presentation/widgets/plant_widget.dart';
import 'package:studymentor/src/utils/growth_stage_utils.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

GardenPlantModel _plant({
  String name = 'Math',
  double mastery = 35.0,
}) =>
    GardenPlantModel(
      subjectId: 1,
      subjectName: name,
      masteryPercent: mastery,
    );

void main() {
  group('GardenSubjectCard', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(
        _wrap(GardenSubjectCard(plant: _plant(), onTap: () {})),
      );
      await tester.pump();
      expect(find.byType(GardenSubjectCard), findsOneWidget);
    });

    testWidgets('shows subject name', (tester) async {
      await tester.pumpWidget(
        _wrap(GardenSubjectCard(plant: _plant(name: 'Science'), onTap: () {})),
      );
      await tester.pump();
      expect(find.text('Science'), findsOneWidget);
    });

    testWidgets('shows mastery percentage rounded to integer', (tester) async {
      await tester.pumpWidget(
        _wrap(GardenSubjectCard(plant: _plant(mastery: 35.0), onTap: () {})),
      );
      await tester.pump();
      expect(find.text('35%'), findsOneWidget);
    });

    testWidgets('shows correct stage badge number for seed (mastery 10%)',
        (tester) async {
      // seed is index 0 → badge shows 1
      await tester.pumpWidget(
        _wrap(GardenSubjectCard(plant: _plant(mastery: 10.0), onTap: () {})),
      );
      await tester.pump();
      final stageIndex = GrowthStage.values.indexOf(GrowthStage.seed) + 1;
      expect(find.text('$stageIndex'), findsOneWidget);
    });

    testWidgets('shows correct stage badge number for sprout (mastery 30%)',
        (tester) async {
      // sprout is index 1 → badge shows 2
      await tester.pumpWidget(
        _wrap(GardenSubjectCard(plant: _plant(mastery: 30.0), onTap: () {})),
      );
      await tester.pump();
      final stageIndex = GrowthStage.values.indexOf(GrowthStage.sprout) + 1;
      expect(find.text('$stageIndex'), findsOneWidget);
    });

    testWidgets('shows correct stage badge number for fullBloom (mastery 90%)',
        (tester) async {
      // fullBloom is index 4 → badge shows 5
      await tester.pumpWidget(
        _wrap(GardenSubjectCard(plant: _plant(mastery: 90.0), onTap: () {})),
      );
      await tester.pump();
      final stageIndex =
          GrowthStage.values.indexOf(GrowthStage.fullBloom) + 1;
      expect(find.text('$stageIndex'), findsOneWidget);
    });

    testWidgets('renders a PlantWidget', (tester) async {
      await tester.pumpWidget(
        _wrap(GardenSubjectCard(plant: _plant(), onTap: () {})),
      );
      await tester.pump();
      expect(find.byType(PlantWidget), findsOneWidget);
    });

    testWidgets('renders a LinearProgressIndicator', (tester) async {
      await tester.pumpWidget(
        _wrap(GardenSubjectCard(plant: _plant(), onTap: () {})),
      );
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('progress bar value is within-stage fraction (mastery 30%)',
        (tester) async {
      // mastery 30%: stage is sprout (20–40). within-stage = (30 % 20) / 20 = 0.5
      await tester.pumpWidget(
        _wrap(GardenSubjectCard(plant: _plant(mastery: 30.0), onTap: () {})),
      );
      await tester.pump();
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, closeTo(0.5, 0.001));
    });

    testWidgets('progress bar value is 0.0 at stage boundary (mastery 40%)',
        (tester) async {
      // mastery 40%: (40 % 20) / 20 = 0.0 — bottom of smallPlant stage
      await tester.pumpWidget(
        _wrap(GardenSubjectCard(plant: _plant(mastery: 40.0), onTap: () {})),
      );
      await tester.pump();
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, closeTo(0.0, 0.001));
    });

    testWidgets('onTap callback fires when card is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(GardenSubjectCard(
          plant: _plant(name: 'Math'),
          onTap: () => tapped = true,
        )),
      );
      await tester.pump();
      // Tap the subject name text which is reliably rendered and hittable.
      await tester.tap(find.text('Math'));
      expect(tapped, isTrue);
    });

    testWidgets('all 5 growth stages render without throwing', (tester) async {
      final masteries = [10.0, 25.0, 50.0, 70.0, 90.0];
      for (final mastery in masteries) {
        await tester.pumpWidget(
          _wrap(GardenSubjectCard(
            plant: _plant(mastery: mastery),
            onTap: () {},
          )),
        );
        await tester.pump();
        expect(find.byType(GardenSubjectCard), findsOneWidget);
      }
    });
  });
}
