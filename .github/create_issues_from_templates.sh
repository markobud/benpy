#!/usr/bin/env bash
set -euo pipefail

# Requires: gh (GitHub CLI) authenticated (gh auth login)
# Run from the repository root.

TEMPLATE_DIR=".github/ISSUE_TEMPLATE"
REPO_SLUG="markobud/benpy"

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "Template dir $TEMPLATE_DIR not found" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI 'gh' not found. Install from https://cli.github.com/ and run 'gh auth login'" >&2
  exit 1
fi

# For each template file, strip leading YAML front-matter (--- ... ---),
# apply labels if provided in front-matter, and create a GitHub issue.
for f in "$TEMPLATE_DIR"/*.md; do
  [ -e "$f" ] || { echo "No templates found in $TEMPLATE_DIR" >&2; exit 1; }
  echo "Processing $f"

  # Extract title from 'name:' front-matter if present, else use filename
  name_line=$(grep -E '^name:' "$f" || true)
  if [ -n "$name_line" ]; then
    # name: <title> (possibly quoted)
    title=$(echo "$name_line" | sed -E "s/^name:[[:space:]]*['\"]?(.*)['\"]?/\1/")
  else
    title=$(basename "$f" .md)
  fi

  # Extract labels from front-matter (comma-separated) and build --label args
  # Strip surrounding quotes safely using tr to avoid brittle sed quoting
  labels_line=$(grep -E '^labels:' "$f" | sed -E 's/^labels:[[:space:]]*//' | tr -d '"' | tr -d "'" || true)
  label_args=()
  if [ -n "${labels_line:-}" ]; then
    IFS=',' read -r -a labels_arr <<< "$labels_line"
    for lb in "${labels_arr[@]}"; do
      lb_trim=$(echo "$lb" | xargs)
      [ -n "$lb_trim" ] || continue
      # Ensure label exists; if missing, attempt to create it
      if gh label view "$lb_trim" --repo "$REPO_SLUG" >/dev/null 2>&1; then
        label_args+=(--label "$lb_trim")
      else
        echo "Label '$lb_trim' not found; attempting to create..."
        if gh label create "$lb_trim" --color "ededed" --description "Auto-created by issue creation script" --repo "$REPO_SLUG" >/dev/null 2>&1; then
          echo "Created label '$lb_trim'"
          label_args+=(--label "$lb_trim")
        else
          echo "Warning: could not create label '$lb_trim'. Proceeding without it." >&2
        fi
      fi
    done
  fi

  # Strip YAML front-matter (--- ... ---) using a portable awk state machine.
  # Avoid variable name 'in' (awk keyword) which caused earlier syntax errors.
  awk '
    BEGIN { fm=0 }
    /^---[[:space:]]*$/ { fm = 1 - fm; next }
    fm==0 { print }
  ' "$f" | sed '1{/^$/d}' > /tmp/issue_body.md

  echo "Creating issue: $title"
  if ! gh issue create --title "$title" --body-file /tmp/issue_body.md --repo "$REPO_SLUG" "${label_args[@]}"; then
    echo "Failed to create issue '$title'. Ensure you are authenticated (gh auth login) and have access to $REPO_SLUG." >&2
    continue
  fi
  sleep 1
done

echo "Done. Check https://github.com/$REPO_SLUG/issues for created issues."
