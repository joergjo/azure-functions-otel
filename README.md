# Azure Functions + OpenTelemetry Sample

This sample runs an Azure Functions app locally with Redis, Azurite, and an OpenTelemetry Collector provided by Docker Compose. Telemetry is exported to Azure Monitor via the collector.

## Azure Prerequisites

This app expects these Azure resources to already exist:

- Application Insights with OpenTelemetry enabled
- An Azure Event Hub namespace and an Event Hub named `debug`

## Local Prerequisites

- Node.js 24 LTS
- npm 11 (included in Node.js)
- Azure Functions Core Tools v4
- Docker Desktop (or compatible container runtime)

## Configure Local Settings

1. Copy the template file.

```bash
cp local.settings.template.json local.settings.json
```

2. Update `local.settings.json` values:

- `EventHubConnectionString`: Full Event Hub connection string including `EntityPath=debug`
- `EventHubName`: `debug`
- `ConsumerGroup`: Usually `$Default`
- `RedisConnectionString`: Keep `redis://localhost:6379` for local Docker
- `RedisPassword`: Leave empty for local Docker (no password)
- `OTEL_EXPORTER_OTLP_ENDPOINT`: Keep `http://localhost:4317` for local Docker collector
- `OTEL_SERVICE_NAME`: A name for this app in traces and logs (e.g. `demo-function-app`)

## Configure Azure Monitor Credentials for the Collector

The Docker Compose setup uses `config/collector.azure.yaml`, which exports telemetry to Azure Monitor using a service principal. Set the following environment variables before running `docker compose up`:

```bash
export CLIENT_ID="<service-principal-client-id>"
export CLIENT_SECRET="<service-principal-client-secret>"
export TENANT_ID="<azure-tenant-id>"
export TRACES_ENDPOINT="<azure-monitor-otlp-traces-endpoint>"
export LOGS_ENDPOINT="<azure-monitor-otlp-logs-endpoint>"
export METRICS_ENDPOINT="<azure-monitor-otlp-metrics-endpoint>"
```

These values are conveniently printed by `./deploy.sh` after a successful deployment (see [Deploy to Azure](#deploy-to-azure)). Store them in `.envrc` (gitignored) and use a tool like [direnv](https://direnv.net/) to load them automatically.

> **Note:** A second collector configuration, `config/collector.yaml`, exports to a local Jaeger instance and a Prometheus endpoint instead of Azure Monitor. To use it, update the `collector` service volume mount in `compose.yaml` to point to `./config/collector.yaml`.

## Start Dependencies (Docker Compose)

Start Redis, Azurite, and the OpenTelemetry Collector:

```bash
docker compose up -d
```

Check container status:

```bash
docker compose ps
```

Stop dependencies when done:

```bash
docker compose down
```

## Install and Run the Function App (npm scripts)

Install dependencies:

```bash
npm install
```

Build once:

```bash
npm run build
```

Run the app locally (this runs `prestart` first: clean + build):

```bash
npm start
```

Useful alternatives:

- Watch TypeScript compilation: `npm run watch`
- Clean build output: `npm run clean`
- Run local Azurite directly without Docker (optional): `npm run azurite`

## Typical Local Workflow

1. Set Azure Monitor credentials in environment (see above)
2. `docker compose up -d`
3. `npm install`
4. `npm start`
5. Send events to Event Hub `debug` and observe function logs
6. `docker compose down`

## HTTP Functions

The app exposes two utility HTTP endpoints (anonymous auth):

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/about` | Returns the configured `ConsumerGroup` value |
| `POST` | `/api/fail` | Sets the Redis key `fail` to the request body (`on`/`off`). When `fail` is `on`, the Event Hub trigger calls `process.exit(1)` on the next message — intentional chaos-testing behavior. |

## Deploy to Azure

The Azure infrastructure is defined with Bicep under `infra/`. `main.bicep` is an
orchestrator that composes three submodules in `infra/modules/`:

- `monitoring.bicep` — Log Analytics workspace and Application Insights component.
- `eventhubs.bicep` — Event Hub namespace and a sample Event Hub.
- `functions.bicep` — the function app on a Flex Consumption plan plus its
  dependencies: the runtime storage account, a user-assigned managed identity,
  and the role assignments granting access to storage, Application Insights, and
  the Event Hub.

Deploy everything with the helper script (creates the resource group if needed):

```bash
export FUNCTIONS_RESOURCE_GROUP_NAME="functions-otel-dev"
./deploy.sh
```

Optional overrides (with defaults): `FUNCTIONS_RUNTIME` (`node`),
`FUNCTIONS_RUNTIME_VERSION` (`24`), and `EVENTHUB_LOCATION` (`swedencentral`).

On success the script prints the function app endpoint, the Event Hub namespace endpoint, and `export` commands for the three OTLP ingestion endpoints (`LOGS_ENDPOINT`, `TRACES_ENDPOINT`, `METRICS_ENDPOINT`). Copy those exports into your `.envrc` to configure the local OTel Collector.

