# AIAnalyzer

AIAnalyzer is a Swift command-line tool that scans Swift source code, finds common architecture and maintainability problems, and can optionally ask an AI provider for refactoring suggestions.

Think of it as a lightweight static-analysis assistant for Mac and iOS projects. New developers can install it with Homebrew, run it locally, wire it into Xcode, or use JSON/SARIF output in scripts and CI.

---

## Quick Start

Install the published command-line tool with Homebrew:

```bash
brew install elangbamjohnson/tap/aianalyzer
aianalyzer --help
```

Scan a Swift file or project:

```bash
aianalyzer /path/to/YourMacProject
aianalyzer /path/to/YourMacProject --format sarif > aianalyzer.sarif
```

Or run from this repository while developing AIAnalyzer itself:

```bash
swift build
swift test
AI_ENABLED=false swift run AIAnalyzer sample.swift
```

Scan another Swift project:

```bash
AI_ENABLED=false swift run AIAnalyzer /path/to/YourMacProject
```

Emit Xcode-compatible diagnostics:

```bash
AI_ENABLED=false swift run AIAnalyzer /path/to/YourMacProject --xcode
AI_ENABLED=false swift run AIAnalyzer /path/to/YourMacProject --format xcode
```

Emit machine-readable JSON:

```bash
AI_ENABLED=false swift run AIAnalyzer /path/to/YourMacProject --json
AI_ENABLED=false swift run AIAnalyzer /path/to/YourMacProject --format json
```

Emit SARIF for GitHub code scanning:

```bash
AI_ENABLED=false swift run AIAnalyzer /path/to/YourMacProject --format sarif > aianalyzer.sarif
```

---

## Technology Stack

| Area | Technology | How it is used |
| --- | --- | --- |
| Language | Swift 5.7+ | Main implementation language. |
| Package manager | Swift Package Manager | Builds the executable and test target. |
| Platforms | macOS 13+, iOS 13+ package platforms | The analyzer runs as a command-line executable, primarily on macOS. |
| Parser | SwiftParser | Parses Swift source into a syntax tree. |
| Syntax tree API | SwiftSyntax | Visits declarations and extracts structure from Swift files. |
| Testing | XCTest through `swift test` | Unit tests cover rules, visitor behavior, AI orchestration, and input validation. |
| Reporting | Console, JSON, Xcode diagnostics, SARIF | Outputs findings for humans, automation, Xcode, and GitHub code scanning. |
| AI providers | Gemini, Ollama, local/Core ML, hybrid | Optional suggestions for warning and critical issues. |
| Configuration | `.aianalyzer.json`, `.aianalyzer.env`, environment variables | Controls ignored folders, rule toggles, thresholds, and AI runtime settings. |
| Distribution | GitHub Releases and Homebrew tap | Publishes a zipped macOS binary and installs it through `elangbamjohnson/tap`. |
| CI integration | GitHub Actions and SARIF upload | Runs analysis in pull requests and can upload findings to GitHub code scanning. |

Primary dependency from `Package.swift`:

```swift
.package(url: "https://github.com/apple/swift-syntax.git", from: "508.0.0")
```

---

## How It Fits Into a Mac Project

Use AIAnalyzer beside your normal Mac or iOS project. Xcode remains your editor, build system, preview tool, and debugger. AIAnalyzer acts as a project health check that can be run from Terminal, an Xcode Run Script phase, a CI job, or a local developer script.

```mermaid
flowchart TD
    Dev["Developer working in Xcode"]
    MacProject["Mac/iOS Swift project"]
    Script["Terminal, Xcode Run Script, or CI job"]
    Analyzer["AIAnalyzer CLI"]
    Config[".aianalyzer.json and .aianalyzer.env"]
    Parser["SwiftParser + SwiftSyntax"]
    Rules["Rule engine"]
    AI["Optional AI suggestion layer"]
    Output["Console, JSON, Xcode diagnostics, or SARIF"]
    Fix["Developer reviews and fixes code"]

    Dev --> MacProject
    MacProject --> Script
    Script --> Analyzer
    Config --> Analyzer
    Analyzer --> Parser
    Parser --> Rules
    Rules --> Output
    Rules --> AI
    AI --> Output
    Output --> Fix
    Fix --> MacProject
```

Recommended local workflow:

1. Add a project-level `.aianalyzer.json` when you need custom ignores or thresholds.
2. Run the analyzer before large refactors or before opening a pull request.
3. Use `--xcode` when you want findings to appear as Xcode warnings/errors.
4. Use `--format sarif` when GitHub code scanning should display the findings.
5. Use `--json` when another tool or CI job needs to consume the results.
6. Turn AI on only when you want explanation and refactoring help, not for deterministic test runs.

---

## What The App Checks

AIAnalyzer parses each Swift file and extracts metrics for classes, structs, enums, actors, and extensions. It then runs a set of independent rules.

| Rule | What it checks | Severity |
| --- | --- | --- |
| `LargeClassRule` | Types with too many methods or too many lines. Uses different limits for ViewControllers, ViewModels, services, models, and unknown types. | Warning or critical |
| `HighMethodDensityRule` | Types with too many methods packed into a relatively small type. Skips very large files so `LargeClassRule` can own that signal. | Warning or critical |
| `GodObjectRule` | Types that breach at least two major signals, such as methods, properties, and lines. | Critical |
| `DataHeavyClassRule` | Types with too many stored properties. | Info |
| `ViewModelUIKitRule` | ViewModel-like types whose file imports `UIKit` or `UIKit.*`. | Critical |
| `ModelServiceUIKitRule` | Model-like or service-like types whose file imports `UIKit` or `UIKit.*`. | Critical |

Type classification is name-based:

| Name contains | Classified as |
| --- | --- |
| `viewcontroller` | ViewController |
| `viewmodel` | ViewModel |
| `service` or `manager` | Service |
| `model` | Model |
| Anything else | Unknown |

This is intentionally simple. The analyzer does not currently do full type resolution, module graph analysis, or folder-based architecture inference.

---

## End-To-End Pipeline

```mermaid
flowchart LR
    Input["Input path"]
    Validate["Validate file or folder"]
    Env["Load .aianalyzer.env"]
    Config["Load .aianalyzer.json"]
    Scan["Discover .swift files"]
    Parse["Parse with SwiftParser"]
    Visit["Visit with ClassVisitor"]
    Analyze["Run RuleEngine"]
    Report["Report output"]
    AISuggest["Optional AISuggester"]

    Input --> Validate
    Validate --> Env
    Env --> Config
    Config --> Scan
    Scan --> Parse
    Parse --> Visit
    Visit --> Analyze
    Analyze --> Report
    Analyze --> AISuggest
    AISuggest --> Report
```

Detailed sequence:

1. The CLI reads one optional input path, `--format`, legacy shortcuts such as `--json` and `--xcode`, quality-gate flags, and `--help`.
2. The input path is validated. A single file must be a `.swift` file.
3. `.aianalyzer.env` is loaded from the config root when present.
4. `.aianalyzer.json` is loaded and merged with default settings.
5. Directory scans recursively collect `.swift` files while skipping ignored folders.
6. `SwiftParser` parses each source file.
7. `ClassVisitor` collects type metrics, member counts, line estimates, and imports.
8. `RuleEngine` evaluates each rule and suppresses some duplicate noise when `GodObjectRule` already fired.
9. The app prints console output, JSON, SARIF, or Xcode-compatible diagnostics.
10. If AI is enabled and configured, warning and critical findings are enriched with suggestions.

---

## Install And Distribution

AIAnalyzer is distributed as a macOS command-line executable through GitHub Releases and a Homebrew tap.

### Install With Homebrew

For most users:

```bash
brew install elangbamjohnson/tap/aianalyzer
aianalyzer --help
```

Equivalent two-step install:

```bash
brew tap elangbamjohnson/tap
brew install aianalyzer
```

Verify the install:

```bash
aianalyzer --help
aianalyzer /path/to/YourMacProject --format sarif > aianalyzer.sarif
```

Current distribution shape:

- The Homebrew formula lives in the public `elangbamjohnson/homebrew-tap` repository.
- The formula downloads `aianalyzer-macos-arm64.zip` from the public `elangbamjohnson/AIAnalyzer` GitHub Release.
- The formula verifies the release asset with `sha256`.
- The installed command is `aianalyzer`.
- The current release asset is Apple Silicon macOS. Add an Intel or universal binary before advertising full Intel Mac support.

### Release Maintainer Checklist

Use this when publishing a new AIAnalyzer version:

```bash
git checkout main
git pull origin main
swift test
swift build -c release
git tag -a v0.1.2 -m "AIAnalyzer v0.1.2"
git push origin v0.1.2
```

After GitHub Actions creates the release asset:

```bash
curl -L -o /tmp/aianalyzer-macos-arm64.zip \
  https://github.com/elangbamjohnson/AIAnalyzer/releases/download/v0.1.2/aianalyzer-macos-arm64.zip

shasum -a 256 /tmp/aianalyzer-macos-arm64.zip
```

Then update the Homebrew formula:

1. Change the formula URL to the new `v*` release.
2. Replace `sha256` with the new checksum.
3. Run `brew fetch --force elangbamjohnson/tap/aianalyzer`.
4. Run `brew test elangbamjohnson/tap/aianalyzer`.
5. Commit and push the formula in `elangbamjohnson/homebrew-tap`.

### Public Install Verification

To test like a fresh user:

```bash
brew uninstall aianalyzer
brew untap elangbamjohnson/tap
brew update
brew install elangbamjohnson/tap/aianalyzer
aianalyzer --help
brew test elangbamjohnson/tap/aianalyzer
```

Also confirm these public URLs return `200`:

- `https://github.com/elangbamjohnson/AIAnalyzer`
- `https://github.com/elangbamjohnson/homebrew-tap`
- `https://raw.githubusercontent.com/elangbamjohnson/homebrew-tap/main/Formula/aianalyzer.rb`

## Output Modes

### Console Output

Default mode is meant for humans.

```bash
aianalyzer /path/to/YourMacProject
AI_ENABLED=false swift run AIAnalyzer /path/to/YourMacProject
```

It prints:

- File name.
- Type names and inferred type categories.
- Method, property, initializer, accessor, subscript, and line counts.
- Approximate member map.
- Issues found in each file.
- Top files with issues.
- Final summary totals.

### JSON Output

Use JSON when another tool needs to consume the result.

```bash
aianalyzer /path/to/YourMacProject --format json
AI_ENABLED=false swift run AIAnalyzer /path/to/YourMacProject --json
AI_ENABLED=false swift run AIAnalyzer /path/to/YourMacProject --format json
```

Each issue is emitted as an `IssueReport`:

```json
{
  "file": "UserViewModel.swift",
  "line": null,
  "message": "UserViewModel imports UIKit. ViewModels should not depend on UIKit.",
  "rule": "ViewModelUIKitViolation",
  "severity": "🔴 Critical",
  "typeName": "UserViewModel"
}
```

Important behavior:

- JSON mode disables AI suggestions.
- JSON mode keeps stdout machine-readable.
- File read errors are written to stderr.
- Add `--fail-on-critical`, `--fail-on-warning`, or `--strict` when JSON is used as a CI quality gate.

### SARIF Output

Use SARIF when GitHub code scanning or another SARIF-compatible tool should consume the result.

```bash
aianalyzer /path/to/YourMacProject --format sarif > aianalyzer.sarif
AI_ENABLED=false swift run AIAnalyzer /path/to/YourMacProject --format sarif > aianalyzer.sarif
```

SARIF output includes:

- Tool metadata for `AIAnalyzer`.
- One SARIF rule descriptor per unique analyzer rule.
- One SARIF result per finding.
- Relative file path.
- Start line when available, otherwise line `1`.
- Severity mapped to SARIF levels: `info` -> `note`, `warning` -> `warning`, `critical` -> `error`.

GitHub Actions upload example:

```yaml
- name: Run AIAnalyzer
  run: swift run AIAnalyzer . --format sarif > aianalyzer.sarif

- name: Upload SARIF
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: aianalyzer.sarif
```

SARIF mode disables AI suggestions and keeps stdout machine-readable. Diagnostics such as `.aianalyzer.env` loading warnings are written to stderr.

### Xcode Output

Use Xcode mode when running the analyzer from a Run Script phase or a local script opened from Xcode.

```bash
aianalyzer /path/to/YourMacProject --format xcode
AI_ENABLED=false swift run AIAnalyzer /path/to/YourMacProject --xcode
AI_ENABLED=false swift run AIAnalyzer /path/to/YourMacProject --format xcode
```

The output uses this shape:

```text
/path/to/File.swift:1: warning: [AIAnalyzer] message
/path/to/File.swift:1: error: [AIAnalyzer] critical message
note: [AIAnalyzer] Analysis complete. Found 3 issues in 12 files.
```

Xcode can display these as warnings, errors, and notes in the issue navigator.

### CI Exit Gates

By default, AIAnalyzer exits successfully when the scan completes, even if it finds issues. Team scripts and CI jobs can opt into failing behavior:

| Flag | Exit behavior |
| --- | --- |
| `--fail-on-critical` | Exit `1` when at least one critical issue is found. |
| `--fail-on-warning` | Exit `1` when at least one warning or critical issue is found. |
| `--strict` | Exit `1` when any issue is found, including info-level findings. |

Examples:

```bash
aianalyzer /path/to/YourMacProject --format sarif --fail-on-critical
AI_ENABLED=false swift run AIAnalyzer /path/to/YourMacProject --json --fail-on-critical
AI_ENABLED=false swift run AIAnalyzer /path/to/YourMacProject --xcode --fail-on-warning
AI_ENABLED=false swift run AIAnalyzer /path/to/YourMacProject --strict
```

---

## How AI Assistance Works

AI is optional. Static analysis always runs first. The AI layer only receives warning and critical findings, so informational issues do not generate AI requests. Source snippets are redacted for common secret patterns before they are sent to any AI provider.

```mermaid
flowchart TD
    Issues["Rule findings"]
    Filter["Keep warning + critical only"]
    Dedup["One highest-severity issue per type"]
    Limit["Apply AI_MAX_SUGGESTIONS"]
    Prompt["Build prompt with rule, metrics, member map, and source snippet"]
    Provider{"AI_PROVIDER"}
    Gemini["Gemini"]
    Ollama["Ollama"]
    Local["Local/Core ML + heuristic fallback"]
    Hybrid["Hybrid local-first provider"]
    Suggestion["Diagnosis + suggested refactor"]
    Output["Console or Xcode note"]

    Issues --> Filter
    Filter --> Dedup
    Dedup --> Limit
    Limit --> Prompt
    Prompt --> Provider
    Provider --> Gemini
    Provider --> Ollama
    Provider --> Local
    Provider --> Hybrid
    Gemini --> Suggestion
    Ollama --> Suggestion
    Local --> Suggestion
    Hybrid --> Suggestion
    Suggestion --> Output
```

AI can help developers understand:

- Why the rule fired.
- What architectural boundary was crossed.
- Which refactor is likely to reduce risk.
- A quick first step before doing a larger cleanup.

AI should be treated as guidance. The rule output is deterministic; the AI explanation is advisory and should be reviewed by a developer.

### Enable AI

Gemini:

```bash
AI_ENABLED=true \
AI_PROVIDER=gemini \
AI_CLOUD_OPT_IN=true \
GEMINI_API_KEY=your_key_here \
swift run AIAnalyzer /path/to/YourMacProject
```

Ollama:

```bash
AI_ENABLED=true \
AI_PROVIDER=ollama \
OLLAMA_MODEL=qwen2.5-coder:7b \
OLLAMA_ENDPOINT=http://localhost:11434 \
swift run AIAnalyzer /path/to/YourMacProject
```

Hybrid local-first mode:

```bash
AI_ENABLED=true \
AI_PROVIDER=hybrid \
OLLAMA_MODEL=qwen2.5-coder:7b \
AI_CLOUD_OPT_IN=true \
GEMINI_API_KEY=your_key_here \
swift run AIAnalyzer /path/to/YourMacProject
```

Without `AI_CLOUD_OPT_IN=true`, hybrid mode stays local-only even when `GEMINI_API_KEY` is present.

### AI Environment Variables

| Variable | Purpose |
| --- | --- |
| `AI_ENABLED` | Must be `true` to enable AI suggestions. |
| `AI_PROVIDER` | `gemini`, `ollama`, `local`, or `hybrid`. Defaults to `local`. |
| `AI_CLOUD_OPT_IN` | Must be `true` to allow Gemini/cloud requests. Defaults to `false`. |
| `GEMINI_API_KEY` | Required for Gemini after cloud opt-in. Used by hybrid for cloud escalation only when `AI_CLOUD_OPT_IN=true`. |
| `AI_MODEL` | Gemini model name. Defaults to `gemini-1.5-flash`. |
| `OLLAMA_MODEL` | Ollama model name. Defaults to `qwen2.5-coder:7b`. |
| `OLLAMA_ENDPOINT` | Ollama endpoint. Host-only values are normalized to `/v1/chat/completions`. |
| `AI_LOCAL_MODEL` | Display name for the local model. |
| `AI_LOCAL_MODEL_PATH` | Optional path to a local Core ML model artifact. |
| `AI_MAX_SUGGESTIONS` | Maximum AI suggestions per analyzed file. Defaults to `5`. |
| `AI_SNIPPET_LINES` | Number of source lines included in each AI prompt. Defaults to `120`. |
| `AI_VERBOSE` | Prints more raw AI output when `true`. |
| `AI_TYPEWRITER_MS` | Console typewriter delay for AI output. |

Privacy notes:

- Cloud AI is opt-in. Setting `AI_ENABLED=true` alone does not permit Gemini requests.
- `AI_PROVIDER=local` and `AI_PROVIDER=ollama` keep prompts on the local machine/network endpoint you configure.
- `AI_PROVIDER=hybrid` starts local-first and only escalates to Gemini when both `AI_CLOUD_OPT_IN=true` and `GEMINI_API_KEY` are set.
- AIAnalyzer redacts common `apiKey`, `token`, `secret`, `password`, `clientSecret`, and bearer-token patterns from snippets before prompt construction.

---

## Configuration Cookbook

Create `.aianalyzer.json` in the root of the project you want to scan.

### Ignore Generated Or Third-Party Code

```json
{
  "ignoreDirectories": [
    "Generated",
    "Vendor",
    "TestFixtures"
  ]
}
```

These values are unioned with the defaults:

```text
.build, .git, .swiftpm, DerivedData, Pods, Build, Carthage
```

### Tune Rule Thresholds

```json
{
  "rules": {
    "largeClass": {
      "enabled": true,
      "threshold": 18
    },
    "highMethodDensity": {
      "enabled": true,
      "threshold": 12
    },
    "dataHeavyClass": {
      "enabled": true,
      "threshold": 8
    }
  }
}
```

### Disable A Rule

```json
{
  "rules": {
    "modelServiceUIKit": {
      "enabled": false
    }
  }
}
```

Available rule keys:

- `largeClass`
- `highMethodDensity`
- `godObject`
- `dataHeavyClass`
- `viewModelUIKit`
- `modelServiceUIKit`

### Store AI Settings In `.aianalyzer.env`

```bash
AI_ENABLED=true
AI_PROVIDER=ollama
OLLAMA_MODEL=qwen2.5-coder:7b
OLLAMA_ENDPOINT=http://localhost:11434
AI_MAX_SUGGESTIONS=3
AI_SNIPPET_LINES=120
```

For deterministic local tests and CI, prefer:

```bash
AI_ENABLED=false
```

### Suppress A Known Finding

Use a source comment when a rule is intentionally noisy for a specific file. Suppressions are file-level and apply before reporting, summaries, CI gates, and AI suggestions.

Disable one rule for the file:

```swift
// aianalyzer:disable LargeClass
```

Disable multiple rules:

```swift
// aianalyzer:disable LargeClass, GodObject
```

Disable every analyzer finding for the file:

```swift
// aianalyzer:disable all
```

Prefer narrow rule suppressions over `all`, and add a normal code comment explaining why the exception is intentional.

---

## Developer Cookbook

### Run The Full Test Suite

```bash
swift test
```

### Run One Test Area

```bash
swift test --filter ModelServiceUIKitRuleTests
swift test --filter Visitor
swift test --filter AISuggesterTests
```

### Smoke Test The CLI

```bash
swift run AIAnalyzer --help
AI_ENABLED=false swift run AIAnalyzer Fixtures/SmokeSample.swift --json
AI_ENABLED=false swift run AIAnalyzer Fixtures/SmokeSample.swift --format sarif
```

### Analyze The Included Sandbox

```bash
AI_ENABLED=false swift run AIAnalyzer TestSandbox/MessyProject
```

### Analyze A Real Mac App

```bash
AI_ENABLED=false swift run AIAnalyzer /Users/you/Projects/MyMacApp
```

### Use As A Pull Request Gate

Start with critical-only gating so the analyzer can be introduced without blocking teams on every advisory finding:

```bash
AI_ENABLED=false swift run AIAnalyzer /Users/you/Projects/MyMacApp --json --fail-on-critical
```

As the project adopts the rules, tighten the gate:

```bash
AI_ENABLED=false swift run AIAnalyzer /Users/you/Projects/MyMacApp --json --fail-on-warning
```

Use strict mode only when the project has a clean baseline:

```bash
AI_ENABLED=false swift run AIAnalyzer /Users/you/Projects/MyMacApp --json --strict
```

### Add A New Rule

1. Add a new type under `Sources/AIAnalyzer/Rules/` that conforms to `Rule`.
2. Add default configuration in `AnalyzerConfig+Default.swift` if it should be configurable.
3. Add a property to `AnalyzerConfig.RuleConfig` if it needs a JSON toggle.
4. Merge the user config in `ConfigLoader`.
5. Register the rule in `AnalyzerApp.main()`.
6. Add focused tests under `Tests/AIAnalyzerTests/`.
7. Decide the severity carefully. Only warning and critical issues are eligible for AI suggestions.

### Add A New AI Provider

1. Create a type under `Sources/AIAnalyzer/AI/` that conforms to `AIProvider`.
2. Add provider configuration to `AIConstants` and `AIConfiguration` if needed.
3. Wire provider construction in `AnalyzerApp.buildAISuggester`.
4. Add unit tests using test doubles from `Tests/AIAnalyzerTests/TestAIProviderStubs.swift`.

### Add A New Output Format

1. Add a formatter or reporter under `Sources/AIAnalyzer/Reporting/`.
2. Use `Reporter` for streaming human/Xcode output, or an encodable report model for machine-readable formats like SARIF.
3. Add the format to `AnalyzerApp.OutputFormat`.
4. Parse the format in `AnalyzerApp.parseCLIArguments()`.
5. Emit the format in `AnalyzerApp.main()`.
6. Add tests for formatting if the output is machine-consumed.

---

## Source Map

| Folder | Purpose |
| --- | --- |
| `Sources/AIAnalyzer/App` | CLI entry point, input validation, environment loading, provider wiring. |
| `Sources/AIAnalyzer/AI` | AI provider protocols, Gemini/Ollama/local/hybrid providers, prompt and formatter logic. |
| `Sources/AIAnalyzer/Extension` | Default analyzer configuration. |
| `Sources/AIAnalyzer/Models` | Shared models such as `ClassInfo`, `Issue`, `AnalyzerConfig`, and summaries. |
| `Sources/AIAnalyzer/Reporting` | Console and Xcode reporters, plus SARIF report generation. |
| `Sources/AIAnalyzer/Rules` | Static analysis rules and rule engine. |
| `Sources/AIAnalyzer/Utils` | File scanning and JSON config loading. |
| `Sources/AIAnalyzer/Visitor` | SwiftSyntax visitor that extracts type metrics. |
| `Tests/AIAnalyzerTests` | Unit tests by concern. |
| `.github/workflows` | CI and release automation. |
| `docs/integrations` | GitHub Actions and SARIF integration examples. |
| `docs/distribution` | Homebrew publishing guide. |
| `packaging/homebrew` | Homebrew formula template. |
| `Fixtures` | Small smoke-test fixture. |
| `TestSandbox` | Sample projects for manual analyzer runs. |

---

## Current Limitations

- Type classification is based on type names, not semantic type resolution.
- Import checks use file-level imports, so every type in the same file sees the same import list.
- Member line ranges are approximate and based on syntax descriptions, not precise source locations.
- Machine-readable JSON and SARIF modes do not include AI suggestions.
- AI output is advisory and can vary by provider/model.

---

## Related Docs

- `TESTING.md` covers test commands and visitor-focused troubleshooting.
- `Project Roadmap.rtf` contains planning notes.
- `docs/integrations/github-actions.md` shows GitHub Actions and SARIF setup.
- `docs/distribution/homebrew.md` explains the Homebrew release path.

---

## Ownership

Project by Johnson Elangbam. Dependencies are governed by their own licenses.
