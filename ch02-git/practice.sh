#!/usr/bin/env bash
# 2장 Git 실습 — 첫 repository 부터 branch, merge 까지
#
#   bash practice.sh            # 임시 폴더에서 처음부터 끝까지 실행
#   bash practice.sh ~/git-lab  # 지정한 폴더에서 실행 (없으면 만든다)
#
# 강의에서는 한 줄씩 직접 쳐 보는 것이 목적이다. 이 스크립트는 막혔을 때
# "원래 어떤 결과가 나와야 하는지" 확인하는 용도로 쓴다.
set -euo pipefail

WORK="${1:-$(mktemp -d)/git-lab}"
mkdir -p "$WORK" && cd "$WORK"
step() { printf '\n\033[1;34m== %s\033[0m\n' "$*"; }

step "1. repository 만들기"
git init -b main                         # .git 폴더가 생긴다
git config user.name  "홍길동"           # 이 repository 에만 적용
git config user.email "hong@example.com"

step "2. 파일을 만들고 상태 보기"
echo "# git-lab" > README.md
git status --short                       # ?? README.md  (untracked)

step "3. staging → commit"
git add README.md
git status --short                       # A  README.md  (staged)
git commit -m "docs: README 추가"

step "4. 수정하고 차이 보기"
echo "Git 실습용 repository" >> README.md
git diff                                 # 아직 add 하지 않은 변경
git add README.md
git diff --staged                        # add 한 변경
git commit -m "docs: README 에 설명 한 줄 추가"
git log --oneline                        # 최신 commit 이 맨 위

step "5. branch 만들고 옮겨 가기"
git switch -c feature/greeting           # 만들고 바로 이동
echo 'echo "hello, devops"' > hello.sh
git add hello.sh
git commit -m "feat: 인사 스크립트 추가"

step "6. main 으로 돌아와 merge (fast-forward)"
git switch main
git merge feature/greeting               # main 에 새 commit 이 없어서 앞으로 당기기만 한다
git log --oneline --graph

step "7. 양쪽에 commit 이 있을 때 merge (merge commit 생성)"
git switch -c feature/bye
echo 'echo "bye"' > bye.sh
git add bye.sh && git commit -m "feat: 종료 인사 추가"
git switch main
echo "- hello.sh: 인사 출력" >> README.md
git commit -am "docs: 스크립트 설명 추가"
git merge --no-edit feature/bye          # 갈라진 두 흐름을 합치는 commit 이 생긴다
git log --oneline --graph

step "8. 다 쓴 branch 정리"
git branch -d feature/greeting feature/bye
git branch

printf '\n완료: %s\n' "$WORK"
