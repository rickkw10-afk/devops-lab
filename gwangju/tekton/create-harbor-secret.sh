#!/bin/sh
# 로컬 kind 의 Tekton 이 광주 Harbor 로 push 할 때 쓰는 docker-registry Secret.
# 반 Harbor 비밀번호를 YAML 로 남기지 않으려고 명령으로만 만든다.
#   HARBOR_USER=skala-gj3 HARBOR_PASS='...' ./gwangju/tekton/create-harbor-secret.sh   (ch05-tekton/03-ci/create-secret.sh 와 같다)
set -eu
: "${HARBOR_USER:?HARBOR_USER=skala-gj<N> 를 지정한다}" "${HARBOR_PASS:?HARBOR_PASS 를 지정한다}"
# 광주 EKS 에 만들지 않도록 로컬 context(docker-desktop, kind-*) 에서만 실행한다
CTX=$(kubectl config current-context)
case "$CTX" in
  docker-desktop|kind-*) ;;
  *) echo "로컬 클러스터 context 가 아니다: $CTX (kubectl config use-context docker-desktop)" >&2; exit 1 ;;
esac
kubectl --context "$CTX" create secret docker-registry harbor-auth \
  --docker-server=harbor.skala-gj.com \
  --docker-username="$HARBOR_USER" \
  --docker-password="$HARBOR_PASS"
