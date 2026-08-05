# values.yaml Structure
```yaml
replicaCount: 2
image:
  registry: docker.io
  repository: example/app
  tag: v1.0.0
  pullPolicy: IfNotPresent
resources:
  limits: {cpu: 1000m, memory: 1Gi}
  requests: {cpu: 500m, memory: 512Mi}
service:
  type: ClusterIP
  port: 80
ingress:
  enabled: true
  hosts: [api.example.com]
```
