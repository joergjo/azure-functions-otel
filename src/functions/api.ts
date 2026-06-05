import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import { redisClient } from "../index";

export async function about(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    context.log(`Processing request for url "${request.url}"`);
    const consumerGroup = process.env.ConsumerGroup || 'unknown';
    return { body: consumerGroup };
};

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
