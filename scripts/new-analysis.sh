#!/usr/bin/env sh
# Start a new analysis folder from the template.
#   scripts/new-analysis.sh my-topic "My topic title"
# Creates analysis/YYYY-MM-my-topic/index.qmd with today's date filled in.
set -eu

slug="${1:?usage: new-analysis.sh <slug> [title]}"
title="${2:-$(printf '%s' "$slug" | sed 's/-/ /g; s/^./\U&/')}"
author="${ANALYSIS_AUTHOR:-$(git config user.name 2>/dev/null || echo "Platform Architecture")}"
today="$(date +%Y-%m-%d)"
dir="analysis/$(date +%Y-%m)-$slug"

if [ -e "$dir" ]; then
  echo "already exists: $dir" >&2
  exit 1
fi

cp -r analysis/_template "$dir"
sed -i.bak \
  -e "s|^title: \"TITLE\"|title: \"$title\"|" \
  -e "s|^author: \"AUTHOR\"|author: \"$author\"|" \
  -e "s|^date: DATE|date: $today|" \
  "$dir/index.qmd"
rm -f "$dir/index.qmd.bak"
echo "created $dir/index.qmd"
