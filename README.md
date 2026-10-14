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

### 1. Initialize (once per app repo, optional)

```bash
change init
```

Creates `changelog/unreleased/` with `added`, `changed`, `deprecated`, `fixed`, `removed` and `security` folders. You don't need it when your app has a `pubspec.yaml`, because entries are filed under the pubspec version automatically.

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
change new added [LW-210] Add QR code scan for Send Money
change new changed [LW-198] Update Cash In confirmation screen
change new fixed [LW-231] Fix wallet balance not refreshing after transfer
change new security Upgrade encryption library
```

Rules:
- The entry is filed under the **version+build in `pubspec.yaml` at the moment you add it**. Bump the pubspec to the next build, and new entries go to the new build automatically. Builds never share entries.
- Write a short, user-facing sentence and put the ticket ID first, like `[LW-210]`.
- Avoid shell special characters such as `*` and `&` in the message.
- Commit the generated file together with your code change.
- Without a `pubspec.yaml`, entries go to `changelog/unreleased`.

### 3. Preview

```bash
change preview                 # the version+build in pubspec.yaml
change preview 1.90.0+93       # any other version+build
```

Output:

```
# What's new?

## [1.90.0+94] 2026-10-06
### Fixed
- [GH-1901] Fix crash when opening notifications
```

- Each version+build has its own preview. Entries from other builds are never mixed in.
- With no version, the preview uses the version from `pubspec.yaml`. If that build has no entries yet, it says `No changes for 1.90.0+94 yet.`
- The date is the release date if the version was released, otherwise today for the version you are working on.
- Short versions are padded: `change preview 2` shows `2.0.0`.

### 4. Release (when you submit to the store)

```bash
change release 1.90.0+93
git add changelog
git commit -m "chore: release 1.90.0+93 changelog"
git tag v1.90.0+93
```

- This marks the version as released and saves the release date in a hidden `.released` file. Commit it.
- Entries do **not** move. They are already in the version's folder because they were filed there when added.
- If `changelog/unreleased` still holds entries (for example added before the pubspec was set up), `change release` moves them into that version.
- Releasing a version twice is refused until you run `change unrelease`.
- Use the full pubspec version. `7` and `7.0` are padded to `7.0.0`. Text such as `version_7.0` or `v7.0` is not valid.

### 5. Undo a release

```bash
change unrelease 1.90.0+93
```

Removes the released mark and date. The entries stay where they are.

## Folder structure

In the LIFE Wallet app repo:

```
lifewallet-mobile-app/
├── lib/
├── pubspec.yaml                  # version: 1.90.0+94
└── changelog/
    ├── 001090000093/             # 1.90.0+93 (released)
    │   ├── .released             # release date
    │   ├── added/
    │   │   └── 20261006101500    # "[GH-1900] Add dark mode"
    │   └── fixed/
    │       └── 20261006101930    # "[GH-1869] Prevent completed onboarding from reappearing"
    └── 001090000094/             # 1.90.0+94 (current build, not released yet)
        └── fixed/
            └── 20261006123905    # "[GH-1901] Fix crash when opening notifications"
```

- Each entry file is named with its creation time (`YYYYMMDDHHMMSS`) and contains one line.
- Version folders are zero-padded so they sort correctly: `1.90.0+93` becomes `001090000093`.
- `changelog/unreleased/` is only used when there is no `pubspec.yaml`, or for entries added before that.

## Typical workflow

1. Create a feature branch and make the code change.
2. Run `change new <type> <message>` and commit the new file with your code.
3. Open a pull request. Entries never conflict because each is its own file.
4. Bump the build number in `pubspec.yaml` for the next build. New entries then go to the new build automatically.
5. When submitting a build to the store: `change release <version+build>`, commit, tag.

## Command reference

| Command | Description |
| --- | --- |
| `change init` | Create the `changelog/unreleased` folders (optional) |
| `change new <type> <message>` | Add a change under the pubspec version+build |
| `change preview [version]` | Preview a version+build (no build number = every build of it, one section each) (default: the one in pubspec.yaml) |
| `change release <version>` | Mark a version+build as released with today's date |
| `change unrelease <version>` | Remove the released mark |
| `change upgrade` | Update the tool to the latest version |

## Duplicates

- If the same message is added more than once in the same type, `change preview` and `change release` show it **once**, keeping the **latest** entry. The older files stay on disk, so delete them if you want a clean folder.
- `change new` never overwrites an entry created in the same second. The new file gets the next free timestamp.
- Messages are compared exactly. `Fix crash` and `Fix crash.` count as different entries.
- The same message in different types (for example `added` and `fixed`) is not treated as a duplicate.
