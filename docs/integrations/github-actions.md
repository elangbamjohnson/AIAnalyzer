# GitHub Actions Integration

Use AIAnalyzer in GitHub Actions when you want pull requests to receive Swift architecture and maintainability feedback.

## SARIF Code Scanning

This workflow builds AIAnalyzer from source, runs it against the checked-out repository, writes SARIF, and uploads the report to GitHub code scanning.

```yaml
name: AIAnalyzer

on:
  pull_request:
  push:
    branches: [main]

jobs:
  analyze:
    runs-on: macos-latest
    permissions:
      contents: read
      security-events: write

    steps:
      - name: Checkout app
        uses: actions/checkout@v4

      - name: Checkout AIAnalyzer
        uses: actions/checkout@v4
        with:
          repository: elangbamjohnson/AIAnalyzer
          path: .aianalyzer-tool

      - name: Build AIAnalyzer
        run: swift build --package-path .aianalyzer-tool -c release

      - name: Run AIAnalyzer SARIF
        run: .aianalyzer-tool/.build/release/AIAnalyzer . --format sarif --fail-on-critical > aianalyzer.sarif

      - name: Upload SARIF
        if: always()
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: aianalyzer.sarif
```

## Gate Strategy

Start with critical-only blocking:

```bash
aianalyzer . --format sarif --fail-on-critical > aianalyzer.sarif
```

After the team has cleaned up the most important findings, tighten the gate:

```bash
aianalyzer . --format sarif --fail-on-warning > aianalyzer.sarif
```

Use strict mode only when the project has a clean baseline:

```bash
aianalyzer . --format sarif --strict > aianalyzer.sarif
```

## Local Script

For teams that prefer a checked-in script, create `scripts/analyze.sh` in the app repo:

```bash
#!/bin/bash
set -euo pipefail

AIANALYZER="${AIANALYZER:-aianalyzer}"
TARGET_PATH="${1:-.}"

"$AIANALYZER" "$TARGET_PATH" --format sarif --fail-on-critical > aianalyzer.sarif
```

Then CI can call:

```bash
scripts/analyze.sh .
```
