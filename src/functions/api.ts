import {
    app,
    HttpRequest,
    HttpResponseInit,
    InvocationContext,
} from '@azure/functions';
import { redisClient } from '../index';
import { redisOperationMeter, redisOperationHistogram } from '../metrics';
import { tracer, withInvocationSpan } from '../trace';
import { logger } from '../logger';
import { Span, SpanKind, SpanStatusCode } from '@opentelemetry/api';

async function isReady(): Promise<boolean> {
    // Not every local function call must be traced, but we do it here for demonstration purposes.
    return await tracer.startActiveSpan(
        'isReady',
        { kind: SpanKind.INTERNAL },
        async (activeSpan) => {
            const isReady = redisClient.isReady;
            activeSpan.end();
            return isReady;
        }
    );
}

export async function incr(
    request: HttpRequest,
    _context: InvocationContext,
    activeSpan: Span
): Promise<HttpResponseInit> {
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
    logger.debug({ incr_count: count }, 'Incremented count in Redis');

    return {
        jsonBody: {
            count,
        },
    };
}

export async function about(
    request: HttpRequest,
    _context: InvocationContext,
    _span: Span
): Promise<HttpResponseInit> {
    logger.info({ request_url: request.url }, 'Processing request');
    const consumerGroup = process.env.ConsumerGroup || 'not set';
    const redisReady = await isReady();
    return {
        jsonBody: {
            redisReady,
            consumerGroup,
        },
    };
}

export async function fail(
    request: HttpRequest,
    _context: InvocationContext,
    activeSpan: Span
): Promise<HttpResponseInit> {
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
}

app.http('about', {
    methods: ['GET'],
    authLevel: 'anonymous',
    handler: withInvocationSpan(about),
});

app.http('incr', {
    methods: ['GET'],
    authLevel: 'anonymous',
    handler: withInvocationSpan(incr),
});

app.http('fail', {
    methods: ['POST'],
    authLevel: 'anonymous',
    handler: withInvocationSpan(fail),
});
