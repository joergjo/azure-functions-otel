import opentelemetry from '@opentelemetry/api';

const serviceName = process.env.OTEL_SERVICE_NAME || 'demo-function-app';

const meter = opentelemetry.metrics.getMeter(serviceName, '0.1.0');
export const redisOperationMeter = meter.createCounter(`${serviceName}.redis_operations`);
