#!/usr/bin/env bash
# Regenerate the LEEA commodity product approval PDF with embedded diagrams.
# make-pdf writes HTML to /tmp; relative image paths break, so we inline PNGs
# into a temp markdown file (source .md is never mutated).
set -euo pipefail
cd "$(dirname "$0")"
P="${MAKE_PDF_BIN:-$HOME/.claude/skills/gstack/make-pdf/dist/pdf}"
MD="2026-08-10-leea-commodity-product-approval.md"
PDF="2026-08-10-leea-commodity-product-approval.pdf"
INLINE="/tmp/leea-approval-inline.md"

python3 - "$MD" "$INLINE" <<'PY'
import base64, re, sys
from pathlib import Path
src, dst = Path(sys.argv[1]), Path(sys.argv[2])
text = src.read_text()
pattern = re.compile(r'!\[([^\]]*)\]\(([^)]+\.png)\)')
def repl(m):
    alt, path = m.group(1), Path(m.group(2))
    if not path.is_absolute():
        path = Path.cwd() / path
    if not path.exists():
        raise SystemExit(f"missing image: {path}")
    b64 = base64.b64encode(path.read_bytes()).decode("ascii")
    return f"![{alt}](data:image/png;base64,{b64})"
dst.write_text(pattern.sub(repl, text))
print(f"inlined -> {dst}")
PY

# Positional input/output first — flag-first + output path confuses this make-pdf build.
"$P" generate "$INLINE" "$PDF" \
  --cover --toc --no-chapter-breaks \
  --watermark "APPROVAL" \
  --title "LEEA Commodity Product — Approval Brief" \
  --author "Peaceism / LEEA" \
  --date "August 10, 2026" \
  --no-confidential

echo "$PWD/$PDF"
