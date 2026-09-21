import {
    app,
    HttpRequest,
    HttpResponseInit,
    InvocationContext,
} from '@azure/functions';
import { redisClient } from '../index';
import { redisOperationMeter, redisOperationHistogram } from '../metrics';
import { tracer } from '../trace';
import { logger } from '../logger';
import { SpanKind, SpanStatusCode } from '@opentelemetry/api';

async function isReady(): Promise<boolean> {
    // Not every local function call must be traced, but we do it here for demonstration purposes.
    return await tracer.startActiveSpan(
        'isReady',
        { kind: SpanKind.INTERNAL },
        async (span) => {
            const isReady = redisClient.isReady;
            span.end();
            return isReady;
        }
    );
}

export async function incr(
    request: HttpRequest,
    context: InvocationContext
): Promise<HttpResponseInit> {
    // Since the Azure Functions instrumentation only sets the context for the current invocation,
    // we need to manually create a new span for our operation. If we didn't do this, incr() and other
    // Azure Functions would run with a NonRecordingSpan, which discards any changes applied to it like
    // setAttribute, addEvent, etc.
    return await tracer.startActiveSpan(
        context.functionName,
        { kind: SpanKind.INTERNAL },
        async (activeSpan) => {
            try {
                logger.info({ request_url: request.url }, 'Processing request');
                const failFast = !(await isReady());
                if (failFast) {
                    activeSpan.setStatus({
                        code: SpanStatusCode.ERROR,
                        message: 'Redis is not ready',
                    });
                    return { status: 503, body: 'Redis is not ready' };
                }

                const startTime = Date.now();
                const operation = 'incr.count';
                const count = await redisClient.incr(operation);
                const duration = Date.now() - startTime;
                redisOperationHistogram.record(duration, {
                    operation: operation,
                });
                redisOperationMeter.add(1, { operation: operation });

                activeSpan.setAttribute('app.incr.result', count);
                logger.debug(
                    { incr_count: count },
                    'Incremented count in Redis'
                );

                return {
                    jsonBody: {
                        count,
                    },
                };
            } finally {
                activeSpan.end();
            }
        }
    );
}

export async function about(
    request: HttpRequest,
    context: InvocationContext
): Promise<HttpResponseInit> {
    return await tracer.startActiveSpan(
        context.functionName,
        { kind: SpanKind.INTERNAL },
        async (activeSpan) => {
            try {
                logger.info({ request_url: request.url }, 'Processing request');
                const consumerGroup = process.env.ConsumerGroup || 'not set';
                const redisReady = await isReady();
                return {
                    jsonBody: {
                        redisReady,
                        consumerGroup,
                    },
                };
            } finally {
                activeSpan.end();
            }
        }
    );
}

export async function fail(
    request: HttpRequest,
    context: InvocationContext
): Promise<HttpResponseInit> {
    return await tracer.startActiveSpan(
        context.functionName,
        { kind: SpanKind.INTERNAL },
        async (activeSpan) => {
            try {
                logger.info({ request_url: request.url }, 'Processing request');
                if (!redisClient.isReady) {
                    activeSpan.setStatus({
                        code: SpanStatusCode.ERROR,
                        message: 'Redis is not ready',
                    });
                    return { status: 503, body: 'Redis is not ready' };
                }

                const val = (await request.text()) || 'off';
                await redisClient.set('fail', val);
                logger.debug({ fail_value: val }, 'Set fail flag');
                return { body: val };
            } finally {
                activeSpan.end();
            }
        }
    );
}

app.http('about', {
    methods: ['GET'],
    authLevel: 'anonymous',
    handler: about,
});

app.http('incr', {
    methods: ['GET'],
    authLevel: 'anonymous',
    handler: incr,
});

app.http('fail', {
    methods: ['POST'],
    authLevel: 'anonymous',
    handler: fail,
});
