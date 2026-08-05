# ArgoCD Troubleshooting

## Common Issues
| Symptom | Diagnosis | Fix |
|---|---|---|
| OutOfSync | Manual kubectl edit | Enable selfHeal, revert manual change |
| SyncError | Invalid YAML, missing CRD | Check `argocd app manifests` |
| Degraded | Pod not ready | Check health check config |
| Unknown | Repo unreachable | Verify SSH key, webhook config |
| Progressing | Rollout stuck | Check analysis run status |

## CLI Commands
```bash
argocd app list
argocd app get <app> --refresh hard
argocd app sync <app>
argocd app history <app>
argocd app rollback <app> <revision>
argocd app logs <app> --tail=100
```

## Never
- Manual kubectl edits to ArgoCD-managed resources
- Deploy without selfHeal in production
- Skip analysis templates for canary rollouts
- Use :latest image tags in ArgoCD sources
- Bypass ArgoCD for production changes
