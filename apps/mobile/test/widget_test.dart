import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/small_business/presentation/screens/manufacturer_details_screen.dart';
import 'package:mobile/features/small_business/presentation/screens/nutritional_values_screen.dart';
import 'package:mobile/main.dart';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl) {
      return Future.value(_MockHttpClientRequest());
    }
    if (invocation.memberName == #openUrl) {
      return Future.value(_MockHttpClientRequest());
    }
    return super.noSuchMethod(invocation);
  }
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #headers) {
      return _MockHttpHeaders();
    }
    if (invocation.memberName == #close) {
      return Future.value(_MockHttpClientResponse());
    }
    return super.noSuchMethod(invocation);
  }
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  // A tiny 1x1 transparent PNG image data
  static const List<int> _transparentImage = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ];

  @override
  int get contentLength => _transparentImage.length;

  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => 'OK';

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #compressionState) {
      return HttpClientResponseCompressionState.notCompressed;
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  testWidgets(
      'Screen 1 to Screen 2 to Screen 3 to Screen 4 to Screen 5 full navigation flow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MyLabelStudioApp());

    // Verify Screen 1
    expect(find.text('My Label Studio'), findsOneWidget);

    // Navigate to Screen 2
    final createLabelBtn = find.text('Start creating your label');
    await tester.tap(createLabelBtn);
    await tester.pumpAndSettle();

    // Fill in fields and navigate to Screen 3
    final textFields2 = find.byType(TextField);
    await tester.enterText(textFields2.at(0), 'Annapurna');
    await tester.enterText(textFields2.at(1), 'Mango Pickle');
    await tester.pumpAndSettle();

    final continueBtnScreen2 = find.text('Continue');
    await tester.tap(continueBtnScreen2);
    await tester.pumpAndSettle();

    // Navigate to Screen 4
    final continueBtnScreen3 = find.text('Continue');
    await tester.tap(continueBtnScreen3);
    await tester.pumpAndSettle();

    // Verify Screen 4 & Tap Next to navigate to Screen 5
    expect(find.text('Step 3 of 6'), findsOneWidget);
    final nextBtnScreen4 = find.text('Next');
    await tester.tap(nextBtnScreen4);
    await tester.pumpAndSettle();

    // Verify Screen 5 (Business & Manufacturer)
    expect(find.text('LabelStudio'), findsOneWidget);
    expect(find.text('Step 4 of 6'), findsOneWidget);
    expect(find.text('Manufacturer Details'), findsWidgets);
    expect(find.text('Business Information'), findsOneWidget);
    expect(find.text('Consumer Care Details'), findsOneWidget);
    expect(find.text('Packer address same as manufacturer'), findsOneWidget);

    // Tap Back on Screen 5 to return to Screen 4
    final backBtnScreen5 = find.text('Back');
    await tester.tap(backBtnScreen5);
    await tester.pumpAndSettle();

    // Verify back on Screen 4
    expect(find.text('Step 3 of 6'), findsOneWidget);
  });

  testWidgets('Screen 5 direct test with input interaction', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: ManufacturerDetailsScreen()),
    );

    // Verify layout elements
    expect(find.text('LabelStudio'), findsOneWidget);
    expect(find.text('Step 4 of 6'), findsOneWidget);
    expect(find.text('Manufacturer Details'), findsWidgets);

    // Verify pre-filled inputs
    expect(find.text('Desi Harvest'), findsOneWidget);
    expect(find.text('India'), findsOneWidget);

    // Verify Next button
    expect(find.text('Next'), findsOneWidget);
  });
}
