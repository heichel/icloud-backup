# iCloud Backup Scripts

Small POSIX shell scripts to back up selected iCloud Drive folders with Borg on macOS.

## What it does

For each folder listed in `ICLOUD_BACKUP_DIRS`, the backup script is designed to:

1. Force-download (materialize) iCloud files
2. Run `borg create` to create a new archive in the configured backup repository
3. Evict local copies to free disk space

## Improving the Performance (optional)

Downloading and evicting is done using `brctl` (bird CLI) by default which comes with macOS.

However, `brctl download` just requests the download asynchronously, so files might not be downloaded when Borg accesses them. The backup will still work but Borg seeing files as "changed during backup" while iCloud downloads them lazily. This disturbs the incremental backup functionality leading to Borg potentially backing up every file again the next time and using significantly more storage (see [borg/discussions/8676](https://github.com/borgbackup/borg/discussions/8676)).

To solve this, a custom cloud file manager like [Cloud File CLI (heichel/cloudfile)](https://github.com/heichel/cloudfile) can be used that offers a synchronous option. Just follow the installation instructions and set the `DOWNLOAD_COMMAND` env variable.

## Prerequisites

- macOS (includes `brctl`)
- [BorgBackup](https://www.borgbackup.org/)
- Set up a Borg repository (see [docs](https://borgbackup.readthedocs.io/en/1.4-maint/usage/init.html))
- [1Password CLI (`op`)](https://developer.1password.com/docs/cli/)
- Add item with the Borg repository password to your 1Password vault
- Standard tools: `find`, `sh`
- Optional: [Cloud File CLI (heichel/cloudfile)](https://github.com/heichel/cloudfile)

## Configuration

1. Copy `.env.example` to `.env`.
2. Fill in all required values.

Required variables:

- `BORG_REPO`: Borg repository URL/path
- `OP_REFERENCE_PASSWORD`: 1Password secret reference to the Borg passphrase
- `ICLOUD_BACKUP_DIRS`: newline-delimited list of folder paths inside iCloud Drive

Optional variables:

- `ICLOUD_DRIVE_ROOT`: defaults to
  `$HOME/Library/Mobile Documents/com~apple~CloudDocs`
- `DOWNLOAD_COMMAND`: command used before backup for each file;
  defaults to `brctl download` (recommendation: use `cloudfile materialize-sync`)
- `EVICT_COMMAND`: command used after backup for each file;
  defaults to `brctl evict` (recommendation: use `cloudfile evict`)

Example:

```env
BORG_REPO='ssh://backup/~/iCloud-Test'
OP_REFERENCE_PASSWORD='op://Personal/Borg/credential'
ICLOUD_BACKUP_DIRS='personal
work
Personal/Tax Documents'
ICLOUD_DRIVE_ROOT="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
DOWNLOAD_COMMAND="cloudfile materialize-sync"
EVICT_COMMAND="cloudfile evict"
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
