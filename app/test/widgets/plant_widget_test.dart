// test/widgets/plant_widget_test.dart
//
// Widget tests for PlantWidget — correct asset loaded per GrowthStage.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studymentor/src/presentation/widgets/plant_widget.dart';
import 'package:studymentor/src/utils/growth_stage_utils.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('PlantWidget', () {
    for (final stage in GrowthStage.values) {
      testWidgets('renders without throwing for GrowthStage.$stage',
          (tester) async {
        await tester.pumpWidget(_wrap(PlantWidget(stage: stage)));
        await tester.pump();
        expect(find.byType(PlantWidget), findsOneWidget);
      });
    }

    testWidgets('renders a SvgPicture for each stage', (tester) async {
      for (final stage in GrowthStage.values) {
        await tester.pumpWidget(_wrap(PlantWidget(stage: stage)));
        await tester.pump();
        expect(find.byType(SvgPicture), findsOneWidget);
      }
    });

    testWidgets('respects custom size', (tester) async {
      await tester.pumpWidget(_wrap(const PlantWidget(
        stage: GrowthStage.seed,
        size: 200,
      )));
      await tester.pump();
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(SvgPicture),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.width, 200);
      expect(sizedBox.height, 200);
    });

    testWidgets('all 5 growth stages render exactly one SvgPicture each',
        (tester) async {
      for (final stage in GrowthStage.values) {
        await tester.pumpWidget(_wrap(PlantWidget(stage: stage)));
        await tester.pump();
        expect(
          find.byType(SvgPicture),
          findsOneWidget,
          reason: 'GrowthStage.$stage should render exactly one SvgPicture',
        );
      }
    });
  });
}
