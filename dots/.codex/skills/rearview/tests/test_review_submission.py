from __future__ import annotations

from contextlib import redirect_stdout
import importlib.util
import io
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).parents[1] / "scripts" / "review_submission.py"
SPEC = importlib.util.spec_from_file_location("review_submission", SCRIPT)
assert SPEC is not None
assert SPEC.loader is not None
review_submission = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(review_submission)


def sidecar(repository: str = "example-org/web", severity: str = "high") -> dict:
    return {
        "pr_number": 1138,
        "pr_url": f"https://github.com/{repository}/pull/1138",
        "head_commit": "abc123",
        "base_branch": "staging",
        "title": "Protect the badger",
        "repo": repository,
        "files_changed": 1,
        "lines_added": 1,
        "lines_removed": 0,
        "changed_files": ["app/models/badger.rb"],
        "changed_ranges": {"app/models/badger.rb": [[10, 10]]},
        "findings": [
            {
                "number": 1,
                "severity": severity,
                "title": "Guard the badger",
                "file": "app/models/badger.rb",
                "line": 10,
                "source_url": f"https://github.com/{repository}/blob/abc123/app/models/badger.rb#L10",
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


def plan(
    comment_body: str | None = None,
    event_override: str | None = None,
    review_body_override: str | None = None,
) -> dict:
    comment = comment_body or " ".join(["Badger access fails after this gate opens unexpectedly."] * 8)
    return {
        "agent": "Codex",
        "user_attribution": "Example User",
        "event_override": event_override,
        "review_body_override": review_body_override,
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


class ReviewSubmissionTest(unittest.TestCase):
    def reply_plan(self, anchor="discussion_r42") -> dict:
        value = plan()
        value["comments"] = []
        url = f"https://github.com/example-org/web/pull/1138#{anchor}"
        value["duplicates"] = [{"finding_number": 1, "thread_url": url, "reason": "Same defect."}]
        value["replies"] = [{"thread_url": url, "body": "+1, we concur. The gate permits the escape."}]
        return value

    def test_reply_body_and_target_are_bound_to_the_approval_digest(self) -> None:
        value = self.reply_plan()
        original = review_submission.publication_digest(sidecar(), value)
        value["replies"][0]["body"] += " We verified the caller."
        self.assertNotEqual(original, review_submission.publication_digest(sidecar(), value))
        changed_body = review_submission.publication_digest(sidecar(), value)
        value["replies"][0]["thread_url"] = value["replies"][0]["thread_url"].replace("42", "43")
        self.assertNotEqual(changed_body, review_submission.publication_digest(sidecar(), value))

    def test_preview_contains_exact_attributed_reply_and_required_choice(self) -> None:
        value = self.reply_plan("issuecomment-42")
        rendered = review_submission.preview_text(sidecar(), value)
        self.assertIn("Publish all", rendered)
        self.assertIn("Review only", rendered)
        self.assertIn("**Publish** or **Publish all**", rendered)
        self.assertNotIn("incomplete until", rendered)
        self.assertIn(review_submission.reply_body(value, value["replies"][0]), rendered)
        self.assertNotIn("replies", review_submission.submission(sidecar(), value))

    def test_reply_validation_rejects_foreign_targets_and_singular_voice(self) -> None:
        for key, replacement in (("thread_url", "https://github.com/other/web/pull/1138#discussion_r42"),
                                 ("body", "I concur."), ("body", "We concur. -- Codex & Example User")):
            with self.subTest(key=key, replacement=replacement):
                value = self.reply_plan()
                value["replies"][0][key] = replacement
                with self.assertRaises(review_submission.ValidationError):
                    review_submission.validate_plan(value, sidecar())

    def test_reply_posts_use_the_correct_github_endpoint(self) -> None:
        for anchor, suffix in (("discussion_r42", "pulls/1138/comments/42/replies"),
                               ("issuecomment-42", "issues/1138/comments"),
                               ("pullrequestreview-42", "issues/1138/comments")):
            with self.subTest(anchor=anchor):
                value = self.reply_plan(anchor)
                reply = value["replies"][0]
                self.assertEqual(f"repos/example-org/web/{suffix}",
                                 review_submission.reply_endpoint(sidecar(), reply))
                body = review_submission.reply_body(value, reply)
                self.assertTrue(body.endswith("-- Codex & Example User"))
                if anchor != "discussion_r42":
                    self.assertIn(reply["thread_url"], body)

    def test_exact_replies_match_parent_and_body_across_all_pages(self) -> None:
        value = self.reply_plan()
        reply = value["replies"][0]
        body = review_submission.reply_body(value, reply)
        wrong_parent = {"body": body, "in_reply_to_id": 43, "html_url": "wrong"}
        expected = {"body": body, "in_reply_to_id": 42, "html_url": "correct"}
        with patch.object(review_submission, "gh_json", side_effect=[[wrong_parent] * 100, [expected]]) as gh:
            self.assertEqual([expected], review_submission.exact_replies(sidecar(), value, reply))
        self.assertEqual(2, gh.call_count)
        self.assertIn("page=2", gh.call_args.args[0][1])
        self.assertIn("--jq", gh.call_args.args[0])

    def test_reply_target_requires_same_pr_and_root_comment(self) -> None:
        reply = self.reply_plan()["replies"][0]
        valid_url = "https://api.github.com/repos/example-org/web/pulls/1138"
        for remote in ({"pull_request_url": valid_url, "in_reply_to_id": 9},
                       {"pull_request_url": valid_url.replace("1138", "1139"), "in_reply_to_id": None}):
            with self.subTest(remote=remote), patch.object(review_submission, "gh_json", return_value=remote):
                with self.assertRaises(review_submission.ValidationError):
                    review_submission.validate_reply_target(sidecar(), reply)

    def test_issue_reply_target_rejects_comment_from_another_pr(self) -> None:
        reply = self.reply_plan("issuecomment-42")["replies"][0]
        with patch.object(review_submission, "gh_json", return_value={
            "issue_url": "https://api.github.com/repos/example-org/web/issues/1139",
        }):
            with self.assertRaisesRegex(review_submission.ValidationError, "another PR"):
                review_submission.validate_reply_target(sidecar(), reply)

    def test_reply_validation_rejects_duplicate_targets_and_unknown_fragments(self) -> None:
        value = self.reply_plan()
        value["replies"].append(dict(value["replies"][0]))
        with self.assertRaisesRegex(review_submission.ValidationError, "duplicate targets"):
            review_submission.validate_plan(value, sidecar())
        value = self.reply_plan("unknown-42")
        with self.assertRaisesRegex(review_submission.ValidationError, "supported comment"):
            review_submission.validate_plan(value, sidecar())

    def test_repository_from_remote_url_accepts_git_and_https_urls(self) -> None:
        urls = (
            "git@github.com:example-org/bw-core-agents.git",
            "https://github.com/example-org/bw-core-agents.git",
            "ssh://git@github.com/example-org/bw-core-agents.git",
        )

        for url in urls:
            with self.subTest(url=url):
                self.assertEqual(
                    "example-org/bw-core-agents",
                    review_submission.repository_from_remote_url(url),
                )

    def test_repository_from_remote_url_rejects_a_non_github_remote(self) -> None:
        with self.assertRaisesRegex(review_submission.ValidationError, "GitHub origin"):
            review_submission.repository_from_remote_url(
                "git@example.com:example-org/bw-core-agents.git"
            )

    def test_github_repository_uses_the_local_origin_mapping(self) -> None:
        result = SimpleNamespace(
            returncode=0,
            stdout="git@github.com:example-org/bw-core-agents.git\n",
        )

        with patch.object(review_submission.subprocess, "run", return_value=result) as run:
            repository = review_submission.github_repository()

        self.assertEqual("example-org/bw-core-agents", repository)
        run.assert_called_once_with(
            ["git", "remote", "get-url", "origin"],
            capture_output=True,
            text=True,
            check=False,
        )

    def test_sidecar_rejects_a_negative_phase_timing(self) -> None:
        value = sidecar()
        value["timings"][0]["seconds"] = -1

        with self.assertRaisesRegex(review_submission.ValidationError, "timings"):
            review_submission.validate_sidecar(value)

    def test_sidecar_validates_an_embedded_publication_plan(self) -> None:
        value = sidecar()
        value["publication_plan"] = plan()

        validated = review_submission.validate_sidecar(value)

        self.assertEqual(plan(), validated["publication_plan"])

    def test_sidecar_rejects_an_invalid_embedded_publication_plan(self) -> None:
        value = sidecar()
        value["publication_plan"] = plan()
        value["publication_plan"]["discussion_check"] = "unknown"

        with self.assertRaisesRegex(review_submission.ValidationError, "discussion_check"):
            review_submission.validate_sidecar(value)

    def test_default_event_requests_changes_for_critical_and_high_findings(self) -> None:
        for severity in ("critical", "high"):
            with self.subTest(severity=severity):
                validated_sidecar = review_submission.validate_sidecar(sidecar(severity=severity))
                validated_plan = review_submission.validate_plan(plan(), validated_sidecar)

                event = review_submission.event_for(validated_sidecar, validated_plan)

                self.assertEqual("REQUEST_CHANGES", event)

    def test_default_event_approves_medium_and_low_findings(self) -> None:
        for severity in ("medium", "low"):
            with self.subTest(severity=severity):
                validated_sidecar = review_submission.validate_sidecar(sidecar(severity=severity))
                candidate = plan()
                if severity == "low":
                    candidate["comments"] = []
                validated_plan = review_submission.validate_plan(candidate, validated_sidecar)

                event = review_submission.event_for(validated_sidecar, validated_plan)

                self.assertEqual("APPROVE", event)

    def test_explicit_event_overrides_the_default(self) -> None:
        for event_override in ("APPROVE", "REQUEST_CHANGES", "COMMENT"):
            with self.subTest(event_override=event_override):
                validated_sidecar = review_submission.validate_sidecar(sidecar())
                validated_plan = review_submission.validate_plan(plan(event_override=event_override), validated_sidecar)

                event = review_submission.event_for(validated_sidecar, validated_plan)

                self.assertEqual(event_override, event)

    def test_plan_rejects_an_invalid_event_override(self) -> None:
        validated_sidecar = review_submission.validate_sidecar(sidecar())

        with self.assertRaisesRegex(review_submission.ValidationError, "event_override"):
            review_submission.validate_plan(plan(event_override="PENDING"), validated_sidecar)

    def test_explicit_review_body_overrides_the_generic_body(self) -> None:
        body = (
            "Found one HIGH concern involving multiple schools. See the inline comment. "
            "The concern does not block this pull request."
        )
        validated_sidecar = review_submission.validate_sidecar(sidecar())
        validated_plan = review_submission.validate_plan(
            plan(event_override="APPROVE", review_body_override=body),
            validated_sidecar,
        )

        payload = review_submission.submission(validated_sidecar, validated_plan)
        preview = review_submission.preview_text(validated_sidecar, validated_plan)

        self.assertEqual(f"{body}\n\n-- Codex & Example User", payload["body"])
        self.assertIn(f"{body}\n\n-- Codex & Example User", preview)

    def test_plan_rejects_attribution_in_a_review_body_override(self) -> None:
        validated_sidecar = review_submission.validate_sidecar(sidecar())

        for attribution in ("-- Codex & Example User", "--Codex & Example User"):
            with self.subTest(attribution=attribution):
                invalid_plan = plan(review_body_override=f"Looks good. {attribution}")

                with self.assertRaisesRegex(review_submission.ValidationError, "must omit attribution"):
                    review_submission.validate_plan(invalid_plan, validated_sidecar)

    def test_plan_rejects_invalid_owned_prose_in_a_review_body_override(self) -> None:
        for body in ("I found one concern.", "We found one concern. Cheers.\u2026"):
            with self.subTest(body=body):
                invalid_plan = plan(review_body_override=body)
                validated_sidecar = review_submission.validate_sidecar(sidecar())

                with self.assertRaises(review_submission.ValidationError):
                    review_submission.validate_plan(invalid_plan, validated_sidecar)

    def test_legacy_plan_without_a_review_body_override_remains_valid(self) -> None:
        legacy_plan = plan()
        del legacy_plan["review_body_override"]
        validated_sidecar = review_submission.validate_sidecar(sidecar())

        validated = review_submission.validate_plan(legacy_plan, validated_sidecar)

        self.assertNotIn("review_body_override", validated)

    def test_plan_accepts_a_rechecked_discussion_status(self) -> None:
        candidate = plan()
        candidate["discussion_check"] = "rechecked"
        validated_sidecar = review_submission.validate_sidecar(sidecar())

        validated = review_submission.validate_plan(candidate, validated_sidecar)

        self.assertEqual("rechecked", validated["discussion_check"])

    def test_clean_plan_accepts_a_not_needed_discussion_status(self) -> None:
        clean_sidecar = sidecar()
        clean_sidecar["findings"] = []
        candidate = plan()
        candidate["discussion_check"] = "not-needed"
        candidate["comments"] = []
        validated_sidecar = review_submission.validate_sidecar(clean_sidecar)

        validated = review_submission.validate_plan(candidate, validated_sidecar)

        self.assertEqual("not-needed", validated["discussion_check"])

    def test_not_needed_discussion_rejects_a_published_finding(self) -> None:
        candidate = plan()
        candidate["discussion_check"] = "not-needed"
        validated_sidecar = review_submission.validate_sidecar(sidecar())

        with self.assertRaisesRegex(review_submission.ValidationError, "not-needed"):
            review_submission.validate_plan(candidate, validated_sidecar)

    def test_privacy_skipped_discussion_requires_a_previewed_caveat(self) -> None:
        candidate = plan()
        candidate["discussion_check"] = "privacy-skipped"
        validated_sidecar = review_submission.validate_sidecar(sidecar())

        with self.assertRaisesRegex(review_submission.ValidationError, "privacy-skipped"):
            review_submission.validate_plan(candidate, validated_sidecar)

    def test_preview_discloses_a_privacy_skipped_discussion_check(self) -> None:
        candidate = plan()
        candidate["discussion_check"] = "privacy-skipped"
        candidate["additional_caveats"] = [
            "Semantic duplicate discussion was skipped because privacy rules prohibit raw prose"
        ]
        validated_sidecar = review_submission.validate_sidecar(sidecar())
        validated_plan = review_submission.validate_plan(candidate, validated_sidecar)

        preview = review_submission.preview_text(validated_sidecar, validated_plan)

        self.assertIn("Discussion check: `privacy-skipped`", preview)

    def test_report_is_rendered_from_the_validated_sidecar(self) -> None:
        validated = review_submission.validate_sidecar(sidecar())

        report = review_submission.report_text(validated)

        self.assertIn("# Review of PR #1138: Protect the badger", report)
        self.assertIn("### 1. Guard the badger (high)", report)
        self.assertIn("Consequence: The badger escapes", report)
        self.assertIn("- Lanes run: flow", report)
        self.assertIn("- metadata: 1.0 seconds", report)

    def test_clean_report_says_there_are_no_findings(self) -> None:
        value = sidecar()
        value["findings"] = []
        validated = review_submission.validate_sidecar(value)

        report = review_submission.report_text(validated)

        self.assertIn("## Findings\n\nNo findings.", report)

    def test_sidecar_accepts_the_current_repository_name(self) -> None:
        value = sidecar("example-org/bw-core-agents")

        validated = review_submission.validate_sidecar(value)

        self.assertEqual("example-org/bw-core-agents", validated["repo"])

    def test_sidecar_pr_url_must_match_its_repository(self) -> None:
        value = sidecar("example-org/bw-core-agents")
        value["pr_url"] = "https://github.com/example-org/web/pull/1138"

        with self.assertRaisesRegex(review_submission.ValidationError, "must identify"):
            review_submission.validate_sidecar(value)

    def test_sidecar_rejects_an_invalid_repository_name(self) -> None:
        value = sidecar("example-org/bw-core-agents")
        value["repo"] = "example-org/bw-core-agents/extra"

        with self.assertRaisesRegex(review_submission.ValidationError, "owner/repository"):
            review_submission.validate_sidecar(value)

    def test_sidecar_rejects_personal_preferences_as_finding_authority(self) -> None:
        value = sidecar()
        value["findings"][0]["authority"]["type"] = "personal_preference"

        with self.assertRaisesRegex(review_submission.ValidationError, "authority type"):
            review_submission.validate_sidecar(value)

    def test_repository_rule_authority_requires_a_tracked_source(self) -> None:
        value = sidecar()
        value["findings"][0]["authority"] = {
            "type": "repository_rule",
            "path": "AGENTS.md",
            "line": 42,
        }
        validated = review_submission.validate_sidecar(value)

        with (
            patch.object(review_submission.subprocess, "run") as run,
            self.assertRaisesRegex(review_submission.ValidationError, "not tracked"),
        ):
            run.return_value.returncode = 1
            review_submission.validate_repository_rule_sources(validated)

        run.assert_called_once_with(
            ["git", "cat-file", "-e", "abc123:AGENTS.md"],
            stdout=review_submission.subprocess.DEVNULL,
            stderr=review_submission.subprocess.DEVNULL,
            check=False,
        )

    def test_repository_rule_authority_accepts_a_tracked_source(self) -> None:
        value = sidecar()
        value["findings"][0]["authority"] = {
            "type": "repository_rule",
            "path": "AGENTS.md",
            "line": 42,
        }
        validated = review_submission.validate_sidecar(value)

        with patch.object(review_submission.subprocess, "run") as run:
            run.return_value.returncode = 0
            review_submission.validate_repository_rule_sources(validated)

        run.assert_called_once()

    def test_repository_rule_authority_rejects_unsafe_paths(self) -> None:
        for path in ("/AGENTS.md", "docs\\AGENTS.md", "docs:AGENTS.md", "../AGENTS.md"):
            with self.subTest(path=path):
                value = sidecar()
                value["findings"][0]["authority"] = {
                    "type": "repository_rule",
                    "path": path,
                    "line": 42,
                }

                with self.assertRaisesRegex(review_submission.ValidationError, "safe repository-relative"):
                    review_submission.validate_sidecar(value)

    def test_non_repository_authority_rejects_a_rule_location(self) -> None:
        value = sidecar()
        value["findings"][0]["authority"]["path"] = "AGENTS.md"

        with self.assertRaisesRegex(review_submission.ValidationError, "must be null"):
            review_submission.validate_sidecar(value)

    def test_nested_code_fence_uses_a_longer_preview_fence(self) -> None:
        comment = " ".join(["Badger access fails after this gate opens unexpectedly."] * 8)
        comment += "\n\nFor example:\n\n```ruby\ngate.close!\n```"
        validated_sidecar = review_submission.validate_sidecar(sidecar())
        validated_plan = review_submission.validate_plan(plan(comment), validated_sidecar)

        preview = review_submission.preview_text(validated_sidecar, validated_plan)

        self.assertIn("````markdown\n", preview)
        self.assertIn("```ruby\ngate.close!\n```", preview)

    def test_all_inline_findings_must_be_classified_once(self) -> None:
        invalid_plan = plan()
        invalid_plan["comments"] = []
        validated_sidecar = review_submission.validate_sidecar(sidecar())

        with self.assertRaisesRegex(review_submission.ValidationError, "classified exactly once"):
            review_submission.validate_plan(invalid_plan, validated_sidecar)

    def test_plan_reports_every_invalid_comment_length(self) -> None:
        value = sidecar()
        value["findings"].append(
            {
                **value["findings"][0],
                "number": 2,
                "title": "Guard the tapir",
            }
        )
        candidate = plan(comment_body="Too short")
        candidate["comments"].append(
            {
                **candidate["comments"][0],
                "finding_number": 2,
            }
        )
        validated_sidecar = review_submission.validate_sidecar(value)

        with self.assertRaises(review_submission.ValidationError) as captured:
            review_submission.validate_plan(candidate, validated_sidecar)

        self.assertIn("finding #1 comment has 2 words", str(captured.exception))
        self.assertIn("finding #2 comment has 2 words", str(captured.exception))

    def test_low_finding_may_be_published_inline(self) -> None:
        validated_sidecar = review_submission.validate_sidecar(sidecar(severity="low"))

        validated_plan = review_submission.validate_plan(plan(), validated_sidecar)

        self.assertEqual(1, len(validated_plan["comments"]))

    def test_low_finding_is_excluded_locally_when_not_published(self) -> None:
        validated_sidecar = review_submission.validate_sidecar(sidecar(severity="low"))
        candidate = plan()
        candidate["comments"] = []
        validated_plan = review_submission.validate_plan(candidate, validated_sidecar)

        preview = review_submission.preview_text(validated_sidecar, validated_plan)

        self.assertIn("Low finding #1: Guard the badger", preview)

    def test_published_low_finding_is_not_listed_as_excluded(self) -> None:
        validated_sidecar = review_submission.validate_sidecar(sidecar(severity="low"))
        validated_plan = review_submission.validate_plan(plan(), validated_sidecar)

        preview = review_submission.preview_text(validated_sidecar, validated_plan)

        self.assertNotIn("Low finding #1: Guard the badger", preview)

    def test_plan_rejects_an_authored_review_body(self) -> None:
        invalid_plan = plan()
        invalid_plan["body"] = "We found another issue."
        validated_sidecar = review_submission.validate_sidecar(sidecar())

        with self.assertRaisesRegex(review_submission.ValidationError, "keys differ"):
            review_submission.validate_plan(invalid_plan, validated_sidecar)

    def test_plan_rejects_a_body_only_finding(self) -> None:
        invalid_plan = plan()
        invalid_plan["body_only"] = [
            {"finding_number": 1, "reason": "No honest changed-line anchor"}
        ]
        validated_sidecar = review_submission.validate_sidecar(sidecar())

        with self.assertRaisesRegex(review_submission.ValidationError, "keys differ"):
            review_submission.validate_plan(invalid_plan, validated_sidecar)

    def test_approval_without_inline_comments_uses_a_generic_body(self) -> None:
        source = sidecar(severity="low")
        validated_sidecar = review_submission.validate_sidecar(source)
        candidate = plan()
        candidate["comments"] = []
        validated_plan = review_submission.validate_plan(candidate, validated_sidecar)

        payload = review_submission.submission(validated_sidecar, validated_plan)

        self.assertEqual("Looks good.\n\n-- Codex & Example User", payload["body"])

    def test_approval_with_medium_findings_requests_follow_up(self) -> None:
        validated_sidecar = review_submission.validate_sidecar(sidecar(severity="medium"))
        validated_plan = review_submission.validate_plan(plan(), validated_sidecar)

        payload = review_submission.submission(validated_sidecar, validated_plan)

        self.assertEqual(
            "Looks good overall. The review thread contains a follow-up request.\n\n-- Codex & Example User",
            payload["body"],
        )

    def test_approval_with_only_low_findings_labels_them_optional(self) -> None:
        validated_sidecar = review_submission.validate_sidecar(sidecar(severity="low"))
        validated_plan = review_submission.validate_plan(plan(), validated_sidecar)

        payload = review_submission.submission(validated_sidecar, validated_plan)

        self.assertEqual(
            "Looks good overall. The review thread contains an optional suggestion.\n\n-- Codex & Example User",
            payload["body"],
        )

    def test_approval_with_a_duplicate_medium_finding_requests_follow_up(self) -> None:
        validated_sidecar = review_submission.validate_sidecar(sidecar(severity="medium"))
        candidate = plan()
        candidate["comments"] = []
        candidate["duplicates"] = [
            {
                "finding_number": 1,
                "thread_url": "https://github.com/example-org/web/pull/1138#discussion_r42",
                "reason": "The existing thread requests the same correction",
            }
        ]
        validated_plan = review_submission.validate_plan(candidate, validated_sidecar)

        payload = review_submission.submission(validated_sidecar, validated_plan)

        self.assertEqual(
            "Looks good overall. The review thread contains a follow-up request.\n\n-- Codex & Example User",
            payload["body"],
        )

    def test_explicit_approval_with_a_high_finding_keeps_blocking_language(self) -> None:
        validated_sidecar = review_submission.validate_sidecar(sidecar(severity="high"))
        validated_plan = review_submission.validate_plan(
            plan(event_override="APPROVE"), validated_sidecar
        )

        payload = review_submission.submission(validated_sidecar, validated_plan)

        self.assertEqual(
            "The review thread contains a blocking request.\n\n-- Codex & Example User",
            payload["body"],
        )

    def test_request_changes_uses_a_generic_body(self) -> None:
        validated_sidecar = review_submission.validate_sidecar(sidecar())
        validated_plan = review_submission.validate_plan(plan(), validated_sidecar)

        payload = review_submission.submission(validated_sidecar, validated_plan)

        self.assertEqual(
            "We found a blocking issue in the review thread.\n\n-- Codex & Example User",
            payload["body"],
        )

    def test_comment_event_uses_generic_bodies(self) -> None:
        validated_sidecar = review_submission.validate_sidecar(sidecar(severity="low"))
        with_comment = review_submission.validate_plan(
            plan(event_override="COMMENT"), validated_sidecar
        )
        without_comment_source = plan(event_override="COMMENT")
        without_comment_source["comments"] = []
        without_comment = review_submission.validate_plan(
            without_comment_source, validated_sidecar
        )

        self.assertEqual(
            "We left a review comment in the thread.\n\n-- Codex & Example User",
            review_submission.submission(validated_sidecar, with_comment)["body"],
        )
        self.assertEqual(
            "No findings.\n\n-- Codex & Example User",
            review_submission.submission(validated_sidecar, without_comment)["body"],
        )

    def test_multiple_published_findings_keep_plural_review_body(self) -> None:
        source = sidecar(severity="medium")
        source["findings"].append(
            {
                **source["findings"][0],
                "number": 2,
                "title": "Guard the tapir",
                "line": 11,
            }
        )
        source["changed_ranges"]["app/models/badger.rb"] = [[10, 11]]
        candidate = plan()
        candidate["comments"].append(
            {
                **candidate["comments"][0],
                "finding_number": 2,
                "line": 11,
            }
        )
        validated_sidecar = review_submission.validate_sidecar(source)
        validated_plan = review_submission.validate_plan(candidate, validated_sidecar)

        payload = review_submission.submission(validated_sidecar, validated_plan)

        self.assertEqual(
            "Looks good overall. The review threads contain follow-up requests.\n\n-- Codex & Example User",
            payload["body"],
        )

    def test_plan_rejects_a_caveat_already_recorded_by_the_sidecar(self) -> None:
        source = sidecar()
        source["not_verified"] = ["Runtime proof was not requested"]
        invalid_plan = plan()
        invalid_plan["additional_caveats"] = ["Runtime proof was not requested"]
        validated_sidecar = review_submission.validate_sidecar(source)

        with self.assertRaisesRegex(review_submission.ValidationError, "duplicates sidecar.not_verified"):
            review_submission.validate_plan(invalid_plan, validated_sidecar)

    def test_plan_rejects_duplicate_additional_caveats(self) -> None:
        invalid_plan = plan()
        invalid_plan["additional_caveats"] = [
            "The external consumer was unavailable",
            "The external consumer was unavailable",
        ]
        validated_sidecar = review_submission.validate_sidecar(sidecar())

        with self.assertRaisesRegex(review_submission.ValidationError, "contains duplicates"):
            review_submission.validate_plan(invalid_plan, validated_sidecar)

    def test_payload_requires_the_approved_preview_to_match(self) -> None:
        validated_sidecar = review_submission.validate_sidecar(sidecar())
        validated_plan = review_submission.validate_plan(plan(), validated_sidecar)
        with tempfile.TemporaryDirectory() as directory:
            preview_path = Path(directory) / "preview.md"
            preview_path.write_text("changed\n", encoding="utf-8")

            with self.assertRaisesRegex(review_submission.ValidationError, "differs"):
                review_submission.approved_preview(validated_sidecar, validated_plan, preview_path)

    def test_diff_parser_accepts_right_and_left_hunk_lines(self) -> None:
        diff = """diff --git a/app/models/badger.rb b/app/models/badger.rb
--- a/app/models/badger.rb
+++ b/app/models/badger.rb
@@ -9,2 +9,2 @@
 context
-old gate
+new gate
"""

        anchors = review_submission.diff_anchor_set(diff)

        self.assertIn(("app/models/badger.rb", "LEFT", 10), anchors)
        self.assertIn(("app/models/badger.rb", "RIGHT", 10), anchors)

    def test_payload_uses_the_same_exact_prose_as_the_preview_source(self) -> None:
        validated_sidecar = review_submission.validate_sidecar(sidecar())
        validated_plan = review_submission.validate_plan(plan(), validated_sidecar)

        payload = review_submission.submission(validated_sidecar, validated_plan)

        self.assertEqual(
            payload["comments"][0]["body"],
            f"{validated_plan['comments'][0]['body']}\n\n-- Codex & Example User",
        )
        json.dumps(payload)

    def test_review_body_override_changes_the_submission_digest(self) -> None:
        validated_sidecar = review_submission.validate_sidecar(sidecar())
        generic_plan = review_submission.validate_plan(
            plan(event_override="APPROVE"), validated_sidecar
        )
        custom_plan = review_submission.validate_plan(
            plan(
                event_override="APPROVE",
                review_body_override="We found one non-blocking concern. Please see the inline comment.",
            ),
            validated_sidecar,
        )

        generic_digest = review_submission.submission_digest(
            review_submission.submission(validated_sidecar, generic_plan)
        )
        custom_digest = review_submission.submission_digest(
            review_submission.submission(validated_sidecar, custom_plan)
        )

        self.assertNotEqual(generic_digest, custom_digest)

    def test_retry_guard_requires_the_exact_inline_comment_set(self) -> None:
        validated_sidecar = review_submission.validate_sidecar(sidecar("example-org/lunchbox"))
        validated_plan = review_submission.validate_plan(plan(), validated_sidecar)
        payload = review_submission.submission(validated_sidecar, validated_plan)
        reviews = [
            {
                "id": 8675309,
                "commit_id": "abc123",
                "body": payload["body"],
                "state": "CHANGES_REQUESTED",
                "html_url": "https://github.com/example-org/lunchbox/pull/1138#pullrequestreview-8675309",
            }
        ]
        other_comments = [
            {
                **payload["comments"][0],
                "body": "A different earlier finding",
                "pull_request_review_id": 8675309,
            }
        ]

        with patch.object(
            review_submission,
            "paged_api",
            side_effect=[reviews, other_comments],
        ):
            matches = review_submission.exact_reviews(validated_sidecar, validated_plan)

        self.assertEqual([], matches)

    def test_retry_guard_matches_the_exact_review_and_comments(self) -> None:
        validated_sidecar = review_submission.validate_sidecar(sidecar("example-org/lunchbox"))
        validated_plan = review_submission.validate_plan(plan(), validated_sidecar)
        payload = review_submission.submission(validated_sidecar, validated_plan)
        reviews = [
            {
                "id": 8675309,
                "commit_id": "abc123",
                "body": payload["body"],
                "state": "CHANGES_REQUESTED",
                "html_url": "https://github.com/example-org/lunchbox/pull/1138#pullrequestreview-8675309",
            }
        ]
        posted = [payload["comments"][0] | {"pull_request_review_id": 8675309}]

        with patch.object(review_submission, "paged_api", side_effect=[reviews, posted]):
            matches = review_submission.exact_reviews(validated_sidecar, validated_plan)

        self.assertEqual(reviews, matches)

    def test_posted_verification_uses_pull_request_comments(self) -> None:
        validated_sidecar = review_submission.validate_sidecar(
            sidecar("example-org/bw-core-agents", severity="medium")
        )
        validated_plan = review_submission.validate_plan(plan(), validated_sidecar)
        payload = review_submission.submission(validated_sidecar, validated_plan)
        review = {
            "id": 8675309,
            "state": "APPROVED",
            "html_url": "https://github.com/example-org/bw-core-agents/pull/1138#pullrequestreview-8675309",
            "commit_id": "abc123",
        }
        posted = [payload["comments"][0] | {"pull_request_review_id": 8675309}]
        args = SimpleNamespace(approved_preview=Path("preview.md"))

        with (
            patch.object(review_submission, "load_artifacts", return_value=(validated_sidecar, validated_plan)),
            patch.object(review_submission, "approved_preview"),
            patch.object(review_submission, "validate_current_pr"),
            patch.object(review_submission, "exact_reviews", return_value=[review]),
            patch.object(review_submission, "paged_api", return_value=posted) as paged_api,
        ):
            with redirect_stdout(io.StringIO()):
                review_submission.command_verify_posted(args)

        paged_api.assert_called_once_with("repos/example-org/bw-core-agents/pulls/1138/comments")

    def test_current_pr_must_belong_to_the_current_repository(self) -> None:
        validated_sidecar = review_submission.validate_sidecar(sidecar("example-org/lunchbox"))

        with (
            patch.object(review_submission, "github_repository", return_value="example-org/web"),
            patch.object(review_submission, "github_pr") as github_pr,
            self.assertRaisesRegex(review_submission.ValidationError, "current repository"),
        ):
            review_submission.validate_current_pr(validated_sidecar)

        github_pr.assert_not_called()

    def test_current_pr_accepts_a_matching_non_web_repository(self) -> None:
        validated_sidecar = review_submission.validate_sidecar(sidecar("example-org/lunchbox"))
        current = {
            "baseRefName": "staging",
            "headRefOid": "abc123",
            "state": "OPEN",
            "url": "https://github.com/example-org/lunchbox/pull/1138",
        }

        with (
            patch.object(review_submission, "github_repository", return_value="example-org/lunchbox"),
            patch.object(review_submission, "github_pr", return_value=current),
        ):
            result = review_submission.validate_current_pr(validated_sidecar)

        self.assertEqual(current, result)

    def test_current_pr_url_must_match_the_sidecar(self) -> None:
        validated_sidecar = review_submission.validate_sidecar(sidecar("example-org/lunchbox"))
        current = {
            "baseRefName": "staging",
            "headRefOid": "abc123",
            "state": "OPEN",
            "url": "https://github.com/example-org/lunchbox/pull/8675309",
        }

        with (
            patch.object(review_submission, "github_repository", return_value="example-org/lunchbox"),
            patch.object(review_submission, "github_pr", return_value=current),
            self.assertRaisesRegex(review_submission.ValidationError, "PR URL"),
        ):
            review_submission.validate_current_pr(validated_sidecar)

    def test_current_pr_base_must_match_the_sidecar(self) -> None:
        validated_sidecar = review_submission.validate_sidecar(sidecar("example-org/lunchbox"))
        current = {
            "baseRefName": "main",
            "headRefOid": "abc123",
            "state": "OPEN",
            "url": "https://github.com/example-org/lunchbox/pull/1138",
        }

        with (
            patch.object(review_submission, "github_repository", return_value="example-org/lunchbox"),
            patch.object(review_submission, "github_pr", return_value=current),
            self.assertRaisesRegex(review_submission.ValidationError, "PR base"),
        ):
            review_submission.validate_current_pr(validated_sidecar)


if __name__ == "__main__":
    unittest.main()
