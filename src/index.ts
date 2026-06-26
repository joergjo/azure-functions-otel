import { app, AppStartContext, PostInvocationContext, PreInvocationContext } from '@azure/functions';

import { createClient, RedisClientType } from "redis";

import { AzureFunctionsInstrumentation } from '@azure/functions-opentelemetry-instrumentation';
import { getNodeAutoInstrumentations, getResourceDetectors } from '@opentelemetry/auto-instrumentations-node';
import { OTLPLogExporter } from '@opentelemetry/exporter-logs-otlp-http';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { registerInstrumentations } from '@opentelemetry/instrumentation';
import { detectResources } from '@opentelemetry/resources';
import { LoggerProvider, SimpleLogRecordProcessor } from '@opentelemetry/sdk-logs';
import { NodeTracerProvider, SimpleSpanProcessor } from '@opentelemetry/sdk-trace-node';

const resource = detectResources({ detectors: getResourceDetectors() });

const tracerProvider = new NodeTracerProvider({
    resource: resource,
    spanProcessors: [new SimpleSpanProcessor(new OTLPTraceExporter())]
});
tracerProvider.register();

const loggerProvider = new LoggerProvider({
    resource: resource,
    processors: [new SimpleLogRecordProcessor(new OTLPLogExporter())]
});

registerInstrumentations({
    tracerProvider,
    loggerProvider,
    instrumentations: [getNodeAutoInstrumentations(), new AzureFunctionsInstrumentation()],
});

let redisClient: RedisClientType;

app.hook.preInvocation((context: PreInvocationContext) => {
    if (context.invocationContext.options.trigger.type === 'eventHubTrigger') {
        context.invocationContext.log(
            `preInvocation hook executed for event hub function ${context.invocationContext.functionName}`
        );
    }
});

app.hook.postInvocation(async (context: PostInvocationContext) => {
    if (context.invocationContext.options.trigger.type === 'eventHubTrigger') {
        context.invocationContext.log(
            `postInvocation hook executed for event hub function ${context.invocationContext.functionName}`
        );
    }
});

app.hook.appStart(async (_: AppStartContext) => {
    console.log('App is starting up...');

    redisClient = createClient({
        url: process.env.RedisConnectionString, password: process.env.RedisPassword, socket: {
            connectTimeout: 100,
            reconnectStrategy: (_) => false
        }
    });
    redisClient.on('error', err => console.log('Redis Client Error', err));
    console.log('Connecting to Redis...');
    await redisClient.connect();
    console.log('Connected to Redis');
});

export { redisClient };
