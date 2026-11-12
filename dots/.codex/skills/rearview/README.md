# Rearview

Rearview reviews, previews, and publishes one GitHub pull request. It performs
read-only review work autonomously, then asks once before publishing.

## Requirements

- Git
- GitHub CLI (`gh`) authenticated for the review target
- Codex CLI installed and configured for use
- Python 3.11 or newer, available as `python3`
- A personal or organization agent policy that permits explicitly requested
  pull request content to enter agent context

Rearview never modifies that privacy policy automatically.
macOS is tested; other platforms are unverified.
The Python scripts use only the standard library.

## Install

For a new installation, extract the supplied archive:

```sh
mkdir -p ~/.codex/skills
tar -xzf /path/to/rearview.tar.gz -C ~/.codex/skills
```

The installed directory must contain `~/.codex/skills/rearview/SKILL.md`.
Alternatively, symlink `~/.codex/skills/rearview` to a source checkout.
Keep the entire skill directory together, including `scripts` and `references`.

Confirm the Python version, then initialize and verify the installation:

```sh
python3 --version
python3 ~/.codex/skills/rearview/scripts/rearviewcodex.py init
python3 ~/.codex/skills/rearview/scripts/rearviewcodex.py doctor
```

Use Python 3.11 or newer for every command in this guide.
If GitHub CLI needs authentication, run `gh auth login` in your terminal first.
`init` asks for your public attribution label.
The default GitHub owner and repository aliases are optional.

`init` creates:

- `~/.config/rearview/config.toml`
- `~/.codex/rearview.config.toml`
- configured cache and artifact directories

It refuses to replace existing files without confirmation.
Keep these configuration files outside the shared skill directory.
For an existing installation, retain your configuration when updating the skill.

Test fresh Git access to a repository you can read:

```sh
python3 ~/.codex/skills/rearview/scripts/rearviewcodex.py doctor \
  --git-only --repository owner/repository
```

This check can take up to 60 seconds.
It covers your terminal; repeat it inside a review session to check its sandbox.

## Optional shell shortcut

The Python commands work without shell customization.
For Fish, save this function as `~/.config/fish/functions/rearview.fish`:

```fish
function rearview --description 'Review and optionally publish a GitHub pull request'
  python3 ~/.codex/skills/rearview/scripts/rearviewcodex.py $argv
end
```

The examples below use this optional `rearview` shortcut.
Without it, use `python3 ~/.codex/skills/rearview/scripts/rearviewcodex.py`
followed by the same arguments.

## Usage

Run from any directory:

```sh
rearview owner/repository 123
rearview repository-alias 123
```

For example, without the shortcut:

```sh
python3 ~/.codex/skills/rearview/scripts/rearviewcodex.py owner/repository 123
```

Rearview creates a detached worktree from its private bare cache.
The first active review for a repository uses a stable worktree path.
Codex can reuse the saved folder-trust decision for that path.
The first review of a repository may ask you to trust that folder.
Later reviews reuse it.

Concurrent reviews for the same repository use isolated temporary worktrees.
Each overflow review may ask you to trust its temporary folder.
Rearview removes every checkout when Codex exits.
Review reports and previews remain under the configured artifact root.

The normal interaction is one publication gate. The gate shows the reviewed
commit, event recommendation, comment count, inline locations, and preview.
Reply with a publication decision, a stop request, or unambiguous revisions.
`Publish` and `Publish all` authorize the review and every previewed reply.
`Review only` authorizes the review and explicitly excludes every reply.
Both publication aliases also work when there are no replies.

For any proposed event, the exact response `Approve instead`
means `Publish all` with the event switched to `APPROVE`, recasts blockers as
suggestions, applies an encouraging and upbeat tone, skips another preview, and
publishes the revised review and every previewed reply after freshness checks.
It requires no further preview or inclusion question.
The shorthand does not apply as part of a longer response.

If the pull request advances after approval, Rearview invalidates the approval,
reviews the new head completely, and presents a new gate.

## Configuration

Example:

```toml
version = 1
user_attribution = "Example User"
default_owner = "example-org"
codex_profile = "rearview"
cache_root = "/Users/example/.cache/rearview/repositories"
artifact_root = "/Users/example/.local/state/rearview/reviews"

[aliases]
web = "example-org/web"

[owners."example-org"]
policy_files = [
  "/Users/example/.config/rearview/policies/example-org.md",
]

[repositories."example-org/web"]
policy_files = [
  "/Users/example/.agents/web-personal.md",
]
context_files = [
  "/Users/example/.config/rearview/contexts/web.md",
]
```

Bare repository arguments use `default_owner`. Values containing `/` are exact
GitHub repository names. Aliases take precedence over both.

Owner policy files apply to every repository under that GitHub owner.
Repository policy files add instructions for one repository. Rearview loads
owner policies first, then repository policies, and loads duplicate paths
once. Repository context files provide mappings and supporting guidance. All
applicable files are copied into the disposable session directory before
Codex starts. Keep company names, local repository maps, and other private
conventions there instead of the shared skill.

## Privacy policy

Rearview must read complete pull request discussion. Each installation needs an
applicable higher-priority policy permitting that content. A narrow policy can
allow content from explicitly requested internal pull requests while retaining
prohibitions for secrets, credentials, environment variables, databases,
consoles, logs, runtime API responses, and unrelated identity fields.

Configuration cannot relax agent privacy rules. Do not add a TOML switch that
claims otherwise.

## Follow-up reviews

Rearview identifies its earlier reviews from GitHub. It evaluates their inline
threads and later replies, then reviews the complete current pull request diff.
Local reports never establish follow-up state.

When history was rewritten, Rearview reports that fact and skips incremental
claims. It still reviews the complete current diff.

## Troubleshooting

Run:

```sh
rearview doctor
```

The command checks executables, GitHub API access, skill discovery,
configuration, the Codex profile, and writable cache and artifact paths. It
does not print GitHub identity data or inspect environment variables.
API access alone does not establish Git access.
Test a fresh HTTPS clone with `rearview doctor --repository owner/repository`.
The probe uses a new temporary directory and removes it on success or failure.
It reports only a classified transport error, without raw Git output.
Each HTTPS Git command has a 60-second timeout.
The result covers the calling process only.
Inside the review session, test only Git access:

```sh
rearview doctor --git-only --repository owner/repository
```

`--git-only` requires an exact owner/repository, without aliases.
It does not load wrapper configuration or test wrapper directories.
Its exit code reports only the fresh-clone result.
The full doctor requires write access to the shared cache and artifact roots.
Review sessions need the current artifact directory and disposable companions;
they do not need write access to those broader roots.
Installed profiles and managed policies can differ from the generated profile.

For a needed companion, the review uses `rearview companion` with an immutable
commit and a destination beneath its disposable companion directory.
This command fetches one commit over HTTPS using GitHub CLI credentials.
Its command-scoped URL alias avoids installed HTTPS-to-SSH rewrites.
It does not modify global Git or SSH configuration or sandbox permissions.
The detached checkout is shallow and has no parent history.
Sandbox network restrictions and unavailable GitHub CLI credentials still apply.
The wrapper's initial bare cache and ref preparation run before Codex starts;
their success does not establish sandbox Git access.

## Sharing

On macOS, create the archive from the real source directory's parent:

```sh
tar -czf /tmp/rearview.tar.gz \
  --no-mac-metadata \
  --exclude='*.pyc' \
  --exclude='*/__pycache__' \
  -C /path/to/skills rearview
```

When the installed skill is a symlink, use its source parent for `-C`.
Archiving the installed symlink itself would require its target
on the recipient's machine.
The archive contains the skill, scripts, references, and tests.
Each recipient runs `init` to create their own configuration and attribution.
