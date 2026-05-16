// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_pipedrive/otel_pipedrive.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_pipedrive-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('deals.add records pipeline + stage + value', () async {
    await tracedPipedrive<String>(
      operation: 'deals.add',
      apiVersion: 'v2',
      invoke: () async => const PipedriveCallResult(
        value: 'ok',
        result: PipedriveResult(
          dealStatus: 'open',
          pipelineId: 1,
          stageId: 3,
          valueMinor: 1500000,
          currency: 'USD',
          apiVersion: 'v2',
          rateLimitRemaining: 78,
          statusCode: 201,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('pipedrive deals.add')!);
    expect(a['pipedrive.api_version'], 'v2');
    expect(a['pipedrive.deal.status'], 'open');
    expect(a['pipedrive.pipeline.id'], 1);
    expect(a['pipedrive.stage.id'], 3);
    expect(a['pipedrive.deal.value.minor'], 1500000);
  });

  test('lost deal does NOT set span error', () async {
    await tracedPipedrive<String>(
      operation: 'deals.update',
      invoke: () async => const PipedriveCallResult(
        value: 'ok',
        result: PipedriveResult(dealStatus: 'lost'),
      ),
    );
    final s = spans.findSpanByName('pipedrive deals.update')!;
    expect(s.status, isNot(SpanStatusCode.Error));
    expect(attrsOf(s)['pipedrive.deal.status'], 'lost');
  });

  test('suppression skips spans', () async {
    await runWithoutPipedriveInstrumentationAsync(() async {
      await tracedPipedrive<String>(
        operation: 'deals.list',
        invoke: () async => const PipedriveCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('pipedrive '), isEmpty);
  });
}
