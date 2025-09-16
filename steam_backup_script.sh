#!/bin/bash

# Steam Library Backup Script
# Backs up Steam library to external drive, ignoring existing files

# Configuration - Modify these paths as needed
STEAM_DIR="$HOME/.local/share/Steam/steamapps"  # Default Linux Steam directory
# STEAM_DIR="$HOME/Library/Application Support/Steam"  # macOS Steam directory
# STEAM_DIR="/c/Program Files (x86)/Steam"  # Windows Steam directory (if using WSL/Git Bash)

BACKUP_DIR="/run/media/sean/VAULT/steamapps"  # Change this to your external drive mount point
LOG_FILE="$HOME/steam_backup.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Steam directory exists
if [ ! -d "$STEAM_DIR" ]; then
    print_error "Steam directory not found: $STEAM_DIR"
    print_error "Please modify STEAM_DIR in the script to point to your Steam installation"
    exit 1
fi

# Check if backup directory parent exists
BACKUP_PARENT=$(dirname "$BACKUP_DIR")
if [ ! -d "$BACKUP_PARENT" ]; then
    print_error "Backup parent directory not found: $BACKUP_PARENT"
    print_error "Please ensure your external drive is mounted and modify BACKUP_DIR"
    exit 1
fi

# Create backup directory if it doesn't exist
if [ ! -d "$BACKUP_DIR" ]; then
    print_status "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
fi

# Start backup process
print_status "Starting Steam library backup..."
print_status "Source: $STEAM_DIR"
print_status "Destination: $BACKUP_DIR"
print_status "Log file: $LOG_FILE"

# Get initial disk usage
INITIAL_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1 || echo "0")
print_status "Current backup size: $INITIAL_SIZE"

# Record start time
START_TIME=$(date)
echo "=== Steam Backup Started: $START_TIME ===" >> "$LOG_FILE"

# rsync command with options:
# -a: Archive mode (preserves permissions, timestamps, etc.)
# -v: Verbose output
# -h: Human-readable numbers
# --ignore-existing: Skip files that exist in destination (key for Steam's timestamp issues)
# --progress: Show progress during transfer
# --log-file: Log to file
# --exclude: Exclude unnecessary files/directories

rsync -avh \
    --ignore-existing \
    --progress \
    --log-file="$LOG_FILE" \
    --no-links \
    --exclude='logs/' \
    --exclude='dumps/' \
    --exclude='appcache/httpcache/' \
    --exclude='userdata/*/7/' \
    --exclude='*.tmp' \
    --exclude='*.log' \
    "$STEAM_DIR/" \
    "$BACKUP_DIR/"

# Check rsync exit status
RSYNC_EXIT=$?
END_TIME=$(date)

if [ $RSYNC_EXIT -eq 0 ]; then
    print_success "Backup completed successfully!"

    # Get final disk usage
    FINAL_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1 || echo "Unknown")
    print_success "Final backup size: $FINAL_SIZE"

    echo "=== Steam Backup Completed Successfully: $END_TIME ===" >> "$LOG_FILE"

elif [ $RSYNC_EXIT -eq 23 ] || [ $RSYNC_EXIT -eq 24 ]; then
    print_warning "Backup completed with warnings (some files/attrs could not be transferred)"
    print_warning "This is normal for Steam - likely due to symlinks on incompatible filesystem"
    echo "=== Steam Backup Completed with Warnings: $END_TIME ===" >> "$LOG_FILE"

else
    print_error "Backup failed with exit code: $RSYNC_EXIT"
    echo "=== Steam Backup Failed: $END_TIME (Exit Code: $RSYNC_EXIT) ===" >> "$LOG_FILE"
    exit $RSYNC_EXIT
fi

print_status "Check $LOG_FILE for detailed backup information"
print_status "Backup started: $START_TIME"
print_status "Backup finished: $END_TIME"
