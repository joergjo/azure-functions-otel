import { app, InvocationContext } from "@azure/functions";
import { redisClient } from "../index";

const productionSlots = ['blue', '$Default'];

interface MessageType {
    eventData: string;
    route: string;
}

export async function invoke(messages: MessageType | MessageType[], context: InvocationContext): Promise<void> {
    if (!isProduction()) {
        context.log('Running in non-production environment. Discarding messages.');
        return;
    }
    if (Array.isArray(messages)) {
        context.log(`Message handler received batch of ${messages.length} messages`);
        for (const message of messages) {
            await handleMessage(message, context);
        }
    } else {
        await handleMessage(messages, context);
    }
}

async function handleMessage(message: MessageType, context: InvocationContext): Promise<void> {
    if (!redisClient.isReady || (await redisClient.get('fail')) === 'on') {
        process.exit(1);
    }

    context.log(`Message handler received message ${message.eventData} for route ${message.route}`);
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
