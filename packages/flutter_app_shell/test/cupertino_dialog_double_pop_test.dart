import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_shell/src/ui/adaptive/cupertino_widget_factory.dart';

void main() {
  testWidgets('Cupertino dialog absorbs double pop from CupertinoDialogAction',
      (tester) async {
    final factory = CupertinoWidgetFactory();
    final resultNotifier = ValueNotifier<bool?>(null);

    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (pageContext) {
            return CupertinoPageScaffold(
              navigationBar: const CupertinoNavigationBar(middle: Text('Demo')),
              child: Center(
                child: CupertinoButton.filled(
                  child: const Text('Show'),
                  onPressed: () async {
                    BuildContext? dialogActionContext;

                    final result = await factory.showDialog<bool>(
                      context: pageContext,
                      title: const Text('Title'),
                      content: const Text('Content'),
                      actions: [
                        Builder(
                          builder: (actionContext) {
                            dialogActionContext = actionContext;
                            return factory.button(
                              label: 'Delete',
                              onPressed: () {
                                // Simulate Cupertino wrapping by popping the dialog context first.
                                Navigator.of(dialogActionContext!).pop();
                                // User callback still closes using the original page context.
                                Navigator.pop(pageContext, true);
                              },
                            );
                          },
                        ),
                      ],
                    );
                    resultNotifier.value = result;
                  },
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(resultNotifier.value, isNull);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(resultNotifier.value, isTrue);
  });

  testWidgets('Cupertino dialog sentinel handles nested navigator contexts',
      (tester) async {
    final factory = CupertinoWidgetFactory();
    final resultNotifier = ValueNotifier<bool?>(null);

    await tester.pumpWidget(
      CupertinoApp(
        home: Navigator(
          onGenerateRoute: (settings) => CupertinoPageRoute<void>(
            builder: (outerContext) {
              return CupertinoPageScaffold(
                navigationBar:
                    const CupertinoNavigationBar(middle: Text('Nested Demo')),
                child: Builder(
                  builder: (pageContext) {
                    return Center(
                      child: CupertinoButton.filled(
                        child: const Text('Show Nested'),
                        onPressed: () async {
                          BuildContext? dialogActionContext;

                          final result = await factory.showDialog<bool>(
                            context: pageContext,
                            title: const Text('Nested Title'),
                            content: const Text('Nested Content'),
                            actions: [
                              Builder(
                                builder: (actionContext) {
                                  dialogActionContext = actionContext;
                                  return factory.button(
                                    label: 'Confirm',
                                    onPressed: () {
                                      Navigator.of(dialogActionContext!).pop();
                                      Navigator.pop(pageContext, true);
                                    },
                                  );
                                },
                              ),
                            ],
                          );
                          resultNotifier.value = result;
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Nested'));
    await tester.pumpAndSettle();

    expect(resultNotifier.value, isNull);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(resultNotifier.value, isTrue);
    expect(find.text('Show Nested'), findsOneWidget);
  });
}
