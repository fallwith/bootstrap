from __future__ import annotations

from pathlib import Path
import sys
import tempfile
import tomllib
import unittest


SCRIPT_DIRECTORY = Path(__file__).parents[1] / "scripts"
if str(SCRIPT_DIRECTORY) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIRECTORY))

import rearview_config  # noqa: E402


def config_value(root: Path) -> dict:
    return {
        "version": 1,
        "user_attribution": "Example User",
        "default_owner": "example-org",
        "codex_profile": "rearview",
        "cache_root": str(root / "cache"),
        "artifact_root": str(root / "reviews"),
        "aliases": {"web": "example-org/web"},
        "owners": {
            "example-org": {
                "policy_files": [str(root / "organization-policy.md")],
            }
        },
        "repositories": {
            "example-org/web": {
                "context_files": [str(root / "web-context.md")],
                "policy_files": [str(root / "web-policy.md")],
            }
        },
    }


class RearviewConfigTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory(dir="/tmp")
        self.addCleanup(self.temporary_directory.cleanup)
        self.root = Path(self.temporary_directory.name)

    def test_repository_resolution_supports_alias_owner_and_default_owner(self) -> None:
        config = rearview_config.parse_config(config_value(self.root))

        self.assertEqual("example-org/web", config.resolve_repository("web"))
        self.assertEqual("other/repository", config.resolve_repository("other/repository"))
        self.assertEqual("example-org/api", config.resolve_repository("api"))

    def test_repository_without_owner_requires_an_alias_or_default_owner(self) -> None:
        value = config_value(self.root)
        value["default_owner"] = ""
        config = rearview_config.parse_config(value)

        with self.assertRaisesRegex(rearview_config.ConfigError, "default_owner"):
            config.resolve_repository("api")

    def test_attribution_rejects_a_complete_signoff(self) -> None:
        value = config_value(self.root)
        value["user_attribution"] = "Codex & Example User"

        with self.assertRaisesRegex(rearview_config.ConfigError, "public user label"):
            rearview_config.parse_config(value)

    def test_unknown_repository_setting_is_rejected(self) -> None:
        value = config_value(self.root)
        value["repositories"]["example-org/web"]["unexpected"] = True

        with self.assertRaisesRegex(rearview_config.ConfigError, "unknown keys"):
            rearview_config.parse_config(value)

    def test_unknown_owner_setting_is_rejected(self) -> None:
        value = config_value(self.root)
        value["owners"]["example-org"]["unexpected"] = True

        with self.assertRaisesRegex(rearview_config.ConfigError, "unknown keys"):
            rearview_config.parse_config(value)

    def test_rendered_config_round_trips_through_toml(self) -> None:
        config = rearview_config.parse_config(config_value(self.root))

        rendered = rearview_config.render_config(config)
        reparsed = rearview_config.parse_config(tomllib.loads(rendered))

        self.assertEqual(config, reparsed)

    def test_repository_files_are_resolved_by_role(self) -> None:
        config = rearview_config.parse_config(config_value(self.root))

        self.assertEqual(
            [(self.root / "web-context.md").resolve()],
            config.context_files("example-org/web"),
        )
        self.assertEqual(
            [
                (self.root / "organization-policy.md").resolve(),
                (self.root / "web-policy.md").resolve(),
            ],
            config.policy_files("example-org/web"),
        )

    def test_owner_policy_applies_to_every_repository_for_that_owner(self) -> None:
        config = rearview_config.parse_config(config_value(self.root))

        self.assertEqual(
            [(self.root / "organization-policy.md").resolve()],
            config.policy_files("example-org/api"),
        )

    def test_duplicate_owner_and_repository_policy_is_loaded_once(self) -> None:
        value = config_value(self.root)
        policy = str(self.root / "organization-policy.md")
        value["repositories"]["example-org/web"]["policy_files"].insert(0, policy)
        config = rearview_config.parse_config(value)

        self.assertEqual(
            [
                (self.root / "organization-policy.md").resolve(),
                (self.root / "web-policy.md").resolve(),
            ],
            config.policy_files("example-org/web"),
        )

    def test_rendered_profile_is_noninteractive_and_github_scoped(self) -> None:
        rendered = rearview_config.render_profile()
        parsed = tomllib.loads(rendered)

        self.assertEqual("never", parsed["approval_policy"])
        self.assertEqual(":workspace", parsed["permissions"]["rearview"]["extends"])
        self.assertEqual(
            {
                "api.github.com": "allow",
                "github.com": "allow",
                "objects.githubusercontent.com": "allow",
            },
            parsed["permissions"]["rearview"]["network"]["domains"],
        )


if __name__ == "__main__":
    unittest.main()
