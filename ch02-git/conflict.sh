#!/usr/bin/env bash
# 2장 conflict 실습 — 같은 줄을 두 branch 에서 고치면 어떻게 되는가
#
#   bash conflict.sh            # conflict 가 난 상태에서 멈춘다. 직접 해결해 본다
#   bash conflict.sh --resolve  # 해결까지 자동으로 진행해 결과를 보여 준다
set -euo pipefail

WORK="$(mktemp -d)/conflict-lab"
mkdir -p "$WORK" && cd "$WORK"

git init -q -b main
git config user.name  "홍길동"
git config user.email "hong@example.com"

printf 'server:\n  port: 8080\n' > app.yaml
git add app.yaml && git commit -qm "chore: 기본 설정"

git switch -qc feature/port
printf 'server:\n  port: 9090\n' > app.yaml
git commit -qam "feat: 포트를 9090 으로"

git switch -q main
printf 'server:\n  port: 8081\n' > app.yaml
git commit -qam "fix: 포트 충돌 회피로 8081"

set +e
git merge feature/port                   # CONFLICT (content): Merge conflict in app.yaml
set -e

echo; echo "---- app.yaml (conflict 표시) ----"
cat app.yaml
echo "----------------------------------"
git status --short                       # UU app.yaml

if [[ "${1:-}" != "--resolve" ]]; then
  echo
  echo "직접 해결해 보기:"
  echo "  cd $WORK"
  echo "  1) app.yaml 을 열어 <<<<<<< ======= >>>>>>> 표시를 지우고 남길 값만 둔다"
  echo "  2) git add app.yaml"
  echo "  3) git commit        (merge commit 메시지가 미리 채워져 있다)"
  exit 0
fi

# 해결: 두 사람과 상의해서 9090 으로 결정했다고 가정
printf 'server:\n  port: 9090\n' > app.yaml
git add app.yaml
git commit -q --no-edit
git log --oneline --graph
