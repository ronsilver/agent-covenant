# Validación de Paths de Agentes

Guía completa para validar que los paths configurados en `manifest.yaml` sean correctos.

## 🎯 Problema

Los agentes de AI esperan archivos de configuración en paths específicos. Paths incorrectos causan:
- Reglas no cargadas
- Skills no detectadas
- Workflows que no funcionan
- MCP servers no conectados

## ✅ Soluciones Implementadas

### 1. Validación Básica (permisos y escritura)

**Ubicación:** `scripts/validate.sh` (función `validate_agents`)

**Qué valida:**
- ✓ Expansión de variables (`${HOME}`, `${REPO_ROOT}`)
- ✓ Directorios padre existen o pueden crearse
- ✓ Permisos de escritura
- ✓ Paths válidos antes de sync

**Uso:**
```bash
# Validar todo
./scripts/validate.sh

# Con debug para ver todos los paths
./scripts/validate.sh --debug
```

**Ejemplo de salida:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Validating agent configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[INFO]   ✓ windsurf: Windsurf IDE / Codeium Cascade (enabled)
[DEBUG]     rules: ${HOME}/.codeium/windsurf/memories/global_rules.md (ok)
[DEBUG]     workflows: ${HOME}/.codeium/windsurf/global_workflows (ok)
[ERROR]     skills: /invalid/path (parent not writable)
```

---

### 2. Validación Canónica (contra documentación oficial)

**Ubicación:** `scripts/validate-canonical-paths.sh`

**Referencia:** `docs/canonical-paths.yaml`

**Qué valida:**
- ✓ Paths coinciden con documentación oficial
- ✓ Detecta paths custom que pueden no funcionar
- ✓ Sugiere alternativas canónicas

**Uso:**
```bash
# Validar contra documentación oficial
./scripts/validate-canonical-paths.sh

# Modo estricto (warnings = errors)
./scripts/validate-canonical-paths.sh --strict

# Con debug
./scripts/validate-canonical-paths.sh --debug
```

**Ejemplo de salida:**
```
[INFO] Validating: Claude Code (Anthropic)
  ✓ rules: ${HOME}/.claude/CLAUDE.md
  ⚠ skills: ${HOME}/.claude/my-skills
    Not in canonical documentation
    Canonical options:
      - ${HOME}/.claude/skills (https://code.claude.com/docs/en/skills)
      - ${REPO_ROOT}/.claude/skills
```

---

### 3. Dry-run de Sync (previsualización)

**Qué hace:**
- Ver qué archivos se van a crear/modificar
- Detectar errores antes de escribir
- Verificar paths expandidos correctamente

**Uso:**
```bash
# Previsualizar todo
./scripts/sync.sh --dry-run

# Previsualizar agente específico
./scripts/sync.sh --agent windsurf --dry-run
```

---

## 📚 Referencia de Paths Canónicos

### Windsurf / Codeium

```yaml
rules:
  - Global: ~/.codeium/windsurf/memories/global_rules.md
  - Workspace: .windsurf/rules/*.md

workflows:
  - Global: ~/.codeium/windsurf/global_workflows/
  - Workspace: .windsurf/workflows/

skills:
  - Global: ~/.codeium/windsurf/skills/
  - Workspace: .windsurf/skills/

subagents:
  - Global: ~/.codeium/windsurf/agents/
  - Workspace: .windsurf/agents/

mcp:
  - Global: ~/.codeium/windsurf/mcp_config.json
```

**Fuente:** https://docs.codeium.com/windsurf/cascade

---

### Claude Code

```yaml
rules:
  - Global: ~/.claude/CLAUDE.md
  - Workspace: .claude/CLAUDE.md

skills:
  - Global: ~/.claude/skills/
  - Workspace: .claude/skills/

subagents:
  - Global: ~/.claude/agents/
  - Workspace: .claude/agents/

mcp:
  - Global: ~/.claude/.mcp.json
  - Workspace: .claude/.mcp.json
```

**Fuente:** https://code.claude.com/docs/en/claude-directory

---

### Google Antigravity

```yaml
rules:
  - Global: ~/.gemini/GEMINI.md

workflows:
  - Global: ~/.gemini/antigravity/global_workflows/

skills:
  - Global: ~/.gemini/antigravity/skills/
  - Workspace: .agents/skills/

mcp:
  - Global: ~/.gemini/antigravity/mcp_config.json
```

**Fuente:** https://codelabs.developers.google.com/getting-started-google-antigravity

---

### GitHub Copilot (VS Code)

```yaml
rules:
  - macOS: ~/Library/Application Support/Code/User/prompts/Default.instructions.md
  - Linux: ~/.config/Code/User/prompts/Default.instructions.md

prompts:
  - macOS: ~/Library/Application Support/Code/User/prompts/
  - Linux: ~/.config/Code/User/prompts/
```

**Fuente:** https://docs.github.com/en/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot

---

### Claude Desktop

```yaml
mcp:
  - macOS: ~/Library/Application Support/Claude/claude_desktop_config.json
  - Linux: ~/.config/Claude/claude_desktop_config.json
```

**Fuente:** https://modelcontextprotocol.io/quickstart/user

---

## 🔧 Workflow Recomendado

### Antes de modificar manifest.yaml

```bash
# 1. Validar configuración actual
./scripts/validate.sh

# 2. Validar contra documentación oficial
./scripts/validate-canonical-paths.sh
```

### Después de modificar manifest.yaml

```bash
# 1. Validar cambios
./scripts/validate.sh

# 2. Previsualizar sync
./scripts/sync.sh --dry-run

# 3. Si todo OK, sincronizar
./scripts/sync.sh
```

### Si tienes dudas sobre un path

```bash
# 1. Consultar canonical-paths.yaml
cat docs/canonical-paths.yaml | grep -A5 "agent-name"

# 2. Validar con modo debug
./scripts/validate-canonical-paths.sh --debug

# 3. Verificar documentación oficial (links en canonical-paths.yaml)
```

---

## 🚨 Errores Comunes

### Error: "parent not writable"

**Causa:** El directorio padre no existe o no tienes permisos.

**Solución:**
```bash
# Crear directorio manualmente
mkdir -p ~/.codeium/windsurf/memories

# O verificar permisos
ls -la ~/.codeium/
```

---

### Warning: "Not in canonical documentation"

**Causa:** El path funciona pero no coincide con la documentación oficial.

**Impacto:** Puede funcionar ahora pero romperse en futuras versiones.

**Solución:**
```bash
# Ver opciones canónicas
./scripts/validate-canonical-paths.sh

# Actualizar manifest.yaml con path canónico
```

---

### Error: Variables no expandidas

**Síntoma:** Path contiene `${HOME}` literalmente.

**Causa:** Error en expansión de variables.

**Solución:** Verificar que usas `${HOME}` y `${REPO_ROOT}` correctamente en manifest.yaml.

---

## 📝 Actualizar Paths Canónicos

Si encuentras documentación oficial nueva o paths actualizados:

1. Editar `docs/canonical-paths.yaml`
2. Agregar `source: "URL"` con link a documentación
3. Validar que el formato sea correcto:
   ```bash
   yq '.' docs/canonical-paths.yaml
   ```

---

## 🔗 Referencias

- **Windsurf:** https://docs.codeium.com/windsurf/cascade
- **Claude Code:** https://code.claude.com/docs/en/claude-directory
- **Antigravity:** https://codelabs.developers.google.com/getting-started-google-antigravity
- **GitHub Copilot:** https://docs.github.com/en/copilot/customizing-copilot
- **MCP Protocol:** https://modelcontextprotocol.io

---

## 📊 Resumen

| Validación | Qué verifica | Cuándo usar |
|------------|--------------|-------------|
| `validate.sh` | Paths válidos, permisos | Siempre antes de sync |
| `validate-canonical-paths.sh` | Coincidencia con docs oficiales | Al agregar/cambiar agentes |
| `sync.sh --dry-run` | Qué se va a escribir | Antes de sync definitivo |
| `sync.sh --validate` | Validación + sync | Workflow automatizado |

**Recomendación:** Ejecuta `validate.sh` en CI/CD para detectar paths incorrectos antes de merge.
