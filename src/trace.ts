import opentelemetry from '@opentelemetry/api';

const serviceName = process.env.OTEL_SERVICE_NAME || 'demo-function-app';

export const tracer = opentelemetry.trace.getTracer(serviceName, '0.1.0');
