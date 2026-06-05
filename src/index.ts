import { app, AppStartContext, PostInvocationContext, PreInvocationContext } from '@azure/functions';

import { createClient, RedisClientType } from "redis";

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
