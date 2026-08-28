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
import { SpanKind } from '@opentelemetry/api';

async function isReady(): Promise<boolean> {
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

export async function about(
    request: HttpRequest,
    _context: InvocationContext
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

export async function incr(
    request: HttpRequest,
    _context: InvocationContext
): Promise<HttpResponseInit> {
    logger.info({ request_url: request.url }, 'Processing request');
    const failFast = !(await isReady());
    if (failFast) {
        return { status: 503, body: 'Redis is not ready' };
    }

    const startTime = Date.now();
    const operation = 'incr.count';
    const count = await redisClient.incr(operation);
    const duration = Date.now() - startTime;
    redisOperationHistogram.record(duration, { operation: operation });
    redisOperationMeter.add(1, { operation: operation });
    logger.debug({ incr_count: count }, 'Incremented count in Redis');

    return {
        jsonBody: {
            count,
        },
    };
}

export async function fail(
    request: HttpRequest,
    _context: InvocationContext
): Promise<HttpResponseInit> {
    logger.info({ request_url: request.url }, 'Processing request');
    if (!redisClient.isReady) {
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
