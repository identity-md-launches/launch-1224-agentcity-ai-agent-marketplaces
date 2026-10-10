// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @notice Offline editorial checks for this report's intentionally narrow Markdown format.
/// @dev Internal-only library; it does not assess factual accuracy or operate a marketplace.
library ReportChecks {
    enum Failure {
        None,
        Empty,
        WordLimit,
        Sections,
        Table,
        Sources,
        Gaps,
        Recommendations,
        Date
    }

    function inspect(string memory report) internal pure returns (Failure) {
        bytes memory data = bytes(report);
        if (data.length == 0) return Failure.Empty;
        if (words(data) >= 2000) return Failure.WordLimit;
        bytes[5] memory headings = [
            bytes("\n## 1. Overview\n"),
            bytes("\n## 2. The main players\n"),
            bytes("\n## 3. Trust and payments\n"),
            bytes("\n## 4. Gaps\n"),
            bytes("\n## 5. Recommendations\n")
        ];
        uint256[5] memory positions;
        uint256 cursor = 0;
        for (uint256 i; i < 5; ++i) {
            positions[i] = find(data, headings[i], cursor);
            if (positions[i] == type(uint256).max) return Failure.Sections;
            cursor = positions[i] + headings[i].length;
        }
        if (count(data, bytes("\n## "), 0, data.length) != 5) return Failure.Sections;
        if (!table(data, positions[1], positions[2])) return Failure.Table;
        if (sources(data) < 8) return Failure.Sources;
        if (!numbered(data, positions[3], positions[4], 3)) return Failure.Gaps;
        if (!numbered(data, positions[4], data.length, 5)) return Failure.Recommendations;
        if (find(data, bytes("10 October 2026"), 0) == type(uint256).max) return Failure.Date;
        return Failure.None;
    }

    /// @dev Conservative whitespace count includes Markdown syntax and URLs.
    function words(bytes memory data) internal pure returns (uint256 result) {
        bool inside = false;
        for (uint256 i; i < data.length; ++i) {
            bool space = whitespace(data[i]);
            if (!space && !inside) ++result;
            inside = !space;
        }
    }

    function whitespace(bytes1 value) private pure returns (bool) {
        return value == 0x20 || (value >= 0x09 && value <= 0x0d);
    }

    function find(bytes memory data, bytes memory needle, uint256 start) internal pure returns (uint256) {
        if (needle.length == 0 || needle.length > data.length || start > data.length - needle.length) {
            return type(uint256).max;
        }
        for (uint256 i = start; i <= data.length - needle.length; ++i) {
            bool same = true;
            for (uint256 j; j < needle.length; ++j) {
                if (data[i + j] != needle[j]) {
                    same = false;
                    break;
                }
            }
            if (same) return i;
        }
        return type(uint256).max;
    }

    function count(bytes memory data, bytes memory needle, uint256 start, uint256 end)
        internal
        pure
        returns (uint256 result)
    {
        uint256 cursor = start;
        while (cursor < end) {
            uint256 at = find(data, needle, cursor);
            if (at == type(uint256).max || at + needle.length > end) break;
            ++result;
            cursor = at + needle.length;
        }
    }

    function table(bytes memory data, uint256 start, uint256 end) private pure returns (bool) {
        uint256 rows = 0;
        uint256 cursor = start;
        bool separator = false;
        while (cursor < end) {
            uint256 at = find(data, bytes("\n| "), cursor);
            if (at == type(uint256).max || at >= end) break;
            uint256 lineEnd = find(data, bytes("\n"), at + 1);
            if (lineEnd == type(uint256).max || lineEnd > end) return false;
            // Four columns, including their outer boundaries; no empty cells.
            if (count(data, bytes("|"), at, lineEnd) != 5) return false;
            if (count(data, bytes("|  |"), at, lineEnd) != 0) return false;
            if (rows == 0) {
                if (
                    find(
                            data,
                            bytes(
                                "\n| Marketplace or network | What it offers | How clients pay | How agent quality is shown |\n"
                            ),
                            at
                        ) != at
                ) return false;
            }
            if (rows == 1) separator = find(data, bytes("\n| --- | --- | --- | --- |\n"), at) == at;
            ++rows;
            cursor = lineEnd;
        }
        return separator && rows >= 8;
    }

    /// @dev Counts distinct, syntactically complete inline HTTPS citations with a label.
    function sources(bytes memory data) internal pure returns (uint256 total) {
        bytes32[] memory seen = new bytes32[](count(data, bytes("](https://"), 0, data.length));
        uint256 cursor = 0;
        while (cursor < data.length) {
            uint256 at = find(data, bytes("](https://"), cursor);
            if (at == type(uint256).max) break;
            uint256 end = find(data, bytes(")"), at + 9);
            if (end == type(uint256).max) break;
            uint256 labelStart = at;
            while (labelStart > 0 && data[labelStart - 1] != "[" && data[labelStart - 1] != "\n") {
                --labelStart;
            }
            bool valid = labelStart > 0 && data[labelStart - 1] == "[" && labelStart < at && end > at + 10;
            bytes memory url = new bytes(end - at - 2);
            for (uint256 i; i < url.length; ++i) {
                url[i] = data[at + 2 + i];
                if (whitespace(url[i]) || url[i] == "[") valid = false;
            }
            if (valid) {
                bytes32 digest = keccak256(url);
                bool duplicate = false;
                for (uint256 i; i < total; ++i) {
                    if (seen[i] == digest) duplicate = true;
                }
                if (!duplicate) seen[total++] = digest;
            }
            cursor = end + 1;
        }
    }

    function numbered(bytes memory data, uint256 start, uint256 end, uint256 expected) private pure returns (bool) {
        uint256 items = 0;
        for (uint256 i = start; i + 3 < end; ++i) {
            if (data[i] != "\n" || data[i + 1] < "0" || data[i + 1] > "9") continue;
            uint256 digitEnd = i + 2;
            while (digitEnd < end && data[digitEnd] >= "0" && data[digitEnd] <= "9") {
                ++digitEnd;
            }
            if (digitEnd + 1 < end && data[digitEnd] == "." && data[digitEnd + 1] == " ") {
                ++items;
                if (digitEnd != i + 2 || items > expected || uint8(data[i + 1]) != 48 + items) return false;
            }
        }
        return items == expected;
    }
}
