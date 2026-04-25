# AIAnalyzer

AIAnalyzer is a static analysis tool for Swift source code. It leverages the `SwiftSyntax` library to parse Swift files, extract structural metrics, and identify potential code smells through a modular rule engine.

## Core Purpose
The tool aims to help developers maintain code quality by automatically flagging classes that violate design principles, such as having too many methods or properties.

## Architecture

### 1. Models
- **`ClassInfo`**: Stores metrics for extracted classes (method count, property count, line count).
- **`Issue` & `Severity`**: Define the structure and importance of found code smells.

### 2. Visitor
- **`ClassVisitor`**: Uses `SwiftSyntax` to traverse the Abstract Syntax Tree (AST) and collect data on class declarations.

### 3. Rules
- **`Rule` Protocol**: A standardized interface for creating new analysis logic.
- **`RuleEngine`**: Executes a collection of rules against the extracted class data.
- **Implemented Rules**:
  - `LargeClassRule`: Flags classes with excessive method counts.
  - `DataHeavyClassRule`: Identifies classes with too many properties.

### 4. App
- **`AnalyzerApp`**: The command-line interface entry point that coordinates parsing, analysis, and reporting.

## Workflow
1. **Parsing**: Converts Swift source code into a structured Syntax Tree.
2. **Extraction**: Scans the tree to build a profile of every class.
3. **Evaluation**: Runs the rule engine to detect violations.
4. **Reporting**: Outputs a formatted list of issues to the console.

## Usage

To analyze a Swift file, run:

```bash
swift run AIAnalyzer <path-to-file.swift>
```

## Testing

The project includes unit tests for the rule engine and individual rules. Run them using:

```bash
swift test
```
