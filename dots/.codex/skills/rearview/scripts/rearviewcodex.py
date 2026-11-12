#!/usr/bin/env python3
"""Initialize, diagnose, and launch interactive Rearview sessions."""

from __future__ import annotations

import argparse
from contextlib import contextmanager
from datetime import UTC, datetime
import fcntl
import json
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
from typing import Iterator
import uuid


SCRIPT_DIRECTORY = Path(__file__).resolve().parent
if str(SCRIPT_DIRECTORY) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIRECTORY))

import rearview_config  # noqa: E402


class CommandError(Exception):
    """Raised when Rearview cannot prepare or launch a review."""


def run(
    arguments: list[str],
    *,
    cwd: Path | None = None,
    capture: bool = False,
    silent: bool = False,
) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        arguments,
        cwd=cwd,
        capture_output=capture or silent,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        command = " ".join(arguments[:3])
        detail = result.stderr.strip() if capture and result.stderr else ""
        suffix = f": {detail}" if detail else ""
        raise CommandError(f"command failed ({result.returncode}): {command}{suffix}")
    return result


def prompt(label: str, default: str | None = None) -> str:
    suffix = f" [{default}]" if default else ""
    value = input(f"{label}{suffix}: ").strip()
    return value or default or ""


def confirm_replace(paths: list[Path]) -> bool:
    existing = [path for path in paths if path.exists()]
    if not existing:
        return True
    print("Existing files:")
    for path in existing:
        print(f"  {path}")
    return input("Replace them? [y/N]: ").strip().lower() in {"y", "yes"}


def parse_aliases(value: str) -> dict[str, str]:
    if not value.strip():
        return {}
    aliases: dict[str, str] = {}
    for item in value.split(","):
        alias, separator, repository = item.strip().partition("=")
        if not separator:
            raise rearview_config.ConfigError(
                f"alias {item!r} must use alias=owner/repository"
            )
        aliases[alias.strip()] = repository.strip()
    return aliases


def initialize(args: argparse.Namespace) -> int:
    path = rearview_config.config_path()
    attribution = args.user_attribution or prompt("Public attribution label")
    default_owner = args.default_owner
    if default_owner is None:
        default_owner = prompt("Default GitHub owner (optional)")
    aliases_value = args.alias
    if aliases_value is None:
        aliases_value = prompt("Aliases, comma-separated alias=owner/repository (optional)")
    aliases = parse_aliases(aliases_value)
    profile = args.codex_profile or "rearview"
    cache_root = (
        Path(args.cache_root).expanduser().resolve()
        if args.cache_root
        else rearview_config.default_cache_root()
    )
    artifact_root = (
        Path(args.artifact_root).expanduser().resolve()
        if args.artifact_root
        else rearview_config.default_artifact_root()
    )
    config = rearview_config.parse_config(
        {
            "version": rearview_config.CONFIG_VERSION,
            "user_attribution": attribution,
            "default_owner": default_owner,
            "codex_profile": profile,
            "cache_root": str(cache_root),
            "artifact_root": str(artifact_root),
            "aliases": aliases,
        }
    )
    profile = rearview_config.profile_path(config.codex_profile)
    if not args.force and not confirm_replace([path, profile]):
        print("No files changed.")
        return 1

    path.parent.mkdir(parents=True, exist_ok=True)
    profile.parent.mkdir(parents=True, exist_ok=True)
    config.cache_root.mkdir(parents=True, exist_ok=True)
    config.artifact_root.mkdir(parents=True, exist_ok=True)
    path.write_text(rearview_config.render_config(config), encoding="utf-8")
    profile.write_text(rearview_config.render_profile(), encoding="utf-8")
    print(f"Configuration: {path}")
    print(f"Codex profile: {profile}")
    print("Next: review and install the PR-content privacy policy described in README.md.")
    print("Then run: rearview doctor")
    return 0


def executable_available(name: str) -> bool:
    return shutil.which(name) is not None


def writable_directory(path: Path) -> bool:
    try:
        path.mkdir(parents=True, exist_ok=True)
        probe = path / f".rearview-write-{uuid.uuid4().hex}"
        probe.touch(mode=0o600)
        probe.unlink()
    except OSError:
        return False
    return True


def diagnose(args: argparse.Namespace) -> int:
    if args.git_only:
        if not args.repository:
            raise CommandError("--git-only requires --repository owner/name")
        probe_git_access(args.repository)
        return 0

    failures: list[str] = []
    for executable in ("git", "gh", "codex"):
        if executable_available(executable):
            print(f"ok: {executable}")
        else:
            failures.append(f"missing executable: {executable}")

    try:
        config = rearview_config.load_config()
        print(f"ok: configuration {rearview_config.config_path()}")
    except rearview_config.ConfigError as error:
        failures.append(str(error))
        config = None

    if config:
        for label, path in (
            ("cache root", config.cache_root),
            ("artifact root", config.artifact_root),
        ):
            if writable_directory(path):
                print(f"ok: {label} {path}")
            else:
                failures.append(f"not writable: {label} {path}")
        profile = rearview_config.profile_path(config.codex_profile)
        if profile.is_file():
            print(f"ok: Codex profile {profile}")
        else:
            failures.append(f"missing Codex profile: {profile}")

    skill = SCRIPT_DIRECTORY.parent / "SKILL.md"
    if skill.is_file():
        print(f"ok: Rearview skill {skill.parent}")
    else:
        failures.append(f"missing Rearview skill: {skill}")

    if executable_available("gh"):
        result = subprocess.run(
            ["gh", "api", "user", "--silent"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        if result.returncode == 0:
            print("ok: GitHub API access")
        else:
            failures.append("GitHub API access failed")

    if args.repository and executable_available("git") and executable_available("gh"):
        repository = config.resolve_repository(args.repository) if config else args.repository
        try:
            probe_git_access(repository)
        except CommandError as error:
            failures.append(str(error))
    else:
        print("Git transport: not checked; use doctor --repository owner/name for a fresh clone.")
    print("Sandbox Git access: run doctor --git-only --repository owner/name inside the review session.")

    if failures:
        for failure in failures:
            print(f"error: {failure}", file=sys.stderr)
        return 1
    print("Checks passed for this execution context only.")
    return 0


def probe_git_access(repository: str) -> None:
    if not rearview_config.REPOSITORY.fullmatch(repository):
        raise CommandError("Git probe repository must be owner/name")
    with tempfile.TemporaryDirectory(prefix="rearview-git-check-", dir="/tmp") as directory:
        github_git([
            "clone", "--bare", "--depth=1", "--",
            f"rearview-github:{repository}.git", str(Path(directory) / "probe.git"),
        ])
    print("ok: fresh HTTPS Git clone in this execution context")


def github_git_arguments(arguments: list[str]) -> list[str]:
    # Rewrite an internal alias once, avoiding installed HTTPS-to-SSH rules.
    return [
        "git", "-c", "url.https://github.com/.insteadOf=rearview-github:",
        "-c", "credential.helper=",
        "-c", "credential.https://github.com.helper=!gh auth git-credential",
        "-c", "credential.interactive=false",
        "-c", "core.hooksPath=/dev/null",
        *arguments,
    ]


def github_git(arguments: list[str]) -> subprocess.CompletedProcess[str]:
    try:
        result = subprocess.run(
            github_git_arguments(arguments), capture_output=True, text=True, check=False, timeout=60,
        )
    except subprocess.TimeoutExpired as error:
        raise CommandError("HTTPS Git access failed: timeout") from error
    except OSError as error:
        raise CommandError("HTTPS Git command could not start") from error
    if result.returncode:
        detail = result.stderr.lower()
        category = "transport or repository access"
        for marker, label in (
            ("could not resolve", "DNS"),
            ("failed to connect", "network connection"),
            ("operation not permitted", "sandbox permission"),
            ("authentication failed", "authentication"),
            ("could not read username", "credentials unavailable"),
            ("repository not found", "repository access"),
        ):
            if marker in detail:
                category = label
                break
        raise CommandError(f"HTTPS Git access failed ({result.returncode}): {category}")
    return result


def prepare_companion(repository: str, commit: str, destination: Path) -> None:
    if not rearview_config.REPOSITORY.fullmatch(repository):
        raise CommandError("companion repository must be owner/name")
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise CommandError("companion commit must be a full immutable GitHub commit SHA")
    destination = destination.absolute()
    if destination.exists() or destination.is_symlink():
        raise CommandError("companion destination already exists; choose a fresh session path")
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".rearview-companion-", dir=destination.parent) as directory:
        checkout = Path(directory) / "checkout"
        github_git(["init", "--template=", str(checkout)])
        github_git(["-C", str(checkout), "remote", "add", "origin", f"https://github.com/{repository}.git"])
        github_git([
            "-C", str(checkout), "fetch", "--no-tags", "--depth=1", "--",
            f"rearview-github:{repository}.git", commit,
        ])
        fetched = github_git(["-C", str(checkout), "rev-parse", "FETCH_HEAD^{commit}"])
        if fetched.stdout.strip() != commit:
            raise CommandError("fetched companion commit does not match the requested SHA")
        github_git(["-C", str(checkout), "checkout", "--detach", commit])
        checkout.rename(destination)
    print(f"Companion prepared at immutable commit {commit}; shallow checkout, no parent history.")


def repository_lock_path(
    cache_root: Path,
    repository: str,
    purpose: str,
) -> Path:
    owner, name = repository.split("/", 1)
    lock_directory = cache_root / ".locks" / owner
    lock_directory.mkdir(parents=True, exist_ok=True)
    return lock_directory / f"{name}.{purpose}.lock"


@contextmanager
def primary_worktree_lease(cache_root: Path, repository: str) -> Iterator[bool]:
    lock_path = repository_lock_path(cache_root, repository, "primary-worktree")
    with lock_path.open("a", encoding="utf-8") as stream:
        try:
            fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            yield False
        else:
            yield True


@contextmanager
def repository_cache_lock(cache_root: Path, repository: str) -> Iterator[None]:
    lock_path = repository_lock_path(cache_root, repository, "cache")
    with lock_path.open("a", encoding="utf-8") as stream:
        fcntl.flock(stream, fcntl.LOCK_EX)
        yield


def cache_path(config: rearview_config.Config, repository: str) -> Path:
    owner, name = repository.split("/", 1)
    return config.cache_root / owner / f"{name}.git"


def worktree_path(config: rearview_config.Config, repository: str) -> Path:
    owner, name = repository.split("/", 1)
    return config.cache_root / ".worktrees" / owner / name


def review_worktree_path(
    config: rearview_config.Config,
    repository: str,
    run_root: Path,
    *,
    primary: bool,
) -> Path:
    if primary:
        return worktree_path(config, repository)
    return run_root / "worktree"


def ensure_cache(config: rearview_config.Config, repository: str) -> Path:
    destination = cache_path(config, repository)
    if destination.is_dir():
        return destination
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.parent / f".{destination.name}.{uuid.uuid4().hex}"
    try:
        run(["gh", "repo", "clone", repository, str(temporary), "--", "--bare"])
        temporary.replace(destination)
    except BaseException:
        if temporary.exists():
            shutil.rmtree(temporary)
        raise
    return destination


def pull_request_metadata(repository: str, pr_number: int) -> dict[str, str]:
    result = run(
        [
            "gh",
            "pr",
            "view",
            str(pr_number),
            "--repo",
            repository,
            "--json",
            "baseRefName,headRefOid,state,url",
        ],
        capture=True,
    )
    try:
        value = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise CommandError("GitHub returned invalid pull request metadata") from error
    expected = {"baseRefName", "headRefOid", "state", "url"}
    if not isinstance(value, dict) or set(value) != expected:
        raise CommandError("GitHub returned incomplete pull request metadata")
    if value["state"] != "OPEN":
        raise CommandError(f"pull request state is {value['state']!r}, not OPEN")
    return value


def refresh_review_refs(cache: Path, pr_number: int, base: str, head: str) -> None:
    run(
        [
            "git",
            f"--git-dir={cache}",
            "fetch",
            "--no-tags",
            "origin",
            f"+refs/heads/{base}:refs/remotes/origin/{base}",
            f"+refs/pull/{pr_number}/head:refs/rearview/pr-{pr_number}",
        ],
        silent=True,
    )
    result = run(
        ["git", f"--git-dir={cache}", "rev-parse", f"refs/rearview/pr-{pr_number}"],
        capture=True,
    )
    if result.stdout.strip() != head:
        raise CommandError("fetched pull request head does not match GitHub metadata")


def artifact_directory(
    config: rearview_config.Config,
    repository: str,
    pr_number: int,
) -> Path:
    owner, name = repository.split("/", 1)
    timestamp = datetime.now(UTC).strftime("%Y%m%dT%H%M%SZ")
    result = config.artifact_root / owner / name / f"pr-{pr_number}" / f"{timestamp}-{uuid.uuid4().hex[:8]}"
    result.mkdir(parents=True)
    return result


def copy_repository_files(
    sources: list[Path],
    artifacts: Path,
    directory_name: str,
) -> list[Path]:
    if not sources:
        return []
    destination = artifacts / directory_name
    destination.mkdir()
    results = []
    for index, source in enumerate(sources, start=1):
        if not source.is_file():
            raise CommandError(f"repository context file is missing: {source}")
        target = destination / f"{index}-{source.name}"
        shutil.copy2(source, target)
        results.append(target)
    return results


def review_prompt(
    *,
    repository: str,
    pr_number: int,
    metadata: dict[str, str],
    config: rearview_config.Config,
    artifacts: Path,
    companion_root: Path,
    policies: list[Path],
    contexts: list[Path],
    quick: bool,
    prove: bool,
) -> str:
    mode = " --quick" if quick else ""
    proof = " --prove" if prove else ""
    policy_text = ", ".join(str(path) for path in policies) or "none"
    context_text = ", ".join(str(path) for path in contexts) or "none"
    companion_command = shlex.join([sys.executable, str(SCRIPT_DIRECTORY / "rearviewcodex.py"), "companion"])
    return f"""Use $rearview to review PR {pr_number}{mode}{proof}.

The Rearview wrapper prepared this disposable checkout:
- repository: {repository}
- base branch: {metadata['baseRefName']}
- head commit: {metadata['headRefOid']}
- artifact directory: {artifacts}
- disposable companion directory: {companion_root}
- public user attribution: {config.user_attribution}
- applicable policy files: {policy_text}
- repository context files: {context_text}

For a needed companion repository, resolve its full immutable commit through gh.
Use this Python wrapper's HTTPS helper before attempting any direct clone:
{companion_command} \\
  --repository OWNER/REPO --commit SHA \\
  --destination {shlex.quote(str(companion_root))}/REPO-SHA
The helper uses gh credentials and command-scoped HTTPS, avoiding the SSH agent
and installed HTTPS-to-SSH rewrites. It fetches only that commit, with no parent
history. It cannot bypass sandbox network restrictions or missing gh credentials.
Keep all companions under the disposable companion directory for session cleanup.

Treat the review's base and head refs as freshly fetched. Do not fetch, pull,
check out, or modify source in the review checkout. Write Rearview artifacts beneath the
artifact directory. Use the GitHub diff for preview and publication freshness
checks. Work autonomously until the single publication gate. If GitHub advances
the PR head, discard the stale review and fully review the new head before
presenting another gate.

The exact response `Approve instead` applies to every proposed event.
It means Publish all with the review event overridden to `APPROVE`.
Set the event to `APPROVE`.
Recast blocking comments as suggestions or strong suggestions.
Use an encouraging, upbeat tone without being patronizing or sympathetic.
Extra replies belong in the same publication gate and exact preview.
Publish and Publish all authorize the review and every reply in the exact preview.
Do not ask another inclusion question after either response.
Review only authorizes the review and explicitly excludes every reply.
Approve instead authorizes the revised review and every previewed reply.
Preserve every previewed reply body and target. Do not ask another inclusion question.
Abandon the active run and prepare the revised APPROVE plan and digest before
publishing with --decision "Approve instead".
Perform every required freshness check, then publish without another preview
when the review remains current. Do not infer this shorthand from a longer
response or different wording."""


def archive_repository_reports(worktree: Path, artifacts: Path, pr_number: int) -> None:
    names = [
        f"pr_{pr_number}_review.md",
        f"pr_{pr_number}_review.json",
        f"pr_{pr_number}_github_review.md",
    ]
    names.extend(path.name for path in worktree.glob(f"pr_{pr_number}_reply_*.md"))
    for name in sorted(set(names)):
        source = worktree / name
        if source.is_file():
            shutil.copy2(source, artifacts / name)


def codex_arguments(
    *,
    config: rearview_config.Config,
    worktree: Path,
    artifacts: Path,
    input_root: Path,
    prompt_value: str,
    model: str | None = None,
    reasoning_effort: str | None = None,
) -> list[str]:
    arguments = [
        "codex",
        "--profile",
        config.codex_profile,
        "--no-daemon",
    ]
    if model:
        arguments.extend(["--model", model])
    if reasoning_effort:
        arguments.extend(["-c", f"model_reasoning_effort={reasoning_effort}"])
    arguments.extend([
        "-C",
        str(worktree),
        "--add-dir",
        str(artifacts),
        "--add-dir",
        str(input_root),
        prompt_value,
    ])
    return arguments


def launch_review(args: argparse.Namespace) -> int:
    config = rearview_config.load_config()
    repository = config.resolve_repository(args.repository)
    with primary_worktree_lease(config.cache_root, repository) as primary:
        return launch_review_session(args, config, repository, primary=primary)


def launch_review_session(
    args: argparse.Namespace,
    config: rearview_config.Config,
    repository: str,
    *,
    primary: bool,
) -> int:
    artifacts = artifact_directory(config, repository, args.pr_number)
    cache = cache_path(config, repository)
    run_root = Path(tempfile.mkdtemp(prefix="rearview-", dir="/tmp")).resolve()
    worktree = review_worktree_path(
        config,
        repository,
        run_root,
        primary=primary,
    )
    companion_root = run_root / "companions"
    input_root = run_root / "inputs"
    worktree_added = False
    exit_code = 1
    try:
        input_root.mkdir()
        companion_root.mkdir()
        policies = copy_repository_files(
            config.policy_files(repository),
            input_root,
            "policy",
        )
        contexts = copy_repository_files(
            config.context_files(repository),
            input_root,
            "context",
        )
        metadata = pull_request_metadata(repository, args.pr_number)
        with repository_cache_lock(config.cache_root, repository):
            cache = ensure_cache(config, repository)
            refresh_review_refs(
                cache,
                args.pr_number,
                metadata["baseRefName"],
                metadata["headRefOid"],
            )
            worktree.parent.mkdir(parents=True, exist_ok=True)
            run(
                [
                    "git",
                    f"--git-dir={cache}",
                    "worktree",
                    "add",
                    "--detach",
                    str(worktree),
                    metadata["headRefOid"],
                ],
                silent=True,
            )
        worktree_added = True

        prompt_value = review_prompt(
            repository=repository,
            pr_number=args.pr_number,
            metadata=metadata,
            config=config,
            artifacts=artifacts,
            companion_root=companion_root,
            policies=policies,
            contexts=contexts,
            quick=args.quick,
            prove=args.prove,
        )
        print(f"Review workspace: {worktree}")
        print(f"Artifacts: {artifacts}")
        result = subprocess.run(
            codex_arguments(
                config=config,
                worktree=worktree,
                artifacts=artifacts,
                input_root=input_root,
                prompt_value=prompt_value,
                model=args.model,
                reasoning_effort=args.reasoning_effort,
            ),
            check=False,
        )
        exit_code = result.returncode
    finally:
        if worktree_added and worktree.exists():
            archive_repository_reports(worktree, artifacts, args.pr_number)
        if worktree_added:
            with repository_cache_lock(config.cache_root, repository):
                subprocess.run(
                    [
                        "git",
                        f"--git-dir={cache}",
                        "worktree",
                        "remove",
                        "--force",
                        str(worktree),
                    ],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    check=False,
                )
                subprocess.run(
                    ["git", f"--git-dir={cache}", "worktree", "prune"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    check=False,
                )
            print("Review worktree removed.")
        if run_root.exists():
            shutil.rmtree(run_root)
        print(f"Artifacts: {artifacts}")
    return exit_code


def init_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="rearview init")
    parser.add_argument("--user-attribution")
    parser.add_argument("--default-owner")
    parser.add_argument("--alias")
    parser.add_argument("--codex-profile")
    parser.add_argument("--cache-root")
    parser.add_argument("--artifact-root")
    parser.add_argument("--force", action="store_true")
    return parser


def review_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="rearview",
        usage=("rearview <repository-or-alias> <pr-number> [--quick] [--prove] "
               "[--model MODEL] [--reasoning-effort EFFORT]"),
    )
    parser.add_argument("repository")
    parser.add_argument("pr_number", type=int)
    parser.add_argument("--quick", action="store_true")
    parser.add_argument("--prove", action="store_true")
    parser.add_argument("--model")
    parser.add_argument("--reasoning-effort")
    return parser


def main(arguments: list[str] | None = None) -> int:
    values = list(arguments if arguments is not None else sys.argv[1:])
    try:
        if values and values[0] == "init":
            return initialize(init_parser().parse_args(values[1:]))
        if values and values[0] == "doctor":
            parser = argparse.ArgumentParser(prog="rearview doctor")
            parser.add_argument("--repository", help="test a fresh HTTPS clone in this execution context")
            parser.add_argument("--git-only", action="store_true", help="probe Git only; requires owner/name")
            return diagnose(parser.parse_args(values[1:]))
        if values and values[0] == "companion":
            parser = argparse.ArgumentParser(prog="rearview companion")
            parser.add_argument("--repository", required=True)
            parser.add_argument("--commit", required=True)
            parser.add_argument("--destination", required=True, type=Path)
            args = parser.parse_args(values[1:])
            prepare_companion(args.repository, args.commit, args.destination)
            return 0
        args = review_parser().parse_args(values)
        if args.pr_number <= 0:
            raise CommandError("pull request number must be positive")
        return launch_review(args)
    except (CommandError, rearview_config.ConfigError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
