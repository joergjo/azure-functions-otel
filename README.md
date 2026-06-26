# Azure Functions + OpenTelemetry Sample

This sample runs an Azure Functions app locally with Redis, Azurite, and an OpenTelemetry Collector provided by Docker Compose.

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
- `OTEL_EXPORTER_OTLP_ENDPOINT`: Keep `http://localhost:4317` for local Docker collector

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

1. `docker compose up -d`
2. `npm install`
3. `npm start`
4. Send events to Event Hub `debug` and observe function logs
5. `docker compose down`

