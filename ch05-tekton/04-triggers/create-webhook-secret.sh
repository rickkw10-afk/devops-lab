#!/bin/sh
# 출력된 값을 GitHub Webhook 화면의 Secret 칸에 그대로 넣는다.
# 값이 다르면 github interceptor 가 서명 검증에 실패해 요청을 버린다.
TOKEN="$(openssl rand -hex 20)"
kubectl create secret generic github-webhook-secret --from-literal=token="$TOKEN"
echo "GitHub Webhook Secret: $TOKEN"
