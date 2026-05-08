# AIAnalyzer 🚀

AIAnalyzer is a sophisticated static analysis tool for Swift projects that combines traditional rule-based linting with cutting-edge AI suggestions. It helps developers maintain high-quality codebases by identifying architectural "smells" and providing intelligent refactoring advice.

---

## 🛠 How It Works

The analysis pipeline follows a multi-stage process:

1.  **Scanning:** Recursively discovers Swift files in your project, respecting `.gitignore` and custom ignore patterns defined in `.aianalyzer.json`.
2.  **Parsing (`SwiftSyntax`):** Utilizes Apple's `SwiftSyntax` and `SwiftParser` to build a full Abstract Syntax Tree (AST) of your code.
3.  **Extraction (`ClassVisitor`):** Traverses the AST to extract structural metrics for **classes, structs, enums, actors, and extensions**. It tracks method counts, property counts, line ranges, and file-level imports.
4.  **Rule Evaluation (`RuleEngine`):** Runs the extracted data through a suite of architectural rules to identify violations.
5.  **AI Enrichment (`AISuggester`):** Optionally sends detected issues to an AI provider (Gemini, Ollama, or Local) to generate human-like refactoring suggestions.
6.  **Reporting:** Outputs findings to the Console, Xcode Issue Navigator, or as machine-readable JSON.

---

## 📁 Project Structure

```text
Sources/AIAnalyzer/
├── AI/             # AI Provider logic (Gemini, Ollama, Core ML)
├── App/            # CLI entry point and argument parsing
├── Models/         # Data structures (Issue, ClassInfo, Config)
├── Reporting/      # Output formatters (Console, Xcode, JSON)
├── Rules/          # Architectural rule implementations
├── Utils/          # File scanning and config loading
└── Visitor/        # SwiftSyntax AST traversal logic
```

---

## 📏 Implemented Rules

The `RuleEngine` evaluates the following architectural constraints:

### 1. **God Object Rule** (`GodObject`)
*   **What it does:** Identifies types that have become "True God Objects"—types that are simultaneously too large, too complex, and too data-heavy.
*   **Trigger:** Triggers only if at least **two** major signals (Lines, Methods, Properties) exceed their thresholds.
*   **Thresholds:** Context-aware (e.g., ViewControllers have higher limits than Models).
*   **Severity:** `Critical`.

### 2. **Large Class Rule** (`LargeClass`)
*   **What it does:** Flags types that exceed context-specific limits for total methods or lines of code.
*   **Context-Aware Limits:**
    *   **ViewController:** 25 Methods / 400 Lines
    *   **ViewModel:** 20 Methods / 300 Lines
    *   **Service:** 15 Methods / 250 Lines
    *   **Model:** 10 Methods / 150 Lines

### 3. **High Method Density Rule** (`HighMethodDensity`)
*   **What it does:** Detects types that are too "busy" with logic relative to their purpose.
*   **Default Threshold:** > 10 methods for standard types.

### 4. **Data Heavy Class Rule** (`DataHeavyClass`)
*   **What it does:** Identifies "Anemic Data Models" or classes primarily used for storage that might need their logic moved elsewhere.
*   **Default Threshold:** > 5 properties.

### 5. **ViewModel UIKit Rule** (`ViewModelUIKitViolation`)
*   **What it does:** Enforces the MVVM contract. Flags any `ViewModel` that imports `UIKit`.
*   **Why:** ViewModels should be framework-agnostic to facilitate testing and portability.

---

## ⚙️ Configuration

### `.aianalyzer.json`
Customize rule thresholds and ignore directories:
```json
{
    "ignoreDirectories": ["TestSandbox", "Builds", "Pods"],
    "rules": {
        "largeClass": { "enabled": true, "threshold": 15 },
        "highMethodDensity": { "enabled": true, "threshold": 8 },
        "godObject": { "enabled": true },
        "viewModelUIKit": { "enabled": true }
    }
}
```

### `.aianalyzer.env`
Manage AI providers and API keys:
| Variable | Description | Default |
| :--- | :--- | :--- |
| `AI_ENABLED` | Toggle AI suggestions on/off | `false` |
| `AI_PROVIDER` | `gemini`, `ollama`, `local`, or `hybrid` | `gemini` |
| `GEMINI_API_KEY` | API key for Google Gemini | (Required for gemini) |
| `OLLAMA_MODEL` | Model name for Ollama (e.g. `qwen2.5-coder:7b`) | `qwen2.5-coder:7b` |
| `AI_MAX_SUGGESTIONS` | Max suggestions per file | `5` |

---

## 🤖 AI Integration Providers

*   **Gemini (`gemini`):** Uses Google's Gemini Pro API for high-quality, cloud-based refactoring suggestions.
*   **Ollama (`ollama`):** Connects to a local Ollama instance for private, local-first suggestions.
*   **Local LLM (`local`):** Uses a Core ML `.mlmodelc` bundle for entirely offline analysis.
*   **Hybrid (`hybrid`):** Tries Ollama first, escalates to Gemini for complex issues, and falls back to Local heuristics.

---

## 🚀 Usage

### Command Line
```bash
# Analyze the current folder
swift run AIAnalyzer .

# Analyze a specific file
swift run AIAnalyzer MyFile.swift

# Export results to JSON
swift run AIAnalyzer . --json > results.json
```

### Xcode Integration
To see issues directly in the Xcode Issue Navigator:
1. Add a **Run Script Phase** to your target:
   ```bash
   # If installed via Homebrew or in path
   AIAnalyzer . --xcode
   # Or using swift run from the project root
   swift run AIAnalyzer "$SRCROOT" --xcode
   ```
2. Any violations will appear as **Warnings** or **Errors** next to your code.

---

## 📈 Roadmap & CI
The project includes a GitHub Actions CI (`.github/workflows/ci.yml`) that:
1.  **Builds** the project on macOS latest.
2.  **Tests** the full Swift suite.
3.  **Smoke Test:** Runs a real analysis on `Fixtures/SmokeSample.swift` and validates the JSON output.
