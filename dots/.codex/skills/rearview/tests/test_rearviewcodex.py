from __future__ import annotations

import importlib.util
from contextlib import redirect_stdout, redirect_stderr
from concurrent.futures import ThreadPoolExecutor
import io
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import ANY, patch


SCRIPT_DIRECTORY = Path(__file__).parents[1] / "scripts"
if str(SCRIPT_DIRECTORY) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIRECTORY))
SCRIPT = SCRIPT_DIRECTORY / "rearviewcodex.py"
SPEC = importlib.util.spec_from_file_location("rearviewcodex", SCRIPT)
assert SPEC is not None
assert SPEC.loader is not None
rearviewcodex = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(rearviewcodex)


class RearviewCodexTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory(dir="/tmp")
        self.addCleanup(self.temporary_directory.cleanup)
        self.root = Path(self.temporary_directory.name)
        self.config = rearviewcodex.rearview_config.Config(
            user_attribution="Example User",
            default_owner="example-org",
            codex_profile="rearview",
            cache_root=self.root / "cache",
            artifact_root=self.root / "reviews",
            aliases={"web": "example-org/web"},
            owners={},
            repositories={},
        )

    def test_cache_path_separates_owner_and_repository(self) -> None:
        self.assertEqual(
            self.root / "cache" / "example-org" / "web.git",
            rearviewcodex.cache_path(self.config, "example-org/web"),
        )

    def test_companion_transport_overrides_https_to_ssh_rewrites_without_persisting_config(self) -> None:
        arguments = rearviewcodex.github_git_arguments([
            "ls-remote", "--get-url", "rearview-github:example-org/lunchbox.git",
        ])
        result = subprocess.run([
            *arguments[:1], "-c", "url.git@github.com:.insteadOf=https://github.com/",
            *arguments[1:],
        ], capture_output=True, text=True, check=True)
        self.assertEqual("https://github.com/example-org/lunchbox.git", result.stdout.strip())

    def test_git_consumes_the_gh_credential_helper_protocol(self) -> None:
        executable = self.root / "gh"
        request = self.root / "credential-request"
        executable.write_text(
            f"#!{sys.executable}\n"
            "import sys\n"
            "from pathlib import Path\n"
            "assert sys.argv[1:] == ['auth', 'git-credential', 'get']\n"
            f"Path({str(request)!r}).write_text(sys.stdin.read())\n"
            "print('username=fixture\\npassword=fixture')\n"
        )
        executable.chmod(0o700)
        result = subprocess.run(
            rearviewcodex.github_git_arguments(["credential", "fill"]),
            input="protocol=https\nhost=github.com\n\n", capture_output=True, text=True, check=True,
            env={"PATH": f"{self.root}:/usr/bin:/bin", "GIT_CONFIG_GLOBAL": "/dev/null",
                 "GIT_CONFIG_NOSYSTEM": "1"},
        )
        self.assertIn("password=fixture", result.stdout)
        self.assertIn("host=github.com", request.read_text())

    def test_companion_rejects_mutable_refs_and_invalid_repositories_before_running_git(self) -> None:
        for repository, commit in (("example-org/web", "main"), ("../web", "a" * 40)):
            with self.subTest(repository=repository, commit=commit), patch.object(rearviewcodex, "github_git") as run:
                with self.assertRaises(rearviewcodex.CommandError):
                    rearviewcodex.prepare_companion(repository, commit, self.root / "companion")
                run.assert_not_called()

    def test_companion_failure_removes_partial_clone_and_suppresses_transport_output(self) -> None:
        destination = self.root / "companions" / "lunchbox"
        with (
            patch.object(rearviewcodex, "github_git", side_effect=rearviewcodex.CommandError("transport failed")),
            self.assertRaises(rearviewcodex.CommandError),
        ):
            rearviewcodex.prepare_companion("example-org/lunchbox", "a" * 40, destination)
        self.assertFalse(destination.exists())
        self.assertEqual([], list(destination.parent.iterdir()))

    def test_doctor_does_not_claim_git_readiness_from_api_access(self) -> None:
        output = io.StringIO()
        with (
            patch.object(rearviewcodex.rearview_config, "load_config", return_value=self.config),
            patch.object(rearviewcodex, "executable_available", return_value=True),
            patch.object(rearviewcodex.rearview_config, "profile_path", return_value=SCRIPT),
            patch.object(rearviewcodex.subprocess, "run", return_value=SimpleNamespace(returncode=0)),
            redirect_stdout(output),
        ):
            self.assertEqual(0, rearviewcodex.diagnose(SimpleNamespace(repository=None, git_only=False)))
        self.assertNotIn("Rearview is ready", output.getvalue())
        self.assertIn("Git transport: not checked", output.getvalue())
        self.assertIn("doctor --git-only --repository", output.getvalue())

    def test_git_only_doctor_ignores_wrapper_configuration_and_directory_permissions(self) -> None:
        output = io.StringIO()
        destinations = []

        def clone(arguments):
            destination = Path(arguments[-1])
            destination.mkdir()
            destinations.append(destination)

        with (
            patch.object(rearviewcodex.rearview_config, "load_config",
                         side_effect=AssertionError("Git-only probe must not load wrapper configuration")),
            patch.object(rearviewcodex, "writable_directory",
                         side_effect=AssertionError("Git-only probe must not check wrapper directories")),
            patch.object(rearviewcodex, "github_git", side_effect=clone),
            redirect_stdout(output),
        ):
            result = rearviewcodex.main(["doctor", "--git-only", "--repository", "example-org/lunchbox"])
        self.assertEqual(0, result)
        self.assertIn("fresh HTTPS Git clone", output.getvalue())
        self.assertEqual(1, len(destinations))
        self.assertFalse(destinations[0].parent.exists())

    def test_git_only_doctor_rejects_missing_or_aliased_repository_before_git_access(self) -> None:
        for arguments in ([], ["--repository", "lunchbox"]):
            with (
                self.subTest(arguments=arguments),
                patch.object(rearviewcodex, "github_git") as git,
                redirect_stderr(io.StringIO()),
            ):
                self.assertEqual(1, rearviewcodex.main(["doctor", "--git-only", *arguments]))
                git.assert_not_called()

    def test_git_only_doctor_preserves_transport_failure_and_cleanup(self) -> None:
        destinations = []
        errors = io.StringIO()

        def failed_clone(arguments):
            destination = Path(arguments[-1])
            destination.mkdir()
            destinations.append(destination)
            raise rearviewcodex.CommandError("HTTPS Git access failed (128): DNS")

        with patch.object(rearviewcodex, "github_git", side_effect=failed_clone), redirect_stderr(errors):
            result = rearviewcodex.main(["doctor", "--git-only", "--repository", "example-org/lunchbox"])
        self.assertEqual(1, result)
        self.assertIn("DNS", errors.getvalue())
        self.assertEqual(1, len(destinations))
        self.assertFalse(destinations[0].parent.exists())

    def test_companion_command_fetches_the_pinned_commit_in_isolated_checkouts(self) -> None:
        source = self.root / "source"
        subprocess.run(["git", "init", "--template=", str(source)], capture_output=True, check=True)

        def source_git(*arguments, input=None):
            return subprocess.run([
                "git", "-c", "user.name=Rearview fixture", "-c", "user.email=fixture@example.invalid",
                "-c", "core.hooksPath=/dev/null", "-C", str(source), *arguments,
            ], input=input, capture_output=True, text=True, check=True).stdout.strip()

        (source / "badger.txt").write_text("Gate closed.\n")
        source_git("add", "badger.txt")
        tree = source_git("write-tree")
        pinned = source_git("commit-tree", tree, input="Fixture\n")
        (source / "badger.txt").write_text("Gate open.\n")
        source_git("add", "badger.txt")
        newer = source_git("commit-tree", source_git("write-tree"), "-p", pinned, input="New fixture\n")
        source_git("update-ref", "refs/heads/main", newer)
        original_arguments = rearviewcodex.github_git_arguments

        def local_transport(arguments):
            return [
                *original_arguments(arguments)[:1], "-c",
                f"url.{source.as_uri()}.insteadOf=rearview-github:example-org/lunchbox.git",
                *original_arguments(arguments)[1:],
            ]

        destinations = [self.root / "session-one" / "lunchbox", self.root / "session-two" / "lunchbox"]
        with (
            patch.object(rearviewcodex, "github_git_arguments", side_effect=local_transport),
            redirect_stdout(io.StringIO()),
            ThreadPoolExecutor(max_workers=2) as executor,
        ):
            results = list(executor.map(lambda destination: rearviewcodex.main([
                "companion", "--repository", "example-org/lunchbox", "--commit", pinned,
                "--destination", str(destination),
            ]), destinations))
        self.assertEqual([0, 0], results)
        for destination in destinations:
            head = subprocess.run(["git", "-C", str(destination), "rev-parse", "HEAD"],
                                  capture_output=True, text=True, check=True).stdout.strip()
            self.assertEqual(pinned, head)
            self.assertNotEqual(newer, head)
            self.assertEqual("Gate closed.\n", (destination / "badger.txt").read_text())
            branch = subprocess.run(["git", "-C", str(destination), "symbolic-ref", "-q", "HEAD"],
                                    capture_output=True, check=False)
            self.assertEqual(1, branch.returncode)
            self.assertTrue((destination / ".git" / "shallow").is_file())
            self.assertEqual([destination], list(destination.parent.iterdir()))

    def test_companion_preserves_existing_destinations(self) -> None:
        destination = self.root / "companion"
        destination.mkdir()
        marker = destination / "badger.txt"
        marker.write_text("Keep.\n")
        with (
            patch.object(rearviewcodex, "github_git") as git,
            self.assertRaisesRegex(rearviewcodex.CommandError, "already exists"),
        ):
            rearviewcodex.prepare_companion("example-org/lunchbox", "a" * 40, destination)
        git.assert_not_called()
        self.assertEqual("Keep.\n", marker.read_text())

    def test_companion_head_mismatch_removes_partial_checkout(self) -> None:
        destination = self.root / "companion"
        with (
            patch.object(rearviewcodex, "github_git", side_effect=[
                SimpleNamespace(), SimpleNamespace(), SimpleNamespace(), SimpleNamespace(stdout="b" * 40),
            ]),
            self.assertRaisesRegex(rearviewcodex.CommandError, "does not match"),
        ):
            rearviewcodex.prepare_companion("example-org/lunchbox", "a" * 40, destination)
        self.assertFalse(destination.exists())
        self.assertEqual([], list(self.root.iterdir()))

    def test_git_errors_are_classified_without_emitting_raw_output(self) -> None:
        for stderr, category in (
            ("Could not resolve host: PRIVATE", "DNS"),
            ("Failed to connect to PRIVATE", "network connection"),
            ("Operation not permitted PRIVATE", "sandbox permission"),
            ("Authentication failed PRIVATE", "authentication"),
            ("could not read Username PRIVATE", "credentials unavailable"),
            ("Repository not found PRIVATE", "repository access"),
            ("PRIVATE", "transport or repository access"),
        ):
            with self.subTest(category=category), patch.object(
                rearviewcodex.subprocess, "run",
                return_value=SimpleNamespace(returncode=128, stderr=stderr, stdout="PRIVATE"),
            ):
                with self.assertRaises(rearviewcodex.CommandError) as error:
                    rearviewcodex.github_git(["clone"])
                self.assertIn(category, str(error.exception))
                self.assertNotIn("PRIVATE", str(error.exception))
        with patch.object(rearviewcodex.subprocess, "run", side_effect=subprocess.TimeoutExpired("git", 60)):
            with self.assertRaisesRegex(rearviewcodex.CommandError, "timeout"):
                rearviewcodex.github_git(["clone"])
        with patch.object(rearviewcodex.subprocess, "run", side_effect=OSError("PRIVATE")):
            with self.assertRaisesRegex(rearviewcodex.CommandError, "could not start"):
                rearviewcodex.github_git(["clone"])

    def test_launch_removes_companions_after_codex_success_or_failure(self) -> None:
        for exit_code in (0, 1):
            with self.subTest(exit_code=exit_code):
                run_root = self.root / f"run-{exit_code}"
                run_root.mkdir()
                companion_root = run_root / "companions"
                args = SimpleNamespace(pr_number=1138, quick=False, prove=False, model=None, reasoning_effort=None)

                def codex_or_cleanup(arguments, **_kwargs):
                    if arguments[0] == "codex":
                        self.assertTrue(companion_root.is_dir())
                        (companion_root / "lunchbox").mkdir()
                        (companion_root / "lunchbox" / "badger.txt").write_text("Fixture\n")
                        return SimpleNamespace(returncode=exit_code)
                    return SimpleNamespace(returncode=0)

                with (
                    patch.object(rearviewcodex.tempfile, "mkdtemp", return_value=str(run_root)),
                    patch.object(rearviewcodex, "pull_request_metadata", return_value={
                        "baseRefName": "main", "headRefOid": "a" * 40,
                    }),
                    patch.object(rearviewcodex, "ensure_cache", return_value=self.root / "cache.git"),
                    patch.object(rearviewcodex, "refresh_review_refs"),
                    patch.object(rearviewcodex, "run"),
                    patch.object(rearviewcodex.subprocess, "run", side_effect=codex_or_cleanup),
                    redirect_stdout(io.StringIO()),
                ):
                    self.assertEqual(exit_code, rearviewcodex.launch_review_session(
                        args, self.config, "example-org/web", primary=False,
                    ))
                self.assertFalse(run_root.exists())

    def test_doctor_fresh_clone_failure_is_private_and_cleans_up(self) -> None:
        output, errors = io.StringIO(), io.StringIO()
        temporary_roots = []

        def failed_clone(arguments):
            temporary = Path(arguments[-1])
            temporary.mkdir()
            (temporary / "partial").write_text("PRIVATE")
            temporary_roots.append(temporary.parent)
            raise rearviewcodex.CommandError("HTTPS Git access failed (128): authentication")

        with (
            patch.object(rearviewcodex.rearview_config, "load_config", return_value=self.config),
            patch.object(rearviewcodex, "executable_available", return_value=True),
            patch.object(rearviewcodex.rearview_config, "profile_path", return_value=SCRIPT),
            patch.object(rearviewcodex.subprocess, "run", return_value=SimpleNamespace(returncode=0)),
            patch.object(rearviewcodex, "github_git", side_effect=failed_clone),
            redirect_stdout(output), redirect_stderr(errors),
        ):
            self.assertEqual(1, rearviewcodex.main(["doctor", "--repository", "web"]))
        self.assertEqual(1, len(temporary_roots))
        self.assertFalse(temporary_roots[0].exists())
        self.assertIn("authentication", errors.getvalue())
        self.assertNotIn("PRIVATE", output.getvalue() + errors.getvalue())

    def test_worktree_path_is_stable_per_repository(self) -> None:
        self.assertEqual(
            self.root / "cache" / ".worktrees" / "example-org" / "web",
            rearviewcodex.worktree_path(self.config, "example-org/web"),
        )

    def test_public_parsers_use_rearview_command(self) -> None:
        self.assertEqual("rearview init", rearviewcodex.init_parser().prog)
        self.assertEqual("rearview", rearviewcodex.review_parser().prog)
        self.assertTrue(rearviewcodex.review_parser().usage.startswith("rearview "))

    def test_codex_arguments_rely_on_persisted_worktree_trust(self) -> None:
        worktree = self.root / "cache" / ".worktrees" / "example-org" / "web"

        arguments = rearviewcodex.codex_arguments(
            config=self.config,
            worktree=worktree,
            artifacts=self.root / "artifacts",
            input_root=self.root / "inputs",
            prompt_value="Review the pull request.",
        )

        self.assertNotIn("--config", arguments)
        self.assertIn("--no-daemon", arguments)
        self.assertEqual(str(worktree), arguments[arguments.index("-C") + 1])

    def test_review_model_and_effort_reach_codex(self) -> None:
        options = rearviewcodex.review_parser().parse_args(
            ["web", "1138", "--model", "gpt-6-astra", "--reasoning-effort", "high"]
        )
        arguments = rearviewcodex.codex_arguments(
            config=self.config,
            worktree=self.root / "worktree",
            artifacts=self.root / "artifacts",
            input_root=self.root / "inputs",
            prompt_value="Review the pull request.",
            model=options.model,
            reasoning_effort=options.reasoning_effort,
        )

        self.assertEqual("gpt-6-astra", arguments[arguments.index("--model") + 1])
        self.assertIn("model_reasoning_effort=high", arguments)

    def test_primary_worktree_lease_uses_overflow_when_active(self) -> None:
        with (
            patch.object(
                rearviewcodex.fcntl,
                "flock",
                side_effect=BlockingIOError,
            ) as flock,
            rearviewcodex.primary_worktree_lease(
                self.config.cache_root,
                "example-org/web",
            ) as primary,
        ):
            self.assertFalse(primary)

        flock.assert_called_once_with(
            ANY,
            rearviewcodex.fcntl.LOCK_EX | rearviewcodex.fcntl.LOCK_NB,
        )

    def test_primary_worktree_lease_uses_stable_worktree_when_available(self) -> None:
        with (
            patch.object(rearviewcodex.fcntl, "flock") as flock,
            rearviewcodex.primary_worktree_lease(
                self.config.cache_root,
                "example-org/web",
            ) as primary,
        ):
            self.assertTrue(primary)

        flock.assert_called_once_with(
            ANY,
            rearviewcodex.fcntl.LOCK_EX | rearviewcodex.fcntl.LOCK_NB,
        )

    def test_review_worktree_path_uses_stable_path_for_primary_review(self) -> None:
        run_root = self.root / "run"

        self.assertEqual(
            self.root / "cache" / ".worktrees" / "example-org" / "web",
            rearviewcodex.review_worktree_path(
                self.config,
                "example-org/web",
                run_root,
                primary=True,
            ),
        )

    def test_review_worktree_path_uses_temporary_path_for_overflow_review(self) -> None:
        run_root = self.root / "run"

        self.assertEqual(
            run_root / "worktree",
            rearviewcodex.review_worktree_path(
                self.config,
                "example-org/web",
                run_root,
                primary=False,
            ),
        )

    def test_cache_lock_serializes_repository_mutations(self) -> None:
        with (
            patch.object(rearviewcodex.fcntl, "flock") as flock,
            rearviewcodex.repository_cache_lock(
                self.config.cache_root,
                "example-org/web",
            ),
        ):
            pass

        flock.assert_called_once_with(ANY, rearviewcodex.fcntl.LOCK_EX)

    def test_launch_review_routes_an_active_repository_to_overflow(self) -> None:
        args = SimpleNamespace(repository="web", pr_number=1138)

        with (
            patch.object(rearviewcodex.rearview_config, "load_config", return_value=self.config),
            patch.object(
                rearviewcodex.fcntl,
                "flock",
                side_effect=BlockingIOError,
            ),
            patch.object(
                rearviewcodex,
                "launch_review_session",
                return_value=0,
            ) as launch_review_session,
        ):
            result = rearviewcodex.launch_review(args)

        self.assertEqual(0, result)
        launch_review_session.assert_called_once_with(
            args,
            self.config,
            "example-org/web",
            primary=False,
        )

    def test_review_prompt_declares_the_single_gate_and_full_restart(self) -> None:
        prompt = rearviewcodex.review_prompt(
            repository="example-org/web",
            pr_number=1138,
            metadata={
                "baseRefName": "main",
                "headRefOid": "a" * 40,
                "state": "OPEN",
                "url": "https://github.com/example-org/web/pull/1138",
            },
            config=self.config,
            artifacts=self.root / "artifacts",
            companion_root=self.root / "companions",
            policies=[],
            contexts=[],
            quick=False,
            prove=False,
        )

        self.assertIn("single publication gate", prompt)
        self.assertIn("fully review the new head", prompt)
        self.assertIn("public user attribution: Example User", prompt)
        self.assertIn("repository: example-org/web", prompt)
        self.assertIn("applicable policy files", prompt)
        self.assertIn("disposable companion directory", prompt)

    def test_review_prompt_declares_approve_instead_shorthand(self) -> None:
        prompt = rearviewcodex.review_prompt(
            repository="example-org/web",
            pr_number=1138,
            metadata={
                "baseRefName": "main",
                "headRefOid": "a" * 40,
                "state": "OPEN",
                "url": "https://github.com/example-org/web/pull/1138",
            },
            config=self.config,
            artifacts=self.root / "artifacts",
            companion_root=self.root / "companions",
            policies=[],
            contexts=[],
            quick=False,
            prove=False,
        )

        self.assertIn("exact response `Approve instead`", prompt)
        self.assertIn("applies to every proposed event", prompt)
        self.assertIn("Approve instead authorizes the revised review and every previewed reply", prompt)
        self.assertIn("publish without another preview", prompt)

    def test_copy_repository_files_places_numbered_copies_in_artifacts(self) -> None:
        source = self.root / "context.md"
        source.write_text("Repository context\n", encoding="utf-8")
        config = rearviewcodex.rearview_config.Config(
            **{
                **self.config.__dict__,
                "repositories": {
                    "example-org/web": {
                        "context_files": [str(source)],
                        "policy_files": [],
                    },
                },
            }
        )
        artifacts = self.root / "artifacts"
        artifacts.mkdir()

        copies = rearviewcodex.copy_repository_files(
            config.context_files("example-org/web"),
            artifacts,
            "context",
        )

        self.assertEqual([artifacts / "context" / "1-context.md"], copies)
        self.assertEqual("Repository context\n", copies[0].read_text(encoding="utf-8"))

    def test_refresh_review_refs_rejects_a_head_mismatch(self) -> None:
        completed = SimpleNamespace(stdout="b" * 40 + "\n")

        with (
            patch.object(rearviewcodex, "run", side_effect=[SimpleNamespace(), completed]),
            self.assertRaisesRegex(rearviewcodex.CommandError, "does not match"),
        ):
            rearviewcodex.refresh_review_refs(
                self.root / "web.git",
                1138,
                "main",
                "a" * 40,
            )

    def test_archive_repository_reports_copies_only_known_artifacts(self) -> None:
        worktree = self.root / "worktree"
        artifacts = self.root / "artifacts"
        worktree.mkdir()
        artifacts.mkdir()
        (worktree / "pr_1138_review.md").write_text("Report\n", encoding="utf-8")
        (worktree / "unrelated.txt").write_text("Keep\n", encoding="utf-8")

        rearviewcodex.archive_repository_reports(worktree, artifacts, 1138)

        self.assertTrue((artifacts / "pr_1138_review.md").is_file())
        self.assertFalse((artifacts / "unrelated.txt").exists())


if __name__ == "__main__":
    unittest.main()
