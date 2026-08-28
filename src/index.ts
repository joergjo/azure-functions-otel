import { shutdownOTel } from './instrumentation';
import {
    app,
    AppStartContext,
    PostInvocationContext,
    PreInvocationContext,
} from '@azure/functions';
import { createClient, RedisClientType } from 'redis';
import { logger } from './logger';

let redisClient: RedisClientType;

// app.hook.preInvocation((context: PreInvocationContext) => {
//     if (context.invocationContext.options.trigger.type === 'eventHubTrigger') {
//         context.invocationContext.log(
//             `preInvocation hook executed for event hub function ${context.invocationContext.functionName}`,
//         );
//     }
// });

// app.hook.postInvocation(async (context: PostInvocationContext) => {
//     if (context.invocationContext.options.trigger.type === 'eventHubTrigger') {
//         context.invocationContext.log(
//             `postInvocation hook executed for event hub function ${context.invocationContext.functionName}`,
//         );
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
