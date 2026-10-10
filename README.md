# AgentCity landscape report

The deliverable is [report.md](report.md): a sourced Markdown report for Orino, as of **10 October 2026**, comparing six AI agent marketplaces or networks, their payment and trust mechanisms, three gaps and five proposed AgentCity features. The report is below 2,000 words, including its table and citations.

## Assumptions and evidence

- AgentCity's location on Robinhood Chain and Orino's client role come from the assignment. No AgentCity code, deployed addresses or operating policies were supplied or inferred.
- Research uses official product documentation and Ethereum specifications, accessed on 10 October 2026. The report describes the available evidence up to that date, not the remainder of October.
- “Main players” means six relevant examples spanning commercial jobs, agent networks, paid tool discovery and enterprise procurement. It is not an exhaustive census or a market-share ranking.
- Product documentation establishes what providers document, not an independent test of production availability or reliability. No wallets were funded and no paid jobs were executed.
- Roadmaps and uncertain protections are labeled. Absence of a uniform refund or appeal policy in reviewed pages is reported as unverified, not proof that no provider offers one privately.
- ERC-8004 and ERC-8183 are labeled Draft according to their primary specifications, regardless of production implementations. Identity registration, usage and settlement are distinguished from successful delivery.
- The report contains no numerical estimates of market size, adoption, fees or return on investment. Gaps are explicitly analytical judgments; features are proposals.

## Local verification

The required Foundry project is at the repository root, with **Solidity 0.8.26** pinned in `foundry.toml`. It has no third-party dependencies, remappings, submodules or package installs. Build and test require only Foundry and the pinned compiler supplied by the verifier. The optional fixture tool uses Python 3's standard library.

```sh
python3 scripts/report_fixture.py --check
forge build
forge test
forge fmt --check
```

`src/ReportChecks.sol` is an internal, pure editorial-check library. `test/Report.t.sol` tests the exact report embedded in `test/fixtures/ReportText.sol`, plus invalid variants: missing/reordered/extra sections, too few marketplace rows, missing payment columns, broken tables, absent/duplicate/malformed citations, wrong gap/feature counts, absent date and the strict 2,000-word boundary. Whitespace counting also has a fuzz test. All tests are independent and require no environment variables, clock waits, network, FFI or filesystem cheatcodes.

The committed fixture keeps `forge test` usable in the verifier's offline environment without filesystem access. The separate `--check` ensures the fixture still matches the Markdown byte-for-byte; ordinary `forge test` alone cannot detect an edit to Markdown that was not regenerated. The checker recognizes this report's specified headings, four-column table, inline HTTPS citations and numbered lists; it is not a general Markdown parser. It checks format and counts, not whether sources are truthful, links remain live or factual statements are accurate. Those require editorial review.

After editing the report:

```sh
python3 scripts/report_fixture.py
forge fmt
python3 scripts/report_fixture.py --check
forge build
forge test
forge fmt --check
```

## Deployment parameters

This is a research deliverable. There are no deployable application contracts, deploy scripts, payment assets, owners, recipients, RPCs, credentials or constructor parameters to configure. Solidity supports offline report checks only. No transactions or launch manifest are needed to use the report.

The five recommendations are future product work. Implementing them would require a separate specification that selects the launch network, verified payment asset and decimals, registry/facilitator integration, escrow administrator, evaluator, deadline and fee policies, dispute reviewer and appeal rules. These choices remain open; this repository does not insert guessed addresses or chain parameters.

## Operational responsibilities

- **Report maintainer:** Refresh primary sources before relying on the comparison, record the new evidence date, review roadmaps versus released features, regenerate the fixture and rerun checks.
- **AgentCity product operator:** If adopting recommendations, publish acceptance, refund, partial-payment and dispute terms; appoint reviewers and disclose conflicts and administrative powers.
- **Integration operator:** Verify contracts and asset identities on Robinhood Chain, facilitator support, custody/authorization limits and failure recovery before connecting real payments. Arrange independent adversarial review of any future funds-holding implementation.
- **Agent operator and client:** Agree on reproducible acceptance tests, approved tools, spending caps and responsibility for subcontracted work; retain redacted evidence without publishing client secrets.
