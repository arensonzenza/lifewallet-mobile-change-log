# LIFE Wallet Change Log: How It Works

A walkthrough of every `change` command, using a sample project. Run all commands from the root of the LIFE Wallet app repo.

## The idea

Every change is its own small file, and it is filed under the **version+build in `pubspec.yaml` at the moment you add it**. So each version+build has its own changes, and builds never share entries.

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
  release     Mark a version as released (saves the release date)
  unrelease   Removes the released mark from a version
  upgrade     Pulls the latest master branch from GitHub
```

## 2. Add changes (pubspec.yaml has `version: 1.90.0+93`)

```bash
change new added [GH-1900] Add dark mode
change new changed [GH-1822] Update onboarding profile setup screen
change new fixed [GH-1869] Prevent completed onboarding from reappearing
change new security Upgrade encryption library
```

- Valid types: `added`, `changed`, `deprecated`, `fixed`, `removed`, `security`. The default is `fixed`.
- Each call creates one file in `changelog/001090000093/<type>/`. Commit it with your code change.
- Avoid shell special characters such as `*` and `&` in messages.
- If the same message is added twice in the same type, the preview shows it once and keeps the latest.
- `change init` is optional. It only creates the `changelog/unreleased` folders.

## 3. Preview the current build

```bash
change preview
```

```
# What's new?

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

The version comes from `pubspec.yaml`. The date is today until the version is released, then the release date.

## 4. Release (when you submit this build to the store)

```bash
change release 1.90.0+93
git add changelog
git commit -m "chore: release 1.90.0+93 changelog"
git tag v1.90.0+93
```

- This marks the version as released and saves the date in a hidden `.released` file. Commit it.
- Entries do not move. They are already in the version's folder.
- Short versions are padded: `7` and `7.0` become `7.0.0`.
- Releasing a version twice is refused: `1.90.0+93 is already released. Run 'change unrelease 1.90.0+93' first.`

## 5. Next build: new entries go to the new build

Bump `pubspec.yaml` to `1.90.0+94`, then:

```bash
change new fixed [GH-1901] Fix crash when opening notifications
change preview
```

```
# What's new?

## [1.90.0+94] 2026-10-06
### Fixed
- [GH-1901] Fix crash when opening notifications
```

No `change release` or `change init` is needed in between. Before you add the first entry for a new build, `change preview` says `No changes for 1.90.0+94 yet.`

## 6. Preview any other build

```bash
change preview 1.90.0+93
```

```
# What's new?

## [1.90.0+93] 2026-10-06
### Added
- [GH-1900] Add dark mode
...
```

Each version+build has its own preview. The date is the release date saved by `change release`. A build that was never released shows no date.

## 6b. Preview or release every build of a version

Give a version without a build number and each build gets its own section, newest first:

```bash
change preview 1.90.0     # shows 1.90.0+95, 1.90.0+94, 1.90.0+93 separately
change release 1.90.0     # releases every build of 1.90.0, each marked with its own date
change unrelease 1.90.0   # removes the released mark from every build of 1.90.0
```

Give the build number (`change release 1.90.0+94`) to touch only that build. Builds that are already released are skipped with a message.

## 7. Undo a release

```bash
change unrelease 1.90.0+93
```

Removes the released mark and date. The entries stay where they are.

## 8. Upgrade the tool

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
├── 001090000093/         # 1.90.0+93
│   ├── .released         # release date (after `change release`)
│   ├── added/
│   ├── changed/
│   ├── fixed/
│   └── security/
└── 001090000094/         # 1.90.0+94 (current build)
    └── fixed/
```

Versions are stored zero-padded, so `1.90.0+93` becomes `001090000093`.

## Older entries in `changelog/unreleased`

Entries added without a `pubspec.yaml`, or with an older version of this tool, sit in `changelog/unreleased`. `change preview` points them out. Run `change release <version>` to move them into a version.

## What not to do

| Command | Result |
| --- | --- |
| `change release version 7.0` | Wrong. `version` is read as the version and `7.0` is ignored. |
| `change release v7.0` | Wrong. Text in the version is not a number. Use `v` only in the git tag. |
| `change release` | Prints `Version is required`. Nothing is released. |
