"""Check local documentation links and images before publishing (Python 3)."""

from pathlib import Path
import re
import sys
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[1] / "docs-site"


def main():
    errors = []
    checked = 0
    for page in ROOT.rglob("*.md"):
        text = page.read_text(encoding="utf-8")
        text = re.sub(r"```.*?```", "", text, flags=re.S)
        targets = re.findall(r"!?\[[^\]]*\]\(([^\s)]+)", text)
        targets += re.findall(r'(?:src|href)="([^\"]+)"', text)
        for target in targets:
            url = urlsplit(target)
            if url.scheme or url.netloc or not url.path:
                continue
            path = unquote(url.path)
            resolved = ((ROOT / path.lstrip("/")) if path.startswith("/")
                        else (page.parent / path)).resolve()
            if resolved.is_dir():
                resolved /= "README.md"
            checked += 1
            if not resolved.is_relative_to(ROOT.resolve()) or not resolved.is_file():
                errors.append(f"{page.relative_to(ROOT)}: missing target {target}")
    for error in errors:
        print(error, file=sys.stderr)
    print(f"Checked {checked} local documentation links and images; {len(errors)} errors.")
    return bool(errors)


if __name__ == "__main__":
    sys.exit(main())
