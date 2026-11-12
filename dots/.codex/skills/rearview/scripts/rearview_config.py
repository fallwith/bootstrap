#!/usr/bin/env python3
"""Load and create Rearview user configuration."""

from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path
import re
import tomllib
from typing import Any


CONFIG_VERSION = 1
REPOSITORY = re.compile(r"^[A-Za-z0-9][A-Za-z0-9.-]*/[A-Za-z0-9_.-]+$")
OWNER = re.compile(r"^[A-Za-z0-9][A-Za-z0-9.-]*$")
ALIAS = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
PROFILE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
TOP_LEVEL_KEYS = {
    "version",
    "user_attribution",
    "default_owner",
    "codex_profile",
    "cache_root",
    "artifact_root",
    "aliases",
    "owners",
    "repositories",
}
OWNER_KEYS = {"policy_files"}
REPOSITORY_KEYS = {"context_files", "policy_files"}


class ConfigError(Exception):
    """Raised when Rearview configuration is invalid."""


@dataclass(frozen=True)
class Config:
    user_attribution: str
    default_owner: str | None
    codex_profile: str
    cache_root: Path
    artifact_root: Path
    aliases: dict[str, str]
    owners: dict[str, dict[str, Any]]
    repositories: dict[str, dict[str, Any]]

    def resolve_repository(self, value: str) -> str:
        if value in self.aliases:
            return self.aliases[value]
        if "/" in value:
            repository = value
        elif self.default_owner:
            repository = f"{self.default_owner}/{value}"
        else:
            raise ConfigError(
                f"repository {value!r} is not an alias and default_owner is not configured"
            )
        if not REPOSITORY.fullmatch(repository):
            raise ConfigError(f"repository {repository!r} must be owner/name")
        return repository

    def context_files(self, repository: str) -> list[Path]:
        settings = self.repositories.get(repository, {})
        return [expand_path(value) for value in settings.get("context_files", [])]

    def policy_files(self, repository: str) -> list[Path]:
        owner, _ = repository.split("/", 1)
        owner_settings = self.owners.get(owner, {})
        repository_settings = self.repositories.get(repository, {})
        values = [
            *owner_settings.get("policy_files", []),
            *repository_settings.get("policy_files", []),
        ]
        return list(dict.fromkeys(expand_path(value) for value in values))


def config_path() -> Path:
    return Path.home() / ".config" / "rearview" / "config.toml"


def profile_path(profile: str) -> Path:
    return Path.home() / ".codex" / f"{profile}.config.toml"


def default_cache_root() -> Path:
    return Path.home() / ".cache" / "rearview" / "repositories"


def default_artifact_root() -> Path:
    return Path.home() / ".local" / "state" / "rearview" / "reviews"


def expand_path(value: str) -> Path:
    return Path(value).expanduser().resolve()


def require_string(value: Any, label: str, allow_empty: bool = False) -> str:
    if not isinstance(value, str):
        raise ConfigError(f"{label} must be a string")
    result = value.strip()
    if not result and not allow_empty:
        raise ConfigError(f"{label} must not be empty")
    return result


def validate_attribution(value: Any) -> str:
    result = require_string(value, "user_attribution")
    if any(ord(character) > 127 for character in result):
        raise ConfigError("user_attribution must contain only ASCII characters")
    if "&" in result or "--" in result:
        raise ConfigError("user_attribution must contain only the public user label")
    return result


def validate_repository(value: Any, label: str) -> str:
    result = require_string(value, label)
    if not REPOSITORY.fullmatch(result):
        raise ConfigError(f"{label} must be owner/name")
    return result


def validate_files(value: Any, label: str) -> list[str]:
    if not isinstance(value, list) or not all(
        isinstance(item, str) and item.strip() for item in value
    ):
        raise ConfigError(f"{label} must be strings")
    return value


def parse_config(value: Any) -> Config:
    if not isinstance(value, dict):
        raise ConfigError("configuration must be a TOML table")
    extra = sorted(value.keys() - TOP_LEVEL_KEYS)
    if extra:
        raise ConfigError(f"configuration contains unknown keys: {extra}")
    if value.get("version") != CONFIG_VERSION:
        raise ConfigError(f"version must be {CONFIG_VERSION}")

    attribution = validate_attribution(value.get("user_attribution"))
    default_owner_value = value.get("default_owner")
    default_owner = None
    if default_owner_value is not None:
        default_owner = require_string(default_owner_value, "default_owner", allow_empty=True)
        if not default_owner:
            default_owner = None
        elif not OWNER.fullmatch(default_owner):
            raise ConfigError("default_owner contains unsupported characters")

    codex_profile = require_string(value.get("codex_profile", "rearview"), "codex_profile")
    if not PROFILE.fullmatch(codex_profile):
        raise ConfigError("codex_profile contains unsupported characters")

    cache_root = expand_path(
        require_string(value.get("cache_root", str(default_cache_root())), "cache_root")
    )
    artifact_root = expand_path(
        require_string(value.get("artifact_root", str(default_artifact_root())), "artifact_root")
    )

    aliases_value = value.get("aliases", {})
    if not isinstance(aliases_value, dict):
        raise ConfigError("aliases must be a TOML table")
    aliases: dict[str, str] = {}
    for alias, repository in aliases_value.items():
        if not ALIAS.fullmatch(alias):
            raise ConfigError(f"alias {alias!r} contains unsupported characters")
        aliases[alias] = validate_repository(repository, f"aliases.{alias}")

    owners_value = value.get("owners", {})
    if not isinstance(owners_value, dict):
        raise ConfigError("owners must be a TOML table")
    owners: dict[str, dict[str, Any]] = {}
    for owner, settings in owners_value.items():
        if not OWNER.fullmatch(owner):
            raise ConfigError(f"owners.{owner} contains unsupported characters")
        if not isinstance(settings, dict):
            raise ConfigError(f"owners.{owner} must be a TOML table")
        settings_extra = sorted(settings.keys() - OWNER_KEYS)
        if settings_extra:
            raise ConfigError(f"owners.{owner} contains unknown keys: {settings_extra}")
        owners[owner] = {
            "policy_files": validate_files(
                settings.get("policy_files", []),
                f"owners.{owner}.policy_files",
            )
        }

    repositories_value = value.get("repositories", {})
    if not isinstance(repositories_value, dict):
        raise ConfigError("repositories must be a TOML table")
    repositories: dict[str, dict[str, Any]] = {}
    for repository, settings in repositories_value.items():
        validate_repository(repository, f"repositories.{repository}")
        if not isinstance(settings, dict):
            raise ConfigError(f"repositories.{repository} must be a TOML table")
        settings_extra = sorted(settings.keys() - REPOSITORY_KEYS)
        if settings_extra:
            raise ConfigError(
                f"repositories.{repository} contains unknown keys: {settings_extra}"
            )
        repository_settings = {}
        for key in sorted(REPOSITORY_KEYS):
            repository_settings[key] = validate_files(
                settings.get(key, []),
                f"repositories.{repository}.{key}",
            )
        repositories[repository] = repository_settings

    return Config(
        user_attribution=attribution,
        default_owner=default_owner,
        codex_profile=codex_profile,
        cache_root=cache_root,
        artifact_root=artifact_root,
        aliases=aliases,
        owners=owners,
        repositories=repositories,
    )


def load_config(path: Path | None = None) -> Config:
    source = (path or config_path()).expanduser().resolve()
    try:
        with source.open("rb") as stream:
            value = tomllib.load(stream)
    except FileNotFoundError as error:
        raise ConfigError(f"configuration is missing: {source}; run rearview init") from error
    except (OSError, tomllib.TOMLDecodeError) as error:
        raise ConfigError(f"cannot read configuration from {source}: {error}") from error
    return parse_config(value)


def toml_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=True)


def render_config(config: Config) -> str:
    lines = [
        f"version = {CONFIG_VERSION}",
        f"user_attribution = {toml_string(config.user_attribution)}",
        f"codex_profile = {toml_string(config.codex_profile)}",
        f"cache_root = {toml_string(str(config.cache_root))}",
        f"artifact_root = {toml_string(str(config.artifact_root))}",
    ]
    if config.default_owner:
        lines.insert(2, f"default_owner = {toml_string(config.default_owner)}")
    if config.aliases:
        lines.extend(["", "[aliases]"])
        for alias, repository in sorted(config.aliases.items()):
            lines.append(f"{toml_string(alias)} = {toml_string(repository)}")
    for owner, settings in sorted(config.owners.items()):
        lines.extend(["", f"[owners.{toml_string(owner)}]"])
        rendered = ", ".join(
            toml_string(item) for item in settings.get("policy_files", [])
        )
        lines.append(f"policy_files = [{rendered}]")
    for repository, settings in sorted(config.repositories.items()):
        lines.extend(["", f"[repositories.{toml_string(repository)}]"])
        for key in sorted(REPOSITORY_KEYS):
            rendered = ", ".join(toml_string(item) for item in settings.get(key, []))
            lines.append(f"{key} = [{rendered}]")
    return "\n".join(lines) + "\n"


def render_profile() -> str:
    return """default_permissions = "rearview"
approval_policy = "never"

[features]
network_proxy = true

[permissions.rearview]
description = "Disposable PR review worktree with GitHub access."
extends = ":workspace"

[permissions.rearview.network]
enabled = true

[permissions.rearview.network.domains]
"api.github.com" = "allow"
"github.com" = "allow"
"objects.githubusercontent.com" = "allow"
"""
