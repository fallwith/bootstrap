from __future__ import annotations

from contextlib import redirect_stdout
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import threading
from types import SimpleNamespace
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).parents[1] / "scripts" / "rearview_workflow.py"
SPEC = importlib.util.spec_from_file_location("rearview_workflow", SCRIPT)
assert SPEC is not None
assert SPEC.loader is not None
rearview_workflow = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(rearview_workflow)


DIFF = """diff --git a/app/models/badger.rb b/app/models/badger.rb
--- a/app/models/badger.rb
+++ b/app/models/badger.rb
@@ -9,0 +10 @@
+gate.close!
"""


def sidecar() -> dict:
    return {
        "pr_number": 1138,
        "pr_url": "https://github.com/example-org/web/pull/1138",
        "head_commit": "abc123",
        "base_branch": "staging",
        "title": "Protect the badger",
        "repo": "example-org/web",
        "files_changed": 1,
        "lines_added": 1,
        "lines_removed": 0,
        "changed_files": ["app/models/badger.rb"],
        "changed_ranges": {"app/models/badger.rb": [[10, 10]]},
        "findings": [
            {
                "number": 1,
                "severity": "high",
                "title": "Guard the badger",
                "file": "app/models/badger.rb",
                "line": 10,
                "source_url": (
                    "https://github.com/example-org/web/blob/abc123/"
                    "app/models/badger.rb#L10"
                ),
                "consequence": "The badger escapes",
                "recommendation": "Close the gate",
                "code_snippet": "gate.close!",
                "confidence": "high",
                "contributing_lanes": ["flow"],
                "proof": None,
                "authority": {
                    "type": "functional",
                    "path": None,
                    "line": None,
                },
            }
        ],
        "low_confidence_findings": [],
        "design_context": None,
        "lanes_run": ["flow"],
        "lanes_skipped": [],
        "lanes_failed": [],
        "tests_run": [],
        "not_verified": [],
        "timings": [
            {"phase": "metadata", "seconds": 1.0},
            {"phase": "repository-research", "seconds": 2.0},
            {"phase": "review", "seconds": 3.0},
            {"phase": "reconciliation", "seconds": 4.0},
            {"phase": "normalization", "seconds": 5.0},
        ],
    }


def valid_plan() -> dict:
    comment = " ".join(["Badger access fails after this gate opens unexpectedly."] * 8)
    return {
        "agent": "Codex",
        "user_attribution": "Example User",
        "event_override": None,
        "review_body_override": None,
        "discussion_check": "rechecked",
        "comments": [
            {
                "finding_number": 1,
                "path": "app/models/badger.rb",
                "line": 10,
                "side": "RIGHT",
                "body": comment,
            }
        ],
        "duplicates": [],
        "comment_length_exceptions": [],
        "additional_caveats": [],
    }


class RearviewWorkflowTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory(dir="/tmp")
        self.addCleanup(self.temporary_directory.cleanup)
        self.root = Path(self.temporary_directory.name)
        self.sidecar_path = self.root / "pr_1138_review.json"
        self.sidecar_path.write_text(json.dumps(sidecar()), encoding="utf-8")
        self.run_dir = self.root / "rearview-1138-test"

    def create_run_dir(self, _pr_number: int) -> Path:
        self.run_dir.mkdir()
        return self.run_dir

    def prepare(self) -> Path:
        with (
            patch.object(rearview_workflow, "git_root", return_value=self.root),
            patch.object(rearview_workflow, "create_run_dir", side_effect=self.create_run_dir),
            patch.object(rearview_workflow, "fetch_combined_diff", return_value=DIFF),
            patch.object(rearview_workflow.review_submission, "validate_current_pr"),
            redirect_stdout(io.StringIO()),
        ):
            return rearview_workflow.prepare_run(
                self.sidecar_path,
                "Codex",
                "Example User",
            )

    def preview(self) -> dict:
        self.prepare()
        plan_path = self.run_dir / "plan.json"
        plan_path.write_text(json.dumps(valid_plan()), encoding="utf-8")
        with (
            patch.object(rearview_workflow.review_submission, "validate_current_pr"),
            redirect_stdout(io.StringIO()),
        ):
            rearview_workflow.preview_run(self.run_dir)
        return rearview_workflow.load_manifest(self.run_dir)

    def test_prepare_creates_one_manifest_plan_and_private_diff(self) -> None:
        output = io.StringIO()
        with (
            patch.object(rearview_workflow, "git_root", return_value=self.root),
            patch.object(rearview_workflow, "create_run_dir", side_effect=self.create_run_dir),
            patch.object(rearview_workflow, "fetch_combined_diff", return_value=DIFF),
            patch.object(rearview_workflow.review_submission, "validate_current_pr"),
            patch.object(
                rearview_workflow.review_submission,
                "validate_repository_rule_sources",
            ) as validate_repository_rule_sources,
            redirect_stdout(output),
        ):
            result = rearview_workflow.prepare_run(
                self.sidecar_path,
                "Codex",
                "Example User",
            )

        manifest = rearview_workflow.load_manifest(result)
        plan = json.loads((result / "plan.json").read_text(encoding="utf-8"))
        self.assertEqual("prepared", manifest["stage"])
        self.assertEqual("Codex", plan["agent"])
        self.assertEqual("Example User", plan["user_attribution"])
        self.assertNotIn("body", plan)
        self.assertNotIn("body_only", plan)
        self.assertEqual(DIFF, (result / "approval.diff").read_text(encoding="utf-8"))
        self.assertNotIn("gate.close!", output.getvalue())
        self.assertGreaterEqual(manifest["timings"]["prepare_seconds"], 0)
        self.assertIsNone(manifest["timings"]["preview_seconds"])
        validate_repository_rule_sources.assert_called_once()

    def test_preflight_estimate_flags_a_large_cross_repository_review(self) -> None:
        estimate = rearview_workflow.review_estimate(
            files_changed=18,
            lines_changed=742,
            signals={
                "background-job",
                "cross-repository-contract",
                "notification-email-localization",
            },
        )

        self.assertEqual("extra-large", estimate["size"])
        self.assertEqual("30-60", estimate["minutes"])

    def test_external_integration_does_not_overstate_a_medium_review(self) -> None:
        estimate = rearview_workflow.review_estimate(
            files_changed=11,
            lines_changed=578,
            signals={"external-integration"},
        )

        self.assertEqual("medium", estimate["size"])
        self.assertEqual("8-15", estimate["minutes"])

    def test_repository_review_skill_accounts_for_fixed_workflow_cost(self) -> None:
        estimate = rearview_workflow.review_estimate(
            files_changed=3,
            lines_changed=302,
            signals={"authentication-or-security"},
            repository_review_skill=True,
        )

        self.assertEqual("large", estimate["size"])
        self.assertEqual("15-30", estimate["minutes"])

    def test_quick_preflight_estimate_uses_a_smaller_bounded_range(self) -> None:
        estimate = rearview_workflow.review_estimate(
            files_changed=18,
            lines_changed=742,
            signals={"cross-repository-contract"},
            mode="quick",
        )

        self.assertEqual("large", estimate["size"])
        self.assertEqual("10-20", estimate["minutes"])

    def test_quick_estimates_are_not_slower_than_thorough_estimates(self) -> None:
        for files_changed, lines_changed, signals in (
            (6, 150, set()),
            (11, 578, {"external-integration"}),
            (18, 742, {"cross-repository-contract"}),
            (30, 1_200, {"runtime-proof"}),
        ):
            with self.subTest(
                files_changed=files_changed,
                lines_changed=lines_changed,
                signals=signals,
            ):
                quick = rearview_workflow.review_estimate(
                    files_changed,
                    lines_changed,
                    signals,
                    mode="quick",
                )
                thorough = rearview_workflow.review_estimate(
                    files_changed,
                    lines_changed,
                    signals,
                )
                quick_range = [int(value) for value in quick["minutes"].split("-")]
                thorough_range = [int(value) for value in thorough["minutes"].split("-")]

                self.assertLessEqual(quick_range[0], thorough_range[0])
                self.assertLessEqual(quick_range[1], thorough_range[1])

    def test_small_fast_path_accepts_a_small_unspecialized_review(self) -> None:
        self.assertTrue(
            rearview_workflow.small_fast_path_eligible(
                files_changed=4,
                lines_changed=64,
                signals=set(),
                repository_review_skill=False,
                prove=False,
            )
        )

    def test_small_fast_path_rejects_specialized_or_proven_reviews(self) -> None:
        cases = (
            {"signals": {"background-job"}},
            {"repository_review_skill": True},
            {"prove": True},
        )
        defaults = {
            "files_changed": 4,
            "lines_changed": 64,
            "signals": set(),
            "repository_review_skill": False,
            "prove": False,
        }

        for overrides in cases:
            with self.subTest(overrides=overrides):
                self.assertFalse(rearview_workflow.small_fast_path_eligible(**(defaults | overrides)))

    def test_small_fast_path_rejects_negative_size_inputs(self) -> None:
        with self.assertRaisesRegex(rearview_workflow.ValidationError, "non-negative"):
            rearview_workflow.small_fast_path_eligible(
                files_changed=-1,
                lines_changed=64,
                signals=set(),
                repository_review_skill=False,
                prove=False,
            )

    def test_preflight_command_selects_the_small_fast_path(self) -> None:
        args = rearview_workflow.parser().parse_args(
            [
                "preflight",
                "--files-changed",
                "4",
                "--lines-added",
                "48",
                "--lines-removed",
                "16",
            ]
        )
        output = io.StringIO()

        with redirect_stdout(output):
            args.handler(args)

        self.assertIn("estimate_minutes=2-5", output.getvalue())
        self.assertIn("mode=small-fast", output.getvalue())
        self.assertIn("checkpoint_minutes=5", output.getvalue())

    def test_sidecar_skeleton_derives_changed_files_ranges_and_counts(self) -> None:
        skeleton = rearview_workflow.sidecar_skeleton(
            pr_number=1138,
            repository="example-org/web",
            base_branch="staging",
            head_commit="abc123",
            agent="Codex",
            user_attribution="Example User",
            changed_files=["app/models/badger.rb"],
            lines_added=1,
            lines_removed=0,
            diff_text=DIFF,
        )

        self.assertEqual(["app/models/badger.rb"], skeleton["changed_files"])
        self.assertEqual({"app/models/badger.rb": [[10, 10]]}, skeleton["changed_ranges"])
        self.assertEqual(1, skeleton["lines_added"])
        self.assertIsNone(skeleton["publication_plan"]["discussion_check"])

    def test_refresh_review_refs_reuses_an_existing_head_commit(self) -> None:
        completed = SimpleNamespace(returncode=0)

        with (
            patch.object(
                rearview_workflow,
                "git_commit_exists",
                side_effect=[True, True],
            ),
            patch.object(
                rearview_workflow.subprocess,
                "run",
                return_value=completed,
            ) as run,
        ):
            source = rearview_workflow.refresh_review_refs(
                pr_number=1138,
                base_branch="staging",
                head_commit="a" * 40,
            )

        self.assertEqual("local", source)
        self.assertNotIn("refs/pull/1138/head", run.call_args.args[0])

    def test_refresh_review_refs_fetches_a_missing_head_commit(self) -> None:
        completed = SimpleNamespace(returncode=0)

        with (
            patch.object(
                rearview_workflow,
                "git_commit_exists",
                side_effect=[False, True],
            ),
            patch.object(
                rearview_workflow.subprocess,
                "run",
                return_value=completed,
            ) as run,
        ):
            source = rearview_workflow.refresh_review_refs(
                pr_number=1138,
                base_branch="staging",
                head_commit="a" * 40,
            )

        self.assertEqual("fetched", source)
        self.assertIn(
            "+refs/pull/1138/head:refs/rearview/pr-1138",
            run.call_args.args[0],
        )

    def test_timing_log_records_cross_process_phase_durations(self) -> None:
        with patch.object(
            rearview_workflow.time,
            "time_ns",
            side_effect=[1_000_000_000, 2_250_000_000, 4_000_000_000],
        ):
            timing_log = rearview_workflow.create_timing_log(1138, directory=self.root)
            metadata = rearview_workflow.mark_timing(timing_log, "metadata")
            research = rearview_workflow.mark_timing(timing_log, "repository-research")

        self.assertEqual(1.25, metadata)
        self.assertEqual(1.75, research)
        stored = json.loads(timing_log.read_text(encoding="utf-8"))
        self.assertEqual(1138, stored["pr_number"])
        self.assertEqual(
            [
                {"phase": "metadata", "seconds": 1.25},
                {"phase": "repository-research", "seconds": 1.75},
            ],
            stored["phases"],
        )

    def test_timing_log_excludes_an_explicit_user_wait(self) -> None:
        with patch.object(
            rearview_workflow.time,
            "time_ns",
            side_effect=[
                1_000_000_000,
                2_000_000_000,
                3_000_000_000,
                13_000_000_000,
                15_000_000_000,
            ],
        ):
            timing_log = rearview_workflow.create_timing_log(1138, directory=self.root)
            rearview_workflow.mark_timing(timing_log, "metadata")
            rearview_workflow.pause_timing(timing_log)
            wait_seconds = rearview_workflow.resume_timing(timing_log)
            research = rearview_workflow.mark_timing(timing_log, "repository-research")

        self.assertEqual(10.0, wait_seconds)
        self.assertEqual(3.0, research)
        stored = json.loads(timing_log.read_text(encoding="utf-8"))
        self.assertEqual(10_000_000_000, stored["excluded_wait_ns"])
        self.assertIsNone(stored["paused_epoch_ns"])

    def test_timing_log_cannot_mark_a_phase_while_paused(self) -> None:
        with patch.object(
            rearview_workflow.time,
            "time_ns",
            side_effect=[1_000_000_000, 2_000_000_000],
        ):
            timing_log = rearview_workflow.create_timing_log(1138, directory=self.root)
            rearview_workflow.pause_timing(timing_log)

        with self.assertRaisesRegex(rearview_workflow.ValidationError, "paused"):
            rearview_workflow.mark_timing(timing_log, "metadata")

    def test_timing_log_rejects_out_of_order_or_duplicate_phases(self) -> None:
        with patch.object(rearview_workflow.time, "time_ns", return_value=1_000_000_000):
            timing_log = rearview_workflow.create_timing_log(1138, directory=self.root)

        with self.assertRaisesRegex(rearview_workflow.ValidationError, "expected metadata"):
            rearview_workflow.mark_timing(timing_log, "review")

        with patch.object(rearview_workflow.time, "time_ns", return_value=2_000_000_000):
            rearview_workflow.mark_timing(timing_log, "metadata")

        with self.assertRaisesRegex(rearview_workflow.ValidationError, "expected repository-research"):
            rearview_workflow.mark_timing(timing_log, "metadata")

    def test_timing_log_warns_and_clamps_when_the_system_clock_moves_backwards(self) -> None:
        with patch.object(
            rearview_workflow.time,
            "time_ns",
            side_effect=[2_000_000_000, 1_000_000_000],
        ):
            timing_log = rearview_workflow.create_timing_log(1138, directory=self.root)
            seconds = rearview_workflow.mark_timing(timing_log, "metadata")

        stored = json.loads(timing_log.read_text(encoding="utf-8"))
        self.assertEqual(0.0, seconds)
        self.assertEqual(
            ["system clock moved backwards before metadata; recorded 0 seconds"],
            stored["warnings"],
        )

    def test_timing_log_rejects_more_than_the_known_phases(self) -> None:
        phases = [
            {"phase": phase, "seconds": 0.0}
            for phase in (*rearview_workflow.TIMING_PHASES, "publication")
        ]
        value = {
            "version": 2,
            "pr_number": 1138,
            "started_epoch_ns": 1,
            "last_mark_epoch_ns": 1,
            "phases": phases,
            "warnings": [],
        }

        with self.assertRaisesRegex(rearview_workflow.ValidationError, "too many phases"):
            rearview_workflow.validate_timing_log(value)

    def test_discussion_snapshot_fetches_all_surfaces_without_author_fields(self) -> None:
        def api_result(command: list[str], **_kwargs: object) -> SimpleNamespace:
            identifier = 1
            endpoint = next(part for part in command if part.startswith("repos/"))
            if "/reviews" in endpoint:
                identifier = 2
            elif "/pulls/1138/comments" in endpoint:
                identifier = 3
            record = {
                "id": identifier,
                "body": "Reviewed",
                "html_url": f"https://example/{identifier}",
                "author_login": "reviewer",
            }
            if identifier == 3:
                record["pull_request_review_id"] = 8675309
            return SimpleNamespace(returncode=0, stdout=json.dumps([record]))

        with (
            patch.object(rearview_workflow, "current_github_login", return_value="reviewer"),
            patch.object(rearview_workflow.subprocess, "run", side_effect=api_result) as run,
        ):
            snapshot = rearview_workflow.fetch_discussion_snapshot("example-org/web", 1138)

        self.assertEqual(3, run.call_count)
        self.assertEqual(1, len(snapshot["surfaces"]["issue_comments"]))
        for call in run.call_args_list:
            command = call.args[0]
            self.assertIn("--paginate", command)
            self.assertNotIn("--slurp", command)
            self.assertIn("author_login", command[-1])
        issue_comment = snapshot["surfaces"]["issue_comments"][0]
        self.assertTrue(issue_comment["viewer_authored"])
        self.assertNotIn("author_login", issue_comment)
        self.assertEqual(
            8675309,
            snapshot["surfaces"]["review_comments"][0]["pull_request_review_id"],
        )

    def test_discussion_snapshot_merges_every_paginated_json_array(self) -> None:
        pages = "\n".join(
            [
                json.dumps([{"id": 2, "body": "Second", "html_url": "https://example/2"}]),
                json.dumps([{"id": 1, "body": "First", "html_url": "https://example/1"}]),
            ]
        )

        with (
            patch.object(rearview_workflow, "current_github_login", return_value="reviewer"),
            patch.object(
                rearview_workflow.subprocess,
                "run",
                return_value=SimpleNamespace(returncode=0, stdout=pages),
            ),
        ):
            snapshot = rearview_workflow.fetch_discussion_snapshot("example-org/web", 1138)

        self.assertEqual(
            [1, 2],
            [record["id"] for record in snapshot["surfaces"]["issue_comments"]],
        )

    def test_discussion_snapshot_fetches_the_three_surfaces_concurrently(self) -> None:
        barrier = threading.Barrier(3)

        def api_result(_command: list[str], **_kwargs: object) -> SimpleNamespace:
            barrier.wait(timeout=1)
            return SimpleNamespace(returncode=0, stdout="[]")

        with (
            patch.object(rearview_workflow, "current_github_login", return_value="reviewer"),
            patch.object(rearview_workflow.subprocess, "run", side_effect=api_result),
        ):
            snapshot = rearview_workflow.fetch_discussion_snapshot("example-org/web", 1138)

        self.assertEqual(
            {surface: [] for surface in rearview_workflow.DISCUSSION_SURFACES},
            snapshot["surfaces"],
        )

    def test_discussion_recheck_writes_only_changed_records_to_a_delta(self) -> None:
        snapshot_path = self.root / "rearview-discussion-1138-test.json"
        previous = {
            "version": rearview_workflow.DISCUSSION_SNAPSHOT_VERSION,
            "repo": "example-org/web",
            "pr_number": 1138,
            "surfaces": {
                "issue_comments": [
                    {
                        "id": 1,
                        "body": "Old",
                        "html_url": "https://example/1",
                        "viewer_authored": False,
                    }
                ],
                "reviews": [],
                "review_comments": [],
            },
        }
        previous["digest"] = rearview_workflow.discussion_digest(previous["surfaces"])
        rearview_workflow.write_json(snapshot_path, previous)
        current = json.loads(json.dumps(previous))
        current["surfaces"]["issue_comments"][0]["body"] = "New"
        current["digest"] = rearview_workflow.discussion_digest(current["surfaces"])
        delta_path = self.root / "rearview-discussion-delta-1138-test.json"
        output = io.StringIO()

        with (
            patch.object(rearview_workflow, "fetch_discussion_snapshot", return_value=current),
            patch.object(rearview_workflow, "private_temporary_path", return_value=delta_path),
            redirect_stdout(output),
        ):
            rearview_workflow.command_discussion_recheck(
                SimpleNamespace(snapshot=snapshot_path)
            )

        delta = json.loads(delta_path.read_text(encoding="utf-8"))
        self.assertEqual("New", delta["changed"]["issue_comments"][0]["body"])
        self.assertIn("discussion_changed=true", output.getvalue())
        self.assertEqual(current, json.loads(snapshot_path.read_text(encoding="utf-8")))

    def test_unchanged_discussion_recheck_does_not_create_a_delta(self) -> None:
        snapshot_path = self.root / "rearview-discussion-1138-test.json"
        snapshot = {
            "version": rearview_workflow.DISCUSSION_SNAPSHOT_VERSION,
            "repo": "example-org/web",
            "pr_number": 1138,
            "surfaces": {surface: [] for surface in rearview_workflow.DISCUSSION_SURFACES},
        }
        snapshot["digest"] = rearview_workflow.discussion_digest(snapshot["surfaces"])
        rearview_workflow.write_json(snapshot_path, snapshot)
        output = io.StringIO()

        with (
            patch.object(rearview_workflow, "fetch_discussion_snapshot", return_value=snapshot),
            patch.object(
                rearview_workflow,
                "private_temporary_path",
                side_effect=AssertionError("unchanged discussion must not create a delta"),
            ),
            redirect_stdout(output),
        ):
            rearview_workflow.command_discussion_recheck(
                SimpleNamespace(snapshot=snapshot_path)
            )

        self.assertIn("discussion_changed=false", output.getvalue())

    def test_prepare_preview_consumes_one_complete_temporary_plan(self) -> None:
        plan_source = self.root / "rearview-plan-1138-test.json"
        plan_source.write_text(json.dumps(valid_plan()), encoding="utf-8")
        output = io.StringIO()

        with (
            patch.object(rearview_workflow, "git_root", return_value=self.root),
            patch.object(rearview_workflow, "create_run_dir", side_effect=self.create_run_dir),
            patch.object(rearview_workflow, "fetch_local_combined_diff", return_value=DIFF),
            patch.object(
                rearview_workflow,
                "fetch_combined_diff",
                side_effect=AssertionError("prepare-preview must remain local"),
            ),
            patch.object(
                rearview_workflow.review_submission,
                "validate_current_pr",
                side_effect=AssertionError("prepare-preview must remain local"),
            ),
            redirect_stdout(output),
        ):
            result = rearview_workflow.prepare_preview_run(
                self.sidecar_path,
                plan_source,
                consume_plan=True,
            )

        manifest = rearview_workflow.load_manifest(result)
        self.assertEqual("previewed", manifest["stage"])
        self.assertFalse(plan_source.exists())
        self.assertIn("digest=", output.getvalue())

    def test_prepare_preview_uses_the_sidecars_embedded_plan(self) -> None:
        value = sidecar()
        value["publication_plan"] = valid_plan()
        self.sidecar_path.write_text(json.dumps(value), encoding="utf-8")
        output = io.StringIO()

        with (
            patch.object(rearview_workflow, "git_root", return_value=self.root),
            patch.object(rearview_workflow, "create_run_dir", side_effect=self.create_run_dir),
            patch.object(rearview_workflow, "fetch_local_combined_diff", return_value=DIFF),
            redirect_stdout(output),
        ):
            result = rearview_workflow.prepare_preview_run(
                self.sidecar_path,
                plan_source_path=None,
            )

        manifest = rearview_workflow.load_manifest(result)
        plan = json.loads((result / "plan.json").read_text(encoding="utf-8"))
        self.assertEqual(valid_plan(), plan)
        self.assertIn("review_timing_metadata=1.0", output.getvalue())

    def test_prepare_preview_injects_and_consumes_measured_timings(self) -> None:
        value = sidecar()
        value.pop("timings")
        value["publication_plan"] = valid_plan()
        self.sidecar_path.write_text(json.dumps(value), encoding="utf-8")
        measured_timings = [
            {"phase": phase, "seconds": float(index)}
            for index, phase in enumerate(rearview_workflow.TIMING_PHASES, start=1)
        ]
        timing_log = self.root / "rearview-timing-1138-test.json"
        rearview_workflow.write_json(
            timing_log,
            {
                "version": 2,
                "pr_number": 1138,
                "started_epoch_ns": 1,
                "last_mark_epoch_ns": 15_000_000_001,
                "phases": measured_timings,
                "warnings": ["system clock moved backwards before review; recorded 0 seconds"],
            },
        )
        output = io.StringIO()

        with (
            patch.object(rearview_workflow, "git_root", return_value=self.root),
            patch.object(rearview_workflow, "create_run_dir", side_effect=self.create_run_dir),
            patch.object(rearview_workflow, "fetch_local_combined_diff", return_value=DIFF),
            redirect_stdout(output),
        ):
            result = rearview_workflow.prepare_preview_run(
                self.sidecar_path,
                plan_source_path=None,
                timing_log_path=timing_log,
            )

        stored_sidecar = json.loads(self.sidecar_path.read_text(encoding="utf-8"))
        self.assertEqual(measured_timings, stored_sidecar["timings"])
        self.assertEqual(
            ["system clock moved backwards before review; recorded 0 seconds"],
            stored_sidecar["timing_warnings"],
        )
        self.assertFalse(timing_log.exists())
        self.assertEqual("previewed", rearview_workflow.load_manifest(result)["stage"])
        self.assertIn("source_timing_removed=true", output.getvalue())
        self.assertIn("timing_warning=system clock moved backwards", output.getvalue())

    def test_prepare_preview_times_normalization_through_failed_attempts(self) -> None:
        value = sidecar()
        value.pop("timings")
        value["publication_plan"] = valid_plan()
        value["publication_plan"]["comments"][0]["body"] = "Too short"
        self.sidecar_path.write_text(json.dumps(value), encoding="utf-8")
        measured_timings = [
            {"phase": phase, "seconds": float(index)}
            for index, phase in enumerate(rearview_workflow.TIMING_PHASES[:-1], start=1)
        ]
        timing_log = self.root / "rearview-timing-1138-test.json"
        rearview_workflow.write_json(
            timing_log,
            {
                "version": 2,
                "pr_number": 1138,
                "started_epoch_ns": 1,
                "last_mark_epoch_ns": 10_000_000_001,
                "phases": measured_timings,
                "warnings": [],
            },
        )

        with (
            patch.object(rearview_workflow, "git_root", return_value=self.root),
            patch.object(rearview_workflow, "create_run_dir", side_effect=self.create_run_dir),
            patch.object(rearview_workflow, "fetch_local_combined_diff", return_value=DIFF),
            patch.object(rearview_workflow.time, "time_ns", return_value=12_000_000_001),
            self.assertRaisesRegex(rearview_workflow.ValidationError, "comment has 2 words"),
        ):
            rearview_workflow.prepare_preview_run(
                self.sidecar_path,
                plan_source_path=None,
                timing_log_path=timing_log,
            )

        stored_timing_log = json.loads(timing_log.read_text(encoding="utf-8"))
        self.assertEqual(measured_timings, stored_timing_log["phases"])

        value["publication_plan"] = valid_plan()
        self.sidecar_path.write_text(json.dumps(value), encoding="utf-8")
        with (
            patch.object(rearview_workflow, "git_root", return_value=self.root),
            patch.object(rearview_workflow, "create_run_dir", side_effect=self.create_run_dir),
            patch.object(rearview_workflow, "fetch_local_combined_diff", return_value=DIFF),
            patch.object(rearview_workflow.time, "time_ns", return_value=15_000_000_001),
        ):
            result = rearview_workflow.prepare_preview_run(
                self.sidecar_path,
                plan_source_path=None,
                timing_log_path=timing_log,
            )

        stored_sidecar = json.loads(self.sidecar_path.read_text(encoding="utf-8"))
        self.assertEqual(
            [*measured_timings, {"phase": "normalization", "seconds": 5.0}],
            stored_sidecar["timings"],
        )
        self.assertFalse(timing_log.exists())
        self.assertEqual("previewed", rearview_workflow.load_manifest(result)["stage"])

    def test_prepare_preview_rejects_timings_that_differ_from_the_log(self) -> None:
        value = sidecar()
        value["publication_plan"] = valid_plan()
        self.sidecar_path.write_text(json.dumps(value), encoding="utf-8")
        timing_log = self.root / "rearview-timing-1138-test.json"
        rearview_workflow.write_json(
            timing_log,
            {
                "version": 2,
                "pr_number": 1138,
                "started_epoch_ns": 1,
                "last_mark_epoch_ns": 5_000_000_001,
                "phases": [
                    {"phase": phase, "seconds": 1.0}
                    for phase in rearview_workflow.TIMING_PHASES
                ],
                "warnings": [],
            },
        )

        with self.assertRaisesRegex(rearview_workflow.ValidationError, "differ from measured"):
            rearview_workflow.prepare_preview_run(
                self.sidecar_path,
                plan_source_path=None,
                timing_log_path=timing_log,
            )

        self.assertTrue(timing_log.exists())

    def test_prepare_preview_rejects_a_timing_log_for_another_pull_request(self) -> None:
        value = sidecar()
        value.pop("timings")
        value["publication_plan"] = valid_plan()
        self.sidecar_path.write_text(json.dumps(value), encoding="utf-8")
        timing_log = self.root / "rearview-timing-8675309-test.json"
        rearview_workflow.write_json(
            timing_log,
            {
                "version": 2,
                "pr_number": 8675309,
                "started_epoch_ns": 1,
                "last_mark_epoch_ns": 5_000_000_001,
                "phases": [
                    {"phase": phase, "seconds": 1.0}
                    for phase in rearview_workflow.TIMING_PHASES
                ],
                "warnings": [],
            },
        )

        with self.assertRaisesRegex(rearview_workflow.ValidationError, "pull request does not match"):
            rearview_workflow.prepare_preview_run(
                self.sidecar_path,
                plan_source_path=None,
                timing_log_path=timing_log,
            )

        self.assertTrue(timing_log.exists())

    def test_prepare_rejects_a_sidecar_changed_during_diff_fetch(self) -> None:
        def change_sidecar(_sidecar: dict) -> str:
            changed = sidecar()
            changed["title"] = "Changed after validation"
            self.sidecar_path.write_text(json.dumps(changed), encoding="utf-8")
            return DIFF

        with (
            patch.object(rearview_workflow, "git_root", return_value=self.root),
            patch.object(rearview_workflow, "fetch_combined_diff", side_effect=change_sidecar),
            patch.object(rearview_workflow.review_submission, "validate_current_pr"),
            self.assertRaisesRegex(rearview_workflow.ValidationError, "sidecar changed during preparation"),
        ):
            rearview_workflow.prepare_run(
                self.sidecar_path,
                "Codex",
                "Example User",
            )

        self.assertFalse(self.run_dir.exists())

    def test_preview_records_the_approved_submission_digest(self) -> None:
        manifest = self.preview()

        self.assertEqual("previewed", manifest["stage"])
        self.assertRegex(manifest["submission_digest"], r"\A[0-9a-f]{64}\Z")
        self.assertRegex(manifest["plan_sha256"], r"\A[0-9a-f]{64}\Z")
        preview_path = Path(manifest["preview_path"])
        self.assertTrue(preview_path.is_file())
        self.assertIn(manifest["submission_digest"], preview_path.read_text(encoding="utf-8"))
        self.assertGreaterEqual(manifest["timings"]["preview_seconds"], 0)

    def test_preview_does_not_repeat_the_remote_pr_check(self) -> None:
        self.prepare()
        plan_path = self.run_dir / "plan.json"
        plan_path.write_text(json.dumps(valid_plan()), encoding="utf-8")

        with (
            patch.object(
                rearview_workflow.review_submission,
                "validate_current_pr",
                side_effect=AssertionError("preview must remain local"),
            ),
            redirect_stdout(io.StringIO()),
        ):
            rearview_workflow.preview_run(self.run_dir)

    def preview_with_reply(self) -> dict:
        self.prepare()
        value = valid_plan()
        value["replies"] = [{
            "thread_url": "https://github.com/example-org/web/pull/1138#issuecomment-42",
            "body": "+1, we concur. The gate permits the escape.",
        }]
        (self.run_dir / "plan.json").write_text(json.dumps(value))
        with redirect_stdout(io.StringIO()):
            rearview_workflow.preview_run(self.run_dir)
        return rearview_workflow.load_manifest(self.run_dir)

    def test_publish_requires_reply_decision_before_any_remote_access(self) -> None:
        manifest = self.preview_with_reply()
        with (
            patch.object(rearview_workflow.review_submission, "validate_current_pr") as remote,
            patch.object(rearview_workflow, "post_review") as post,
            self.assertRaisesRegex(rearview_workflow.ValidationError, "reply decision"),
        ):
            rearview_workflow.publish_run(self.run_dir, manifest["submission_digest"])
        remote.assert_not_called()
        post.assert_not_called()

    def test_publish_review_only_skips_replies_and_cleans_up(self) -> None:
        manifest = self.preview_with_reply()
        with (
            patch.object(rearview_workflow.review_submission, "validate_current_pr"),
            patch.object(rearview_workflow.review_submission, "exact_reviews", return_value=[]),
            patch.object(rearview_workflow, "fetch_combined_diff", return_value=DIFF),
            patch.object(rearview_workflow, "post_review", return_value=0) as review,
            patch.object(rearview_workflow, "post_reply") as reply,
            patch.object(rearview_workflow, "verify_posted"),
            redirect_stdout(io.StringIO()),
        ):
            rearview_workflow.publish_run(self.run_dir, manifest["submission_digest"], reply_decision="none")
        review.assert_called_once()
        reply.assert_not_called()
        self.assertFalse(self.run_dir.exists())

    def test_publish_all_recovers_missing_reply_without_reposting_review(self) -> None:
        manifest = self.preview_with_reply()
        reviews = []
        replies = []
        def post_review(*_args):
            reviews.append({"id": 7})
            return 0
        def post_reply(*_args):
            replies.append({"html_url": "https://github.com/example-org/web/pull/1138#issuecomment-43"})
            return 0
        with (
            patch.object(rearview_workflow.review_submission, "validate_current_pr"),
            patch.object(rearview_workflow.review_submission, "exact_reviews", side_effect=lambda *_: reviews),
            patch.object(rearview_workflow, "fetch_combined_diff", return_value=DIFF),
            patch.object(rearview_workflow, "post_review", side_effect=post_review) as review,
            patch.object(rearview_workflow, "post_reply", return_value=1) as reply,
            patch.object(rearview_workflow.review_submission, "exact_replies", side_effect=lambda *_: replies),
            patch.object(rearview_workflow.review_submission, "validate_reply_target"),
            patch.object(rearview_workflow, "verify_posted"),
            redirect_stdout(io.StringIO()),
        ):
            with self.assertRaisesRegex(rearview_workflow.ValidationError, "reply"):
                rearview_workflow.publish_run(self.run_dir, manifest["submission_digest"], reply_decision="all")
            self.assertTrue(self.run_dir.exists())
            reply.side_effect = post_reply
            rearview_workflow.publish_run(self.run_dir, manifest["submission_digest"], reply_decision="all")
        review.assert_called_once()
        self.assertEqual(2, reply.call_count)
        self.assertFalse(self.run_dir.exists())

    def test_verify_keeps_run_when_selected_reply_is_missing(self) -> None:
        manifest = self.preview_with_reply()
        rearview_workflow.write_json(self.run_dir / "publication.json", {
            "submission_digest": manifest["submission_digest"], "replies": "all",
        })
        with (
            patch.object(rearview_workflow, "verify_posted"),
            patch.object(rearview_workflow.review_submission, "exact_replies", return_value=[]),
            self.assertRaisesRegex(rearview_workflow.ValidationError, "selected reply is missing"),
        ):
            rearview_workflow.verify_run(self.run_dir)
        self.assertTrue(self.run_dir.exists())

    def test_recovery_rejects_a_changed_reply_choice_before_remote_access(self) -> None:
        manifest = self.preview_with_reply()
        rearview_workflow.write_json(self.run_dir / "publication.json", {
            "submission_digest": manifest["submission_digest"], "replies": "all",
        })
        with (
            patch.object(rearview_workflow.review_submission, "validate_current_pr") as remote,
            self.assertRaisesRegex(rearview_workflow.ValidationError, "decision changed"),
        ):
            rearview_workflow.publish_run(self.run_dir, manifest["submission_digest"], reply_decision="none")
        remote.assert_not_called()

    def test_publish_replies_skips_existing_and_accepts_verified_unclear_post(self) -> None:
        plan = valid_plan()
        first = {"thread_url": "https://github.com/example-org/web/pull/1138#discussion_r42", "body": "We concur."}
        second = {"thread_url": "https://github.com/example-org/web/pull/1138#issuecomment-43", "body": "We agree."}
        self.run_dir.mkdir()
        with (
            patch.object(rearview_workflow.review_submission, "validate_current_pr"),
            patch.object(rearview_workflow.review_submission, "validate_reply_target"),
            patch.object(rearview_workflow.review_submission, "exact_replies", side_effect=[[{}], [], [{}]]),
            patch.object(rearview_workflow, "post_reply", return_value=1) as post,
        ):
            rearview_workflow.publish_replies(self.run_dir, sidecar(), plan, [first, second])
        post.assert_called_once()
        self.assertEqual(second, post.call_args.args[1])
        payload = json.loads((self.run_dir / "reply-payload.json").read_text())
        self.assertIn(second["thread_url"], payload["body"])
        self.assertTrue(payload["body"].endswith("-- Codex & Example User"))

    def test_changed_head_stops_replies_after_the_review(self) -> None:
        with (
            patch.object(rearview_workflow.review_submission, "validate_current_pr",
                         side_effect=rearview_workflow.ValidationError("head changed")),
            patch.object(rearview_workflow, "post_reply") as post,
            self.assertRaisesRegex(rearview_workflow.ValidationError, "head changed"),
        ):
            rearview_workflow.publish_replies(self.run_dir, sidecar(), valid_plan(), [{"body": "We concur."}])
        post.assert_not_called()

    def test_cli_carries_the_explicit_reply_decision(self) -> None:
        args = rearview_workflow.parser().parse_args([
            "publish", "--run-dir", str(self.run_dir), "--approved-digest", "a" * 64, "--replies", "all",
        ])
        with patch.object(rearview_workflow, "publish_run") as publish:
            args.handler(args)
        self.assertEqual("all", publish.call_args.kwargs["reply_decision"])

    def test_publication_decisions_publish_the_exact_preview_with_or_without_replies(self) -> None:
        for decision in ("Publish", "Publish all", "Review only", "Approve instead"):
            for with_replies in (False, True):
                with self.subTest(decision=decision, with_replies=with_replies):
                    self.run_dir = self.root / f"rearview-1138-{decision.replace(' ', '-')}-{with_replies}"
                    manifest = self.preview_with_reply() if with_replies else self.preview()
                    if decision == "Approve instead":
                        rearview_workflow.cleanup_run(self.run_dir)
                        self.prepare()
                        revised = valid_plan()
                        revised["event_override"] = "APPROVE"
                        if with_replies:
                            revised["replies"] = [{
                                "thread_url": "https://github.com/example-org/web/pull/1138#issuecomment-42",
                                "body": "+1, we concur. The gate permits the escape.",
                            }]
                        (self.run_dir / "plan.json").write_text(json.dumps(revised))
                        with redirect_stdout(io.StringIO()):
                            rearview_workflow.preview_run(self.run_dir)
                        manifest = rearview_workflow.load_manifest(self.run_dir)
                    posted_replies = []
                    expected = rearview_workflow.review_submission.submission(
                        sidecar(), json.loads((self.run_dir / "plan.json").read_text()),
                    )
                    if decision == "Approve instead":
                        self.assertEqual("APPROVE", expected["event"])

                    def post_review(_sidecar, payload_path):
                        self.assertEqual(expected, json.loads(payload_path.read_text()))
                        return 0

                    def post_reply(*_args):
                        posted_replies.append({
                            "html_url": "https://github.com/example-org/web/pull/1138#issuecomment-43",
                        })
                        return 0

                    args = rearview_workflow.parser().parse_args([
                        "publish", "--run-dir", str(self.run_dir),
                        "--approved-digest", manifest["submission_digest"], "--decision", decision,
                    ])
                    with (
                        patch.object(rearview_workflow.review_submission, "validate_current_pr"),
                        patch.object(rearview_workflow.review_submission, "exact_reviews", return_value=[]),
                        patch.object(rearview_workflow, "fetch_combined_diff", return_value=DIFF),
                        patch.object(rearview_workflow, "post_review", side_effect=post_review) as review,
                        patch.object(rearview_workflow, "post_reply", side_effect=post_reply) as reply,
                        patch.object(rearview_workflow.review_submission, "exact_replies",
                                     side_effect=lambda *_: posted_replies),
                        patch.object(rearview_workflow.review_submission, "validate_reply_target"),
                        patch.object(rearview_workflow, "verify_posted"),
                        redirect_stdout(io.StringIO()),
                    ):
                        args.handler(args)
                    review.assert_called_once()
                    self.assertEqual(int(with_replies and decision != "Review only"), reply.call_count)
                    self.assertFalse(self.run_dir.exists())

    def test_approve_instead_requires_the_revised_approve_event_before_remote_access(self) -> None:
        for event in ("REQUEST_CHANGES", "COMMENT", "APPROVE"):
            with self.subTest(event=event):
                self.run_dir = self.root / f"rearview-1138-{event}"
                self.prepare()
                value = valid_plan()
                value["event_override"] = event
                (self.run_dir / "plan.json").write_text(json.dumps(value))
                with redirect_stdout(io.StringIO()):
                    rearview_workflow.preview_run(self.run_dir)
                manifest = rearview_workflow.load_manifest(self.run_dir)
                args = rearview_workflow.parser().parse_args([
                    "publish", "--run-dir", str(self.run_dir),
                    "--approved-digest", manifest["submission_digest"], "--decision", "Approve instead",
                ])
                with patch.object(rearview_workflow.review_submission, "validate_current_pr") as remote:
                    if event == "APPROVE":
                        remote.side_effect = RuntimeError("freshness check reached")
                        with self.assertRaisesRegex(RuntimeError, "freshness check reached"):
                            args.handler(args)
                    else:
                        with self.assertRaisesRegex(rearview_workflow.ValidationError, "APPROVE"):
                            args.handler(args)
                        remote.assert_not_called()

    def test_publish_rejects_an_unapproved_digest_before_posting(self) -> None:
        manifest = self.preview()

        with (
            patch.object(rearview_workflow, "post_review") as post_review,
            self.assertRaisesRegex(rearview_workflow.ValidationError, "approved digest"),
        ):
            rearview_workflow.publish_run(
                self.run_dir,
                "0" * 64,
                "rechecked",
            )

        post_review.assert_not_called()
        self.assertEqual("previewed", manifest["stage"])

    def test_publish_requires_the_previewed_discussion_confirmation(self) -> None:
        manifest = self.preview()

        with (
            patch.object(rearview_workflow, "post_review") as post_review,
            self.assertRaisesRegex(rearview_workflow.ValidationError, "discussion confirmation"),
        ):
            rearview_workflow.publish_run(
                self.run_dir,
                manifest["submission_digest"],
                "privacy-skipped",
            )

        post_review.assert_not_called()

    def test_publish_rejects_a_plan_changed_after_preview(self) -> None:
        manifest = self.preview()
        changed_plan = valid_plan()
        changed_plan["additional_caveats"] = ["The plan changed after approval"]
        (self.run_dir / "plan.json").write_text(json.dumps(changed_plan), encoding="utf-8")

        with (
            patch.object(rearview_workflow, "post_review") as post_review,
            self.assertRaisesRegex(rearview_workflow.ValidationError, "plan changed"),
        ):
            rearview_workflow.publish_run(
                self.run_dir,
                manifest["submission_digest"],
                "rechecked",
            )

        post_review.assert_not_called()

    def test_publish_rejects_a_changed_posting_diff_before_posting(self) -> None:
        manifest = self.preview()
        changed_diff = DIFF.replace("gate.close!", "gate.open!")

        with (
            patch.object(rearview_workflow.review_submission, "validate_current_pr"),
            patch.object(rearview_workflow.review_submission, "exact_reviews", return_value=[]),
            patch.object(rearview_workflow, "fetch_combined_diff", return_value=changed_diff),
            patch.object(rearview_workflow, "post_review") as post_review,
            self.assertRaisesRegex(rearview_workflow.ValidationError, "combined diff changed"),
        ):
            rearview_workflow.publish_run(
                self.run_dir,
                manifest["submission_digest"],
                "rechecked",
            )

        post_review.assert_not_called()

    def test_publish_posts_once_verifies_and_removes_the_run_directory(self) -> None:
        manifest = self.preview()

        with (
            patch.object(
                rearview_workflow.review_submission,
                "validate_current_pr",
            ) as validate_current_pr,
            patch.object(rearview_workflow.review_submission, "exact_reviews", return_value=[]),
            patch.object(rearview_workflow, "fetch_combined_diff", return_value=DIFF),
            patch.object(rearview_workflow, "post_review", return_value=0) as post_review,
            patch.object(rearview_workflow, "verify_posted") as verify_posted,
            redirect_stdout(io.StringIO()),
        ):
            rearview_workflow.publish_run(
                self.run_dir,
                manifest["submission_digest"],
            )

        post_review.assert_called_once()
        verify_posted.assert_called_once()
        self.assertEqual(2, validate_current_pr.call_count)
        self.assertFalse(self.run_dir.exists())
        self.assertTrue(Path(manifest["preview_path"]).is_file())

    def test_publish_rechecks_the_head_immediately_before_posting(self) -> None:
        manifest = self.preview()

        with (
            patch.object(
                rearview_workflow.review_submission,
                "validate_current_pr",
                side_effect=[None, rearview_workflow.ValidationError("head changed")],
            ),
            patch.object(rearview_workflow.review_submission, "exact_reviews", return_value=[]),
            patch.object(rearview_workflow, "fetch_combined_diff", return_value=DIFF),
            patch.object(rearview_workflow, "post_review") as post_review,
            self.assertRaisesRegex(rearview_workflow.ValidationError, "head changed"),
        ):
            rearview_workflow.publish_run(
                self.run_dir,
                manifest["submission_digest"],
                "rechecked",
            )

        post_review.assert_not_called()

    def test_prepare_preview_diff_can_be_published_without_format_skew(self) -> None:
        plan_source = self.root / "rearview-plan-1138-publish.json"
        plan_source.write_text(json.dumps(valid_plan()), encoding="utf-8")

        with (
            patch.object(rearview_workflow, "git_root", return_value=self.root),
            patch.object(rearview_workflow, "create_run_dir", side_effect=self.create_run_dir),
            patch.object(rearview_workflow, "fetch_local_combined_diff", return_value=DIFF),
            redirect_stdout(io.StringIO()),
        ):
            rearview_workflow.prepare_preview_run(self.sidecar_path, plan_source)
        manifest = rearview_workflow.load_manifest(self.run_dir)

        with (
            patch.object(rearview_workflow.review_submission, "validate_current_pr"),
            patch.object(rearview_workflow.review_submission, "exact_reviews", return_value=[]),
            patch.object(rearview_workflow, "fetch_base_branch") as fetch_base_branch,
            patch.object(rearview_workflow, "fetch_local_combined_diff", return_value=DIFF),
            patch.object(rearview_workflow, "post_review", return_value=0),
            patch.object(rearview_workflow, "verify_posted"),
            redirect_stdout(io.StringIO()),
        ):
            rearview_workflow.publish_run(self.run_dir, manifest["submission_digest"])

        fetch_base_branch.assert_called_once_with("staging")
        self.assertFalse(self.run_dir.exists())

    def test_prepare_preview_can_pin_the_github_diff(self) -> None:
        plan_source = self.root / "rearview-plan-1138-github.json"
        plan_source.write_text(json.dumps(valid_plan()), encoding="utf-8")

        with (
            patch.object(rearview_workflow, "git_root", return_value=self.root),
            patch.object(rearview_workflow, "create_run_dir", side_effect=self.create_run_dir),
            patch.object(
                rearview_workflow.review_submission,
                "validate_current_pr",
            ) as validate_current_pr,
            patch.object(rearview_workflow, "fetch_combined_diff", return_value=DIFF),
            patch.object(
                rearview_workflow,
                "fetch_local_combined_diff",
                side_effect=AssertionError("GitHub diff mode must not use the local diff"),
            ),
            redirect_stdout(io.StringIO()),
        ):
            rearview_workflow.prepare_preview_run(
                self.sidecar_path,
                plan_source,
                diff_source="github",
            )

        manifest = rearview_workflow.load_manifest(self.run_dir)
        self.assertEqual("github", manifest["diff_source"])
        validate_current_pr.assert_called_once()

    def test_stability_check_reports_the_validated_head(self) -> None:
        args = SimpleNamespace(sidecar=self.sidecar_path)
        current = {
            "baseRefName": "staging",
            "headRefOid": "abc123",
            "state": "OPEN",
            "url": "https://github.com/example-org/web/pull/1138",
        }
        output = io.StringIO()

        with (
            patch.object(
                rearview_workflow.review_submission,
                "validate_current_pr",
                return_value=current,
            ),
            redirect_stdout(output),
        ):
            rearview_workflow.command_stability_check(args)

        self.assertIn("stable=true", output.getvalue())
        self.assertIn("head=abc123", output.getvalue())

    def test_failed_post_with_a_matching_review_requires_verification(self) -> None:
        manifest = self.preview()
        existing_review = {"html_url": "https://github.com/example-org/web/pull/1138#review"}

        with (
            patch.object(rearview_workflow.review_submission, "validate_current_pr"),
            patch.object(
                rearview_workflow.review_submission,
                "exact_reviews",
                side_effect=[[], [], [existing_review]],
            ),
            patch.object(rearview_workflow, "fetch_combined_diff", return_value=DIFF),
            patch.object(rearview_workflow, "post_review", return_value=1),
            self.assertRaisesRegex(rearview_workflow.ValidationError, "run verify"),
        ):
            rearview_workflow.publish_run(
                self.run_dir,
                manifest["submission_digest"],
                "rechecked",
            )

        self.assertTrue(self.run_dir.exists())

    def test_verify_recovers_a_posted_review_and_removes_the_run_directory(self) -> None:
        self.preview()

        with (
            patch.object(rearview_workflow, "verify_posted") as verify_posted,
            redirect_stdout(io.StringIO()),
        ):
            rearview_workflow.verify_run(self.run_dir)

        verify_posted.assert_called_once()
        self.assertFalse(self.run_dir.exists())

    def test_cleanup_refuses_a_run_directory_with_an_unknown_file(self) -> None:
        self.prepare()
        (self.run_dir / "unexpected.txt").write_text("keep", encoding="utf-8")

        with self.assertRaisesRegex(rearview_workflow.ValidationError, "unexpected entries"):
            rearview_workflow.cleanup_run(self.run_dir)

        self.assertTrue(self.run_dir.exists())

    def test_cleanup_refuses_a_directory_outside_the_rearview_temp_boundary(self) -> None:
        unsafe_dir = self.root / "ordinary-directory"
        unsafe_dir.mkdir()

        with self.assertRaisesRegex(rearview_workflow.ValidationError, "Rearview temporary directory"):
            rearview_workflow.cleanup_run(unsafe_dir)

        self.assertTrue(unsafe_dir.exists())


if __name__ == "__main__":
    unittest.main()
