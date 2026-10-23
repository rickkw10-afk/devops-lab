#!/usr/bin/env bash
# 광주 EKS(skala-gj) 접속 확인. 읽기만 하고 클러스터에 아무것도 만들지 않는다.
#   ./gwangju/check-gj.sh 3
set -u
N=${1:-}
case "$N" in 1|2|3|4) ;; *) echo "사용법: $0 <반 번호 1~4>" >&2; exit 1 ;; esac
NS=skala-gj$N
CTX=${CTX:-skala-gj}            # update-kubeconfig --alias 로 붙인 이름

ok()   { printf '  [OK]   %s\n' "$1"; }
fail() { printf '  [FAIL] %s\n' "$1"; FAILED=1; }
FAILED=0
HAVE_CTX=0
K="kubectl --context $CTX"

echo "1) AWS 자격 증명 (profile $NS)"
ARN=$(aws sts get-caller-identity --profile "$NS" --query Arn --output text 2>/dev/null)
case "$ARN" in
  *":user/"*"$NS") ok "$ARN" ;;
  "") fail "profile $NS 가 없다. 안내문의 aws configure set 세 줄을 다시 실행" ;;
  *)  fail "다른 사용자다: $ARN" ;;
esac

echo "2) kubeconfig context"
if kubectl config get-contexts "$CTX" >/dev/null 2>&1; then
  HAVE_CTX=1
  DEF=$(kubectl config view -o jsonpath="{.contexts[?(@.name==\"$CTX\")].context.namespace}")
  [ "$DEF" = "$NS" ] && ok "$CTX (namespace $DEF)" \
    || fail "$CTX 의 기본 namespace 가 '$DEF' 다. kubectl config set-context $CTX --namespace=$NS"
else
  fail "context $CTX 가 없다. aws eks update-kubeconfig ... --alias $CTX"
fi

if [ "$HAVE_CTX" = "1" ]; then
  echo "3) 권한"
  [ "$($K auth can-i create deployments -n "$NS" 2>/dev/null)" = "yes" ] \
    && ok "$NS 에 Deployment 생성 가능" || fail "$NS 에 쓰기 권한이 없다. 반 번호와 profile 을 확인"
  [ "$($K auth can-i create namespaces 2>/dev/null)" = "no" ] \
    && ok "namespace 생성은 막혀 있다 (정상)" || fail "namespace 생성 권한 확인 실패. 강사에게 알린다"

  echo "4) Harbor pull Secret"
  $K get secret harbor-cred -n "$NS" >/dev/null 2>&1 \
    && ok "harbor-cred 있음" || fail "harbor-cred 가 없다. 강사에게 알린다"

  echo "5) 훈련생 노드"
  READY=$($K get nodes -l workload=student --no-headers 2>/dev/null | grep -c ' Ready ')
  [ "$READY" -gt 0 ] && ok "Ready ${READY}대" \
    || fail "Ready 노드 0대. 23:00~08:00 에는 노드가 내려가 있다. 그 밖의 시간이면 강사에게 알린다"
else
  echo "3)~5) 건너뜀. 2) 의 context 부터 만든다"
fi

echo "6) Harbor · Argo CD"
for u in https://harbor.skala-gj.com/api/v2.0/ping https://argocd.skala-gj.com/healthz; do
  C=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$u")
  [ "$C" = "200" ] && ok "$u → 200" || fail "$u → $C"
done

echo
[ "$FAILED" = "0" ] && echo "준비 완료" || { echo "위 FAIL 항목부터 해결"; exit 1; }
