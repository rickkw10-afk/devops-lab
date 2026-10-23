#!/usr/bin/env bash
# 6장(광주캠퍼스). manifest repository 를 만들고 반 번호·개인 ID·GitHub ID 를 채운다.
# devops-lab 폴더에서 실행한다.
#   ./gwangju/make-manifests.sh 3 g001 my-github-id
# 결과: ~/devops-lab-manifests/  nginx-demo(6장), devops-lab-app(7장), argocd/(Application 두 개)
set -eu

if [ $# -ne 3 ]; then
  echo "사용법: $0 <반 번호 1~4> <개인 ID> <GitHub ID>" >&2
  exit 1
fi
N=$1; ID=$2; GH=$3
case "$N" in 1|2|3|4) ;; *) echo "반 번호는 1~4 중 하나다: $N" >&2; exit 1 ;; esac
# Kubernetes 이름·DNS 이름에 그대로 들어가므로 소문자·숫자·'-' 만 허용한다
echo "$ID" | grep -Eq '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$' \
  || { echo "개인 ID 는 소문자·숫자·'-' 만 쓴다: $ID" >&2; exit 1; }

HERE=$(cd "$(dirname "$0")" && pwd)
DEST=${DEST:-$HOME/devops-lab-manifests}
[ -e "$DEST" ] && { echo "이미 있다: $DEST (지우거나 DEST=다른경로 로 실행)" >&2; exit 1; }

cp -R "$HERE/manifest-repo-template" "$DEST"
# 자리표시자 세 개를 바꿔 쓴다. macOS·Linux sed 의 -i 차이를 피하려고 임시 파일로 옮긴다
for f in "$DEST"/*/*.yaml; do
  sed -e "s/<N>/$N/g" -e "s/<ID>/$ID/g" -e "s/<github-id>/$GH/g" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done

echo "manifest repository : $DEST"
echo "Argo CD Application : $ID-nginx-demo(6장), $ID-devops-lab-app(7장) / project skala-gj$N"
echo "6장 접속 주소       : http://skala-gj$N-$ID-nginx.skala-gj.com"
echo "7장 접속 주소       : http://skala-gj$N-$ID-devops.skala-gj.com/api/hello"
