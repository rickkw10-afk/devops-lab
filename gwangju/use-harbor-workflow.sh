#!/usr/bin/env bash
# 7장(광주캠퍼스). .github/workflows/ci-cd.yml 의 <N> <ID> 를 반 번호와 개인 ID 로 채운다.
# devops-lab 폴더에서 실행한다.
#   ./gwangju/use-harbor-workflow.sh 3 g001
set -eu

if [ $# -ne 2 ]; then
  echo "사용법: $0 <반 번호 1~4> <개인 ID>" >&2
  exit 1
fi
N=$1; ID=$2
case "$N" in 1|2|3|4) ;; *) echo "반 번호는 1~4 중 하나다: $N" >&2; exit 1 ;; esac
echo "$ID" | grep -Eq '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$' \
  || { echo "개인 ID 는 소문자·숫자·'-' 만 쓴다: $ID" >&2; exit 1; }

HERE=$(cd "$(dirname "$0")" && pwd)
mkdir -p .github/workflows
sed -e "s/<N>/$N/g" -e "s/<ID>/$ID/g" "$HERE/workflows/ci-cd.yml" > .github/workflows/ci-cd.yml

echo "workflow : .github/workflows/ci-cd.yml"
echo "image    : harbor.skala-gj.com/skala-gj$N/$ID-devops-lab-app"
echo "다음     : Secrets HARBOR_USERNAME · HARBOR_PASSWORD · MANIFEST_REPO_TOKEN 등록 후 commit, push"
