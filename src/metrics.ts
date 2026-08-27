import opentelemetry from '@opentelemetry/api';

const serviceName = process.env.OTEL_SERVICE_NAME || 'demo-function-app';

const meter = opentelemetry.metrics.getMeter(serviceName, '0.1.0');
const redisOperationMeter = meter.createCounter(`${serviceName}.redis_operations`);
const redisOperationHistogram = meter.createHistogram(`${serviceName}.redis_operation_duration`);

export {
  redisOperationMeter,
  redisOperationHistogram
};
