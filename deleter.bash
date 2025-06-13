#!/bin/bash

# File containing blob hashes (one per line)
HASH_FILE="large_blobs.txt"

if [[ ! -f "$HASH_FILE" ]]; then
  echo "Error: Hash file '$HASH_FILE' not found!"
  exit 1
fi

echo "Reading blob hashes from $HASH_FILE ..."

# Build the index-filter commands to remove files by blob hash
index_filter_cmd=""

while read -r blob; do
  # Skip empty lines or comments
  [[ -z "$blob" || "$blob" == \#* ]] && continue

  # Append command to remove files with this blob hash from index
  index_filter_cmd+="
    git ls-files -s | awk '\$2==\"$blob\" {print \$4}' | xargs -r git rm --cached --ignore-unmatch;
  "
done < "$HASH_FILE"

if [[ -z "$index_filter_cmd" ]]; then
  echo "No valid blob hashes found in $HASH_FILE."
  exit 1
fi

echo "Rewriting Git history to remove these blobs..."

git filter-branch --force --index-filter "
  $index_filter_cmd
" -- --all

echo "Done rewriting history."
echo "Run 'git gc --prune=now --aggressive' to clean up dangling objects."
echo "Force push branches/tags if you want to update remote:"
echo "  git push --force --all"
echo "  git push --force --tags"
