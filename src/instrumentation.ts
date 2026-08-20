import { AzureFunctionsInstrumentation } from '@azure/functions-opentelemetry-instrumentation';
import { getNodeAutoInstrumentations, getResourceDetectors } from '@opentelemetry/auto-instrumentations-node';
import { OTLPLogExporter } from '@opentelemetry/exporter-logs-otlp-grpc';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-grpc';
import { OTLPMetricExporter } from '@opentelemetry/exporter-metrics-otlp-grpc';
import { registerInstrumentations } from '@opentelemetry/instrumentation';
import { detectResources } from '@opentelemetry/resources';
import { LoggerProvider, SimpleLogRecordProcessor } from '@opentelemetry/sdk-logs';
import { NodeTracerProvider, SimpleSpanProcessor } from '@opentelemetry/sdk-trace-node';
import { MeterProvider, PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics';

if (process.env.NODE_OPTIONS?.includes('@opentelemetry/auto-instrumentations-node/register')) {
    throw new Error(
        'Remove the OpenTelemetry auto-instrumentation preload from NODE_OPTIONS; this application registers its own providers.'
    );
}

const resource = detectResources({ detectors: getResourceDetectors() });

const tracerProvider = new NodeTracerProvider({
    resource: resource,
    spanProcessors: [new SimpleSpanProcessor(new OTLPTraceExporter())]
});
tracerProvider.register();

const loggerProvider = new LoggerProvider({
    resource: resource,
    processors: [new SimpleLogRecordProcessor({
        exporter: new OTLPLogExporter()
    })]
});

const meterProvider = new MeterProvider({
    resource: resource,
    readers: [new PeriodicExportingMetricReader({
        exporter:  new OTLPMetricExporter(),
        exportIntervalMillis: 10000,
    })],
});

registerInstrumentations({
    tracerProvider,
    loggerProvider,
    meterProvider,
    instrumentations: [getNodeAutoInstrumentations(), new AzureFunctionsInstrumentation()],
});

console.log('OpenTelemetry SDK initialized');
