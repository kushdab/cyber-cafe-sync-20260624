# Cyber-Cafe-Sync-20260624

Secure SME automation script for daily encrypted backups to Google Drive. This project ensures that sensitive accounting data is compressed, encrypted locally, and synchronized to cloud storage using industry-standard tools.

## Features
- **Automated Compression**: Gzip-compressed tarballs.
- **AES-256 Encryption**: Symmetric encryption via GPG before any file leaves the server.
- **Rclone Integration**: Reliable multi-threaded upload to Google Drive.
- **Rotation**: Automatic cleanup of local temporary files and remote retention management.
- **Logging**: Detailed execution logs for audit trails.

## Prerequisites
1. **rclone**: Must be configured with a remote named `gdrive-backup`.
   ```bash
   rclone config
   ```
2. **GnuPG**: Required for encryption.
3. **Tar/Gzip**: Standard Linux utilities.

## Setup
1. Create a passphrase file (highly sensitive):
   ```bash
   echo "your-secure-passphrase" > ~/.backup_passphrase
   chmod 600 ~/.backup_passphrase
   ```
2. Update the `SOURCE_DIR` variable in `backup.sh` to point to your accounting files.
3. Ensure the script is executable:
   ```bash
   chmod +x backup.sh
   ```

## Automation
To run daily at 2:00 AM, add to crontab:
```cron
0 2 * * * /path/to/backup.sh >> /var/log/cyber-cafe-cron.log 2>&1
```