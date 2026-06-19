// test/utils/growth_stage_utils_test.dart
//
// Unit tests for GrowthStageUtils — mastery-to-stage mapping and health color.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studymentor/src/utils/growth_stage_utils.dart';

void main() {
  group('GrowthStageUtils.fromMastery', () {
    // ── Stage boundaries ──────────────────────────────────────────────────────

    test('0% mastery → GrowthStage.seed', () {
      expect(GrowthStageUtils.fromMastery(0), GrowthStage.seed);
    });

    test('10% mastery → GrowthStage.seed (within 0–20 range)', () {
      expect(GrowthStageUtils.fromMastery(10), GrowthStage.seed);
    });

    test('19.9% mastery → GrowthStage.seed (just below sprout threshold)', () {
      expect(GrowthStageUtils.fromMastery(19.9), GrowthStage.seed);
    });

    test('20% mastery → GrowthStage.sprout (boundary)', () {
      expect(GrowthStageUtils.fromMastery(20), GrowthStage.sprout);
    });

    test('30% mastery → GrowthStage.sprout (within 20–40 range)', () {
      expect(GrowthStageUtils.fromMastery(30), GrowthStage.sprout);
    });

    test('39.9% mastery → GrowthStage.sprout (just below smallPlant threshold)', () {
      expect(GrowthStageUtils.fromMastery(39.9), GrowthStage.sprout);
    });

    test('40% mastery → GrowthStage.smallPlant (boundary)', () {
      expect(GrowthStageUtils.fromMastery(40), GrowthStage.smallPlant);
    });

    test('55% mastery → GrowthStage.smallPlant (within 40–60 range)', () {
      expect(GrowthStageUtils.fromMastery(55), GrowthStage.smallPlant);
    });

    test('59.9% mastery → GrowthStage.smallPlant (just below mediumPlant threshold)', () {
      expect(GrowthStageUtils.fromMastery(59.9), GrowthStage.smallPlant);
    });

    test('60% mastery → GrowthStage.mediumPlant (boundary)', () {
      expect(GrowthStageUtils.fromMastery(60), GrowthStage.mediumPlant);
    });

    test('70% mastery → GrowthStage.mediumPlant (within 60–80 range)', () {
      expect(GrowthStageUtils.fromMastery(70), GrowthStage.mediumPlant);
    });

    test('79.9% mastery → GrowthStage.mediumPlant (just below fullBloom threshold)', () {
      expect(GrowthStageUtils.fromMastery(79.9), GrowthStage.mediumPlant);
    });

    test('80% mastery → GrowthStage.fullBloom (boundary)', () {
      expect(GrowthStageUtils.fromMastery(80), GrowthStage.fullBloom);
    });

    test('90% mastery → GrowthStage.fullBloom (well within 80–100 range)', () {
      expect(GrowthStageUtils.fromMastery(90), GrowthStage.fullBloom);
    });

    test('100% mastery → GrowthStage.fullBloom', () {
      expect(GrowthStageUtils.fromMastery(100), GrowthStage.fullBloom);
    });

    // ── All five stages are reachable ─────────────────────────────────────────

    test('all 5 growth stages are represented', () {
      final stages = {
        GrowthStageUtils.fromMastery(0),
        GrowthStageUtils.fromMastery(20),
        GrowthStageUtils.fromMastery(40),
        GrowthStageUtils.fromMastery(60),
        GrowthStageUtils.fromMastery(80),
      };

      expect(stages, containsAll(GrowthStage.values));
    });
  });

  // ---------------------------------------------------------------------------
  // healthColor
  // ---------------------------------------------------------------------------

  group('GrowthStageUtils.healthColor', () {
    test('returns green for mastery >= 75%', () {
      expect(
        GrowthStageUtils.healthColor(75),
        const Color(0xFF34A853),
      );
      expect(
        GrowthStageUtils.healthColor(100),
        const Color(0xFF34A853),
      );
    });

    test('returns amber for mastery >= 50% and < 75%', () {
      expect(
        GrowthStageUtils.healthColor(50),
        const Color(0xFFFBBC05),
      );
      expect(
        GrowthStageUtils.healthColor(74.9),
        const Color(0xFFFBBC05),
      );
    });

    test('returns red for mastery < 50%', () {
      expect(
        GrowthStageUtils.healthColor(0),
        const Color(0xFFEA4335),
      );
      expect(
        GrowthStageUtils.healthColor(49.9),
        const Color(0xFFEA4335),
      );
    });

    test('returns green at exactly 75% boundary', () {
      expect(
        GrowthStageUtils.healthColor(75),
        const Color(0xFF34A853),
      );
    });

    test('returns amber at exactly 50% boundary', () {
      expect(
        GrowthStageUtils.healthColor(50),
        const Color(0xFFFBBC05),
      );
    });
  });
}
