import { app, InvocationContext } from '@azure/functions';
import { redisClient } from '../index';
import { tracer } from '../trace';
import { logger } from '../logger';

const productionSlots = ['blue', '$Default'];

interface MessageType {
    eventData: string;
    route: string;
}

export async function invoke(
    messages: MessageType | MessageType[],
    _context: InvocationContext
): Promise<void> {
    if (!isProduction()) {
        logger.info(
            'Running in non-production environment, discarding messages.'
        );
        return;
    }
    const mustCrash = await tracer.startActiveSpan(
        'message-handler',
        async (span) => {
            try {
                const messageCount = Array.isArray(messages)
                    ? messages.length
                    : 1;
                span.setAttribute('message.count', messageCount);
                logger.info({ messageCount }, 'Processing messages');
                if (Array.isArray(messages)) {
                    for (const message of messages) {
                        await handleMessage(message);
                    }
                } else {
                    await handleMessage(messages);
                }
                return false;
            } catch (error) {
                logger.error({ error: error }, 'Error processing messages');
                span.recordException(error as Error);
                return true;
            } finally {
                span.end();
            }
        }
    );

    if (mustCrash) {
        logger.fatal('Crashing due to message handling failure');
        process.exit(1);
    }
}

async function handleMessage(message: MessageType): Promise<void> {
    if (!redisClient.isReady || (await redisClient.get('fail')) === 'on') {
        throw new Error('Redis is not ready or fail flag is set to on');
    }

    await redisClient.incr('messages:processed');
    logger.info(
        { payload: message.eventData, route: message.route },
        'Message handled'
    );
}

function isProduction(): boolean {
    return productionSlots.includes(process.env.ConsumerGroup || '');
}

app.eventHub('messageHandler', {
    connection: 'EventHubConnectionString',
    eventHubName: '%EventHubName%',
    consumerGroup: '%ConsumerGroup%',
    cardinality: 'many',
    handler: invoke,
    retry: {
        strategy: 'fixedDelay',
        delayInterval: {
            seconds: 1,
        },
        maxRetryCount: 1,
    },
});
