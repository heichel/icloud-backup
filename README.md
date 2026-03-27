# iCloud Backup Scripts

Small POSIX shell scripts to back up selected iCloud Drive folders with Borg on macOS.

## What it does

For each folder listed in `ICLOUD_BACKUP_DIRS`, the backup script is designed to:

1. Force-download iCloud files with `brctl download`
2. Run `borg create` into your configured repository
3. Evict local copies with `brctl evict` to free disk space

This avoids Borg seeing files as "changed during backup" while iCloud downloads them lazily.

## Prerequisites

- macOS (uses `brctl`)
- [BorgBackup](https://www.borgbackup.org/)
- [1Password CLI (`op`)](https://developer.1password.com/docs/cli/)
- Standard tools: `find`, `sh`

## Configuration

1. Copy `.env.example` to `.env`.
2. Fill in all required values.

Required variables:

- `BORG_REPO`: Borg repository URL/path
- `OP_REFERENCE_PASSWORD`: 1Password secret reference to the Borg passphrase
- `ICLOUD_BACKUP_DIRS`: newline-delimited list of folder paths inside iCloud Drive

Optional variable:

- `ICLOUD_DRIVE_ROOT`: defaults to
  `$HOME/Library/Mobile Documents/com~apple~CloudDocs`

Example:

```env
BORG_REPO='ssh://backup/~/iCloud-Test'
OP_REFERENCE_PASSWORD='op://Personal/Borg/credential'
ICLOUD_BACKUP_DIRS='personal
work
Personal/Tax Documents'
```

## Usage

Run from the repository root:

```sh
sh backup.sh
```

The script loads `.env`, reads `BORG_PASSPHRASE` via `op read`, then processes each configured folder.

## Notes

- `ICLOUD_BACKUP_DIRS` is newline-delimited so paths can include spaces.
- Missing folders are skipped with an error message.
- Archive names use local timestamp format: `YYYY-MM-DDTHH-MM-SS`.
