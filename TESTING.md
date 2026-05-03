# Testing the Visitor changes

Quick commands (run from project root /Users/johnson/Projects/AIAnalyzer):

- Run full unit test suite:
  ```bash
  swift test
  ```

- Run only visitor-related tests:
  ```bash
  swift test --filter Visitor
  ```

- Run the CLI analyzer against the included sample file:
  ```bash
  # Disable AI calls to avoid network/local model noise:
  AI_ENABLED=false swift run AIAnalyzer sample.swift
  ```

What to look for
- Unit tests should pass (including the updated Visitor tests that assert methodCount, propertyCount, initializerCount, subscriptCount, accessorCount, and memberInfos).
- CLI run (sample) prints per-file classes and metrics. With AI disabled you should only see ConsoleReporter output (class names, methods, properties, lines).
- If you need to inspect raw visitor output programmatically, add a small runnable snippet that parses a file with `Parser.parse(...)`, instantiates `ClassVisitor`, calls `visitor.walk(sourceFile)`, and prints `visitor.classes` (use `swift run` or a short Swift script).

Troubleshooting
- If tests fail after changes, run the failing tests in isolation:
  ```bash
  swift test --filter <TestName>
  ```
- To prevent AI provider side-effects during testing, set `AI_ENABLED=false` in the environment or in `.aianalyzer.env`.
- To inspect exact member ranges next, consider running the analyzer on a small file and comparing `memberInfos` printed in a temporary debug print in `ConsoleReporter` or a quick script.

Notes
- Phase 2 (more precise line numbers) will replace description-based counting with `SourceLocationConverter`. After that you should re-run the same tests and verify exact start/end lines in `memberInfos`.