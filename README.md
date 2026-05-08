# AIAnalyzer 🚀

AIAnalyzer is a sophisticated static analysis tool for Swift projects that combines traditional rule-based linting with cutting-edge AI suggestions. It helps developers maintain high-quality codebases by identifying architectural "smells" and providing intelligent refactoring advice.

---

## 🛠 How It Works

The analysis pipeline follows a multi-stage process:

1.  **Scanning:** Recursively discovers Swift files in your project, respecting `.gitignore` and custom ignore patterns.
2.  **Parsing (`SwiftSyntax`):** Utilizes Apple's `SwiftSyntax` and `SwiftParser` to build a full Abstract Syntax Tree (AST) of your code.
3.  **Extraction (`ClassVisitor`):** Traverses the AST to extract structural metrics for classes, structs, enums, actors, and extensions (method counts, property counts, line ranges, imports, etc.).
4.  **Rule Evaluation (`RuleEngine`):** Runs the extracted data through a suite of architectural rules to identify violations.
5.  **AI Enrichment (`AISuggester`):** Optionally sends detected issues to an AI provider (Gemini, Ollama, or Local) to generate human-like refactoring suggestions.
6.  **Reporting:** Outputs findings to the Console, Xcode Issue Navigator, or as a machine-readable JSON.

---

## 🏗 Frameworks & Responsibilities

| Framework | Role |
| :--- | :--- |
| **SwiftSyntax** | The backbone of the analyzer. Responsible for parsing Swift source code into a type-safe tree structure without requiring compilation. |
| **SwiftParser** | Provides the high-performance parsing logic used by SwiftSyntax. |
| **Foundation** | Used for file system navigation, environment management, and basic data structures. |
| **Core ML** | (Internal) Powers the `LocalLLMProvider` for on-device heuristic analysis when cloud providers are unavailable. |

---

## 📏 Implemented Rules

The `RuleEngine` currently evaluates the following architectural constraints:

### 1. **God Object Rule** (`GodObject`)
*   **What it does:** Identifies types that have become "True God Objects"—classes that are simultaneously too large, too complex, and too data-heavy.
*   **Trigger:** Triggers only if at least **two** major signals (Lines, Methods, Properties) exceed their thresholds.
*   **Thresholds:** Context-aware (e.g., ViewControllers have higher limits than Models).
*   **Severity:** `Critical`.

### 2. **Large Class Rule** (`LargeClass`)
*   **What it does:** Flags types that exceed context-specific limits for total methods or lines of code.
*   **Thresholds:**
    *   **ViewController:** 25 Methods / 400 Lines
    *   **ViewModel:** 20 Methods / 300 Lines
    *   **Service:** 15 Methods / 250 Lines
    *   **Model:** 10 Methods / 150 Lines
*   **Severity:** `Warning` (or `Critical` if double the threshold).

### 3. **High Method Density Rule** (`HighMethodDensity`)
*   **What it does:** Detects types that are too "busy" with logic relative to their purpose.
*   **Threshold:** > 10 methods for standard types.
*   **Severity:** `Critical`.

### 4. **Data Heavy Class Rule** (`DataHeavyClass`)
*   **What it does:** Identifies "Anemic Data Models" or classes primarily used for storage that might need their logic moved elsewhere.
*   **Threshold:** > 5 properties.
*   **Severity:** `Info`.

### 5. **ViewModel UIKit Rule** (`ViewModelUIKitViolation`)
*   **What it does:** Enforces the MVVM contract. Flags any `ViewModel` that imports `UIKit`.
*   **Why:** ViewModels should be framework-agnostic to facilitate testing and portability.
*   **Severity:** `Critical`.

---

## 🤖 AI Integration Providers

AIAnalyzer supports a versatile AI pipeline controlled via `.aianalyzer.env`:

*   **Gemini (`gemini`):** Uses Google's Gemini Pro API for high-quality, cloud-based refactoring suggestions.
*   **Ollama (`ollama`):** Connects to a local Ollama instance (e.g., `qwen2.5-coder`) for private, local-first suggestions.
*   **Local LLM (`local`):** Uses a Core ML `.mlmodelc` bundle for entirely offline analysis.
*   **Hybrid (`hybrid`):** The smartest mode. Tries Ollama first, escalates to Gemini for complex issues, and falls back to Local heuristics if all else fails.

---

## 🚀 Getting Started

### Prerequisites
- macOS 12.0+
- Swift 5.7+

### Running the Analyzer
```bash
# Analyze the current folder
swift run AIAnalyzer .

# Analyze a specific file
swift run AIAnalyzer sample.swift

# For Xcode integration (outputs warnings in the Issue Navigator)
swift run AIAnalyzer . --xcode
```

### Configuration
Create a `.aianalyzer.env` in your project root to configure AI behaviors:
```bash
AI_ENABLED=true
AI_PROVIDER=hybrid
GEMINI_API_KEY=your_key_here
```

---

## 📈 Roadmap & CI
The project includes a GitHub Actions CI (`.github/workflows/ci.yml`) that:
1.  Builds the project on macOS.
2.  Runs the Swift unit test suite.
3.  Executes a "Smoke Test" on fixtures to ensure the analysis engine is healthy.
