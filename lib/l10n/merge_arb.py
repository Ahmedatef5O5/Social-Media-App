#!/usr/bin/env python3
"""Merge the *.arb.additions.json fragments into lib/l10n/app_en.arb and
app_ar.arb (run from the repo root), then run `flutter gen-l10n`.
Existing keys are never overwritten."""
import json, sys
for lang in ("en", "ar"):
    target = f"lib/l10n/app_{lang}.arb"
    add = json.load(open(f"lib/l10n/app_{lang}.arb.additions.json", encoding="utf-8"))
    data = json.load(open(target, encoding="utf-8"))
    added = [k for k in add if k not in data]
    for k in added:
        data[k] = add[k]
    json.dump(data, open(target, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    print(lang, "added", len([k for k in added if not k.startswith('@')]), "keys")
