# Commands
```bash
# Install
helm install app ./chart -n namespace -f values.yaml

# Upgrade
helm upgrade app ./chart --atomic

# Rollback
helm rollback app 0

# Uninstall
helm uninstall app
```
