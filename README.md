# LIFE Wallet Mobile Change Log

A conflict-free changelog tool for the **LIFE Wallet** mobile app (Flutter). This set up for LIFE Wallet only, with support for the Flutter build number (`1.4.0+12`).

It renders release notes in the standard [keepachangelog](https://keepachangelog.com) style.

> **How does it work and how do I use it?** See [how-it-works.md](how-it-works.md) for sample usage of every command with real output.

## Why

A single `CHANGELOG.md` causes merge conflicts when several developers edit it. Here, **every change is its own small file**, so entries never conflict.

## How the two repos work

| Repo | What it holds | Who touches it |
| --- | --- | --- |
| `lifewallet-mobile-change-log` (this repo) | The tool (shell scripts) | Installed once per developer machine into `~/.change` |
| The LIFE Wallet app repo | The `changelog/` folder with the entries | Every developer, with their feature commits |

Run all `change` commands from the **root of the LIFE Wallet app repo**.

## Installation (once per machine)

Requires `git` and `sudo` (macOS/Linux). You need access to the GitHub repo (sign in with GitHub, or use SSH, if it is private).

```bash
git clone https://github.com/arensonzenza/lifewallet-mobile-change-log.git ~/.change
sudo chmod +x ~/.change/changelog.sh
sudo ln -s ~/.change/changelog.sh /usr/local/bin/change
```

This installs the tool into `~/.change` and creates the `change` command in `/usr/local/bin`. Check it works by running `change`.

- "Already exists"? Delete the old copy first: `rm -rf ~/.change`, then run the three commands again.
- `ln: /usr/local/bin/change: File exists`? The command is already linked. Check where it points with `ls -l /usr/local/bin/change`; it should point to `~/.change/changelog.sh`. Use `sudo ln -sf` to replace it.
- Update the tool later with `change upgrade`. It pulls from the repo that `~/.change` was cloned from, so keep the clone URL above.

## Usage

A full walkthrough with sample output is in [how-it-works.md](how-it-works.md).

### 1. Initialize (once per app repo)

```bash
change init
git add changelog && git commit -m "chore: init changelog"
```

Creates `changelog/unreleased/` with `added`, `changed`, `deprecated`, `fixed`, `removed` and `security` folders.

### 2. Add a change (every task)

```bash
change new <type> <message>
```

| Type | Use for |
| --- | --- |
| `added` | New features |
| `changed` | Changes to existing features |
| `deprecated` | Features that will be removed soon |
| `fixed` | Bug fixes (default if no type is given) |
| `removed` | Removed features |
| `security` | Security-related changes |

Examples:

```bash
change new added "[LW-210] Add QR code scan for Send Money"
change new changed "[LW-198] Update Cash In confirmation screen"
change new fixed "[LW-231] Fix wallet balance not refreshing after transfer"
change new security "Upgrade encryption library"
```

Rules:
- Write a short, user-facing sentence and put the ticket ID first, like `[LW-210]`.
- Avoid shell special characters such as `*` and `&` in the message.
- Commit the generated file together with your code change.

### 3. Preview

```bash
change preview               # pending (unreleased) changes
change preview 1.4.0+12      # a released version
```

Output:

```
# What's new?

## Unreleased

## [1.90.0+95] 2026-10-13
### Added
- [LW-210] Add QR code scan for Send Money

### Fixed
- [LW-231] Fix wallet balance not refreshing after transfer
```

#### Version and date in the heading

The heading shows the app version with build number and a date:

- `change preview` (unreleased) reads `version:` from `pubspec.yaml` in the current folder and uses **today's date**, and the output starts with `## Unreleased`, followed by `## [1.90.0+95] 2026-10-13`. Without a `pubspec.yaml` only `## Unreleased` is shown.
- `change preview <version>` (released) starts with `## Release <version>` (the version you released, without the build number), followed by `## [<app version+build>] <date>`. The app version (from `pubspec.yaml`) and the **date it was released** are saved by `change release`. They are saved in hidden `.released` and `.version` files inside the version folder, so commit them.
- Each version+build has its own preview, for example `change preview 1.90.0+93` and `change preview 1.90.0+92`.

### 4. Release (when you submit to the store)

Use the exact version from `pubspec.yaml`, including the build number:

```yaml
# pubspec.yaml
version: 1.4.0+12
```

```bash
change release 1.4.0+12
change init                              # recreate the empty unreleased folders
git add changelog
git commit -m "chore: release 1.4.0+12 changelog"
git tag v1.4.0+12
```

- Bumping the build number in `pubspec.yaml` does **not** change the changelog. Entries stay in `unreleased` until you run `change release`.
- Run `change release` only when you submit. It moves **all** unreleased entries into that version.
- Short versions are padded to three parts: `7` and `7.0` become `7.0.0`, and `7.0+3` becomes `7.0.0+3`. `7.0.0` and `7.0.0+1` stay different versions.
- Only digits, dots and an optional `+build` are valid. Text such as `version_7.0` or `v7.0` is not.
- Use `change preview <version>` to get the notes for the store listing or release notes.

### 5. Undo a release

```bash
change unrelease 1.4.0+12
```

Moves the entries back to `unreleased`.

## Folder structure

In the LIFE Wallet app repo:

```
lifewallet-mobile-app/
├── lib/
├── pubspec.yaml                  # version: 1.5.0+15
└── changelog/
    ├── 001004000012/             # released 1.4.0+12
    │   ├── added/
    │   │   └── 20260915101200    # "Add biometric login"
    │   └── fixed/
    │       └── 20260918161530    # "[LW-231] Fix wallet balance not refreshing"
    ├── 001005000014/             # released 1.5.0+14
    │   └── added/
    │       └── 20260928113045    # "[LW-250] Add transaction history filter"
    └── unreleased/               # pending, next submission
        ├── added/
        │   └── 20261005121500    # "[LW-270] Add dark mode"
        ├── changed/
        ├── deprecated/
        ├── fixed/
        ├── removed/
        └── security/
```

- Each entry file is named with its creation time (`YYYYMMDDHHMMSS`) and contains one line.
- Version folders are zero-padded so they sort correctly: `1.4.0+12` becomes `001004000012`, `1.4.0` becomes `001004000`.

In this tool repo:

```
lifewallet-mobile-change-log/
├── changelog.sh                  # the `change` command
├── changelog-helpers.sh
├── changelog-init.sh
├── changelog-new.sh
├── changelog-preview.sh
├── changelog-release.sh
├── changelog-unrelease.sh
├── changelog-upgrade.sh
├── tools/
│   └── install.sh
├── LICENSE
├── how-it-works.md
└── README.md
```

## Typical workflow

1. Create a feature branch and make the code change.
2. Run `change new <type> <message>` and commit the new file with your code.
3. Open a pull request. Entries never conflict because each is its own file.
4. Bump the build number in `pubspec.yaml` for each build as needed. The changelog is untouched.
5. When submitting to the store: `change release <version+build>`, `change init`, commit, tag.

## Command reference

| Command | Description |
| --- | --- |
| `change init` | Initialize changelog in the current directory |
| `change new <type> <message>` | Register a new change |
| `change preview [version]` | Preview the changelog in Markdown (unreleased if no version) |
| `change release <version>` | Release all unreleased changes as a version |
| `change unrelease <version>` | Revert a released version back to unreleased |
| `change upgrade` | Update the tool to the latest version |

## Duplicates

- If the same message is added more than once in the same type, `change preview` and `change release` show it **once**, keeping the **latest** entry. The older files stay on disk, so delete them if you want a clean folder.
- `change new` never overwrites an entry created in the same second. The new file gets the next free timestamp.
- Messages are compared exactly. `Fix crash` and `Fix crash.` count as different entries.
- The same message in different types (for example `added` and `fixed`) is not treated as a duplicate.
