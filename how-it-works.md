# LIFE Wallet Change Log: Sample Usage

A walkthrough of every `change` command, using a sample project whose `pubspec.yaml` has `version: 1.90.0+93`. Run all commands from the root of the LIFE Wallet app repo.

## 1. List the commands

```bash
change
```

```
usage: change <command> [<args>]

These are the available commands:

  init        Initialize changelog in current directory
  new         Register new change in the changelog
  preview     Preview the changelog in Markdown format
  release     Release the changes for the current version
  unrelease   Reverts the changes from the version specified back to unreleased
  upgrade     Pulls the latest master branch from GitHub
```

## 2. Initialize (once per app repo)

```bash
change init
```

Creates `changelog/unreleased/` with `added`, `changed`, `deprecated`, `fixed`, `removed` and `security` folders. Commit it.

## 3. Add changes

```bash
change new added [GH-1900] Add dark mode
change new changed [GH-1822] Update onboarding profile setup screen
change new fixed [GH-1869] Prevent completed onboarding from reappearing
change new security Upgrade encryption library
```

- Valid types: `added`, `changed`, `deprecated`, `fixed`, `removed`, `security`. The default is `fixed`.
- Each call creates one small file in `changelog/unreleased/<version+build>/<type>/`, using the version+build in `pubspec.yaml` at that moment. It is always unreleased. Commit it with your code change.
- Avoid shell special characters such as `*` and `&` in messages.
- If the same message is added twice in the same type, the preview shows it once and keeps the latest.

## 4. Preview pending changes

```bash
change preview
```

```
# What's new?

## Unreleased

## [1.90.0+93] 2026-10-06
### Added
- [GH-1900] Add dark mode

### Changed
- [GH-1822] Update onboarding profile setup screen

### Fixed
- [GH-1869] Prevent completed onboarding from reappearing

### Security
- Upgrade encryption library
```

Pending changes start with `## Unreleased`. Then every version+build that has pending entries gets its own section, newest build first (see step 6). The date is the date of the newest entry in that build.

## 5. Release (when you submit to the store)

```bash
change release 1.90.0+93
git add changelog
git commit -m "chore: release 1.90.0+93 changelog"
git tag v1.90.0+93
```

- `change release 1.90.0` releases every pending build of 1.90.0 (for example +93 and +94) into `changelog/001090000/`. Each build keeps its own section.
- `change release 1.90.0+93` releases only that build.
- Entries added without a version+build (older style) go along with `change release 1.90.0`.
- Bumping the build number in `pubspec.yaml` does not release anything. Entries stay unreleased until you release.
- Short versions are padded: `7` and `7.0` become `7.0.0`.
- `Nothing to release for X.` is printed when no pending entry matches.

## 6. Next build: new pending entries

After bumping `pubspec.yaml` to `1.90.0+94`:

```bash
change new fixed [GH-1901] Fix crash when opening notifications
change preview
```

```
# What's new?

## Unreleased

## [1.90.0+94] 2026-10-07
### Fixed
- [GH-1901] Fix crash when opening notifications

## [1.90.0+93] 2026-10-06
### Added
- [GH-1900] Add dark mode
```

Each version+build is its own section under `## Unreleased`, so entries of +93 and +94 never mix.

## 7. Preview an earlier release

```bash
change preview 1.90.0+93
```

```
# What's new?

## Release 1.90.0

## [1.90.0+94] 2026-10-07
### Fixed
- [GH-1901] Fix crash when opening notifications

## [1.90.0+93] 2026-10-06
### Added
- [GH-1900] Add dark mode
```

`change preview 1.90.0` shows `## Release 1.90.0` and every build released under it, each in its own section. `change preview 1.90.0+93` shows only that build. The release date is saved in the hidden `.released` file in the version folder. Commit it.

## 8. Undo a release

```bash
change unrelease 1.90.0+93
```

Moves that build back into `changelog/unreleased/`, merging with entries already pending there. `change unrelease 1.90.0` moves every build of 1.90.0. Nothing is overwritten or dropped.

## 9. Upgrade the tool

```bash
change upgrade
```

Pulls the latest version of this repo into `~/.change`. If it doesn't update, check that `~/.change` points to your repo:

```bash
git -C ~/.change remote -v
```

## Folder structure

```
changelog/
├── 001090000/                # released 1.90.0
│   ├── .released             # release date
│   ├── 001090000093/         # build 93
│   │   ├── added/
│   │   └── fixed/
│   └── 001090000094/         # build 94
│       └── fixed/
└── unreleased/               # not released yet
    └── 001090000095/         # build 95 (current)
        ├── added/
        └── security/
```

Versions are stored zero-padded, so `1.90.0+93` becomes `001090000093` and `1.90.0` becomes `001090000`.

## What not to do

| Command | Result |
| --- | --- |
| `change release version 7.0` | Wrong. `version` is read as the version and `7.0` is ignored. |
| `change release v7.0` | Wrong. Text in the version is not a number. Use `v` only in the git tag. |
| `change release` | Prints `Version is required`. Nothing is released. |
