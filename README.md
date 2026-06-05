# Useful notes

## Export environment variables

```bash
export FUNCTION_APP='<function-app>'
export RESOURCE_GROUP='<resource-group>'
```

## Update slot settings (blue)
```bash
az functionapp config appsettings set -n $FUNCTION_APP -g $RESOURCE_GROUP --slot-settings @cloud-blue.settings.json
```

## Update slot settings (green)
```bash
az functionapp config appsettings set -n $FUNCTION_APP -g $RESOURCE_GROUP -s green --slot-settings @cloud-green.settings.json
```

## Publish app (blue)
```bash
npm run build
func azure functionapp publish $FUNCTION_APP
```

## Publish app (green)
```bash
npm run build
func azure functionapp publish $FUNCTION_APP --slot green
```

## Stream logs (blue)
```bash
func azure functionapp logstream $FUNCTION_APP  
```

## Stream logs (green)
```bash
func azure functionapp logstream $FUNCTION_APP --slot green
```

