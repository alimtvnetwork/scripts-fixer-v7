# Spec: Models Orchestrator

## Purpose

Single entry point (`./run.ps1 models` / `model` / `-M`) for browsing,
filtering, and installing AI models across both supported backends:

| Backend     | Folder                          | What it installs                    |
|-------------|---------------------------------|-------------------------------------|
| `llama-cpp` | `scripts/43-install-llama-cpp/` | Raw GGUF files for llama.cpp runtime |
| `ollama`   | `scripts/42-install-ollama/`    | Models pulled via the Ollama daemon |

The orchestrator never duplicates picker logic -- it dispatches to the
existing scripts (which already own catalogs, filters, and downloaders).

## CLI surface

| Invocation                                           | Behaviour                                                    |
|------------------------------------------------------|--------------------------------------------------------------|
| `.\run.ps1 models`                                   | Interactive: pick backend, then dispatch to its picker        |
| `.\run.ps1 model`                                    | Alias for `models`                                           |
| `.\run.ps1 -M`                                       | Shortcut flag, same as `models`                              |
| `.\run.ps1 models qwen2.5-coder-3b,llama3.2`         | CSV direct install (auto-routes per backend)                 |
| `.\run.ps1 models -Backend llama-cpp`                | Skip backend prompt, go straight to llama.cpp picker          |
| `.\run.ps1 models -Backend ollama -Install llama3.2,qwen2.5-coder` | Non-interactive install on a specific backend |
| `.\run.ps1 models list`                              | List all models from both catalogs                            |
| `.\run.ps1 models list llama`                        | List only llama.cpp catalog                                   |
| `.\run.ps1 models list ollama`                       | List only Ollama defaults                                    |
| `.\run.ps1 models -Help`                             | Help text                                                    |

## File layout

```
scripts/models/
  run.ps1              # Thin dispatcher (this file is intentionally small)
  config.json          # Backend registry: scriptFolder, catalogFile, idField
  log-messages.json    # All user-facing strings (per logging convention)
  helpers/
    picker.ps1         # Backend picker, catalog loader, CSV resolver, dispatcher
```

`run.ps1` only handles arg parsing + flow control. All real logic lives in
`helpers/picker.ps1` so the file stays under ~120 lines per the project's
"keep run.ps1 small" rule.

## Algorithm

1. **Parse args**: detect list mode vs CSV vs interactive.
2. **List mode**: load catalogs, render flat table, exit.
3. **CSV mode**: load catalog(s), match each id (exact, then `-like *id*`),
   group matches by backend, dispatch to each backend's `run.ps1` with
   the resolved ids passed via env var (`LLAMA_CPP_INSTALL_IDS` /
   `OLLAMA_PULL_MODELS`).
4. **Interactive mode**: prompt for backend (1=llama, 2=ollama, 3=both),
   then either show combined list or invoke the backend script's own
   picker.

## Catalog wiring

`config.json` declares each backend:

```json
{
  "backends": {
    "llama-cpp": {
      "scriptFolder": "43-install-llama-cpp",
      "catalogFile":  "models-catalog.json",
      "idField":      "id",
      "displayField": "displayName"
    },
    "ollama": {
      "scriptFolder": "42-install-ollama",
      "catalogFile":  "config.json",
      "catalogPath":  "defaultModels",
      "idField":      "slug",
      "displayField": "displayName"
    }
  }
}
```

To add a third backend, drop a config entry and a script that accepts
either an env var or a CSV positional arg -- no changes to `picker.ps1`.

## Dispatcher contract

The orchestrator passes resolved ids to backends via env vars rather than
positional args, since both backend scripts already use positional args
for their own subcommands (`install`, `pull`, `models`, `uninstall`).

| Backend     | Env var passed         | Subcommand invoked | Honored by (since) |
|-------------|------------------------|--------------------|--------------------|
| `llama-cpp` | `LLAMA_CPP_INSTALL_IDS` | `all`              | `Invoke-ModelInstaller` -- v0.33.0 |
| `ollama`    | `OLLAMA_PULL_MODELS`    | `pull`             | `Pull-OllamaModels` -- v0.33.0 |

**llama-cpp** behaviour when `LLAMA_CPP_INSTALL_IDS` is set: skip all RAM/size/speed/capability filter prompts, resolve each CSV id against the catalog (exact match first, then `-like *id*`), download only the matched subset. Unmatched ids are warned and skipped; empty result aborts cleanly.

**ollama** behaviour when `OLLAMA_PULL_MODELS` is set: skip per-model yes/no prompt, resolve each slug against `config.json -> defaultModels` (matches `slug` or `pullCommand`), and fall back to ad-hoc `ollama pull <slug>` for unknown slugs so users can pull anything from ollama.com/library without editing config.

## Examples

```powershell
# Interactive: friendliest path
.\run.ps1 models

# Direct install across backends, comma-separated
.\run.ps1 models qwen2.5-coder-3b,llama3.2,deepseek-r1:8b

# Browse before deciding
.\run.ps1 models list
.\run.ps1 models list llama

# Force a backend, skip prompt
.\run.ps1 models -Backend llama-cpp
```

## Why not just point users at scripts 42 and 43?

- Discoverability: `models` is the obvious verb; users don't need to
  know which numbered script handles what.
- Cross-backend CSV: `qwen2.5-coder-3b,llama3.2` mixes backends; users
  shouldn't have to split the call.
- Single help surface: one `--help` lists every model id from every backend.
