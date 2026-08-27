# Copilot Instructions

Azure Functions Node.js/TypeScript sample using the programming model v4. It uses both OpenTelemetry auto-instrumentation and manual instrumentaion for HTTP and Event Hub functions, sends OTLP telemetry through an OpenTelemetry Collector, and uses Redis for shared state and failure injection.

Note that the instrumentation bootstrapping code follows the OpenTelemetry guidelines for Node.js applications,
and not the Azure Functions-specific OpenTelemetry guidance, which is outdated and should be avoided.

## Build, run, and validation

- `npm install` — install Node.js dependencies.
- `npm run build` — compile TypeScript with `tsc` into `dist/`.
- `npm run watch` — run the TypeScript compiler in watch mode.
- `npm run clean` — remove `dist/`.
- `npm start` — clean, build, then run `func start`.
- `npm test` — placeholder only; there is no test suite and therefore no single-test command.
- There is no configured lint command.
- `az bicep build --file infra/main.bicep` — compile and validate the complete Bicep deployment.
- `bash -n deploy.sh create-sp.sh` — syntax-check the deployment scripts.
- Local execution requires `docker compose up -d` for Redis, Azurite, and the OTel Collector, plus `local.settings.json` copied from `local.settings.template.json`.

## Application architecture

- `src/index.ts` is the application bootstrap and must be loaded before function modules. `package.json` uses `dist/src/{index.js,functions/*.js}` so the bootstrap and self-registering function modules are discovered by the Functions host.
- Importing `./instrumentation` from `src/index.ts` starts the `NodeSDK` before `@azure/functions` is evaluated. It configures OTLP/gRPC trace, metric, and log exporters, Node auto-instrumentations, and `AzureFunctionsInstrumentation`; `appTerminate` shuts it down.
- Functions register themselves through module side effects:
  - `src/functions/api.ts` registers anonymous `/api/about`, `/api/incr`, and `/api/fail` HTTP functions.
  - `src/functions/message-handler.ts` registers the Event Hub trigger.
- `src/index.ts` creates the single Redis client in the `appStart` hook and exports it. Function modules import this live binding; do not create additional Redis clients.
- `src/trace.ts` and `src/metrics.ts` expose the application tracer and Redis-operation counter. Their instrumentation scope name comes from `OTEL_SERVICE_NAME`, with `demo-function-app` as the fallback.
- `host.json` enables Functions host OpenTelemetry output with `telemetryMode: OpenTelemetry`.

## Telemetry paths

- Local path: Functions app → OTLP/gRPC on `localhost:4317` → collector from `compose.yaml`.
- `config/collector.azure.yaml` is mounted by Docker Compose and exports traces, logs, and metrics to the Azure Monitor OTLP endpoints using service-principal environment variables.
- `config/collector.yaml` is the local Jaeger/Prometheus alternative; it is not the collector config currently mounted by `compose.yaml`.
- Azure path: Function App → HTTPS App Service endpoint → `otel/opentelemetry-collector-contrib` → Azure Monitor.
- `config/collector.deployed.yaml` is embedded by `infra/modules/storage.bicep`, uploaded to the public `config` blob container by an Azure CLI deployment script, and passed to the collector App Service through `--config=<blob-url>`.
- The collector App Service routes OTLP/HTTP to port 4318 and gRPC to port 4317 using `WEBSITES_PORT`, `HTTP20_ONLY_PORT`, HTTP/2, and the gRPC proxy.

## Azure infrastructure

- `infra/main.bicep` is the orchestrator. Preserve module-output references because they intentionally establish deployment dependencies.
- `monitoring.bicep` creates Log Analytics, an Azure Monitor workspace, and Application Insights. Application Insights implicitly creates the DCR; the module exposes the DCR resource ID and OTLP ingestion endpoints from Application Insights properties.
- `storage.bicep` creates the public collector-config blob and uploads `config/collector.deployed.yaml`.
- `appservice.bicep` runs the collector and receives the config URL, Azure Monitor endpoints, and service-principal credentials.
- `redis.bicep` creates Azure Managed Redis with an encrypted default database on port 10000.
- `functions.bicep` creates the Flex Consumption Function App, its deployment storage, user-assigned identity, role assignments, and application settings. Function runtime storage uses managed identity with shared-key access disabled.
- `eventhubs.bicep` creates the namespace and sample hub. The generated `EventHubConnectionString` is namespace-scoped; `EventHubName` selects the entity separately, so do not add `EntityPath`.
- `deploy.sh` requires `FUNCTIONS_RESOURCE_GROUP_NAME`, `CLIENT_ID`, `CLIENT_SECRET`, and `TENANT_ID`. It deploys Bicep, then grants the collector service principal Monitoring Metrics Publisher on the implicitly created DCR. Application code is published separately with the printed `func azure functionapp publish ...` command.

## Repository-specific conventions

- Binding settings use Functions app-setting expansion. For example, `eventHubName: '%EventHubName%'` and `consumerGroup: '%ConsumerGroup%'` resolve settings, while `connection: 'EventHubConnectionString'` names the connection setting.
- `ConsumerGroup` is also an environment gate. `message-handler.ts` processes messages only for `blue` and `$Default`; other values intentionally discard messages.
- The Redis `fail` key is deliberate chaos testing. `/api/fail` sets it, and the Event Hub handler converts Redis unavailability or `fail=on` into `process.exit(1)` after recording the span error. Do not “fix” this crash behavior.
- Keep the collector environment-variable names synchronized across Bicep, Compose, and collector YAML: `CLIENT_ID`, `CLIENT_SECRET`, `TENANT_ID`, `TRACES_ENDPOINT`, `LOGS_ENDPOINT`, and `METRICS_ENDPOINT`.
- The Function App receives `OTEL_EXPORTER_OTLP_ENDPOINT` as `https://<collector-app-host>`, Redis as `rediss://<managed-redis-host>:<database-port>`, and the Redis primary key separately as `RedisPassword`.
- Bicep secrets such as `clientSecret` must remain `@secure()`. Local credentials and connection strings belong in gitignored `local.settings.json` or `.envrc`.
- TypeScript compiles with `module: commonjs`, `target: es6`, and `strict: false`; keep additions compatible with this configuration.
