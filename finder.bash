#!/bin/bash

# Threshold in bytes: change this to your desired size
THRESHOLD=$((0.5 * 1024 * 1024))  # 0.5 MiB

OUTPUT_FILE="large_blobs.txt"

echo "Scanning for large Git blobs (> $THRESHOLD bytes)..."
echo "" > "$OUTPUT_FILE"  # Clear output file

# Step 1: Get all blob objects from all commits
git rev-list --objects --all \
| cut -d' ' -f1 \
| git cat-file --batch-check='%(objectname) %(objecttype) %(objectsize)' \
| awk '$2 == "blob" { print $1, $3 }' \
| awk -v threshold="$THRESHOLD" '$2 > threshold' \
| sort -k2 -n -r \
| while read hash size; do
    # Get the file path (if available)
    path=$(git rev-list --objects --all | grep "^$hash" | cut -d' ' -f2-)
    echo "$size bytes - $hash - $path"
    echo "$hash" >> "$OUTPUT_FILE"
done

echo "Hashes of large blobs saved to $OUTPUT_FILE"