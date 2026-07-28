# Homebrew Distribution

AIAnalyzer is published through a GitHub Release asset and the public `elangbamjohnson/homebrew-tap` repository.

The user install path is:

```bash
brew install elangbamjohnson/tap/aianalyzer
aianalyzer . --format sarif --fail-on-critical > aianalyzer.sarif
```

Equivalent two-step install:

```bash
brew tap elangbamjohnson/tap
brew install aianalyzer
```

## Automated Release Workflow

Releases and Homebrew tap formula updates are automated via GitHub Actions (`.github/workflows/release.yml`).

### Prerequisites
Ensure the GitHub secret `HOMEBREW_TAP_TOKEN` is configured in `elangbamjohnson/AIAnalyzer`:
- Create a Personal Access Token (PAT) with write access to `elangbamjohnson/homebrew-tap` (Fine-grained PAT with **Contents: Read and write** on `homebrew-tap`, or Classic PAT with `repo` scope).
- Add it under **Settings > Secrets and variables > Actions** as `HOMEBREW_TAP_TOKEN`.

### Triggering a Release

1. Tag and push a release:

   ```bash
   git checkout main
   git pull origin main
   swift test
   swift build -c release
   git tag -a v0.1.2 -m "AIAnalyzer v0.1.2"
   git push origin v0.1.2
   ```

2. The Release workflow will automatically:
   - Build `aianalyzer-macos-arm64.zip`.
   - Create the GitHub release and upload the zip asset.
   - Compute the asset's SHA256 checksum.
   - Checkout `elangbamjohnson/homebrew-tap`.
   - Update `Formula/aianalyzer.rb` with the new URL and SHA256.
   - Run `brew audit` on the updated formula.
   - Commit and push directly to `main` in `elangbamjohnson/homebrew-tap`.

## Public Verification

Check these URLs are public:

```bash
curl -L -s -o /dev/null -w "%{http_code}\n" https://github.com/elangbamjohnson/AIAnalyzer
curl -L -s -o /dev/null -w "%{http_code}\n" https://github.com/elangbamjohnson/homebrew-tap
curl -L -s -o /dev/null -w "%{http_code}\n" https://raw.githubusercontent.com/elangbamjohnson/homebrew-tap/main/Formula/aianalyzer.rb
```

Expected result for each command is `200`.

Test like a fresh Homebrew user:

```bash
brew uninstall aianalyzer
brew untap elangbamjohnson/tap
brew update
brew install elangbamjohnson/tap/aianalyzer
aianalyzer --help
brew test elangbamjohnson/tap/aianalyzer
```

The current release asset is `aianalyzer-macos-arm64.zip`, so the published binary is confirmed for Apple Silicon Macs. Add an Intel or universal binary before advertising full Intel Mac support.

## Formula Template

The formula template lives at:

```text
packaging/homebrew/aianalyzer.rb.template
```
