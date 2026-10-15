import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/shared/layout/safe_area_padding.dart';

void main() {
  testWidgets('rotation clears obsolete borders and applies safe area once', (
    tester,
  ) async {
    const contentKey = ValueKey('content');
    for (final insets in [
      const EdgeInsets.only(top: 59, bottom: 34),
      const EdgeInsets.only(left: 59, right: 59, bottom: 21),
      const EdgeInsets.only(top: 59, bottom: 34),
    ]) {
      final data = MediaQueryData(
        size: const Size(800, 600),
        padding: insets,
        viewPadding: insets,
      );
      EdgeInsets? remainingPadding;
      await tester.pumpWidget(
        MediaQuery(
          data: data.copyWith(
            padding: currentSafeAreaPadding(data, preserveViewPadding: true),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SafeArea(
              child: SafeArea(
                child: Builder(
                  builder: (context) {
                    remainingPadding = MediaQuery.paddingOf(context);
                    return const SizedBox.expand(key: contentKey);
                  },
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getRect(find.byKey(contentKey)),
        Rect.fromLTRB(
          insets.left,
          insets.top,
          800 - insets.right,
          600 - insets.bottom,
        ),
      );
      expect(remainingPadding, EdgeInsets.zero);
    }
  });

  test('temporary zero padding uses current iOS view insets', () {
    const insets = EdgeInsets.only(left: 59, right: 59, bottom: 21);
    const data = MediaQueryData(viewPadding: insets);
    expect(currentSafeAreaPadding(data, preserveViewPadding: true), insets);
    expect(
      currentSafeAreaPadding(data, preserveViewPadding: false),
      EdgeInsets.zero,
    );
  });
}
