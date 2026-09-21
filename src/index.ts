import { shutdownOTel } from './instrumentation';
import { app, AppStartContext } from '@azure/functions';
import { createClient, RedisClientType } from 'redis';
import { logger } from './logger';

let redisClient: RedisClientType;

// This a sample setup for OpenTelemetry context propagation in Azure Functions.
// Unfortunately, we cannot override the hooks registered by the Azure Functions instrumentation
// package, so our choice is to either work within the constraints of the existing hooks
// or implement our own context propagation mechanism and don't use the Azure Functions
// instrumentation at all.
// const ACTIVE_SPAN_KEY = '__otel_Azure_funtion_active_span';
// interface Carrier {
//     traceparent?: string;
//     tracestate?: string;
// }

// app.hook.preInvocation(async (context: PreInvocationContext) => {
//     if (context.invocationContext.options.trigger.type === 'httpTrigger') {
//         const carrier: Carrier = {
//             traceparent: context.invocationContext.traceContext.traceParent,
//         };

//         const currentContext = propagation.extract(ROOT_CONTEXT, carrier);

//         const resource = detectResources();
//         const span = tracer.startSpan(
//             context.invocationContext.functionName,
//             {
//                 kind: SpanKind.SERVER,
//                 attributes: resource.attributes,
//             },
//             currentContext
//         );
//         otelContext.bind(
//             trace.setSpan(currentContext, span),
//             context.functionHandler
//         );
//         context.hookData[ACTIVE_SPAN_KEY] = span;
//     }
// });

// app.hook.postInvocation(async (context: PostInvocationContext) => {
//     const span = context.hookData[ACTIVE_SPAN_KEY] as Span;
//     if (span) {
//         if (context.invocationContext.options.trigger.type === 'httpTrigger') {
//             span.setAttribute(
//                 ATTR_HTTP_RESPONSE_STATUS_CODE,
//                 (context.result as string) || 0
//             );

//             if (context.error) {
//                 span.recordException(context.error as Error);
//                 span.setStatus({ code: SpanStatusCode.ERROR });
//             }
//         }
//         span.end();
//     }
// });

app.hook.appStart(async (_: AppStartContext) => {
    logger.info('Function app is starting up');

    redisClient = createClient({
        url: process.env.RedisConnectionString,
        password: process.env.RedisPassword,
        socket: {
            connectTimeout: 100,
            reconnectStrategy: (_) => false,
        },
    });
    redisClient.on('error', (err) =>
        logger.error({ error: err }, 'Redis error')
    );
    logger.debug('Connecting to Redis');
    await redisClient.connect();
    logger.debug('Connected to Redis');
});

app.hook.appTerminate(async () => {
    await shutdownOTel();
    logger.info('Function app is shutting down');
});

export { redisClient };
