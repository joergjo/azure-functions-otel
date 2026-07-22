# Copilot Instructions

Azure Functions (Node.js/TypeScript, programming model v4) sample demonstrating manual OpenTelemetry instrumentation, exporting to Azure Monitor via an OpenTelemetry Collector. Triggers: HTTP and Event Hub. Uses Redis for shared state.

## Build, run, test

- `npm run build` — compile TypeScript (`tsc`) to `dist/`.
- `npm run watch` — incremental compile.
- `npm start` — runs `func start`. `prestart` cleans + rebuilds first.
- `npm run clean` — remove `dist/`.
- There is **no test suite**; `npm test` just echoes a placeholder. Do not assume tests exist.
- Local run requires dependencies from `docker compose up -d` (Redis, Azurite, OTel Collector) and a populated `local.settings.json` (copy from `local.settings.template.json`).

## Architecture

- **`src/index.ts` is the bootstrap module and must load first.** It sets up OpenTelemetry providers (tracer + logger via OTLP exporters, `AzureFunctionsInstrumentation`, node auto-instrumentations), registers `app.hook` lifecycle handlers, and creates the singleton `redisClient` in the `appStart` hook. `redisClient` is exported and imported by function modules — do not create additional Redis clients.
- **Functions self-register via side effects.** Each module under `src/functions/` calls `app.http(...)` / `app.eventHub(...)` at import time; there is no central router. `package.json` `main` glob (`dist/src/{index.js,functions/*.js}`) is what loads them.
- **Telemetry pipeline:** app → OTLP → Collector → Azure Monitor. `host.json` sets `telemetryMode: OpenTelemetry`. Local collector config is `config/collector.yaml` (exports to Jaeger/Prometheus); `config/collector.azure.yaml` exports to Azure Monitor using the env vars in `.envrc` / `compose.yaml`.
- **Infrastructure:** `infra/main.bicep` provisions a Flex Consumption Function App using **managed identity only** (shared key access disabled), plus Event Hub namespace, App Insights, Log Analytics, and storage. Deploy with `./deploy.sh` (requires `FUNCTIONS_RESOURCE_GROUP_NAME`).

## Conventions

- **Binding values use app-setting expansion**, e.g. `eventHubName: '%EventHubName%'`, `connection: 'EventHubConnectionString'` — the `%NAME%` syntax reads from settings, not literal strings.
- **`ConsumerGroup` doubles as a deployment-slot / environment gate.** `message-handler.ts` treats only `blue` and `$Default` as production; other values cause messages to be discarded. Preserve this check when editing message handling.
- **Intentional failure injection:** `message-handler.ts` calls `process.exit(1)` when the Redis key `fail` is `on` (set via the `fail` HTTP function). This is deliberate chaos-testing behavior, not a bug.
- TypeScript is compiled with `strict: false`, `target: es6`, `module: commonjs`. Keep new code CommonJS-compatible.
- Secrets belong in `local.settings.json` / `.envrc` (both gitignored) — never commit connection strings or credentials.
