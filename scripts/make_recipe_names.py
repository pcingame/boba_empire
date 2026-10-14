#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sinh assets/recipes/names.json từ scripts/data/recipe_names.py (và kiểm đủ/khớp với recipes.json).
Chạy:  python3 scripts/make_recipe_names.py"""
import json, pathlib, sys
root = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(root / 'scripts/data'))
import recipe_names as rn

data = json.loads((root / 'assets/recipes/recipes.json').read_text(encoding='utf-8'))
ids = {r['id'] for r in data['recipes']}
gids = {g['id'] for g in data['groups']}
ings = {i['name'] for r in data['recipes'] for i in r['ingredients']}
for label, have, need in [('món', set(rn.RECIPES), ids), ('nhóm', set(rn.GROUPS), gids), ('nguyên liệu', set(rn.INGREDIENTS), ings)]:
    if have != need:
        sys.exit(f'Thiếu/thừa {label}: thiếu {sorted(need - have)}, thừa {sorted(have - need)}')
out = {}
for k, lang in enumerate(rn.LANGS):
    for table in (rn.GROUPS, rn.RECIPES, rn.INGREDIENTS):
        for key, v in table.items():
            if len(v) != len(rn.LANGS) or not v[k].strip():
                sys.exit(f'Bản dịch {lang} trống/sai độ dài ở {key}')
    out[lang] = {
        'groups': {str(g): rn.GROUPS[g][k] for g in sorted(rn.GROUPS)},
        'recipes': {str(i): rn.RECIPES[i][k] for i in sorted(rn.RECIPES)},
        'ingredients': {n: rn.INGREDIENTS[n][k] for n in sorted(rn.INGREDIENTS)},
    }
(root / 'assets/recipes/names.json').write_text(json.dumps(out, ensure_ascii=False, indent=1), encoding='utf-8')
print('OK', {l: (len(v['recipes']), len(v['ingredients']), len(v['groups'])) for l, v in out.items()})
