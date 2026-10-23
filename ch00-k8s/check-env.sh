#!/usr/bin/env bash
# 0장 설치 확인. 읽기만 하고 클러스터에 아무것도 만들지 않는다(마지막 이미지 테스트는 --pull 옵션일 때만).
set -u

ok()   { printf '  [OK]   %s\n' "$1"; }
fail() { printf '  [FAIL] %s\n' "$1"; FAILED=1; }
FAILED=0

echo "1) 도구"
for c in docker kubectl git; do
  command -v "$c" >/dev/null && ok "$c $(command -v "$c")" || fail "$c 가 없다"
done

echo "2) 현재 context"
CTX=$(kubectl config current-context 2>/dev/null || echo "")
case "$CTX" in
  "")          fail "context 가 없다. Docker Desktop 에서 Kubernetes 를 켰는지 확인" ;;
  arn:aws:eks*) fail "EKS context ($CTX) 다. kubectl config use-context docker-desktop" ;;
  *)           ok "$CTX" ;;
esac

echo "3) 노드"
if kubectl get nodes --no-headers 2>/dev/null | grep -q ' Ready '; then
  ok "$(kubectl get nodes --no-headers | awk '{print $1" "$2}' | head -1)"
else
  fail "Ready 노드가 없다"
fi

echo "4) kube-system Pod"
if PODS=$(kubectl get pods -n kube-system --no-headers 2>/dev/null) && [ -n "$PODS" ]; then
  BAD=$(printf '%s\n' "$PODS" | grep -v -c -E 'Running|Completed')
  [ "$BAD" = "0" ] && ok "모두 Running" || fail "Running 이 아닌 Pod ${BAD}개. kubectl get pods -n kube-system"
else
  fail "kube-system Pod 를 읽지 못했다"
fi

if [ "${1:-}" = "--pull" ]; then
  echo "5) 이미지 받기 (test Pod 를 만들었다가 지운다)"
  kubectl run env-check --image=nginx --restart=Never >/dev/null 2>&1
  kubectl wait --for=condition=Ready pod/env-check --timeout=120s >/dev/null 2>&1 \
    && ok "nginx 이미지 받기 성공" || fail "이미지를 못 받았다. kubectl describe pod env-check"
  kubectl delete pod env-check --wait=false >/dev/null 2>&1
fi

echo
[ "$FAILED" = "0" ] && echo "준비 완료" || { echo "위 FAIL 항목부터 해결"; exit 1; }
