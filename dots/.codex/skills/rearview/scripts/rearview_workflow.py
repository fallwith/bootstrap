#!/usr/bin/env python3
"""Orchestrate one approved Rearview GitHub submission."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time
from types import SimpleNamespace
from typing import Any, Iterator


SCRIPT_DIRECTORY = Path(__file__).resolve().parent
if str(SCRIPT_DIRECTORY) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIRECTORY))

import review_submission  # noqa: E402


ValidationError = review_submission.ValidationError
RUN_VERSION = 2
STAGES = {"prepared", "previewed"}
DISCUSSION_CHECKS = review_submission.DISCUSSION_CHECKS
REVIEW_SIGNAL_WEIGHTS = {
    "authentication-or-security": 2,
    "background-job": 1,
    "cross-repository-contract": 2,
    "database-migration": 2,
    "external-integration": 1,
    "notification-email-localization": 1,
    "runtime-proof": 2,
}
RUN_FILENAMES = {
    "approval.diff",
    "manifest.json",
    "payload.json",
    "reply-payload.json",
    "publication.json",
    "plan.json",
    "posting.diff",
}
MANIFEST_KEYS = {
    "version",
    "stage",
    "repository_root",
    "sidecar_path",
    "sidecar_sha256",
    "plan_path",
    "preview_path",
    "repo",
    "pr_number",
    "head_commit",
    "base_branch",
    "approval_diff_sha256",
    "plan_sha256",
    "preview_sha256",
    "submission_digest",
    "discussion_check",
    "diff_source",
    "timings",
}
TIMING_KEYS = {"prepare_seconds", "preview_seconds"}
TIMING_LOG_VERSION = 3
TIMING_LOG_KEYS = {
    "version",
    "pr_number",
    "started_epoch_ns",
    "last_mark_epoch_ns",
    "phases",
    "warnings",
    "paused_epoch_ns",
    "excluded_wait_ns",
}
LEGACY_TIMING_LOG_KEYS = TIMING_LOG_KEYS - {"paused_epoch_ns", "excluded_wait_ns"}
TIMING_PHASES = (
    "metadata",
    "repository-research",
    "review",
    "reconciliation",
    "normalization",
)
COMMIT_OID = re.compile(r"^[0-9a-f]{40}$")
BRANCH_NAME = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._/-]*$")
DISCUSSION_SNAPSHOT_VERSION = 1
DISCUSSION_SURFACES = {
    "issue_comments": (
        "issues/{pr_number}/comments",
        "[.[] | {id, body, html_url, created_at, updated_at, author_login: .user.login}]",
    ),
    "reviews": (
        "pulls/{pr_number}/reviews",
        (
            "[.[] | {id, body, html_url, state, commit_id, submitted_at, "
            "author_login: .user.login}]"
        ),
    ),
    "review_comments": (
        "pulls/{pr_number}/comments",
        (
            "[.[] | {id, body, html_url, path, line, original_line, side, "
            "in_reply_to_id, commit_id, pull_request_review_id, created_at, "
            "updated_at, author_login: .user.login}]"
        ),
    ),
}
DISCUSSION_RECORD_KEYS = {
    "issue_comments": {
        "id",
        "body",
        "html_url",
        "created_at",
        "updated_at",
        "viewer_authored",
    },
    "reviews": {
        "id",
        "body",
        "html_url",
        "state",
        "commit_id",
        "submitted_at",
        "viewer_authored",
    },
    "review_comments": {
        "id",
        "body",
        "html_url",
        "path",
        "line",
        "original_line",
        "side",
        "in_reply_to_id",
        "commit_id",
        "pull_request_review_id",
        "created_at",
        "updated_at",
        "viewer_authored",
    },
}


def fail(message: str) -> None:
    raise ValidationError(message)


def sha256_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def file_sha256(path: Path) -> str:
    try:
        return hashlib.sha256(path.read_bytes()).hexdigest()
    except OSError as error:
        fail(f"cannot hash {path}: {error}")


def write_json(path: Path, value: dict[str, Any]) -> None:
    path.write_text(json.dumps(value, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")


def replace_json(path: Path, value: dict[str, Any]) -> None:
    descriptor, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary_path = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
            stream.write(json.dumps(value, ensure_ascii=True, indent=2) + "\n")
        temporary_path.chmod(0o600)
        temporary_path.replace(path)
    except BaseException:
        temporary_path.unlink(missing_ok=True)
        raise


def private_temporary_path(prefix: str, suffix: str = ".json") -> Path:
    descriptor, name = tempfile.mkstemp(prefix=prefix, suffix=suffix, dir="/tmp")
    os.close(descriptor)
    path = Path(name).resolve()
    path.chmod(0o600)
    return path


def validated_discussion_path(path: Path, prefix: str = "rearview-discussion-") -> Path:
    if path.is_symlink():
        fail("discussion artifact must not be a symbolic link")
    resolved = path.resolve()
    temporary_root = Path("/tmp").resolve()
    if temporary_root not in resolved.parents or not resolved.name.startswith(prefix):
        fail(f"discussion artifact must be a {prefix}* file beneath /tmp")
    if not resolved.is_file():
        fail("discussion artifact must be a regular file")
    return resolved


def discussion_digest(surfaces: dict[str, list[dict[str, Any]]]) -> str:
    canonical = json.dumps(surfaces, ensure_ascii=True, sort_keys=True, separators=(",", ":"))
    return sha256_text(canonical)


def validate_discussion_snapshot(value: Any) -> dict[str, Any]:
    review_submission.require_type(value, dict, "discussion_snapshot")
    review_submission.require_exact_keys(
        value,
        {"version", "repo", "pr_number", "surfaces", "digest"},
        "discussion_snapshot",
    )
    if value["version"] != DISCUSSION_SNAPSHOT_VERSION:
        fail(f"discussion_snapshot.version must be {DISCUSSION_SNAPSHOT_VERSION}")
    review_submission.require_nonempty_string(value["repo"], "discussion_snapshot.repo")
    if not review_submission.REPOSITORY.fullmatch(value["repo"]):
        fail("discussion_snapshot.repo must be an owner/repository name")
    review_submission.require_type(value["pr_number"], int, "discussion_snapshot.pr_number")
    if value["pr_number"] <= 0:
        fail("discussion_snapshot.pr_number must be positive")
    review_submission.require_type(value["surfaces"], dict, "discussion_snapshot.surfaces")
    review_submission.require_exact_keys(
        value["surfaces"], set(DISCUSSION_SURFACES), "discussion_snapshot.surfaces"
    )
    for surface, records in value["surfaces"].items():
        review_submission.require_type(records, list, f"discussion_snapshot.surfaces.{surface}")
        identifiers: list[int] = []
        for index, record in enumerate(records):
            label = f"discussion_snapshot.surfaces.{surface}[{index}]"
            review_submission.require_type(record, dict, label)
            extra_keys = sorted(record.keys() - DISCUSSION_RECORD_KEYS[surface])
            if extra_keys:
                fail(f"{label} contains unsupported keys: {extra_keys}")
            review_submission.require_type(record.get("id"), int, f"{label}.id")
            review_submission.require_type(record.get("body"), str, f"{label}.body")
            review_submission.require_nonempty_string(record.get("html_url"), f"{label}.html_url")
            review_submission.require_type(
                record.get("viewer_authored"),
                bool,
                f"{label}.viewer_authored",
            )
            identifiers.append(record["id"])
        if identifiers != sorted(set(identifiers)):
            fail(f"discussion_snapshot.surfaces.{surface} must have unique sorted ids")
    validate_digest(value["digest"], "discussion_snapshot.digest")
    if value["digest"] != discussion_digest(value["surfaces"]):
        fail("discussion_snapshot.digest does not match its surfaces")
    return value


def paginated_json_arrays(value: str, label: str) -> list[Any]:
    decoder = json.JSONDecoder()
    pages = []
    index = 0
    while index < len(value):
        while index < len(value) and value[index].isspace():
            index += 1
        if index == len(value):
            break
        try:
            page, index = decoder.raw_decode(value, index)
        except json.JSONDecodeError as error:
            fail(f"cannot parse pull request {label}: {error}")
        review_submission.require_type(page, list, f"discussion.{label}.page")
        pages.extend(page)
    return pages


def fetch_discussion_surface(
    repo: str,
    pr_number: int,
    surface: tuple[str, tuple[str, str]],
    viewer_login: str,
) -> tuple[str, list[dict[str, Any]]]:
    name, (endpoint_template, jq_filter) = surface
    endpoint = f"repos/{repo}/{endpoint_template.format(pr_number=pr_number)}"
    result = subprocess.run(
        ["gh", "api", "--paginate", endpoint, "--jq", jq_filter],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        fail(f"cannot enumerate pull request {name.replace('_', ' ')}")
    records = paginated_json_arrays(result.stdout, name.replace("_", " "))
    review_submission.require_type(records, list, f"discussion.{name}")
    for index, record in enumerate(records):
        review_submission.require_type(record, dict, f"discussion.{name}[{index}]")
        record["viewer_authored"] = record.pop("author_login", None) == viewer_login
    return name, sorted(records, key=lambda record: record.get("id", -1))


def current_github_login() -> str:
    result = subprocess.run(
        ["gh", "api", "user", "--jq", ".login"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0 or not result.stdout.strip():
        fail("cannot resolve the authenticated GitHub account")
    return result.stdout.strip()


def fetch_discussion_snapshot(repo: str, pr_number: int) -> dict[str, Any]:
    if not review_submission.REPOSITORY.fullmatch(repo):
        fail("discussion repository must be an owner/repository name")
    if pr_number <= 0:
        fail("discussion pull request number must be positive")
    viewer_login = current_github_login()
    with ThreadPoolExecutor(max_workers=len(DISCUSSION_SURFACES)) as executor:
        results = executor.map(
            lambda surface: fetch_discussion_surface(
                repo,
                pr_number,
                surface,
                viewer_login,
            ),
            DISCUSSION_SURFACES.items(),
        )
        surfaces = dict(results)
    snapshot = {
        "version": DISCUSSION_SNAPSHOT_VERSION,
        "repo": repo,
        "pr_number": pr_number,
        "surfaces": surfaces,
        "digest": discussion_digest(surfaces),
    }
    return validate_discussion_snapshot(snapshot)


def discussion_delta(
    previous: dict[str, Any], current: dict[str, Any]
) -> dict[str, Any]:
    changed: dict[str, list[dict[str, Any]]] = {}
    removed: dict[str, list[dict[str, Any]]] = {}
    for surface in DISCUSSION_SURFACES:
        old_by_id = {record["id"]: record for record in previous["surfaces"][surface]}
        new_by_id = {record["id"]: record for record in current["surfaces"][surface]}
        changed[surface] = [
            record
            for identifier, record in sorted(new_by_id.items())
            if old_by_id.get(identifier) != record
        ]
        removed[surface] = [
            {"id": identifier, "html_url": record["html_url"]}
            for identifier, record in sorted(old_by_id.items())
            if identifier not in new_by_id
        ]
    return {
        "repo": current["repo"],
        "pr_number": current["pr_number"],
        "previous_digest": previous["digest"],
        "current_digest": current["digest"],
        "changed": changed,
        "removed": removed,
    }


def elapsed_seconds(started_at: float) -> float:
    return round(time.monotonic() - started_at, 3)


def validated_timing_log_path(path: Path) -> Path:
    if path.is_symlink():
        fail("timing log must not be a symbolic link")
    resolved = path.resolve()
    temporary_root = Path("/tmp").resolve()
    if temporary_root not in resolved.parents or not resolved.name.startswith("rearview-timing-"):
        fail("timing log must be a rearview-timing-* file beneath /tmp")
    if not resolved.is_file():
        fail("timing log must be a regular file")
    return resolved


def validate_timing_log(value: Any, complete: bool = False) -> dict[str, Any]:
    review_submission.require_type(value, dict, "timing_log")
    review_submission.require_type(value.get("version"), int, "timing_log.version")
    if value.get("version") == 2:
        review_submission.require_exact_keys(value, LEGACY_TIMING_LOG_KEYS, "timing_log")
    elif value["version"] == TIMING_LOG_VERSION:
        review_submission.require_exact_keys(value, TIMING_LOG_KEYS, "timing_log")
        paused_epoch_ns = value["paused_epoch_ns"]
        if paused_epoch_ns is not None:
            review_submission.require_type(paused_epoch_ns, int, "timing_log.paused_epoch_ns")
            if paused_epoch_ns < value["last_mark_epoch_ns"]:
                fail("timing_log.paused_epoch_ns predates its last mark")
        review_submission.require_type(value["excluded_wait_ns"], int, "timing_log.excluded_wait_ns")
        if value["excluded_wait_ns"] < 0:
            fail("timing_log.excluded_wait_ns must be non-negative")
    else:
        fail(f"timing_log.version must be 2 or {TIMING_LOG_VERSION}")
    review_submission.require_type(value["pr_number"], int, "timing_log.pr_number")
    if value["pr_number"] <= 0:
        fail("timing_log.pr_number must be positive")
    for key in ("started_epoch_ns", "last_mark_epoch_ns"):
        review_submission.require_type(value[key], int, f"timing_log.{key}")
        if value[key] < 0:
            fail(f"timing_log.{key} must be non-negative")
    if value["last_mark_epoch_ns"] < value["started_epoch_ns"]:
        fail("timing_log.last_mark_epoch_ns predates its start")

    review_submission.require_string_list(value["warnings"], "timing_log.warnings")
    for index, warning in enumerate(value["warnings"]):
        review_submission.require_nonempty_string(warning, f"timing_log.warnings[{index}]")

    review_submission.require_type(value["phases"], list, "timing_log.phases")
    actual_phases: list[str] = []
    for index, item in enumerate(value["phases"]):
        label = f"timing_log.phases[{index}]"
        review_submission.require_type(item, dict, label)
        review_submission.require_exact_keys(item, {"phase", "seconds"}, label)
        review_submission.require_nonempty_string(item["phase"], f"{label}.phase")
        seconds = item["seconds"]
        if isinstance(seconds, bool) or not isinstance(seconds, (int, float)) or seconds < 0:
            fail(f"{label}.seconds must be a non-negative number")
        actual_phases.append(item["phase"])

    if len(actual_phases) > len(TIMING_PHASES):
        fail("timing log contains too many phases")
    expected_prefix = list(TIMING_PHASES[: len(actual_phases)])
    if actual_phases != expected_prefix:
        expected = TIMING_PHASES[len(actual_phases) - 1] if actual_phases else TIMING_PHASES[0]
        fail(f"timing log phases are out of order; expected {expected}")
    if complete and tuple(actual_phases) != TIMING_PHASES:
        missing = list(TIMING_PHASES[len(actual_phases) :])
        fail(f"timing log is incomplete; missing phases: {missing}")

    elapsed = (value["last_mark_epoch_ns"] - value["started_epoch_ns"]) / 1_000_000_000
    measured = sum(item["seconds"] for item in value["phases"])
    rounding_tolerance = max(0.001, len(value["phases"]) * 0.0005)
    if abs(elapsed - measured) > rounding_tolerance:
        fail("timing log durations do not match its epoch timestamps")
    return value


def create_timing_log(pr_number: int, directory: Path = Path("/tmp")) -> Path:
    if pr_number <= 0:
        fail("timing log pull request number must be positive")
    started = time.time_ns()
    descriptor, name = tempfile.mkstemp(prefix=f"rearview-timing-{pr_number}-", suffix=".json", dir=directory)
    os.close(descriptor)
    path = Path(name).resolve()
    path.chmod(0o600)
    replace_json(
        path,
        {
            "version": TIMING_LOG_VERSION,
            "pr_number": pr_number,
            "started_epoch_ns": started,
            "last_mark_epoch_ns": started,
            "phases": [],
            "warnings": [],
            "paused_epoch_ns": None,
            "excluded_wait_ns": 0,
        },
    )
    return path


def mark_timing(path: Path, phase: str) -> float:
    path = validated_timing_log_path(path)
    value = validate_timing_log(review_submission.load_json(path))
    if value.get("paused_epoch_ns") is not None:
        fail("timing log is paused; resume it before marking a phase")
    phase_index = len(value["phases"])
    if phase_index >= len(TIMING_PHASES):
        fail("timing log already contains every phase")
    expected = TIMING_PHASES[phase_index]
    if phase != expected:
        fail(f"timing log expected {expected}, not {phase}")
    now = time.time_ns()
    if now < value["last_mark_epoch_ns"]:
        value["warnings"].append(f"system clock moved backwards before {phase}; recorded 0 seconds")
        now = value["last_mark_epoch_ns"]
    seconds = round((now - value["last_mark_epoch_ns"]) / 1_000_000_000, 3)
    value["last_mark_epoch_ns"] = now
    value["phases"].append({"phase": phase, "seconds": seconds})
    validate_timing_log(value)
    replace_json(path, value)
    return seconds


def pause_timing(path: Path) -> None:
    path = validated_timing_log_path(path)
    value = validate_timing_log(review_submission.load_json(path))
    if value["version"] != TIMING_LOG_VERSION:
        fail("legacy timing logs cannot be paused")
    if value["paused_epoch_ns"] is not None:
        fail("timing log is already paused")
    now = time.time_ns()
    if now < value["last_mark_epoch_ns"]:
        value["warnings"].append("system clock moved backwards before pause; clamped timestamp")
        now = value["last_mark_epoch_ns"]
    value["paused_epoch_ns"] = now
    validate_timing_log(value)
    replace_json(path, value)


def resume_timing(path: Path) -> float:
    path = validated_timing_log_path(path)
    value = validate_timing_log(review_submission.load_json(path))
    if value["version"] != TIMING_LOG_VERSION:
        fail("legacy timing logs cannot be resumed")
    paused = value["paused_epoch_ns"]
    if paused is None:
        fail("timing log is not paused")
    now = time.time_ns()
    if now < paused:
        value["warnings"].append("system clock moved backwards before resume; recorded 0 seconds")
        now = paused
    excluded = now - paused
    value["started_epoch_ns"] += excluded
    value["last_mark_epoch_ns"] += excluded
    value["excluded_wait_ns"] += excluded
    value["paused_epoch_ns"] = None
    validate_timing_log(value)
    replace_json(path, value)
    return round(excluded / 1_000_000_000, 3)


def complete_normalization_timing(value: dict[str, Any]) -> dict[str, Any]:
    validate_timing_log(value)
    if value.get("paused_epoch_ns") is not None:
        fail("timing log is paused; resume it before prepare-preview")
    phase_count = len(value["phases"])
    if phase_count == len(TIMING_PHASES):
        return value
    if phase_count != len(TIMING_PHASES) - 1:
        fail("timing log must be marked through reconciliation before prepare-preview")

    now = time.time_ns()
    if now < value["last_mark_epoch_ns"]:
        value["warnings"].append(
            "system clock moved backwards before normalization; recorded 0 seconds"
        )
        now = value["last_mark_epoch_ns"]
    seconds = round((now - value["last_mark_epoch_ns"]) / 1_000_000_000, 3)
    value["last_mark_epoch_ns"] = now
    value["phases"].append({"phase": "normalization", "seconds": seconds})
    return validate_timing_log(value, complete=True)


def review_estimate(
    files_changed: int,
    lines_changed: int,
    signals: set[str],
    mode: str = "thorough",
    repository_review_skill: bool = False,
) -> dict[str, str]:
    if files_changed < 0 or lines_changed < 0:
        fail("review size inputs must be non-negative")
    if mode not in {"quick", "thorough"}:
        fail("review mode must be quick or thorough")
    unknown_signals = sorted(signals - REVIEW_SIGNAL_WEIGHTS.keys())
    if unknown_signals:
        fail(f"unknown review estimate signals: {unknown_signals}")

    file_score = 3 if files_changed > 12 else 1 if files_changed > 5 else 0
    if files_changed > 25:
        file_score = 4
    if lines_changed > 1_000:
        line_score = 4
    elif lines_changed > 500:
        line_score = 3
    elif lines_changed > 200:
        line_score = 1
    else:
        line_score = 0
    workflow_score = 3 if repository_review_skill else 0
    score = (
        file_score
        + line_score
        + workflow_score
        + sum(REVIEW_SIGNAL_WEIGHTS[signal] for signal in signals)
    )
    if score >= 9:
        size = "extra-large"
    elif score >= 6:
        size = "large"
    elif score >= 2:
        size = "medium"
    else:
        size = "small"
    ranges = {
        "quick": {
            "small": "3-5",
            "medium": "5-10",
            "large": "10-20",
            "extra-large": "20-40",
        },
        "thorough": {
            "small": "3-7",
            "medium": "8-15",
            "large": "15-30",
            "extra-large": "30-60",
        },
    }
    return {"size": size, "minutes": ranges[mode][size]}


def small_fast_path_eligible(
    files_changed: int,
    lines_changed: int,
    signals: set[str],
    repository_review_skill: bool,
    prove: bool,
) -> bool:
    if files_changed < 0 or lines_changed < 0:
        fail("review size inputs must be non-negative")
    return (
        files_changed <= 5
        and lines_changed <= 200
        and not signals
        and not repository_review_skill
        and not prove
    )


def git_root() -> Path:
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        fail("cannot resolve the current Git repository")
    root = result.stdout.strip()
    if not root:
        fail("git rev-parse returned an empty repository root")
    return Path(root).resolve()


@contextmanager
def working_directory(path: Path) -> Iterator[None]:
    previous = Path.cwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(previous)


def create_run_dir(pr_number: int) -> Path:
    path = Path(tempfile.mkdtemp(prefix=f"rearview-{pr_number}-", dir="/tmp"))
    path.chmod(0o700)
    return path.resolve()


def fetch_combined_diff(sidecar: dict[str, Any]) -> str:
    result = subprocess.run(
        [
            "gh",
            "pr",
            "diff",
            str(sidecar["pr_number"]),
            "--repo",
            sidecar["repo"],
            "--patch",
            "--color",
            "never",
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        fail("cannot fetch the pull request combined diff")
    if not result.stdout:
        fail("the pull request combined diff is empty")
    return result.stdout


def fetch_local_combined_diff(sidecar: dict[str, Any]) -> str:
    base = f"refs/remotes/origin/{sidecar['base_branch']}"
    result = subprocess.run(
        [
            "git",
            "diff",
            "--find-renames",
            "--no-ext-diff",
            "--color=never",
            f"{base}...{sidecar['head_commit']}",
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        fail("cannot build the combined diff from the fetched base and reviewed head")
    if not result.stdout:
        fail("the local combined diff is empty")
    return result.stdout


def git_commit_exists(commit: str) -> bool:
    if not COMMIT_OID.fullmatch(commit):
        fail("review head must be a full lowercase commit OID")
    result = subprocess.run(
        ["git", "cat-file", "-e", f"{commit}^{{commit}}"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return result.returncode == 0


def refresh_review_refs(pr_number: int, base_branch: str, head_commit: str) -> str:
    if pr_number <= 0:
        fail("pull request number must be positive")
    if (
        not BRANCH_NAME.fullmatch(base_branch)
        or ".." in base_branch
        or "//" in base_branch
        or base_branch.endswith("/")
    ):
        fail("pull request base branch is invalid")
    head_source = "local" if git_commit_exists(head_commit) else "fetched"
    refspecs = [
        f"+refs/heads/{base_branch}:refs/remotes/origin/{base_branch}",
    ]
    if head_source == "fetched":
        refspecs.append(f"+refs/pull/{pr_number}/head:refs/rearview/pr-{pr_number}")
    result = subprocess.run(
        ["git", "fetch", "--no-tags", "origin", *refspecs],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    if result.returncode != 0:
        fail("cannot refresh the pull request review refs")
    if not git_commit_exists(head_commit):
        fail("the reviewed head commit is absent after refresh")
    return head_source


def contiguous_ranges(lines: list[int]) -> list[list[int]]:
    ranges: list[list[int]] = []
    for line in sorted(set(lines)):
        if ranges and line == ranges[-1][1] + 1:
            ranges[-1][1] = line
        else:
            ranges.append([line, line])
    return ranges


def changed_ranges(diff_text: str, changed_files: list[str]) -> dict[str, list[list[int]]]:
    lines_by_file = {path: [] for path in changed_files}
    for path, side, line in review_submission.diff_anchor_set(diff_text):
        if side == "RIGHT" and path in lines_by_file:
            lines_by_file[path].append(line)
    return {path: contiguous_ranges(lines) for path, lines in lines_by_file.items()}


def changed_line_counts(diff_text: str) -> tuple[int, int]:
    added = 0
    removed = 0
    in_hunk = False
    for line in diff_text.splitlines():
        if line.startswith("@@"):
            in_hunk = True
        elif line.startswith("diff --git "):
            in_hunk = False
        elif in_hunk and line.startswith("+"):
            added += 1
        elif in_hunk and line.startswith("-"):
            removed += 1
    return added, removed


def sidecar_skeleton(
    *,
    pr_number: int,
    repository: str,
    base_branch: str,
    head_commit: str,
    agent: str,
    user_attribution: str,
    changed_files: list[str],
    lines_added: int,
    lines_removed: int,
    diff_text: str,
) -> dict[str, Any]:
    return {
        "pr_number": pr_number,
        "pr_url": f"https://github.com/{repository}/pull/{pr_number}",
        "head_commit": head_commit,
        "base_branch": base_branch,
        "title": f"PR {pr_number}",
        "repo": repository,
        "files_changed": len(changed_files),
        "lines_added": lines_added,
        "lines_removed": lines_removed,
        "changed_files": changed_files,
        "changed_ranges": changed_ranges(diff_text, changed_files),
        "findings": [],
        "low_confidence_findings": [],
        "design_context": None,
        "lanes_run": [],
        "lanes_skipped": [],
        "lanes_failed": [],
        "tests_run": [],
        "not_verified": [],
        "publication_plan": {
            "agent": agent,
            "user_attribution": user_attribution,
            "event_override": None,
            "review_body_override": None,
            "discussion_check": None,
            "comments": [],
            "duplicates": [],
            "replies": [],
            "comment_length_exceptions": [],
            "additional_caveats": [],
        },
    }


def command_repository(_: argparse.Namespace) -> None:
    print(f"repository={review_submission.github_repository()}")


def command_fetch_review_refs(args: argparse.Namespace) -> None:
    repository_root = git_root()
    with working_directory(repository_root):
        head_source = refresh_review_refs(
            args.pr_number,
            args.base_branch,
            args.head_commit,
        )
    print(f"base_ref=refs/remotes/origin/{args.base_branch}")
    print(f"head_commit={args.head_commit}")
    print(f"head_source={head_source}")


def command_sidecar_init(args: argparse.Namespace) -> None:
    if args.output.exists():
        fail(f"refusing to replace existing sidecar: {args.output}")
    repository_root = git_root()
    base = f"refs/remotes/origin/{args.base_branch}"
    with working_directory(repository_root):
        diff_result = subprocess.run(
            [
                "git",
                "diff",
                "--find-renames",
                "--no-ext-diff",
                "--color=never",
                "--unified=0",
                f"{base}...{args.head_commit}",
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        files_result = subprocess.run(
            [
                "git",
                "diff",
                "--find-renames",
                "--name-only",
                "-z",
                f"{base}...{args.head_commit}",
            ],
            capture_output=True,
            check=False,
        )
    if diff_result.returncode != 0 or files_result.returncode != 0:
        fail("cannot derive sidecar metadata from the fetched review diff")
    if not diff_result.stdout:
        fail("the local review diff is empty")
    changed_files = [
        path.decode("utf-8")
        for path in files_result.stdout.split(b"\0")
        if path
    ]
    lines_added, lines_removed = changed_line_counts(diff_result.stdout)
    skeleton = sidecar_skeleton(
        pr_number=args.pr_number,
        repository=args.repo,
        base_branch=args.base_branch,
        head_commit=args.head_commit,
        agent=args.agent,
        user_attribution=args.user_attribution,
        changed_files=changed_files,
        lines_added=lines_added,
        lines_removed=lines_removed,
        diff_text=diff_result.stdout,
    )
    write_json(args.output, skeleton)
    print(f"sidecar={args.output}")
    print(f"files_changed={len(changed_files)}")
    print(f"lines_added={lines_added}")
    print(f"lines_removed={lines_removed}")


def fetch_base_branch(base_branch: str) -> None:
    result = subprocess.run(
        [
            "git",
            "fetch",
            "--no-tags",
            "origin",
            f"+refs/heads/{base_branch}:refs/remotes/origin/{base_branch}",
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    if result.returncode != 0:
        fail("cannot refresh the pull request base branch")


def plan_template(agent: str, user_attribution: str) -> dict[str, Any]:
    return {
        "agent": agent,
        "user_attribution": user_attribution,
        "event_override": None,
        "review_body_override": None,
        "discussion_check": None,
        "comments": [],
        "duplicates": [],
        "replies": [],
        "comment_length_exceptions": [],
        "additional_caveats": [],
    }


def store_prepared_run(
    sidecar_path: Path,
    sidecar: dict[str, Any],
    agent: str,
    user_attribution: str,
    repository_root: Path,
    combined_diff: str,
    sidecar_sha256: str,
    diff_source: str,
    started_at: float,
    announce: bool,
) -> Path:
    run_dir = create_run_dir(sidecar["pr_number"])
    plan_path = run_dir / "plan.json"
    approval_diff_path = run_dir / "approval.diff"
    preview_path = sidecar_path.parent / f"pr_{sidecar['pr_number']}_github_review.md"
    approval_diff_path.write_text(combined_diff, encoding="utf-8")
    write_json(plan_path, plan_template(agent, user_attribution))
    manifest = {
        "version": RUN_VERSION,
        "stage": "prepared",
        "repository_root": str(repository_root),
        "sidecar_path": str(sidecar_path),
        "sidecar_sha256": sidecar_sha256,
        "plan_path": str(plan_path),
        "preview_path": str(preview_path.resolve()),
        "repo": sidecar["repo"],
        "pr_number": sidecar["pr_number"],
        "head_commit": sidecar["head_commit"],
        "base_branch": sidecar["base_branch"],
        "approval_diff_sha256": sha256_text(combined_diff),
        "plan_sha256": None,
        "preview_sha256": None,
        "submission_digest": None,
        "discussion_check": None,
        "diff_source": diff_source,
        "timings": {
            "prepare_seconds": elapsed_seconds(started_at),
            "preview_seconds": None,
        },
    }
    write_json(run_dir / "manifest.json", manifest)
    if announce:
        print(f"run_dir={run_dir}")
        print(f"plan={plan_path}")
        print(f"preview={preview_path.resolve()}")
        print(f"head={sidecar['head_commit']}")
        print(f"prepare_seconds={manifest['timings']['prepare_seconds']}")
    return run_dir


def prepare_run(
    sidecar_path: Path,
    agent: str,
    user_attribution: str,
    announce: bool = True,
) -> Path:
    started_at = time.monotonic()
    sidecar_path = sidecar_path.resolve()
    initial_sidecar_sha256 = file_sha256(sidecar_path)
    sidecar = review_submission.validate_sidecar(review_submission.load_json(sidecar_path))
    review_submission.require_nonempty_string(agent, "agent")
    review_submission.validate_ascii(agent, "agent")
    repository_root = git_root()
    with working_directory(repository_root):
        review_submission.validate_current_pr(sidecar)
        review_submission.validate_repository_rule_sources(sidecar)
        combined_diff = fetch_combined_diff(sidecar)
    if file_sha256(sidecar_path) != initial_sidecar_sha256:
        fail("sidecar changed during preparation")
    return store_prepared_run(
        sidecar_path,
        sidecar,
        agent,
        user_attribution,
        repository_root,
        combined_diff,
        initial_sidecar_sha256,
        "github",
        started_at,
        announce,
    )


def run_path(value: Any, label: str) -> Path:
    review_submission.require_nonempty_string(value, label)
    return Path(value).resolve()


def validate_manifest(data: Any, run_dir: Path) -> dict[str, Any]:
    review_submission.require_type(data, dict, "manifest")
    review_submission.require_exact_keys(data, MANIFEST_KEYS, "manifest")
    review_submission.require_type(data["version"], int, "manifest.version")
    if data["version"] != RUN_VERSION:
        fail(f"manifest.version must be {RUN_VERSION}")
    review_submission.require_nonempty_string(data["stage"], "manifest.stage")
    if data["stage"] not in STAGES:
        fail(f"manifest.stage must be one of {sorted(STAGES)}")
    for key in (
        "repository_root",
        "sidecar_path",
        "sidecar_sha256",
        "plan_path",
        "preview_path",
        "repo",
        "head_commit",
        "base_branch",
        "approval_diff_sha256",
    ):
        review_submission.require_nonempty_string(data[key], f"manifest.{key}")
    review_submission.require_type(data["pr_number"], int, "manifest.pr_number")
    if data["pr_number"] <= 0:
        fail("manifest.pr_number must be positive")
    for key in ("sidecar_sha256", "approval_diff_sha256"):
        validate_digest(data[key], f"manifest.{key}")
    for key in ("plan_sha256", "preview_sha256", "submission_digest"):
        if data[key] is not None:
            validate_digest(data[key], f"manifest.{key}")
    if data["discussion_check"] is not None and data["discussion_check"] not in DISCUSSION_CHECKS:
        fail(f"manifest.discussion_check must be one of {sorted(DISCUSSION_CHECKS)} or null")
    if data["diff_source"] not in {"github", "local"}:
        fail("manifest.diff_source must be github or local")
    review_submission.require_type(data["timings"], dict, "manifest.timings")
    review_submission.require_exact_keys(data["timings"], TIMING_KEYS, "manifest.timings")
    for key in TIMING_KEYS:
        value = data["timings"][key]
        if value is None and key == "preview_seconds":
            continue
        if isinstance(value, bool) or not isinstance(value, (int, float)) or value < 0:
            fail(f"manifest.timings.{key} must be a non-negative number")

    expected_plan = run_dir / "plan.json"
    if run_path(data["plan_path"], "manifest.plan_path") != expected_plan:
        fail("manifest.plan_path does not belong to this run directory")
    if not run_dir.name.startswith(f"rearview-{data['pr_number']}-"):
        fail("run directory name does not match manifest.pr_number")
    return data


def validate_digest(value: Any, label: str) -> None:
    review_submission.require_nonempty_string(value, label)
    if len(value) != 64 or any(character not in "0123456789abcdef" for character in value):
        fail(f"{label} must be a lowercase SHA-256 digest")


def normalize_run_dir(path: Path) -> Path:
    if path.is_symlink():
        fail("run directory must not be a symbolic link")
    resolved = path.resolve()
    if not resolved.is_dir():
        fail(f"run directory does not exist: {resolved}")
    temporary_root = Path("/tmp").resolve()
    if temporary_root not in resolved.parents or not resolved.name.startswith("rearview-"):
        fail("run directory is outside the Rearview temporary directory boundary")
    return resolved


def load_manifest(run_dir: Path) -> dict[str, Any]:
    run_dir = normalize_run_dir(run_dir)
    return validate_manifest(review_submission.load_json(run_dir / "manifest.json"), run_dir)


def write_manifest(run_dir: Path, manifest: dict[str, Any]) -> None:
    validate_manifest(manifest, run_dir)
    write_json(run_dir / "manifest.json", manifest)


def load_sidecar(manifest: dict[str, Any]) -> dict[str, Any]:
    sidecar_path = run_path(manifest["sidecar_path"], "manifest.sidecar_path")
    if file_sha256(sidecar_path) != manifest["sidecar_sha256"]:
        fail("sidecar changed after the run was prepared")
    sidecar = review_submission.validate_sidecar(review_submission.load_json(sidecar_path))
    expected = {
        "repo": manifest["repo"],
        "pr_number": manifest["pr_number"],
        "head_commit": manifest["head_commit"],
        "base_branch": manifest["base_branch"],
    }
    actual = {key: sidecar[key] for key in expected}
    if actual != expected:
        fail("sidecar metadata differs from the run manifest")
    return sidecar


def load_plan(manifest: dict[str, Any], sidecar: dict[str, Any]) -> dict[str, Any]:
    plan_path = run_path(manifest["plan_path"], "manifest.plan_path")
    return review_submission.validate_plan(review_submission.load_json(plan_path), sidecar)


def validate_approval_diff(run_dir: Path, manifest: dict[str, Any]) -> Path:
    path = run_dir / "approval.diff"
    if file_sha256(path) != manifest["approval_diff_sha256"]:
        fail("approval diff changed after the run was prepared")
    return path


def preview_run(run_dir: Path) -> None:
    started_at = time.monotonic()
    run_dir = normalize_run_dir(run_dir)
    manifest = load_manifest(run_dir)
    sidecar = load_sidecar(manifest)
    plan = load_plan(manifest, sidecar)
    approval_diff_path = validate_approval_diff(run_dir, manifest)
    review_submission.validate_anchors(plan, approval_diff_path)
    rendered = review_submission.preview_text(sidecar, plan)
    preview_path = run_path(manifest["preview_path"], "manifest.preview_path")
    review_submission.write_text(preview_path, rendered)
    payload = review_submission.submission(sidecar, plan)
    manifest.update(
        {
            "stage": "previewed",
            "plan_sha256": file_sha256(run_dir / "plan.json"),
            "preview_sha256": file_sha256(preview_path),
            "submission_digest": review_submission.publication_digest(sidecar, plan),
            "discussion_check": plan["discussion_check"],
            "timings": {
                **manifest["timings"],
                "preview_seconds": elapsed_seconds(started_at),
            },
        }
    )
    write_manifest(run_dir, manifest)
    print(f"preview={preview_path}")
    print(f"event={payload['event']}")
    print(f"comments={len(payload['comments'])}")
    print(f"extra_replies={len(plan.get('replies', []))}")
    print(f"digest={manifest['submission_digest']}")
    print(f"preview_seconds={manifest['timings']['preview_seconds']}")
    for timing in sidecar["timings"]:
        print(f"review_timing_{timing['phase']}={timing['seconds']}")


def consumable_plan_path(path: Path) -> Path:
    if path.is_symlink():
        fail("consumed plan must not be a symbolic link")
    resolved = path.resolve()
    temporary_root = Path("/tmp").resolve()
    if temporary_root not in resolved.parents or not resolved.name.startswith("rearview-plan-"):
        fail("consumed plan must be a rearview-plan-* file beneath /tmp")
    if not resolved.is_file():
        fail("consumed plan must be a regular file")
    return resolved


def prepare_preview_run(
    sidecar_path: Path,
    plan_source_path: Path | None,
    consume_plan: bool = False,
    timing_log_path: Path | None = None,
    diff_source: str = "local",
) -> Path:
    started_at = time.monotonic()
    sidecar_path = sidecar_path.resolve()
    initial_sidecar_sha256 = file_sha256(sidecar_path)
    sidecar_value = review_submission.load_json(sidecar_path)
    review_submission.require_type(sidecar_value, dict, "sidecar")
    source_timing_path = None
    source_timing_sha256 = None
    timing_was_injected = False
    timing_log = None
    supplied_timings = None
    if timing_log_path is not None:
        source_timing_path = validated_timing_log_path(timing_log_path)
        source_timing_sha256 = file_sha256(source_timing_path)
        timing_log = validate_timing_log(review_submission.load_json(source_timing_path))
        if timing_log["pr_number"] != sidecar_value.get("pr_number"):
            fail("timing log pull request does not match sidecar.pr_number")
        supplied_timings = sidecar_value.get("timings")
        timing_log = complete_normalization_timing(timing_log)
        measured_timings = timing_log["phases"]
        if supplied_timings is not None and supplied_timings != measured_timings:
            fail("sidecar timings differ from measured timing log")
        if supplied_timings is None:
            sidecar_value["timings"] = measured_timings
            timing_was_injected = True
        supplied_warnings = sidecar_value.get("timing_warnings")
        if supplied_warnings is not None and supplied_warnings != timing_log["warnings"]:
            fail("sidecar timing warnings differ from measured timing log")
        if timing_log["warnings"] and supplied_warnings is None:
            sidecar_value["timing_warnings"] = timing_log["warnings"]
            timing_was_injected = True
    sidecar = review_submission.validate_sidecar(sidecar_value)
    source_path = None
    source_sha256 = None
    if plan_source_path is None:
        if consume_plan:
            fail("consume-plan requires a separate plan file")
        if "publication_plan" not in sidecar:
            fail("sidecar has no embedded publication_plan")
        plan = review_submission.validate_plan(sidecar["publication_plan"], sidecar)
    else:
        source_path = consumable_plan_path(plan_source_path) if consume_plan else plan_source_path.resolve()
        source_sha256 = file_sha256(source_path)
        plan = review_submission.validate_plan(review_submission.load_json(source_path), sidecar)
    repository_root = git_root()
    with working_directory(repository_root):
        review_submission.validate_repository_rule_sources(sidecar)
        if diff_source == "github":
            review_submission.validate_current_pr(sidecar)
            combined_diff = fetch_combined_diff(sidecar)
        else:
            combined_diff = fetch_local_combined_diff(sidecar)

    if file_sha256(sidecar_path) != initial_sidecar_sha256:
        fail("sidecar changed during preparation")
    if source_path is not None and file_sha256(source_path) != source_sha256:
        fail("plan changed during preparation")
    if source_timing_path is not None and file_sha256(source_timing_path) != source_timing_sha256:
        fail("timing log changed during preparation")
    if timing_was_injected:
        replace_json(sidecar_path, sidecar)
    sidecar_sha256 = file_sha256(sidecar_path)
    run_dir = store_prepared_run(
        sidecar_path,
        sidecar,
        plan["agent"],
        plan["user_attribution"],
        repository_root,
        combined_diff,
        sidecar_sha256,
        diff_source,
        started_at,
        announce=False,
    )
    write_json(run_dir / "plan.json", plan)
    print(f"run_dir={run_dir}")
    preview_run(run_dir)
    if consume_plan and source_path is not None:
        source_path.unlink()
        print("source_plan_removed=true")
    if source_timing_path is not None:
        if file_sha256(source_timing_path) != source_timing_sha256:
            fail("timing log changed before cleanup")
        source_timing_path.unlink()
        print("source_timing_removed=true")
        if timing_log["version"] == TIMING_LOG_VERSION:
            wait_seconds = round(timing_log["excluded_wait_ns"] / 1_000_000_000, 3)
            print(f"review_timing_wait={wait_seconds}")
        for warning in timing_log["warnings"]:
            print(f"timing_warning={warning}")
    return run_dir


def command_preflight(args: argparse.Namespace) -> None:
    signals = set(args.signal)
    lines_changed = args.lines_added + args.lines_removed
    fast_path = small_fast_path_eligible(
        files_changed=args.files_changed,
        lines_changed=lines_changed,
        signals=signals,
        repository_review_skill=args.repository_review_skill,
        prove=args.prove,
    )
    if fast_path:
        estimate = {"size": "small", "minutes": "2-5"}
        mode = "small-fast"
    else:
        estimate = review_estimate(
            files_changed=args.files_changed,
            lines_changed=lines_changed,
            signals=signals,
            mode=args.mode,
            repository_review_skill=args.repository_review_skill,
        )
        mode = args.mode
    print(f"size={estimate['size']}")
    print(f"estimate_minutes={estimate['minutes']}")
    print(f"mode={mode}")
    print("estimate_is_heuristic=true")
    print(f"drivers={','.join(sorted(signals)) if signals else 'none'}")
    print(f"checkpoint_minutes={5 if fast_path else 10}")


def command_timing_start(args: argparse.Namespace) -> None:
    print(f"timing_log={create_timing_log(args.pr_number)}")


def command_timing_mark(args: argparse.Namespace) -> None:
    seconds = mark_timing(args.timing_log, args.phase)
    value = validate_timing_log(review_submission.load_json(args.timing_log))
    print(f"review_timing_{args.phase}={seconds}")
    next_index = len(value["phases"])
    next_phase = TIMING_PHASES[next_index] if next_index < len(TIMING_PHASES) else "complete"
    print(f"next_phase={next_phase}")
    for warning in value["warnings"]:
        print(f"timing_warning={warning}")


def command_timing_pause(args: argparse.Namespace) -> None:
    pause_timing(args.timing_log)
    print("timing_paused=true")


def command_timing_resume(args: argparse.Namespace) -> None:
    wait_seconds = resume_timing(args.timing_log)
    print("timing_resumed=true")
    print(f"review_timing_wait={wait_seconds}")


def command_discussion_snapshot(args: argparse.Namespace) -> None:
    snapshot = fetch_discussion_snapshot(args.repo, args.pr_number)
    path = private_temporary_path(f"rearview-discussion-{args.pr_number}-")
    replace_json(path, snapshot)
    print(f"discussion_snapshot={path}")
    print(f"discussion_digest={snapshot['digest']}")
    for surface, records in snapshot["surfaces"].items():
        print(f"discussion_{surface}={len(records)}")


def command_discussion_recheck(args: argparse.Namespace) -> None:
    path = validated_discussion_path(args.snapshot)
    previous = validate_discussion_snapshot(review_submission.load_json(path))
    current = fetch_discussion_snapshot(previous["repo"], previous["pr_number"])
    if current["digest"] == previous["digest"]:
        print("discussion_changed=false")
        print(f"discussion_digest={current['digest']}")
        return
    delta = discussion_delta(previous, current)
    delta_path = private_temporary_path(
        f"rearview-discussion-delta-{current['pr_number']}-"
    )
    replace_json(delta_path, delta)
    replace_json(path, current)
    print("discussion_changed=true")
    print(f"discussion_delta={delta_path}")
    print(f"discussion_digest={current['digest']}")
    for surface in DISCUSSION_SURFACES:
        print(f"discussion_{surface}_changed={len(delta['changed'][surface])}")
        print(f"discussion_{surface}_removed={len(delta['removed'][surface])}")


def command_discussion_cleanup(args: argparse.Namespace) -> None:
    path = validated_discussion_path(args.artifact)
    path.unlink()
    print("discussion_artifact_removed=true")


def command_render_report(args: argparse.Namespace) -> None:
    sidecar = review_submission.validate_sidecar(review_submission.load_json(args.sidecar))
    expected_name = f"pr_{sidecar['pr_number']}_review.md"
    output = args.output or args.sidecar.parent / expected_name
    if output.name != expected_name:
        fail(f"report output must be named {expected_name}")
    review_submission.write_text(output, review_submission.report_text(sidecar))
    print(f"report={output}")


def command_stability_check(args: argparse.Namespace) -> None:
    sidecar = review_submission.validate_sidecar(review_submission.load_json(args.sidecar))
    current = review_submission.validate_current_pr(sidecar)
    print("stable=true")
    print(f"head={current['headRefOid']}")
    print(f"state={current['state']}")


def load_previewed_run(
    run_dir: Path,
) -> tuple[dict[str, Any], dict[str, Any], dict[str, Any]]:
    manifest = load_manifest(run_dir)
    if manifest["stage"] != "previewed":
        fail("run has no approved preview")
    sidecar = load_sidecar(manifest)
    plan = load_plan(manifest, sidecar)
    if file_sha256(run_dir / "plan.json") != manifest["plan_sha256"]:
        fail("plan changed after the preview was generated")
    preview_path = run_path(manifest["preview_path"], "manifest.preview_path")
    if file_sha256(preview_path) != manifest["preview_sha256"]:
        fail("preview changed after it was generated")
    review_submission.approved_preview(sidecar, plan, preview_path)
    if manifest["discussion_check"] != plan["discussion_check"]:
        fail("discussion check changed after the preview was generated")
    return manifest, sidecar, plan


def post_payload(endpoint: str, payload_path: Path) -> int:
    result = subprocess.run(
        ["gh", "api", "--method", "POST", endpoint, "--input", str(payload_path), "--silent"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return result.returncode


def post_review(sidecar: dict[str, Any], payload_path: Path) -> int:
    return post_payload(f"repos/{sidecar['repo']}/pulls/{sidecar['pr_number']}/reviews", payload_path)


def post_reply(sidecar: dict[str, Any], reply: dict[str, Any], payload_path: Path) -> int:
    return post_payload(review_submission.reply_endpoint(sidecar, reply), payload_path)


def publication_choice(run_dir: Path, manifest: dict[str, Any]) -> str | None:
    path = run_dir / "publication.json"
    if not path.exists():
        return None
    if path.is_symlink():
        fail("publication decision must not be a symbolic link")
    value = review_submission.load_json(path)
    review_submission.require_type(value, dict, "publication decision")
    review_submission.require_exact_keys(value, {"submission_digest", "replies"}, "publication decision")
    if value["submission_digest"] != manifest["submission_digest"] or value["replies"] not in {"all", "none"}:
        fail("publication decision does not match the approved package")
    return value["replies"]


def selected_replies(plan: dict[str, Any], decision: str | None) -> list[dict[str, Any]]:
    if plan.get("duplicates") and "replies" not in plan:
        fail("legacy duplicate plan has no reply decision; prepare a preview containing the reply drafts")
    if plan.get("replies") and decision not in {"all", "none"}:
        fail("explicit reply decision required: --replies all or --replies none")
    return plan.get("replies", []) if decision == "all" else []


def publish_replies(run_dir: Path, sidecar: dict[str, Any], plan: dict[str, Any], replies: list[dict]) -> None:
    for reply in replies:
        review_submission.validate_current_pr(sidecar)
        review_submission.validate_reply_target(sidecar, reply)
        matches = review_submission.exact_replies(sidecar, plan, reply)
        if matches:
            continue
        payload_path = run_dir / "reply-payload.json"
        write_json(payload_path, {"body": review_submission.reply_body(plan, reply)})
        result = post_reply(sidecar, reply, payload_path)
        matches = review_submission.exact_replies(sidecar, plan, reply)
        if not matches:
            fail(f"reply POST exit {result}; exact reply not verified; retain the run and recheck before retrying")


def verify_posted(
    sidecar_path: Path,
    plan_path: Path,
    preview_path: Path,
) -> None:
    review_submission.command_verify_posted(
        SimpleNamespace(
            sidecar=sidecar_path,
            plan=plan_path,
            approved_preview=preview_path,
        )
    )


def publish_run(
    run_dir: Path,
    approved_digest: str,
    discussion_confirmation: str | None = None,
    reply_decision: str | None = None,
    approve_instead: bool = False,
) -> None:
    started_at = time.monotonic()
    run_dir = normalize_run_dir(run_dir)
    manifest, sidecar, plan = load_previewed_run(run_dir)
    if approved_digest != manifest["submission_digest"]:
        fail("approved digest does not match the previewed submission")
    if discussion_confirmation is not None and discussion_confirmation != manifest["discussion_check"]:
        fail("discussion confirmation does not match the previewed plan")
    if approve_instead and review_submission.event_for(sidecar, plan) != "APPROVE":
        fail("Approve instead requires a revised APPROVE plan and its prepared digest")
    previous_choice = publication_choice(run_dir, manifest)
    if previous_choice is not None and reply_decision != previous_choice:
        fail("reply decision changed during publication; keep the recorded choice for recovery")
    replies = selected_replies(plan, reply_decision)
    repository_root = run_path(manifest["repository_root"], "manifest.repository_root")
    with working_directory(repository_root):
        review_submission.validate_current_pr(sidecar)
        if review_submission.exact_reviews(sidecar, plan) and previous_choice is None:
            fail("an exact review already exists; run verify instead")
        for reply in replies:
            review_submission.validate_reply_target(sidecar, reply)
        if manifest["diff_source"] == "local":
            fetch_base_branch(sidecar["base_branch"])
            posting_diff = fetch_local_combined_diff(sidecar)
        else:
            posting_diff = fetch_combined_diff(sidecar)

    posting_diff_path = run_dir / "posting.diff"
    posting_diff_path.write_text(posting_diff, encoding="utf-8")
    if sha256_text(posting_diff) != manifest["approval_diff_sha256"]:
        fail("combined diff changed after preview; prepare a new run")
    review_submission.validate_anchors(plan, posting_diff_path)

    payload = review_submission.submission(sidecar, plan)
    payload_path = run_dir / "payload.json"
    write_json(payload_path, payload)
    write_manifest(run_dir, manifest)

    with working_directory(repository_root):
        review_submission.validate_current_pr(sidecar)
        existing = review_submission.exact_reviews(sidecar, plan)
        if existing and previous_choice is None:
            fail("an exact review already exists; run verify instead")
        if plan.get("replies"):
            write_json(run_dir / "publication.json", {
                "submission_digest": approved_digest, "replies": reply_decision,
            })
        if not existing:
            result = post_review(sidecar, payload_path)
            if result != 0:
                if review_submission.exact_reviews(sidecar, plan):
                    fail("GitHub POST was unclear and an exact review exists; run verify before resuming")
                fail("GitHub POST failed and no exact review exists; recheck before retrying")
        if replies:
            verify_posted(
                run_path(manifest["sidecar_path"], "manifest.sidecar_path"),
                run_path(manifest["plan_path"], "manifest.plan_path"),
                run_path(manifest["preview_path"], "manifest.preview_path"),
            )
            publish_replies(run_dir, sidecar, plan, replies)

    verify_run(run_dir)
    print(f"publish_seconds={elapsed_seconds(started_at)}")


def verify_run(run_dir: Path) -> None:
    run_dir = normalize_run_dir(run_dir)
    manifest, sidecar, plan = load_previewed_run(run_dir)
    replies = selected_replies(plan, publication_choice(run_dir, manifest))
    repository_root = run_path(manifest["repository_root"], "manifest.repository_root")
    with working_directory(repository_root):
        verify_posted(
            run_path(manifest["sidecar_path"], "manifest.sidecar_path"),
            run_path(manifest["plan_path"], "manifest.plan_path"),
            run_path(manifest["preview_path"], "manifest.preview_path"),
        )
        for reply in replies:
            matches = review_submission.exact_replies(sidecar, plan, reply)
            if not matches:
                fail("review exists but a selected reply is missing; resume publish with the same digest and choice")
            print(f"reply_url={matches[0]['html_url']}")
    print(f"replies_verified={len(replies)}")
    print(f"replies_skipped={len(plan.get('replies', [])) - len(replies)}")
    cleanup_run(run_dir)
    print("run_dir_removed=true")


def cleanup_run(run_dir: Path) -> None:
    run_dir = normalize_run_dir(run_dir)
    load_manifest(run_dir)
    entries = {entry.name for entry in run_dir.iterdir()}
    unexpected = sorted(entries - RUN_FILENAMES)
    if unexpected:
        fail(f"run directory contains unexpected entries: {unexpected}")
    for name in sorted(RUN_FILENAMES - {"manifest.json"}):
        path = run_dir / name
        if path.exists():
            if path.is_symlink() or not path.is_file():
                fail(f"refusing to remove unsafe run entry: {path}")
            path.unlink()
    (run_dir / "manifest.json").unlink()
    run_dir.rmdir()


def path_argument(value: str) -> Path:
    return Path(value).resolve()


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    commands = result.add_subparsers(dest="command", required=True)

    repository = commands.add_parser(
        "repository",
        help="resolve owner/repository from the local origin mapping",
    )
    repository.set_defaults(handler=command_repository)

    fetch_review_refs = commands.add_parser(
        "fetch-review-refs",
        help="refresh the base and fetch the exact PR head only when absent",
    )
    fetch_review_refs.add_argument("--pr-number", required=True, type=int)
    fetch_review_refs.add_argument("--base-branch", required=True)
    fetch_review_refs.add_argument("--head-commit", required=True)
    fetch_review_refs.set_defaults(handler=command_fetch_review_refs)

    preflight = commands.add_parser("preflight", help="estimate review size before substantive work")
    preflight.add_argument("--files-changed", required=True, type=int)
    preflight.add_argument("--lines-added", required=True, type=int)
    preflight.add_argument("--lines-removed", required=True, type=int)
    preflight.add_argument("--mode", choices=("quick", "thorough"), default="thorough")
    preflight.add_argument("--repository-review-skill", action="store_true")
    preflight.add_argument("--prove", action="store_true")
    preflight.add_argument(
        "--signal",
        action="append",
        default=[],
        choices=sorted(REVIEW_SIGNAL_WEIGHTS),
    )
    preflight.set_defaults(handler=command_preflight)

    timing_start = commands.add_parser("timing-start", help="start a measured review timing log")
    timing_start.add_argument("--pr-number", required=True, type=int)
    timing_start.set_defaults(handler=command_timing_start)

    timing_mark = commands.add_parser("timing-mark", help="finish one measured review phase")
    timing_mark.add_argument("--timing-log", required=True, type=path_argument)
    timing_mark.add_argument("--phase", required=True, choices=TIMING_PHASES)
    timing_mark.set_defaults(handler=command_timing_mark)

    timing_pause = commands.add_parser(
        "timing-pause",
        help="exclude an explicit user wait from measured review work",
    )
    timing_pause.add_argument("--timing-log", required=True, type=path_argument)
    timing_pause.set_defaults(handler=command_timing_pause)

    timing_resume = commands.add_parser(
        "timing-resume",
        help="resume measured review work after an explicit user wait",
    )
    timing_resume.add_argument("--timing-log", required=True, type=path_argument)
    timing_resume.set_defaults(handler=command_timing_resume)

    discussion_snapshot = commands.add_parser(
        "discussion-snapshot",
        help="enumerate and privately cache all pull request discussion",
    )
    discussion_snapshot.add_argument("--repo", required=True)
    discussion_snapshot.add_argument("--pr-number", required=True, type=int)
    discussion_snapshot.set_defaults(handler=command_discussion_snapshot)

    discussion_recheck = commands.add_parser(
        "discussion-recheck",
        help="re-enumerate discussion and write only changes to a private delta",
    )
    discussion_recheck.add_argument("--snapshot", required=True, type=path_argument)
    discussion_recheck.set_defaults(handler=command_discussion_recheck)

    discussion_cleanup = commands.add_parser(
        "discussion-cleanup",
        help="remove one private discussion snapshot or delta",
    )
    discussion_cleanup.add_argument("--artifact", required=True, type=path_argument)
    discussion_cleanup.set_defaults(handler=command_discussion_cleanup)

    render_report = commands.add_parser(
        "render-report",
        help="render the local Markdown report directly from a validated sidecar",
    )
    render_report.add_argument("--sidecar", required=True, type=path_argument)
    render_report.add_argument("--output", type=path_argument)
    render_report.set_defaults(handler=command_render_report)

    stability_check = commands.add_parser(
        "stability-check",
        help="confirm the reviewed PR head, base, URL, and state are unchanged",
    )
    stability_check.add_argument("--sidecar", required=True, type=path_argument)
    stability_check.set_defaults(handler=command_stability_check)

    sidecar_init = commands.add_parser(
        "sidecar-init",
        help="derive a review sidecar skeleton from the fetched local diff",
    )
    sidecar_init.add_argument("--pr-number", required=True, type=int)
    sidecar_init.add_argument("--repo", required=True)
    sidecar_init.add_argument("--base-branch", required=True)
    sidecar_init.add_argument("--head-commit", required=True)
    sidecar_init.add_argument("--agent", required=True)
    sidecar_init.add_argument("--user-attribution", required=True)
    sidecar_init.add_argument("--output", required=True, type=path_argument)
    sidecar_init.set_defaults(handler=command_sidecar_init)

    prepare = commands.add_parser("prepare", help="create a private submission run")
    prepare.add_argument("--sidecar", required=True, type=path_argument)
    prepare.add_argument("--agent", required=True)
    prepare.add_argument("--user-attribution", required=True)
    prepare.set_defaults(
        handler=lambda args: prepare_run(
            args.sidecar,
            args.agent,
            args.user_attribution,
        )
    )

    preview = commands.add_parser("preview", help="render and record the approval preview")
    preview.add_argument("--run-dir", required=True, type=path_argument)
    preview.set_defaults(handler=lambda args: preview_run(args.run_dir))

    prepare_preview = commands.add_parser(
        "prepare-preview",
        help="store one complete plan and render its approval preview",
    )
    prepare_preview.add_argument("--sidecar", required=True, type=path_argument)
    plan_source = prepare_preview.add_mutually_exclusive_group(required=True)
    plan_source.add_argument("--plan", type=path_argument)
    plan_source.add_argument("--embedded-plan", action="store_true")
    prepare_preview.add_argument("--consume-plan", action="store_true")
    prepare_preview.add_argument("--timing-log", type=path_argument)
    prepare_preview.add_argument(
        "--diff-source",
        choices=("local", "github"),
        default="local",
    )
    prepare_preview.set_defaults(
        handler=lambda args: prepare_preview_run(
            args.sidecar,
            args.plan,
            consume_plan=args.consume_plan,
            timing_log_path=args.timing_log,
            diff_source=args.diff_source,
        )
    )

    publish = commands.add_parser("publish", help="post one explicitly approved review")
    publish.add_argument("--run-dir", required=True, type=path_argument)
    publish.add_argument("--approved-digest", required=True)
    selection = publish.add_mutually_exclusive_group()
    selection.add_argument("--replies", choices=("all", "none"), help="explicit extra-reply decision")
    selection.add_argument("--decision", choices=("Publish", "Publish all", "Review only", "Approve instead"))
    publish.add_argument(
        "--discussion-confirmation",
        choices=sorted(DISCUSSION_CHECKS),
    )
    publish.set_defaults(
        handler=lambda args: publish_run(
            args.run_dir,
            args.approved_digest,
            args.discussion_confirmation,
            reply_decision={
                "Publish": "all", "Publish all": "all", "Review only": "none", "Approve instead": "all",
            }.get(args.decision, args.replies),
            approve_instead=args.decision == "Approve instead",
        )
    )

    verify = commands.add_parser("verify", help="verify an existing post and clean the run")
    verify.add_argument("--run-dir", required=True, type=path_argument)
    verify.set_defaults(handler=lambda args: verify_run(args.run_dir))

    cleanup = commands.add_parser("cleanup", help="remove only files owned by an abandoned run")
    cleanup.add_argument("--run-dir", required=True, type=path_argument)
    cleanup.set_defaults(handler=lambda args: cleanup_run(args.run_dir))
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
