import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-grpc';
import { OTLPMetricExporter } from '@opentelemetry/exporter-metrics-otlp-grpc';
import { OTLPLogExporter } from '@opentelemetry/exporter-logs-otlp-grpc';
import { PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics';
import { SimpleLogRecordProcessor } from '@opentelemetry/sdk-logs';
import { AzureFunctionsInstrumentation } from '@azure/functions-opentelemetry-instrumentation';

// All configuration is driven by standard OTel environment variables:
//   OTEL_SERVICE_NAME                   — service name (required)
//   OTEL_EXPORTER_OTLP_ENDPOINT         — base URL for all signals, e.g. http://otel-collector:4318
//   OTEL_EXPORTER_OTLP_TRACES_ENDPOINT  — override traces endpoint
//   OTEL_EXPORTER_OTLP_METRICS_ENDPOINT — override metrics endpoint
//   OTEL_EXPORTER_OTLP_LOGS_ENDPOINT    — override logs endpoint
//   OTEL_METRIC_EXPORT_INTERVAL         — metrics export interval in ms (default 60000)

const sdk = new NodeSDK({
    traceExporter: new OTLPTraceExporter(),
    logRecordProcessors: [new SimpleLogRecordProcessor({
        exporter: new OTLPLogExporter()
    })],
    metricReader: new PeriodicExportingMetricReader({
        exporter: new OTLPMetricExporter(),
    }),
    instrumentations: [getNodeAutoInstrumentations(), new AzureFunctionsInstrumentation()],
});

sdk.start()

export async function shutdownOTel() {
    await sdk.shutdown();
}

// This alternate version is based on the Azure Functions specific OpenTelemetry guidance, which is outdated and should be avoided.
// import { AzureFunctionsInstrumentation } from '@azure/functions-opentelemetry-instrumentation';
// import { getNodeAutoInstrumentations, getResourceDetectors } from '@opentelemetry/auto-instrumentations-node';
// import { OTLPLogExporter } from '@opentelemetry/exporter-logs-otlp-grpc';
// import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-grpc';
// import { OTLPMetricExporter } from '@opentelemetry/exporter-metrics-otlp-grpc';
// import { registerInstrumentations } from '@opentelemetry/instrumentation';
// import { detectResources } from '@opentelemetry/resources';
// import { LoggerProvider, SimpleLogRecordProcessor } from '@opentelemetry/sdk-logs';
// import { NodeTracerProvider, SimpleSpanProcessor } from '@opentelemetry/sdk-trace-node';
// import { MeterProvider, PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics';

// if (process.env.NODE_OPTIONS?.includes('@opentelemetry/auto-instrumentations-node/register')) {
//     throw new Error(
//         'Remove the OpenTelemetry auto-instrumentation preload from NODE_OPTIONS; this application registers its own providers.'
//     );
// }

// const resource = detectResources({ detectors: getResourceDetectors() });

// const tracerProvider = new NodeTracerProvider({
//     resource: resource,
//     spanProcessors: [new SimpleSpanProcessor(new OTLPTraceExporter())]
// });
// tracerProvider.register();

// const loggerProvider = new LoggerProvider({
//     resource: resource,
//     processors: [new SimpleLogRecordProcessor({
//         exporter: new OTLPLogExporter()
//     })]
// });

// const meterProvider = new MeterProvider({
//     resource: resource,
//     readers: [new PeriodicExportingMetricReader({
//         exporter:  new OTLPMetricExporter(),
//         exportIntervalMillis: 10000,
//     })],
// });

// registerInstrumentations({
//     tracerProvider,
//     loggerProvider,
//     meterProvider,
//     instrumentations: [getNodeAutoInstrumentations(), new AzureFunctionsInstrumentation()],
// });

// console.log('OpenTelemetry SDK initialized');
