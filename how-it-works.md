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
- Each call creates one small file. Commit it with your code change.
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

The version comes from `pubspec.yaml` and the date is today. Pending changes start with `## Unreleased`, followed by `## [<version+build>] <date>`. Without a `pubspec.yaml`, only `## Unreleased` is shown.

## 5. Release (when you submit to the store)

```bash
change release 1.90.0+93
change init
git add changelog
git commit -m "chore: release 1.90.0+93 changelog"
git tag v1.90.0+93
```

- Use the exact version from `pubspec.yaml`, including the build number.
- It moves **all** pending entries into that version.
- Run `change init` afterwards to recreate the empty `unreleased` folders.
- Bumping the build number in `pubspec.yaml` does not change the changelog. Entries stay pending until you release.
- Short versions are padded: `7` and `7.0` become `7.0.0`.
- Releasing a version that already exists is refused: `1.90.0+93 is already released. Run 'change unrelease 1.90.0+93' first.`

## 6. Next build: new pending entries

After bumping `pubspec.yaml` to `1.90.0+94`:

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

Each version+build has its own preview. Earlier releases are not mixed in.

## 7. Preview an earlier release

```bash
change preview 1.90.0+93
```

```
# What's new?

## Release 1.90.0

## [1.90.0+93] 2026-10-06
### Added
- [GH-1900] Add dark mode
...
```

`## Release 1.90.0` is the version you released, without the build number. The date is the day `change release` was run, saved in the hidden `.released` file inside the version folder. Commit that file.

## 8. Undo a release

```bash
change unrelease 1.90.0+93
```

Moves the entries back to `unreleased`, merging with any entries already pending. Nothing is overwritten or dropped.

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
├── 001090000093/         # released 1.90.0+93
│   ├── .released         # release date
│   ├── added/
│   ├── changed/
│   ├── fixed/
│   └── security/
└── unreleased/           # pending for the next release
    ├── added/
    ├── changed/
    ├── deprecated/
    ├── fixed/
    ├── removed/
    └── security/
```

Versions are stored zero-padded, so `1.90.0+93` becomes `001090000093`.

## What not to do

| Command | Result |
| --- | --- |
| `change release version 7.0` | Wrong. `version` is read as the version and `7.0` is ignored. |
| `change release v7.0` | Wrong. Text in the version is not a number. Use `v` only in the git tag. |
| `change release` | Prints `Version is required`. Nothing is released. |
