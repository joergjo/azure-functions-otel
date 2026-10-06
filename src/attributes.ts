import { Attributes } from '@opentelemetry/api';

import { ATTR_HTTP_ROUTE } from '@opentelemetry/semantic-conventions';
import {
    ATTR_FAAS_NAME,
    ATTR_FAAS_INSTANCE,
    ATTR_FAAS_TRIGGER,
    ATTR_FAAS_INVOCATION_ID,
    FAAS_TRIGGER_VALUE_DATASOURCE,
    FAAS_TRIGGER_VALUE_HTTP,
    FAAS_TRIGGER_VALUE_OTHER,
    FAAS_TRIGGER_VALUE_PUBSUB,
    FAAS_TRIGGER_VALUE_TIMER,
} from './semconv';
import { InvocationContext } from '@azure/functions';

export function getInvocationAttributes(
    context: InvocationContext
): Attributes {
    const trigger = context.options.trigger;
    const attributes: Attributes = {};

    switch (trigger.type) {
        case 'httpTrigger':
            attributes[ATTR_FAAS_TRIGGER] = FAAS_TRIGGER_VALUE_HTTP;
            attributes[ATTR_HTTP_ROUTE] =
                typeof trigger.route === 'string'
                    ? trigger.route
                    : context.functionName;
            break;

        case 'timerTrigger':
            attributes[ATTR_FAAS_TRIGGER] = FAAS_TRIGGER_VALUE_TIMER;
            break;

        case 'eventHubTrigger':
        case 'serviceBusTrigger':
        case 'queueTrigger':
        case 'eventGridTrigger':
            attributes[ATTR_FAAS_TRIGGER] = FAAS_TRIGGER_VALUE_PUBSUB;
            break;

        case 'blobTrigger':
        case 'cosmosDBTrigger':
            attributes[ATTR_FAAS_TRIGGER] = FAAS_TRIGGER_VALUE_DATASOURCE;
            break;

        default:
            attributes[ATTR_FAAS_TRIGGER] = FAAS_TRIGGER_VALUE_OTHER;
    }
    attributes[ATTR_FAAS_NAME] = context.functionName;
    const hostInstanceId = context.traceContext?.attributes?.['HostInstanceId'];
    if (hostInstanceId) {
        attributes[ATTR_FAAS_INSTANCE] = hostInstanceId;
    }
    attributes[ATTR_FAAS_INVOCATION_ID] = context.invocationId;

    return attributes;
}
