#!/usr/bin/env python3
import json, sys, subprocess, os

data    = json.load(sys.stdin)
model   = data['model']['display_name']
dirname = os.path.basename(data['workspace']['current_dir'])
pct     = int(data.get('context_window', {}).get('used_percentage', 0) or 0)

CYAN, GREEN, YELLOW, RED, RESET = '\033[36m', '\033[32m', '\033[33m', '\033[31m', '\033[0m'

git = ''
try:
    subprocess.check_output(['git', 'rev-parse', '--git-dir'], stderr=subprocess.DEVNULL)
    branch   = subprocess.check_output(['git', 'branch', '--show-current'], text=True).strip()
    staged   = subprocess.check_output(['git', 'diff', '--cached', '--numstat'], text=True).strip()
    modified = subprocess.check_output(['git', 'diff', '--numstat'],           text=True).strip()
    n_s = len(staged.split('\n'))   if staged   else 0
    n_m = len(modified.split('\n')) if modified else 0
    git = f' | \U0001f331 {branch}'
    if n_s: git += f' {GREEN}+{n_s}{RESET}'
    if n_m: git += f' {YELLOW}~{n_m}{RESET}'
except Exception:
    pass

bar_color = RED if pct >= 90 else YELLOW if pct >= 70 else GREEN
bar = f"{bar_color}{'█' * (pct // 10)}{'░' * (10 - pct // 10)}{RESET}"

print(f'{CYAN}[{model}]{RESET} \U0001f4c1 {dirname}{git}  {bar} {pct}%')
