import opentelemetry from '@opentelemetry/api';

const meter = opentelemetry.metrics.getMeter('sample.functionapp', '0.1.0');
const redisOperationMeter = meter.createCounter('cache.operations');
const redisOperationHistogram = meter.createHistogram(
    'cache.operation_duration'
);

export { redisOperationMeter, redisOperationHistogram };
