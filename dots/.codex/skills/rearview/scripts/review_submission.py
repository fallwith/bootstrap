#!/usr/bin/env python3
"""Validate, render, and verify one Rearview submission."""

from __future__ import annotations

import argparse
import ast
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
from typing import Any


SEVERITIES = {"critical", "high", "medium", "low"}
CONFIDENCES = {"high", "medium", "low"}
REQUIRED_CLASSIFICATION_SEVERITIES = {"critical", "high", "medium"}
AUTHORITY_TYPES = {"functional", "security", "repository_rule", "explicit_review_request"}
AUTHORITY_KEYS = {"type", "path", "line"}
SIDES = {"LEFT", "RIGHT"}
REVIEW_EVENTS = {"APPROVE", "COMMENT", "REQUEST_CHANGES"}
DISCUSSION_CHECKS = {"not-needed", "privacy-skipped", "rechecked"}
REVIEW_STATES = {
    "APPROVE": "APPROVED",
    "COMMENT": "COMMENTED",
    "REQUEST_CHANGES": "CHANGES_REQUESTED",
}
PLAN_KEYS = {
    "agent",
    "user_attribution",
    "event_override",
    "review_body_override",
    "discussion_check",
    "comments",
    "duplicates",
    "replies",
    "comment_length_exceptions",
    "additional_caveats",
}
COMMENT_KEYS = {"finding_number", "path", "line", "side", "body"}
DUPLICATE_KEYS = {"finding_number", "thread_url", "reason"}
LENGTH_EXCEPTION_KEYS = {"finding_number", "reason"}
TIMING_KEYS = {"phase", "seconds"}
REQUIRED_TIMING_PHASES = {
    "metadata",
    "normalization",
    "reconciliation",
    "repository-research",
    "review",
}
SINGULAR_VOICE = re.compile(r"(?<![A-Za-z0-9_])(?:I|me|my|I'm)(?![A-Za-z0-9_])")
WORD = re.compile(r"[A-Za-z0-9_]+(?:['-][A-Za-z0-9_]+)*")
HUNK = re.compile(r"^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@")
REPOSITORY = re.compile(r"^[A-Za-z0-9][A-Za-z0-9.-]*/[A-Za-z0-9_.-]+$")


class ValidationError(Exception):
    """Raised when an artifact cannot be submitted safely."""


def fail(message: str) -> None:
    raise ValidationError(message)


def load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        fail(f"cannot read JSON from {path}: {error}")


def require_type(value: Any, expected: type, label: str) -> None:
    if expected is int:
        valid = isinstance(value, int) and not isinstance(value, bool)
    else:
        valid = isinstance(value, expected)
    if not valid:
        fail(f"{label} must be {expected.__name__}")


def require_nonempty_string(value: Any, label: str) -> None:
    require_type(value, str, label)
    if not value.strip():
        fail(f"{label} must not be empty")


def require_exact_keys(value: dict[str, Any], keys: set[str], label: str) -> None:
    missing = sorted(keys - value.keys())
    extra = sorted(value.keys() - keys)
    if missing or extra:
        fail(f"{label} keys differ: missing={missing}, extra={extra}")


def require_string_list(value: Any, label: str) -> None:
    require_type(value, list, label)
    for index, item in enumerate(value):
        require_type(item, str, f"{label}[{index}]")


def validate_lane_results(value: Any, label: str) -> None:
    require_type(value, list, label)
    for index, item in enumerate(value):
        require_type(item, dict, f"{label}[{index}]")
        require_exact_keys(item, {"lane", "reason"}, f"{label}[{index}]")
        require_nonempty_string(item["lane"], f"{label}[{index}].lane")
        require_nonempty_string(item["reason"], f"{label}[{index}].reason")


def validate_timings(value: Any, label: str) -> None:
    require_type(value, list, label)
    phases: list[str] = []
    for index, item in enumerate(value):
        item_label = f"{label}[{index}]"
        require_type(item, dict, item_label)
        require_exact_keys(item, TIMING_KEYS, item_label)
        require_nonempty_string(item["phase"], f"{item_label}.phase")
        validate_ascii(item["phase"], f"{item_label}.phase")
        seconds = item["seconds"]
        if isinstance(seconds, bool) or not isinstance(seconds, (int, float)) or seconds < 0:
            fail(f"{item_label}.seconds must be a non-negative number")
        phases.append(item["phase"])
    if len(phases) != len(set(phases)):
        fail(f"{label} contains duplicate phases")
    missing = sorted(REQUIRED_TIMING_PHASES - set(phases))
    if missing:
        fail(f"{label} is missing required phases: {missing}")


def validate_proof(value: Any, label: str) -> None:
    if value is None or value == "not_applicable":
        return
    require_type(value, dict, label)
    if value.get("reproduced") is False:
        require_exact_keys(value, {"reproduced", "reason"}, label)
        require_nonempty_string(value["reason"], f"{label}.reason")
        return
    if value.get("reproduced") is True:
        keys = {
            "reproduced",
            "spec",
            "spec_body",
            "failure_output",
            "fix_description",
            "execution_boundary",
            "pass_count",
            "files_reverted",
        }
        require_exact_keys(value, keys, label)
        for key in keys - {"reproduced", "pass_count", "files_reverted"}:
            require_nonempty_string(value[key], f"{label}.{key}")
        require_type(value["pass_count"], int, f"{label}.pass_count")
        if value["pass_count"] <= 0:
            fail(f"{label}.pass_count must be positive")
        require_string_list(value["files_reverted"], f"{label}.files_reverted")
        return
    fail(f"{label} has an invalid proof state")


def validate_authority(value: Any, label: str) -> None:
    require_type(value, dict, label)
    require_exact_keys(value, AUTHORITY_KEYS, label)
    authority_type = value["type"]
    require_nonempty_string(authority_type, f"{label}.type")
    if authority_type not in AUTHORITY_TYPES:
        fail(f"{label} authority type must be one of {sorted(AUTHORITY_TYPES)}")
    if authority_type == "repository_rule":
        require_nonempty_string(value["path"], f"{label}.path")
        path = value["path"]
        if path.startswith("/") or "\\" in path or ":" in path or ".." in path.split("/"):
            fail(f"{label}.path must be a safe repository-relative path")
        require_type(value["line"], int, f"{label}.line")
        if value["line"] <= 0:
            fail(f"{label}.line must be positive")
        return
    if value["path"] is not None or value["line"] is not None:
        fail(f"{label}.path and {label}.line must be null unless type is repository_rule")


def validate_sidecar(data: Any) -> dict[str, Any]:
    require_type(data, dict, "sidecar")
    required = {
        "pr_number",
        "pr_url",
        "head_commit",
        "base_branch",
        "title",
        "repo",
        "files_changed",
        "lines_added",
        "lines_removed",
        "changed_files",
        "changed_ranges",
        "findings",
        "low_confidence_findings",
        "design_context",
        "lanes_run",
        "lanes_skipped",
        "lanes_failed",
        "tests_run",
        "not_verified",
        "timings",
    }
    missing = sorted(required - data.keys())
    if missing:
        fail(f"sidecar is missing keys: {missing}")

    require_type(data["pr_number"], int, "sidecar.pr_number")
    if data["pr_number"] <= 0:
        fail("sidecar.pr_number must be positive")
    for key in ("pr_url", "head_commit", "base_branch", "title", "repo"):
        require_nonempty_string(data[key], f"sidecar.{key}")
    if not REPOSITORY.fullmatch(data["repo"]):
        fail("sidecar.repo must be an owner/repository name")
    expected_pr_url = f"https://github.com/{data['repo']}/pull/{data['pr_number']}"
    if data["pr_url"] != expected_pr_url:
        fail("sidecar.pr_url must identify sidecar.repo and sidecar.pr_number")
    for key in ("files_changed", "lines_added", "lines_removed"):
        require_type(data[key], int, f"sidecar.{key}")
        if data[key] < 0:
            fail(f"sidecar.{key} must be non-negative")

    require_string_list(data["changed_files"], "sidecar.changed_files")
    if len(data["changed_files"]) != len(set(data["changed_files"])):
        fail("sidecar.changed_files contains duplicates")
    if data["files_changed"] != len(data["changed_files"]):
        fail("sidecar.files_changed must equal the number of sidecar.changed_files")
    require_type(data["changed_ranges"], dict, "sidecar.changed_ranges")
    if set(data["changed_ranges"]) != set(data["changed_files"]):
        fail("sidecar.changed_ranges keys must equal sidecar.changed_files")
    for path, ranges in data["changed_ranges"].items():
        require_type(ranges, list, f"sidecar.changed_ranges[{path!r}]")
        for index, pair in enumerate(ranges):
            require_type(pair, list, f"changed range {path}[{index}]")
            if len(pair) != 2:
                fail(f"changed range {path}[{index}] must contain two lines")
            start, end = pair
            require_type(start, int, f"changed range {path}[{index}][0]")
            require_type(end, int, f"changed range {path}[{index}][1]")
            if start <= 0 or end < start:
                fail(f"changed range {path}[{index}] is invalid")

    require_type(data["findings"], list, "sidecar.findings")
    numbers: list[int] = []
    finding_keys = {
        "number",
        "severity",
        "title",
        "file",
        "line",
        "source_url",
        "consequence",
        "recommendation",
        "code_snippet",
        "confidence",
        "contributing_lanes",
        "proof",
        "authority",
    }
    for index, finding in enumerate(data["findings"]):
        label = f"sidecar.findings[{index}]"
        require_type(finding, dict, label)
        missing_finding = sorted(finding_keys - finding.keys())
        if missing_finding:
            fail(f"{label} is missing keys: {missing_finding}")
        require_type(finding["number"], int, f"{label}.number")
        require_type(finding["line"], int, f"{label}.line")
        if finding["number"] <= 0 or finding["line"] <= 0:
            fail(f"{label} number and line must be positive")
        numbers.append(finding["number"])
        for key in ("severity", "title", "file", "source_url", "consequence", "recommendation", "confidence"):
            require_nonempty_string(finding[key], f"{label}.{key}")
        if finding["file"] not in data["changed_files"]:
            fail(f"{label}.file is absent from sidecar.changed_files")
        require_type(finding["code_snippet"], str, f"{label}.code_snippet")
        if finding["severity"] not in SEVERITIES:
            fail(f"{label}.severity is invalid")
        if finding["confidence"] not in CONFIDENCES - {"low"}:
            fail(f"{label}.confidence must be high or medium")
        require_string_list(finding["contributing_lanes"], f"{label}.contributing_lanes")
        if not finding["contributing_lanes"]:
            fail(f"{label}.contributing_lanes must not be empty")
        validate_proof(finding["proof"], f"{label}.proof")
        validate_authority(finding["authority"], f"{label}.authority")
    if numbers != list(range(1, len(numbers) + 1)):
        fail("sidecar finding numbers must be contiguous from 1")

    require_type(data["low_confidence_findings"], list, "sidecar.low_confidence_findings")
    low_keys = {"title", "file", "line", "source_url", "description", "confidence", "authority"}
    for index, finding in enumerate(data["low_confidence_findings"]):
        label = f"sidecar.low_confidence_findings[{index}]"
        require_type(finding, dict, label)
        missing_low = sorted(low_keys - finding.keys())
        if missing_low:
            fail(f"{label} is missing keys: {missing_low}")
        require_type(finding["line"], int, f"{label}.line")
        if finding["line"] <= 0:
            fail(f"{label}.line must be positive")
        for key in ("title", "file", "source_url", "description"):
            require_nonempty_string(finding[key], f"{label}.{key}")
        if finding["file"] not in data["changed_files"]:
            fail(f"{label}.file is absent from sidecar.changed_files")
        if finding["confidence"] != "low":
            fail(f"{label}.confidence must be low")
        validate_authority(finding["authority"], f"{label}.authority")

    if data["design_context"] is not None:
        require_type(data["design_context"], str, "sidecar.design_context")
    require_string_list(data["lanes_run"], "sidecar.lanes_run")
    require_string_list(data["not_verified"], "sidecar.not_verified")
    validate_lane_results(data["lanes_skipped"], "sidecar.lanes_skipped")
    validate_lane_results(data["lanes_failed"], "sidecar.lanes_failed")
    validate_timings(data["timings"], "sidecar.timings")
    if "timing_warnings" in data:
        require_string_list(data["timing_warnings"], "sidecar.timing_warnings")
        for index, warning in enumerate(data["timing_warnings"]):
            require_nonempty_string(warning, f"sidecar.timing_warnings[{index}]")
    require_type(data["tests_run"], list, "sidecar.tests_run")
    for index, test in enumerate(data["tests_run"]):
        label = f"sidecar.tests_run[{index}]"
        require_type(test, dict, label)
        require_exact_keys(test, {"command", "result"}, label)
        require_nonempty_string(test["command"], f"{label}.command")
        require_nonempty_string(test["result"], f"{label}.result")
    if "publication_plan" in data:
        validate_plan(data["publication_plan"], data)
    return data


def validate_repository_rule_sources(sidecar: dict[str, Any]) -> None:
    findings = [*sidecar["findings"], *sidecar["low_confidence_findings"]]
    for finding in findings:
        authority = finding["authority"]
        if authority["type"] != "repository_rule":
            continue
        source = f"{sidecar['head_commit']}:{authority['path']}"
        result = subprocess.run(
            ["git", "cat-file", "-e", source],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        if result.returncode != 0:
            fail(
                f"finding authority path {authority['path']!r} is not tracked "
                "at sidecar.head_commit"
            )


def validate_ascii(value: str, label: str) -> None:
    for index, character in enumerate(value):
        if ord(character) > 127:
            fail(f"{label} contains non-ASCII U+{ord(character):04X} at character {index + 1}")


def prose_without_code(value: str) -> str:
    lines = value.splitlines()
    kept: list[str] = []
    fence: str | None = None
    for line in lines:
        stripped = line.lstrip()
        match = re.match(r"(`{3,}|~{3,})", stripped)
        if match:
            marker = match.group(1)
            if fence is None:
                fence = marker[0]
            elif marker[0] == fence:
                fence = None
            continue
        if fence is None:
            kept.append(line)
    prose = "\n".join(kept)
    return re.sub(r"`+[^`\n]*`+", "", prose)


def validate_owned_prose(value: str, label: str) -> None:
    validate_ascii(value, label)
    prose = prose_without_code(value)
    match = SINGULAR_VOICE.search(prose)
    if match:
        fail(f"{label} contains singular voice {match.group(0)!r}; inspect and rewrite it")


def validate_numbered_reason_entries(
    entries: Any,
    keys: set[str],
    label: str,
    finding_numbers: set[int],
) -> list[dict[str, Any]]:
    require_type(entries, list, label)
    result = []
    for index, entry in enumerate(entries):
        item_label = f"{label}[{index}]"
        require_type(entry, dict, item_label)
        require_exact_keys(entry, keys, item_label)
        require_type(entry["finding_number"], int, f"{item_label}.finding_number")
        if entry["finding_number"] not in finding_numbers:
            fail(f"{item_label}.finding_number does not identify a sidecar finding")
        require_nonempty_string(entry["reason"], f"{item_label}.reason")
        validate_ascii(entry["reason"], f"{item_label}.reason")
        result.append(entry)
    return result


def validate_plan(data: Any, sidecar: dict[str, Any]) -> dict[str, Any]:
    require_type(data, dict, "plan")
    required_plan_keys = PLAN_KEYS - {"review_body_override", "replies"}
    missing = sorted(required_plan_keys - data.keys())
    extra = sorted(data.keys() - PLAN_KEYS)
    if missing or extra:
        fail(f"plan keys differ: missing={missing}, extra={extra}")
    require_nonempty_string(data["agent"], "plan.agent")
    if "&" in data["agent"] or "--" in data["agent"]:
        fail("plan.agent must contain only the agent product name")
    validate_ascii(data["agent"], "plan.agent")
    require_nonempty_string(data["user_attribution"], "plan.user_attribution")
    if "&" in data["user_attribution"] or "--" in data["user_attribution"]:
        fail("plan.user_attribution must contain only the public user label")
    validate_ascii(data["user_attribution"], "plan.user_attribution")
    if data["event_override"] is not None:
        require_type(data["event_override"], str, "plan.event_override")
        if data["event_override"] not in REVIEW_EVENTS:
            fail("plan.event_override must be APPROVE, COMMENT, REQUEST_CHANGES, or null")
    attribution = attribution_marker(data["agent"], data["user_attribution"])
    review_body_override = data.get("review_body_override")
    if review_body_override is not None:
        require_nonempty_string(review_body_override, "plan.review_body_override")
        compact_attribution = f"--{data['agent']} & {data['user_attribution']}"
        if attribution in review_body_override or compact_attribution in review_body_override:
            fail("plan.review_body_override must omit attribution; the helper appends it")
        validate_owned_prose(review_body_override, "plan.review_body_override")
    require_nonempty_string(data["discussion_check"], "plan.discussion_check")
    if data["discussion_check"] not in DISCUSSION_CHECKS:
        fail(f"plan.discussion_check must be one of {sorted(DISCUSSION_CHECKS)}")
    finding_by_number = {finding["number"]: finding for finding in sidecar["findings"]}
    finding_numbers = set(finding_by_number)
    require_type(data["comments"], list, "plan.comments")
    comments = []
    for index, comment in enumerate(data["comments"]):
        label = f"plan.comments[{index}]"
        require_type(comment, dict, label)
        require_exact_keys(comment, COMMENT_KEYS, label)
        require_type(comment["finding_number"], int, f"{label}.finding_number")
        if comment["finding_number"] not in finding_numbers:
            fail(f"{label}.finding_number does not identify a sidecar finding")
        require_nonempty_string(comment["path"], f"{label}.path")
        require_type(comment["line"], int, f"{label}.line")
        if comment["line"] <= 0:
            fail(f"{label}.line must be positive")
        if comment["side"] not in SIDES:
            fail(f"{label}.side must be LEFT or RIGHT")
        require_nonempty_string(comment["body"], f"{label}.body")
        if attribution in comment["body"]:
            fail(f"{label}.body must omit attribution; the helper appends it")
        validate_owned_prose(comment["body"], f"{label}.body")
        comments.append(comment)

    duplicates = validate_numbered_reason_entries(
        data["duplicates"], DUPLICATE_KEYS, "plan.duplicates", finding_numbers
    )
    for index, duplicate in enumerate(duplicates):
        require_nonempty_string(duplicate["thread_url"], f"plan.duplicates[{index}].thread_url")
        validate_ascii(duplicate["thread_url"], f"plan.duplicates[{index}].thread_url")
        expected = f"https://github.com/{sidecar['repo']}/pull/{sidecar['pr_number']}#"
        if not duplicate["thread_url"].startswith(expected):
            fail(f"plan.duplicates[{index}].thread_url must link to this PR's discussion")

    replies = data.get("replies", [])
    require_type(replies, list, "plan.replies")
    targets = set()
    for index, reply in enumerate(replies):
        label = f"plan.replies[{index}]"
        require_type(reply, dict, label)
        require_exact_keys(reply, {"thread_url", "body"}, label)
        reply_target(sidecar, reply)
        if reply["thread_url"] in targets:
            fail("plan.replies contains duplicate targets; combine the reply")
        targets.add(reply["thread_url"])
        require_nonempty_string(reply["body"], f"{label}.body")
        if attribution in reply["body"] or f"--{data['agent']} & {data['user_attribution']}" in reply["body"]:
            fail(f"{label}.body must omit attribution; the helper appends it")
        validate_owned_prose(reply["body"], f"{label}.body")
    if replies and data["discussion_check"] != "rechecked":
        fail("extra replies require a rechecked discussion")

    if data["discussion_check"] == "not-needed" and (comments or duplicates):
        fail("plan.discussion_check not-needed requires no published findings")

    exceptions = validate_numbered_reason_entries(
        data["comment_length_exceptions"],
        LENGTH_EXCEPTION_KEYS,
        "plan.comment_length_exceptions",
        finding_numbers,
    )
    exception_numbers = [entry["finding_number"] for entry in exceptions]
    if len(exception_numbers) != len(set(exception_numbers)):
        fail("plan.comment_length_exceptions contains duplicate finding numbers")

    require_string_list(data["additional_caveats"], "plan.additional_caveats")
    for index, caveat in enumerate(data["additional_caveats"]):
        require_nonempty_string(caveat, f"plan.additional_caveats[{index}]")
        validate_ascii(caveat, f"plan.additional_caveats[{index}]")
    normalized_caveats = [caveat.strip() for caveat in data["additional_caveats"]]
    if len(normalized_caveats) != len(set(normalized_caveats)):
        fail("plan.additional_caveats contains duplicates")
    sidecar_caveats = {caveat.strip() for caveat in sidecar["not_verified"] if caveat.strip()}
    repeated_caveats = sorted(set(normalized_caveats) & sidecar_caveats)
    if repeated_caveats:
        fail("plan.additional_caveats duplicates sidecar.not_verified")
    if data["discussion_check"] == "privacy-skipped":
        caveats = [*sidecar["not_verified"], *data["additional_caveats"]]
        disclosed = any(
            "privacy" in caveat.lower() and "discussion" in caveat.lower()
            for caveat in caveats
        )
        if not disclosed:
            fail("plan.discussion_check privacy-skipped requires a privacy discussion caveat")

    groups = {
        "comments": [entry["finding_number"] for entry in comments],
        "duplicates": [entry["finding_number"] for entry in duplicates],
    }
    classified = [number for numbers in groups.values() for number in numbers]
    if len(classified) != len(set(classified)):
        fail("a finding appears in more than one submission-plan classification")
    eligible = {
        number
        for number, finding in finding_by_number.items()
        if finding["severity"] in REQUIRED_CLASSIFICATION_SEVERITIES
    }
    missing = eligible - set(classified)
    if missing:
        fail(
            "Critical, High, and Medium findings must be classified exactly once; "
            f"missing={sorted(missing)}"
        )

    invalid_lengths = {}
    for comment in comments:
        count = len(WORD.findall(prose_without_code(comment["body"])))
        if not 60 <= count <= 120:
            invalid_lengths[comment["finding_number"]] = count
    length_errors = [
        (
            f"finding #{number} comment has {count} words; "
            "add a justified length exception or revise it"
        )
        for number, count in invalid_lengths.items()
        if number not in exception_numbers
    ]
    unused_exceptions = set(exception_numbers) - set(invalid_lengths)
    if unused_exceptions:
        length_errors.append(
            f"comment length exceptions are unnecessary for findings {sorted(unused_exceptions)}"
        )
    if length_errors:
        fail("comment length validation failed:\n- " + "\n- ".join(length_errors))
    return data


def decode_git_path(value: str) -> str:
    value = value.strip()
    if value.startswith('"'):
        try:
            value = ast.literal_eval(value)
        except (SyntaxError, ValueError) as error:
            fail(f"cannot decode Git path {value!r}: {error}")
    if value.startswith("a/") or value.startswith("b/"):
        return value[2:]
    return value


def diff_anchor_set(diff_text: str) -> set[tuple[str, str, int]]:
    anchors: set[tuple[str, str, int]] = set()
    old_path: str | None = None
    new_path: str | None = None
    old_line = 0
    new_line = 0
    in_hunk = False
    for line in diff_text.splitlines():
        if line.startswith("diff --git "):
            old_path = None
            new_path = None
            in_hunk = False
        elif line.startswith("--- "):
            value = line[4:]
            old_path = None if value == "/dev/null" else decode_git_path(value)
        elif line.startswith("+++ "):
            value = line[4:]
            new_path = None if value == "/dev/null" else decode_git_path(value)
        elif match := HUNK.match(line):
            old_line = int(match.group(1))
            new_line = int(match.group(3))
            in_hunk = True
        elif in_hunk and line.startswith("\\ No newline at end of file"):
            continue
        elif in_hunk and line.startswith("+"):
            if new_path is not None:
                anchors.add((new_path, "RIGHT", new_line))
            new_line += 1
        elif in_hunk and line.startswith("-"):
            path = new_path or old_path
            if path is not None:
                anchors.add((path, "LEFT", old_line))
            old_line += 1
        elif in_hunk and line.startswith(" "):
            path = new_path or old_path
            if old_path is not None and path is not None:
                anchors.add((path, "LEFT", old_line))
            if new_path is not None:
                anchors.add((new_path, "RIGHT", new_line))
            old_line += 1
            new_line += 1
        elif in_hunk:
            in_hunk = False
    return anchors


def validate_anchors(plan: dict[str, Any], diff_path: Path) -> None:
    try:
        diff_text = diff_path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        fail(f"cannot read combined diff from {diff_path}: {error}")
    anchors = diff_anchor_set(diff_text)
    for comment in plan["comments"]:
        anchor = (comment["path"], comment["side"], comment["line"])
        if anchor not in anchors:
            fail(f"finding #{comment['finding_number']} anchor is not in the combined diff: {anchor}")


def event_for(sidecar: dict[str, Any], plan: dict[str, Any]) -> str:
    if plan["event_override"] is not None:
        return plan["event_override"]
    severities = {finding["severity"] for finding in sidecar["findings"]}
    return "REQUEST_CHANGES" if severities & {"critical", "high"} else "APPROVE"


def attribution_marker(agent: str, user_attribution: str) -> str:
    return f"-- {agent} & {user_attribution}"


def attributed(value: str, agent: str, user_attribution: str) -> str:
    return f"{value.rstrip()}\n\n{attribution_marker(agent, user_attribution)}"


def published_severities(sidecar: dict[str, Any], plan: dict[str, Any]) -> set[str]:
    published_numbers = {
        entry["finding_number"]
        for entry in plan["comments"] + plan["duplicates"]
    }
    return {
        finding["severity"]
        for finding in sidecar["findings"]
        if finding["number"] in published_numbers
    }


def review_body(sidecar: dict[str, Any], plan: dict[str, Any]) -> str:
    if plan.get("review_body_override") is not None:
        return plan["review_body_override"]

    event = event_for(sidecar, plan)
    severities = published_severities(sidecar, plan)
    singular = len(plan["comments"]) + len(plan["duplicates"]) == 1
    if event == "REQUEST_CHANGES":
        if singular:
            return "We found a blocking issue in the review thread."
        return "We found blocking issues in the review threads."
    if event == "COMMENT":
        if singular:
            return "We left a review comment in the thread."
        return "We left review comments in the threads." if severities else "No findings."
    if severities & {"critical", "high"}:
        if singular:
            return "The review thread contains a blocking request."
        return "The review threads contain blocking requests."
    if "medium" in severities:
        if singular:
            return "Looks good overall. The review thread contains a follow-up request."
        return "Looks good overall. The review threads contain follow-up requests."
    if "low" in severities:
        if singular:
            return "Looks good overall. The review thread contains an optional suggestion."
        return "Looks good overall. The review threads contain optional suggestions."
    return "Looks good."


def submission(sidecar: dict[str, Any], plan: dict[str, Any]) -> dict[str, Any]:
    return {
        "commit_id": sidecar["head_commit"],
        "body": attributed(
            review_body(sidecar, plan),
            plan["agent"],
            plan["user_attribution"],
        ),
        "event": event_for(sidecar, plan),
        "comments": [
            {
                "path": comment["path"],
                "line": comment["line"],
                "side": comment["side"],
                "body": attributed(
                    comment["body"],
                    plan["agent"],
                    plan["user_attribution"],
                ),
            }
            for comment in plan["comments"]
        ],
    }


def submission_digest(payload: dict[str, Any]) -> str:
    encoded = json.dumps(payload, ensure_ascii=True, separators=(",", ":"), sort_keys=True).encode()
    return hashlib.sha256(encoded).hexdigest()


def reply_target(sidecar: dict[str, Any], reply: dict[str, Any]) -> tuple[str, int]:
    require_nonempty_string(reply["thread_url"], "reply.thread_url")
    prefix = re.escape(sidecar["pr_url"])
    match = re.fullmatch(prefix + r"#(discussion_r|issuecomment-|pullrequestreview-)([1-9][0-9]*)", reply["thread_url"])
    if not match:
        fail("reply target must be a supported comment on this PR")
    return match[1], int(match[2])


def reply_body(plan: dict[str, Any], reply: dict[str, Any]) -> str:
    body = reply["body"]
    if "#discussion_r" not in reply["thread_url"]:
        body = f"In reply to [the existing review]({reply['thread_url']}):\n\n{body}"
    return attributed(body, plan["agent"], plan["user_attribution"])


def reply_endpoint(sidecar: dict[str, Any], reply: dict[str, Any]) -> str:
    kind, comment_id = reply_target(sidecar, reply)
    root = f"repos/{sidecar['repo']}"
    if kind == "discussion_r":
        return f"{root}/pulls/{sidecar['pr_number']}/comments/{comment_id}/replies"
    return f"{root}/issues/{sidecar['pr_number']}/comments"


def publication_digest(sidecar: dict[str, Any], plan: dict[str, Any]) -> str:
    payload = submission(sidecar, plan)
    if plan.get("replies"):
        payload = {"review": payload, "replies": [
            {"thread_url": reply["thread_url"], "body": reply_body(plan, reply)}
            for reply in plan["replies"]
        ]}
    return submission_digest(payload)


def markdown_fence(value: str) -> str:
    longest = max((len(match.group(0)) for match in re.finditer(r"`+", value)), default=0)
    return "`" * max(3, longest + 1)


def preview_text(sidecar: dict[str, Any], plan: dict[str, Any]) -> str:
    payload = submission(sidecar, plan)
    lines = [
        f"# GitHub review preview for PR #{sidecar['pr_number']}",
        "",
        f"- PR: {sidecar['pr_url']}",
        f"- Head: `{sidecar['head_commit']}`",
        f"- Base: `{sidecar['base_branch']}`",
        f"- Submission digest: `{publication_digest(sidecar, plan)}`",
        f"- Discussion check: `{plan['discussion_check']}`",
        "",
        "## Proposed event",
        "",
        f"`{payload['event']}`",
        "",
        "## Exact review body",
        "",
    ]
    body_fence = markdown_fence(payload["body"])
    lines.extend([f"{body_fence}markdown", payload["body"], body_fence, "", "## Inline comments", ""])
    if payload["comments"]:
        for index, (source, comment) in enumerate(zip(plan["comments"], payload["comments"]), start=1):
            lines.append(
                f"{index}. `{comment['path']}:{comment['line']}` "
                f"(`{comment['side']}`), finding #{source['finding_number']}"
            )
            lines.append("")
            fence = markdown_fence(comment["body"])
            lines.extend([f"{fence}markdown", comment["body"], fence, ""])
    else:
        lines.extend(["None.", ""])

    lines.extend(["## Extra replies - publication decision", ""])
    if plan.get("replies"):
        lines.extend([
            "Choose **Publish** or **Publish all** (review and every reply), "
            "**Review only** (skip every reply), or **Edit**.",
            "GitHub receives separate requests in one publishing run; partial failures are recoverable.", "",
        ])
        for index, reply in enumerate(plan["replies"], start=1):
            body = reply_body(plan, reply)
            fence = markdown_fence(body)
            lines.extend([f"{index}. [Reply target]({reply['thread_url']})", "",
                          f"{fence}markdown", body, fence, ""])
    else:
        lines.extend(["None. Publish and Publish all authorize the review alone.", ""])

    lines.extend(["## Existing-thread duplicates", ""])
    if plan["duplicates"]:
        for duplicate in plan["duplicates"]:
            lines.append(
                f"- Finding #{duplicate['finding_number']}: {duplicate['reason']} "
                f"([thread]({duplicate['thread_url']}))."
            )
    else:
        lines.append("- None.")

    lines.extend(["", "## Excluded findings", ""])
    classified = {
        entry["finding_number"]
        for key in ("comments", "duplicates")
        for entry in plan[key]
    }
    low_findings = [
        finding
        for finding in sidecar["findings"]
        if finding["severity"] == "low" and finding["number"] not in classified
    ]
    if low_findings:
        for finding in low_findings:
            lines.append(f"- Low finding #{finding['number']}: {finding['title']}")
    else:
        lines.append("- Low: none.")
    if sidecar["low_confidence_findings"]:
        for finding in sidecar["low_confidence_findings"]:
            lines.append(f"- Low-confidence: {finding['title']}")
    else:
        lines.append("- Low-confidence: none.")

    lines.extend(["", "## Measured review timing", ""])
    for timing in sidecar["timings"]:
        lines.append(f"- {timing['phase']}: {timing['seconds']:.1f} seconds")
    for warning in sidecar.get("timing_warnings", []):
        lines.append(f"- Warning: {warning}")

    lines.extend(["", "## Caveats", ""])
    if sidecar["lanes_failed"]:
        for failure in sidecar["lanes_failed"]:
            lines.append(f"- Failed lane `{failure['lane']}`: {failure['reason']}")
    else:
        lines.append("- Failed lanes: none.")
    if sidecar["not_verified"]:
        for caveat in sidecar["not_verified"]:
            lines.append(f"- Not verified: {caveat}")
    else:
        lines.append("- Not verified: nothing material.")
    for caveat in plan["additional_caveats"]:
        lines.append(f"- {caveat}")
    result = "\n".join(lines).rstrip() + "\n"
    validate_ascii(result, "rendered preview")
    return result


def report_text(sidecar: dict[str, Any]) -> str:
    lines = [
        f"# Review of PR #{sidecar['pr_number']}: {sidecar['title']}",
        "",
        f"- PR: {sidecar['pr_url']}",
        f"- Head: `{sidecar['head_commit']}`",
        f"- Base: `{sidecar['base_branch']}`",
        f"- Diff: {sidecar['files_changed']} files, +{sidecar['lines_added']} "
        f"/-{sidecar['lines_removed']}",
        "",
        "## Findings",
        "",
    ]
    if sidecar["findings"]:
        for finding in sidecar["findings"]:
            lines.extend(
                [
                    f"### {finding['number']}. {finding['title']} ({finding['severity']})",
                    "",
                    f"- Source: [{finding['file']}:{finding['line']}]({finding['source_url']})",
                    f"- Confidence: {finding['confidence']}",
                    f"- Contributing lanes: {', '.join(finding['contributing_lanes'])}",
                    "",
                    f"Consequence: {finding['consequence']}",
                    "",
                    f"Recommendation: {finding['recommendation']}",
                ]
            )
            if finding["code_snippet"]:
                fence = markdown_fence(finding["code_snippet"])
                lines.extend(["", fence, finding["code_snippet"], fence])
            if finding["proof"] == "not_applicable":
                lines.extend(["", "Proof: not applicable."])
            elif isinstance(finding["proof"], dict):
                if finding["proof"]["reproduced"]:
                    lines.extend(
                        [
                            "",
                            f"Proof: reproduced at `{finding['proof']['execution_boundary']}`; "
                            f"{finding['proof']['pass_count']} passing verification run(s).",
                        ]
                    )
                else:
                    lines.extend(["", f"Proof not run: {finding['proof']['reason']}"])
            lines.append("")
    else:
        lines.extend(["No findings.", ""])

    lines.extend(["## Low-confidence observations", ""])
    if sidecar["low_confidence_findings"]:
        for finding in sidecar["low_confidence_findings"]:
            lines.append(
                f"- [{finding['title']}]({finding['source_url']}): {finding['description']}"
            )
    else:
        lines.append("- None.")

    lines.extend(["", "## Review coverage", ""])
    lines.append(
        f"- Lanes run: {', '.join(sidecar['lanes_run']) if sidecar['lanes_run'] else 'none'}"
    )
    for label, key in (("Skipped lane", "lanes_skipped"), ("Failed lane", "lanes_failed")):
        if sidecar[key]:
            for item in sidecar[key]:
                lines.append(f"- {label} `{item['lane']}`: {item['reason']}")
        else:
            lines.append(f"- {label}s: none.")
    if sidecar["design_context"]:
        lines.append(f"- Design context: {sidecar['design_context']}")

    lines.extend(["", "## Verification", ""])
    if sidecar["tests_run"]:
        for test in sidecar["tests_run"]:
            lines.append(f"- `{test['command']}`: {test['result']}")
    else:
        lines.append("- Tests run: none.")
    if sidecar["not_verified"]:
        for caveat in sidecar["not_verified"]:
            lines.append(f"- Not verified: {caveat}")
    else:
        lines.append("- Not verified: nothing material.")

    lines.extend(["", "## Measured review timing", ""])
    for timing in sidecar["timings"]:
        lines.append(f"- {timing['phase']}: {timing['seconds']:.1f} seconds")
    for warning in sidecar.get("timing_warnings", []):
        lines.append(f"- Warning: {warning}")
    result = "\n".join(lines).rstrip() + "\n"
    validate_ascii(result, "rendered report")
    return result


def load_artifacts(args: argparse.Namespace, require_diff: bool = False) -> tuple[dict[str, Any], dict[str, Any]]:
    sidecar = validate_sidecar(load_json(args.sidecar))
    plan = validate_plan(load_json(args.plan), sidecar)
    if require_diff:
        validate_anchors(plan, args.diff)
    return sidecar, plan


def write_text(path: Path, value: str) -> None:
    path.write_text(value, encoding="utf-8")


def command_preview(args: argparse.Namespace) -> None:
    sidecar, plan = load_artifacts(args, require_diff=True)
    rendered = preview_text(sidecar, plan)
    write_text(args.output, rendered)
    payload = submission(sidecar, plan)
    print(f"preview={args.output}")
    print(f"event={payload['event']}")
    print(f"comments={len(payload['comments'])}")
    print(f"digest={publication_digest(sidecar, plan)}")


def approved_preview(sidecar: dict[str, Any], plan: dict[str, Any], path: Path) -> None:
    try:
        actual = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        fail(f"cannot read approved preview from {path}: {error}")
    expected = preview_text(sidecar, plan)
    if actual != expected:
        fail("approved preview differs from the current validated plan")


def command_payload(args: argparse.Namespace) -> None:
    sidecar, plan = load_artifacts(args, require_diff=True)
    approved_preview(sidecar, plan, args.approved_preview)
    payload = submission(sidecar, plan)
    write_text(args.output, json.dumps(payload, ensure_ascii=True, indent=2) + "\n")
    print(f"payload={args.output}")
    print(f"event={payload['event']}")
    print(f"comments={len(payload['comments'])}")
    print(f"digest={publication_digest(sidecar, plan)}")


def gh_json(arguments: list[str]) -> Any:
    result = subprocess.run(["gh", *arguments], capture_output=True, text=True, check=False)
    if result.returncode != 0:
        fail(f"gh command failed with exit {result.returncode}: {' '.join(arguments[:3])}")
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        fail(f"gh command returned invalid JSON: {' '.join(arguments[:3])}")


def github_pr(sidecar: dict[str, Any]) -> dict[str, Any]:
    return gh_json(
        [
            "pr",
            "view",
            str(sidecar["pr_number"]),
            "--repo",
            sidecar["repo"],
            "--json",
            "baseRefName,headRefOid,state,url",
        ]
    )


def paged_api(endpoint: str, projection: str | None = None) -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    page = 1
    while True:
        separator = "&" if "?" in endpoint else "?"
        arguments = ["api", f"{endpoint}{separator}per_page=100&page={page}"]
        if projection is not None:
            arguments.extend(["--jq", projection])
        batch = gh_json(arguments)
        require_type(batch, list, "GitHub API page")
        items.extend(batch)
        if len(batch) < 100:
            return items
        page += 1


def validate_reply_target(sidecar: dict[str, Any], reply: dict[str, Any]) -> None:
    kind, comment_id = reply_target(sidecar, reply)
    root = f"repos/{sidecar['repo']}"
    if kind == "discussion_r":
        comment = gh_json(["api", f"{root}/pulls/comments/{comment_id}", "--jq",
                           "{pull_request_url,in_reply_to_id}"])
        if comment.get("pull_request_url") != f"https://api.github.com/{root}/pulls/{sidecar['pr_number']}":
            fail("reply target belongs to another PR")
        if comment.get("in_reply_to_id") is not None:
            fail("reply target must be the root review comment, not another reply")
    elif kind == "issuecomment-":
        comment = gh_json(["api", f"{root}/issues/comments/{comment_id}", "--jq", "{issue_url}"])
        if comment.get("issue_url") != f"https://api.github.com/{root}/issues/{sidecar['pr_number']}":
            fail("reply target belongs to another PR")
    else:
        gh_json(["api", f"{root}/pulls/{sidecar['pr_number']}/reviews/{comment_id}", "--jq", "{id}"])


def exact_replies(sidecar: dict[str, Any], plan: dict[str, Any], reply: dict[str, Any]) -> list[dict[str, Any]]:
    kind, comment_id = reply_target(sidecar, reply)
    surface = "pulls" if kind == "discussion_r" else "issues"
    comments = paged_api(
        f"repos/{sidecar['repo']}/{surface}/{sidecar['pr_number']}/comments",
        "[.[] | {body,html_url,in_reply_to_id}]",
    )
    expected = reply_body(plan, reply)
    return [comment for comment in comments if comment.get("body") == expected
            and (kind != "discussion_r" or comment.get("in_reply_to_id") == comment_id)]


def posted_comment_key(comment: dict[str, Any]) -> tuple[Any, ...]:
    return (comment.get("path"), comment.get("line"), comment.get("side"), comment.get("body"))


def exact_reviews(sidecar: dict[str, Any], plan: dict[str, Any]) -> list[dict[str, Any]]:
    expected = submission(sidecar, plan)
    expected_state = REVIEW_STATES[expected["event"]]
    reviews = paged_api(f"repos/{sidecar['repo']}/pulls/{sidecar['pr_number']}/reviews")
    candidates = [
        review
        for review in reviews
        if review.get("commit_id") == expected["commit_id"]
        and review.get("body") == expected["body"]
        and review.get("state") == expected_state
    ]
    if not candidates:
        return []
    comments = paged_api(f"repos/{sidecar['repo']}/pulls/{sidecar['pr_number']}/comments")
    expected_comments = Counter(posted_comment_key(comment) for comment in expected["comments"])
    exact = []
    for review in candidates:
        review_id = review.get("id")
        if not isinstance(review_id, int):
            continue
        posted = [
            comment
            for comment in comments
            if comment.get("pull_request_review_id") == review_id
        ]
        actual_comments = Counter(posted_comment_key(comment) for comment in posted)
        if actual_comments == expected_comments:
            exact.append(review)
    return exact
    return [
        review
        for review in reviews
        if review.get("commit_id") == sidecar["head_commit"]
        and isinstance(review.get("body"), str)
        and review["body"].rstrip().endswith(marker)
    ]


def repository_from_remote_url(remote_url: str) -> str:
    prefixes = (
        "git@github.com:",
        "https://github.com/",
        "ssh://git@github.com/",
        "git://github.com/",
    )
    repository = next(
        (remote_url[len(prefix) :] for prefix in prefixes if remote_url.startswith(prefix)),
        None,
    )
    if repository is None:
        fail("origin is not a supported GitHub origin")
    repository = repository.removesuffix("/").removesuffix(".git")
    if not REPOSITORY.fullmatch(repository):
        fail("origin does not identify one GitHub owner/repository")
    return repository


def github_repository() -> str:
    result = subprocess.run(
        ["git", "remote", "get-url", "origin"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        fail("cannot resolve the local origin mapping")
    return repository_from_remote_url(result.stdout.strip())


def validate_current_repository(sidecar: dict[str, Any]) -> str:
    current = github_repository()
    if current != sidecar["repo"]:
        fail(f"current repository is {current!r}, not sidecar.repo {sidecar['repo']!r}")
    return current


def validate_current_pr(sidecar: dict[str, Any]) -> dict[str, Any]:
    validate_current_repository(sidecar)
    current = github_pr(sidecar)
    if current.get("baseRefName") != sidecar["base_branch"]:
        fail("current PR base does not match sidecar.base_branch")
    if current.get("headRefOid") != sidecar["head_commit"]:
        fail("current PR head does not match sidecar.head_commit")
    if current.get("state") != "OPEN":
        fail(f"PR state is {current.get('state')!r}, not OPEN")
    if current.get("url") != sidecar["pr_url"]:
        fail("current PR URL does not match sidecar.pr_url")
    return current


def command_github_check(args: argparse.Namespace) -> None:
    sidecar, plan = load_artifacts(args)
    current = validate_current_pr(sidecar)
    matches = exact_reviews(sidecar, plan)
    print(f"head={current['headRefOid']}")
    print(f"state={current['state']}")
    if matches:
        for review in matches:
            print(f"matching_review={review.get('html_url', 'unknown')}")
        fail("an exact review already exists at the sidecar commit; do not submit or retry")
    print("matching_review=none")


def command_verify_posted(args: argparse.Namespace) -> None:
    sidecar, plan = load_artifacts(args)
    approved_preview(sidecar, plan, args.approved_preview)
    validate_current_pr(sidecar)
    matches = exact_reviews(sidecar, plan)
    if len(matches) != 1:
        fail(f"expected one exact posted review, found {len(matches)}")
    review = matches[0]
    expected = submission(sidecar, plan)
    expected_state = REVIEW_STATES[expected["event"]]
    if review.get("state") != expected_state:
        fail(f"posted review state is {review.get('state')!r}, expected {expected_state!r}")
    review_id = review.get("id")
    require_type(review_id, int, "posted review id")

    comments = paged_api(f"repos/{sidecar['repo']}/pulls/{sidecar['pr_number']}/comments")
    posted = [comment for comment in comments if comment.get("pull_request_review_id") == review_id]
    expected_comments = Counter(posted_comment_key(comment) for comment in expected["comments"])
    actual_comments = Counter(posted_comment_key(comment) for comment in posted)
    if actual_comments != expected_comments:
        fail("posted inline comments differ in count, body, or current anchors")

    print(f"review_url={review.get('html_url', 'unknown')}")
    print(f"state={review['state']}")
    print(f"commit={review['commit_id']}")
    print(f"comments={len(posted)}")
    print(f"digest={publication_digest(sidecar, plan)}")


def path_argument(value: str) -> Path:
    return Path(value).expanduser().resolve()


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    commands = result.add_subparsers(dest="command", required=True)

    def artifacts(command: argparse.ArgumentParser) -> None:
        command.add_argument("--sidecar", required=True, type=path_argument)
        command.add_argument("--plan", required=True, type=path_argument)

    preview = commands.add_parser("preview", help="validate and render the approval preview")
    artifacts(preview)
    preview.add_argument("--diff", required=True, type=path_argument)
    preview.add_argument("--output", required=True, type=path_argument)
    preview.set_defaults(handler=command_preview)

    payload = commands.add_parser("payload", help="generate a payload from an approved preview")
    artifacts(payload)
    payload.add_argument("--diff", required=True, type=path_argument)
    payload.add_argument("--approved-preview", required=True, type=path_argument)
    payload.add_argument("--output", required=True, type=path_argument)
    payload.set_defaults(handler=command_payload)

    github_check = commands.add_parser("github-check", help="check PR head, state, and exact prior submission")
    artifacts(github_check)
    github_check.set_defaults(handler=command_github_check)

    verify = commands.add_parser("verify-posted", help="verify the exact posted review and inline comments")
    artifacts(verify)
    verify.add_argument("--approved-preview", required=True, type=path_argument)
    verify.set_defaults(handler=command_verify_posted)
    return result


def main() -> int:
    args = parser().parse_args()
    try:
        args.handler(args)
    except ValidationError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
