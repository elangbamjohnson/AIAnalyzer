# Homebrew Distribution

Homebrew should be added after the first GitHub release binary is published.

The intended user experience is:

```bash
brew tap elangbamjohnson/aianalyzer
brew install aianalyzer
aianalyzer . --format sarif --fail-on-critical > aianalyzer.sarif
```

## Release Steps

1. Tag a release:

   ```bash
   git tag v0.1.0
   git push origin v0.1.0
   ```

2. Wait for the Release workflow to upload `aianalyzer-macos-arm64.zip`.

3. Download the asset and compute its SHA-256:

   ```bash
   shasum -a 256 aianalyzer-macos-arm64.zip
   ```

4. Copy `packaging/homebrew/aianalyzer.rb.template` into a Homebrew tap repository as `Formula/aianalyzer.rb`.

5. Replace:

   - `__VERSION__`
   - `__SHA256__`

6. Test locally:

   ```bash
   brew install --build-from-source Formula/aianalyzer.rb
   aianalyzer --help
   ```

## Formula Template

The formula template lives at:

```text
packaging/homebrew/aianalyzer.rb.template
```
