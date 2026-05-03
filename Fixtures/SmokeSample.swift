/// Minimal Swift source used by CI to smoke-test the `AIAnalyzer` executable.
/// Parsed with default rule configuration; AI must stay off in CI (`AI_ENABLED=false`).
struct SmokeFixture {
    let id: Int

    func describe() -> String {
        "smoke-\(id)"
    }
}
