# AIAnalyzer

AIAnalyzer is a static analysis tool for Swift source code. It leverages the `SwiftSyntax` library to parse Swift files, extract structural metrics, and identify potential code smells through a modular rule engine.

## Core Purpose
The tool aims to help developers maintain code quality by automatically flagging classes that violate design principles, such as having too many methods or properties.

## Architecture

### 1. Models
- **`ClassInfo`**: Stores metrics for extracted classes (method count, property count, line count).
- **`Issue` & `Severity`**: Define the structure and importance of found code smells.
- **`AnalyzerConfig`**: Defines configurable rules and ignored directories.

### 2. App / Orchestration
- **`AnalyzerApp`**: The CLI entry point that validates input, loads config, scans files, runs rules, and prints the summary.
- **`InputPathValidator`**: Validates single-file CLI input and enforces `.swift` extension.

### 3. Visitor
- **`ClassVisitor`**: Uses `SwiftSyntax` to traverse the Abstract Syntax Tree (AST) and collect data on class declarations.

### 4. Rules
- **`Rule` Protocol**: A standardized interface for creating new analysis logic.
- **`RuleEngine`**: Executes configured rules and suppresses redundant structural findings when `GodObject` is already detected for a class.
- Built-in rules:
  - **`LargeClassRule`**
  - **`HighMethodDensityRule`**
  - **`DataHeavyClassRule`**
  - **`GodObjectRule`**

### 5. Reporting
- **`Reporter` Protocol**: Interface for reporting discovered issues.
- **`ConsoleReporter`**: Implementation that outputs results to the standard console.

### 6. Configuration
- **`.aianalyzer.json`**: Optional project-level configuration for ignore directories and rule toggles/thresholds.
- Default ignored folders are centralized in `AnalyzerConfig.default`.

## Workflow
1. **Validate Input**: Ensures path exists; single-file input must be a `.swift` file.
2. **Load Config**: Loads `.aianalyzer.json` if present, otherwise uses defaults.
3. **Discovery**: Scans target directories for Swift files while honoring ignore lists.
4. **Parsing & Extraction**: Builds AST and extracts class metrics.
5. **Evaluation**: Runs rule engine and filters redundant overlaps (`GodObject` supersedes weaker structural signals).
6. **Reporting**: Prints per-file issues and final aggregate summary.

## Usage

To analyze a Swift file:

```bash
swift run AIAnalyzer <path-to-file.swift>
```

To analyze a folder recursively:

```bash
swift run AIAnalyzer <path-to-folder>
```

If a non-Swift file is passed in single-file mode, AIAnalyzer exits with:

```text
❌ Single-file input must be a .swift file
```

## Configuration

Example `.aianalyzer.json`:

```json
{
  "ignoreDirectories": ["TestSandbox", "Generated", "Builds", "Pods"],
  "rules": {
    "largeClass": { "enabled": true, "threshold": 15 },
    "highMethodDensity": { "enabled": true, "threshold": 8 },
    "godObject": { "enabled": true },
    "dataHeavyClass": { "enabled": true, "threshold": 5 }
  }
}
```

## Testing

Run the full test suite:

```bash
swift test
```

Run only overlap/dedup behavior tests:

```bash
swift test --filter RuleEngineDedupTests
```
