import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import { redisClient } from "../index";
import { redisOperationMeter } from "../metrics";
import { tracer } from "../trace";
import { SpanKind } from "@opentelemetry/api";

export async function about(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    context.log(`Processing request for url "${request.url}"`);
    const failFast = !(await isReady());
    if (failFast) {
        return { status: 503, body: 'Redis is not ready' };
    }
    const requestCount = await incr('about:requests');
    const consumerGroup = process.env.ConsumerGroup || 'unknown';
    return {
        jsonBody: {
            consumerGroup,
            requestCount
        }
    };
};

async function isReady(): Promise<boolean> {
    return await tracer.startActiveSpan('isReady', { kind: SpanKind.INTERNAL }, async (span) => {
        console.log(`Active span for isReady: ${span.spanContext().spanId}`);
        const isReady = redisClient.isReady
        span.end();
        return isReady;
    });
}

async function incr(operation: string): Promise<number> {
    const count = await redisClient.incr(`${operation}.count`);
    redisOperationMeter.add(1, { operation: operation });
    return count;
}

export async function fail(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    context.log(`Processing request for url "${request.url}"`);
    if (!redisClient.isReady) {
        return { status: 503, body: 'Redis is not ready' };
    }

    const val = await request.text() || 'off';
    await redisClient.set('fail', val);
    return { body: val };
};


app.http('about', {
    methods: ['GET'],
    authLevel: 'anonymous',
    handler: about
});

app.http('fail', {
    methods: ['POST'],
    authLevel: 'anonymous',
    handler: fail
});
