#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sinh assets/recipes/recipes.json từ scripts/data/recipes_source.md (100 công thức do chủ dự án cung cấp).
Chạy lại khi sửa source.md:  python3 scripts/make_recipes.py"""
import json, re, sys, pathlib

root = pathlib.Path(__file__).resolve().parent.parent
src = (root / 'scripts/data/recipes_source.md').read_text(encoding='utf-8')
recipes, group, groups = [], 0, []
for line in src.splitlines():
    m = re.match(r'## Nhóm (\d+) — (.+?) \((\d+)[–-](\d+)\)', line)
    if m:
        group = int(m.group(1))
        groups.append({'id': group, 'name': m.group(2)})
        continue
    m = re.match(r'\|\s*(\d+)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*$', line)
    if not m or not group:
        continue
    ings = []
    for part in m.group(3).split(';'):
        part = part.strip()
        q = re.match(r'^(.*?)\s+(\d+(?:\.\d+)?)\s*(g|ml)$', part)
        if not q:
            sys.exit(f'Không đọc được nguyên liệu "{part}" ở món {m.group(1)}')
        n = float(q.group(2))
        name = q.group(1).strip()
        name = name[0].upper() + name[1:]  # file nguồn viết hoa không đồng nhất (Hồng trà khô / hồng trà khô)
        ings.append({'name': name, 'qty': int(n) if n == int(n) else n, 'unit': q.group(3)})
    recipes.append({'id': int(m.group(1)), 'name': m.group(2), 'group': group, 'ingredients': ings})

assert len(recipes) == 100, len(recipes)
assert [r['id'] for r in recipes] == list(range(1, 101))
out = root / 'assets/recipes/recipes.json'
out.write_text(json.dumps({'groups': groups, 'recipes': recipes}, ensure_ascii=False, indent=1), encoding='utf-8')
print(len(recipes), 'công thức,', len({i['name'] for r in recipes for i in r['ingredients']}), 'nguyên liệu khác nhau')
