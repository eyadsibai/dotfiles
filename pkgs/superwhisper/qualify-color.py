# From Omarchy's superwhisper-bin PKGBUILD: Qt 6.12 adds a Color type that
# shadows Omarchy's palette singleton, so qualify it as Commons.Color.
from pathlib import Path
import re
import sys

for path in Path(sys.argv[1]).glob("*.qml"):
  original = path.read_text()
  updated = re.sub(r"(?<![\w.])Color\b", "Commons.Color", original)
  if updated != original:
    alias = r"(?m)^import qs\.Commons(?: [0-9.]+)? as Commons[ \t]*$"
    if not re.search(alias, updated):
      updated, imports = re.subn(r"(?m)^(import qs\.Commons(?: [0-9.]+)?[ \t]*)$", r"\1\nimport qs.Commons as Commons", updated, count=1)
      if imports != 1:
        raise SystemExit(f"Cannot qualify palette import in {path}")
    if len(re.findall(alias, updated)) != 1 or re.search(r"(?<![\w.])Color\b", updated):
      raise SystemExit(f"Invalid palette references in {path}")
    path.write_text(updated)
