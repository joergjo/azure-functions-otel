import { InvocationContext } from '@azure/functions';
import opentelemetry, {
    Span,
    SpanKind,
    SpanOptions,
    SpanStatusCode,
} from '@opentelemetry/api';
import { getInvocationAttributes } from './attributes';

const serviceName = process.env.OTEL_SERVICE_NAME || 'demo-function-app';

export const tracer = opentelemetry.trace.getTracer(serviceName, '0.1.0');

type InvocationHandler<TInput, TResult> = (
    input: TInput,
    context: InvocationContext,
    span: Span
) => TResult | Promise<TResult>;

export function withInvocationSpan<TInput, TResult>(
    handler: InvocationHandler<TInput, TResult>,
    options: SpanOptions = {},
    name?: string
): (input: TInput, context: InvocationContext) => Promise<TResult> {
    return async (input, context) =>
        tracer.startActiveSpan(
            name ?? context.functionName,
            {
                kind: options.kind ?? SpanKind.INTERNAL,
                ...options,
                attributes: {
                    ...getInvocationAttributes(context),
                    ...options.attributes,
                },
            },
            async (span) => {
                try {
                    const result = await handler(input, context, span);
                    span.setStatus({ code: SpanStatusCode.OK });
                    return result;
                } catch (error) {
                    span.recordException(error as Error);
                    span.setStatus({ code: SpanStatusCode.ERROR });
                    throw error;
                } finally {
                    span.end();
                }
            }
        );
}
