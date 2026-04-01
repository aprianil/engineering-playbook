#!/bin/bash
# Check for unprocessed compound drafts from eng-check.
# Outputs a quiet note if drafts exist -- doesn't interrupt the session.
# Auto-cleans drafts older than 30 days.

DRAFTS_DIR="docs/solutions/.drafts"

if [ -d "$DRAFTS_DIR" ]; then
  # Clean stale drafts (older than 30 days)
  find "$DRAFTS_DIR" -name "*.md" -type f -mtime +30 -delete 2>/dev/null

  # Count remaining drafts
  DRAFT_COUNT=$(find "$DRAFTS_DIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
  if [ "$DRAFT_COUNT" -gt 0 ]; then
    echo "Note: $DRAFT_COUNT compound draft(s) in docs/solutions/.drafts/ from past reviews. Run /eng-compound when you're ready."
  fi
fi
