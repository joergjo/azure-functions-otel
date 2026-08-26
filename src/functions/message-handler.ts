import { app, InvocationContext } from "@azure/functions";
import { redisClient } from "../index";
import { tracer } from "../trace";

const productionSlots = ['blue', '$Default'];

interface MessageType {
    eventData: string;
    route: string;
}

export async function invoke(messages: MessageType | MessageType[], context: InvocationContext): Promise<void> {
    if (!isProduction()) {
        console.log('Running in non-production environment. Discarding messages.');
        return;
    }
    const mustCrash = await tracer.startActiveSpan('message-handler', async (span) => {
        try {
            if (Array.isArray(messages)) {
                const messageCount = messages.length;
                span.setAttribute('message.count', messageCount);
                console.log(`Message handler received batch of ${messageCount} messages`);
                for (const message of messages) {
                    await handleMessage(message, context);
                }
            } else {
                span.setAttribute('message.count', 1);
                await handleMessage(messages, context);
            }
            return false;
        } catch (error) {
            span.recordException(error as Error);
            return true;
        } finally {
            span.end();
        }
    });

    if (mustCrash) {
        process.exit(1);
    }
}

async function handleMessage(message: MessageType, context: InvocationContext): Promise<void> {
    if (!redisClient.isReady || (await redisClient.get('fail')) === 'on') {
        throw new Error('Redis is not ready or fail flag is set to on');
    }

    const processedCount = await redisClient.incr('messages:processed');

    console.log(`Message handler received message ${message.eventData} for route ${message.route}. Processed count: ${processedCount}`);
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
        maxRetryCount: 1
    }
});
