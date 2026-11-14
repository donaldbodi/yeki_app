// Vérifie les tokens de design (P4.1) : ruptures responsive, échelle
// typographique fluide, respect de `disableAnimations`, et intégrité de la
// palette de cours du CDC.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeki/core/design/tokens/tokens.dart';

Widget _withMediaQuery(
  Size size, {
  bool disableAnimations = false,
  required WidgetBuilder builder,
}) {
  return MediaQuery(
    data: MediaQueryData(size: size, disableAnimations: disableAnimations),
    child: Builder(builder: builder),
  );
}

void main() {
  group('YkBreakpoints', () {
    test('fromWidth renvoie la rupture exacte à chaque limite', () {
      expect(YkBreakpoints.fromWidth(599), YkBreakpoint.compact);
      expect(YkBreakpoints.fromWidth(600), YkBreakpoint.medium);
      expect(YkBreakpoints.fromWidth(904), YkBreakpoint.medium);
      expect(YkBreakpoints.fromWidth(905), YkBreakpoint.expanded);
      expect(YkBreakpoints.fromWidth(1239), YkBreakpoint.expanded);
      expect(YkBreakpoints.fromWidth(1240), YkBreakpoint.large);
      expect(YkBreakpoints.fromWidth(1599), YkBreakpoint.large);
      expect(YkBreakpoints.fromWidth(1600), YkBreakpoint.xlarge);
    });

    testWidgets('of(context) délègue à MediaQuery.sizeOf', (tester) async {
      await tester.pumpWidget(
        _withMediaQuery(
          const Size(1300, 900),
          builder: (context) {
            expect(YkBreakpoints.of(context), YkBreakpoint.large);
            return const SizedBox.shrink();
          },
        ),
      );
    });
  });

  group('YkTypography', () {
    test('fluidSize borne aux valeurs mobile/desktop hors intervalle', () {
      expect(YkTypography.fluidSize(300, 32, 44), 32);
      expect(YkTypography.fluidSize(2000, 32, 44), 44);
    });

    test('fluidSize interpole linéairement au milieu', () {
      expect(YkTypography.fluidSize(800, 32, 44), closeTo(38, 0.01));
    });

    testWidgets('display vaut 32 à 360px et 44 à 1240px', (tester) async {
      double? sizeAt360;
      double? sizeAt1240;
      await tester.pumpWidget(
        _withMediaQuery(
          const Size(360, 800),
          builder: (context) {
            sizeAt360 = YkTypography.display(context).fontSize;
            return const SizedBox.shrink();
          },
        ),
      );
      await tester.pumpWidget(
        _withMediaQuery(
          const Size(1240, 800),
          builder: (context) {
            sizeAt1240 = YkTypography.display(context).fontSize;
            return const SizedBox.shrink();
          },
        ),
      );
      expect(sizeAt360, 32);
      expect(sizeAt1240, 44);
    });
  });

  group('YkMotion', () {
    testWidgets('duration respecte disableAnimations sauf pour l\'opacité', (
      tester,
    ) async {
      await tester.pumpWidget(
        _withMediaQuery(
          const Size(400, 800),
          disableAnimations: true,
          builder: (context) {
            expect(
              YkMotion.duration(context, YkMotionSpeed.normal),
              Duration.zero,
            );
            expect(
              YkMotion.duration(
                context,
                YkMotionSpeed.normal,
                isOpacity: true,
              ),
              YkMotion.normal,
            );
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets('duration renvoie la durée normale quand non réduite', (
      tester,
    ) async {
      await tester.pumpWidget(
        _withMediaQuery(
          const Size(400, 800),
          builder: (context) {
            expect(
              YkMotion.duration(context, YkMotionSpeed.fast),
              YkMotion.fast,
            );
            return const SizedBox.shrink();
          },
        ),
      );
    });
  });

  group('YkCourseColors', () {
    test('la palette contient exactement les 12 couleurs du CDC', () {
      expect(YkCourseColors.palette.length, 12);
    });
  });
}
