// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_pipedrive_suppression.dart';

const _tracerName = 'dartastic_otel_libs_pipedrive';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class PipedriveResult {
  const PipedriveResult({
    this.itemCount,
    this.moreItemsInCollection,
    this.companyDomain,
    this.dealStatus,
    this.pipelineId,
    this.stageId,
    this.valueMinor,
    this.currency,
    this.apiVersion,
    this.rateLimitRemaining,
    this.requestId,
    this.statusCode,
  });

  /// `data.length`.
  final int? itemCount;

  /// `additional_data.pagination.more_items_in_collection`.
  final bool? moreItemsInCollection;

  /// `company_domain` of the workspace.
  final String? companyDomain;

  /// `open` / `won` / `lost` / `deleted` for deals.
  final String? dealStatus;

  /// `pipeline_id`.
  final int? pipelineId;

  /// `stage_id`.
  final int? stageId;

  /// `value` in minor units (Pipedrive returns floats; multiply *100).
  final int? valueMinor;

  /// ISO 4217.
  final String? currency;

  /// `v1` / `v2` — v2 has different rate limits.
  final String? apiVersion;

  /// `X-RateLimit-Remaining`.
  final int? rateLimitRemaining;

  /// `X-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

class PipedriveCallResult<T> {
  const PipedriveCallResult({required this.value, this.result});
  final T value;
  final PipedriveResult? result;
}

/// Wraps a Pipedrive API call in a CLIENT span. [operation] is one of
/// `deals.list`, `deals.get`, `deals.add`, `deals.update`,
/// `deals.delete`, `deals.merge`, `deals.search`, `persons.list`,
/// `persons.add`, `persons.search`, `organizations.list`,
/// `organizations.add`, `activities.list`, `activities.add`,
/// `leads.list`, `leads.add`, `products.list`, `pipelines.list`,
/// `stages.list`, `webhooks.create`, `notes.add`, `files.add`.
Future<T> tracedPipedrive<T>({
  required String operation,
  required Future<PipedriveCallResult<T>> Function() invoke,
  String? apiVersion,
}) async {
  if (pipedriveInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'pipedrive',
    'rpc.method': operation,
    'pipedrive.operation': operation,
  };
  if (apiVersion != null) m['pipedrive.api_version'] = apiVersion;

  final span = _tracer().startSpan(
    'pipedrive $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTel.attributeInt(
          'pipedrive.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.moreItemsInCollection != null) {
        extras.add(OTel.attributeBool(
          'pipedrive.pagination.more',
          r.result!.moreItemsInCollection!,
        ));
      }
      if (r.result!.companyDomain != null) {
        extras.add(OTel.attributeString(
          'pipedrive.company.domain',
          r.result!.companyDomain!,
        ));
      }
      if (r.result!.dealStatus != null) {
        extras.add(OTel.attributeString(
          'pipedrive.deal.status',
          r.result!.dealStatus!,
        ));
      }
      if (r.result!.pipelineId != null) {
        extras.add(OTel.attributeInt(
          'pipedrive.pipeline.id',
          r.result!.pipelineId!,
        ));
      }
      if (r.result!.stageId != null) {
        extras.add(OTel.attributeInt(
          'pipedrive.stage.id',
          r.result!.stageId!,
        ));
      }
      if (r.result!.valueMinor != null) {
        extras.add(OTel.attributeInt(
          'pipedrive.deal.value.minor',
          r.result!.valueMinor!,
        ));
      }
      if (r.result!.currency != null) {
        extras.add(OTel.attributeString(
          'pipedrive.currency',
          r.result!.currency!,
        ));
      }
      if (r.result!.apiVersion != null) {
        extras.add(OTel.attributeString(
          'pipedrive.api_version',
          r.result!.apiVersion!,
        ));
      }
      if (r.result!.rateLimitRemaining != null) {
        extras.add(OTel.attributeInt(
          'pipedrive.rate_limit.remaining',
          r.result!.rateLimitRemaining!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'pipedrive.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Pipedrive HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
