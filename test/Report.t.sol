// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ReportChecks} from "../src/ReportChecks.sol";
import {ReportText} from "./fixtures/ReportText.sol";

contract ReportTest {
    function testReportMeetsAssignment() public pure {
        require(ReportChecks.inspect(ReportText.text()) == ReportChecks.Failure.None, "report fails assignment");
    }

    function testEmptyReportFails() public pure {
        require(ReportChecks.inspect("") == ReportChecks.Failure.Empty, "empty accepted");
    }

    function testMissingSectionFails() public pure {
        checkMutation("## 3. Trust and payments", "## 3. Payments", ReportChecks.Failure.Sections);
    }

    function testOutOfOrderSectionFails() public pure {
        checkMutation("## 2. The main players", "## 3. Trust and payments", ReportChecks.Failure.Sections);
    }

    function testExtraSectionFails() public pure {
        require(
            ReportChecks.inspect(string.concat(ReportText.text(), "\n## Appendix\n")) == ReportChecks.Failure.Sections,
            "extra section accepted"
        );
    }

    function testTooFewPlayersFails() public pure {
        checkMutation("\n| [Olas", "\n [Olas", ReportChecks.Failure.Table);
    }

    function testBrokenTableSeparatorFails() public pure {
        checkMutation("| --- | --- | --- | --- |", "| --- | --- | --- |", ReportChecks.Failure.Table);
    }

    function testMissingPaymentColumnFails() public pure {
        checkMutation("How clients pay", "Payment not compared", ReportChecks.Failure.Table);
    }

    function testUnlinkedSourcesFail() public pure {
        bytes memory report = bytes(ReportText.text());
        // Disable all inline HTTPS links without deleting the surrounding claims.
        for (uint256 i; i + 8 < report.length; ++i) {
            if (report[i] == "]" && report[i + 1] == "(" && report[i + 2] == "h") report[i + 1] = "{";
        }
        require(ReportChecks.inspect(string(report)) == ReportChecks.Failure.Sources, "uncited report accepted");
    }

    function testDuplicateCitationDoesNotInflateCount() public pure {
        require(
            ReportChecks.sources(bytes("[a](https://docs.site/path) [b](https://docs.site/path)")) == 1,
            "duplicate counted twice"
        );
    }

    function testMalformedCitationsDoNotCount() public pure {
        require(
            ReportChecks.sources(bytes("[](https://docs.site) [a](https://) [b](https://bad url) [c](https://missing"))
                == 0,
            "malformed source counted"
        );
    }

    function testEightDistinctSourcesCount() public pure {
        require(
            ReportChecks.sources(
                bytes(
                    "[a](https://a.site) [b](https://b.site) [c](https://c.site) [d](https://d.site) [e](https://e.site) [f](https://f.site) [g](https://g.site) [h](https://h.site)"
                )
            ) == 8,
            "distinct sources lost"
        );
    }

    function testMissingGapFails() public pure {
        checkMutation("3. **Responsibility", "- **Responsibility", ReportChecks.Failure.Gaps);
    }

    function testExtraGapFails() public pure {
        checkMutation("## 5. Recommendations", "10. Extra gap\n\n## 5. Recommendations", ReportChecks.Failure.Gaps);
    }

    function testMissingRecommendationFails() public pure {
        checkMutation("5. **Scoped", "- **Scoped", ReportChecks.Failure.Recommendations);
    }

    function testExtraRecommendationFails() public pure {
        require(
            ReportChecks.inspect(string.concat(ReportText.text(), "\n6. Extra feature\n"))
                == ReportChecks.Failure.Recommendations,
            "extra recommendation accepted"
        );
    }

    function testDuplicateRecommendationNumberFails() public pure {
        checkMutation("5. **Scoped", "4. **Scoped", ReportChecks.Failure.Recommendations);
    }

    function testMissingAsOfDateFails() public pure {
        checkMutation("10 October 2026", "October 2025", ReportChecks.Failure.Date);
    }

    function testWordLimitIsStrict() public pure {
        bytes memory padded = new bytes(4000);
        for (uint256 i; i < padded.length; i += 2) {
            padded[i] = "x";
            padded[i + 1] = " ";
        }
        require(ReportChecks.words(padded) == 2000, "word counter wrong");
        require(ReportChecks.inspect(string(padded)) == ReportChecks.Failure.WordLimit, "2000 words accepted");
        bytes memory shorter = new bytes(3998);
        for (uint256 i; i < shorter.length; ++i) {
            shorter[i] = padded[i];
        }
        require(ReportChecks.words(shorter) == 1999, "1999 boundary wrong");
        require(ReportChecks.inspect(string(shorter)) == ReportChecks.Failure.Sections, "1999 rejected by budget");
    }

    function testWhitespaceAndUnicodeWords() public pure {
        require(
            ReportChecks.words(bytes(unicode"  CLI\tfix\r\nfor Orino — automation  ")) == 6, "whitespace count wrong"
        );
    }

    function testFuzzWordsWithWhitespace(uint8 size) public pure {
        bytes memory sample = new bytes(uint256(size) * 3);
        for (uint256 i; i < size; ++i) {
            sample[i * 3] = "x";
            sample[i * 3 + 1] = "\n";
            sample[i * 3 + 2] = "\t";
        }
        require(ReportChecks.words(sample) == size, "separator-dependent word count");
    }

    function checkMutation(string memory needle, string memory replacement, ReportChecks.Failure expected)
        private
        pure
    {
        bytes memory original = bytes(ReportText.text());
        bytes memory before = bytes(needle);
        bytes memory after_ = bytes(replacement);
        uint256 at = ReportChecks.find(original, before, 0);
        require(at != type(uint256).max, "mutation not applied");
        bytes memory modified = new bytes(original.length - before.length + after_.length);
        for (uint256 i; i < at; ++i) {
            modified[i] = original[i];
        }
        for (uint256 i; i < after_.length; ++i) {
            modified[at + i] = after_[i];
        }
        for (uint256 i = at + before.length; i < original.length; ++i) {
            modified[i - before.length + after_.length] = original[i];
        }
        require(ReportChecks.inspect(string(modified)) == expected, "invalid report not rejected as expected");
    }
}
