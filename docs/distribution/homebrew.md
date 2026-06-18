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

## Release Steps

1. Tag a release:

   ```bash
   git checkout main
   git pull origin main
   swift test
   swift build -c release
   git tag -a v0.1.2 -m "AIAnalyzer v0.1.2"
   git push origin v0.1.2
   ```

2. Wait for the Release workflow to upload `aianalyzer-macos-arm64.zip`.

3. Download the asset and compute its SHA-256:

   ```bash
   curl -L -o /tmp/aianalyzer-macos-arm64.zip \
     https://github.com/elangbamjohnson/AIAnalyzer/releases/download/v0.1.2/aianalyzer-macos-arm64.zip

   shasum -a 256 /tmp/aianalyzer-macos-arm64.zip
   ```

4. Copy `packaging/homebrew/aianalyzer.rb.template` into a Homebrew tap repository as `Formula/aianalyzer.rb`.

5. Replace:

   - `__VERSION__`
   - `__SHA256__`

6. Test locally:

   ```bash
   brew fetch --force elangbamjohnson/tap/aianalyzer
   brew reinstall elangbamjohnson/tap/aianalyzer
   aianalyzer --help
   brew test elangbamjohnson/tap/aianalyzer
   ```

7. Commit and push the formula change from the tap repository:

   ```bash
   cd "$(brew --repo)/Library/Taps/elangbamjohnson/homebrew-tap"
   git add Formula/aianalyzer.rb
   git commit -m "Update AIAnalyzer formula to v0.1.2"
   git push origin main
   ```

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
