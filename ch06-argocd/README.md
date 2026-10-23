# 6장 GitOps 와 Argo CD 실습

공개 image(`nginxinc/nginx-unprivileged`)로 GitOps 흐름을 먼저 익힌다.
우리 앱 image 로 바꾸는 것은 7장(`../ch07-capstone`)에서 한다.

## 파일

| 파일 | 역할 |
| --- | --- |
| `manifests/namespace.yaml` | `devops-lab` namespace |
| `manifests/deployment.yaml` | Pod 2개. image tag 는 kustomization 이 붙인다 |
| `manifests/service.yaml` | 80 → 8080 |
| `manifests/kustomization.yaml` | 위 세 파일 묶음 + `images` 로 tag 지정 |
| `application.yaml` | Argo CD 에게 "이 경로를 이 클러스터에 맞춰라" 라고 알려 주는 리소스 |

## 순서

```bash
# 0. 로컬 클러스터인지 먼저 확인한다 (EKS 가 나오면 멈춘다)
kubectl config current-context

# 1. Argo CD 설치
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n argocd -w          # 전부 Running 이 될 때까지

# 2. UI 접속 (다른 터미널)
kubectl port-forward svc/argocd-server -n argocd 8080:443
argocd admin initial-password -n argocd   # 사용자 admin

# 3. 매니페스트가 제대로 렌더되는지 로컬에서 확인
kubectl kustomize manifests

# 4. application.yaml 의 repoURL 을 본인 repository 로 고친 뒤 등록
kubectl apply -f application.yaml
kubectl get applications -n argocd     # SYNC STATUS=Synced, HEALTH STATUS=Healthy

# 5. GitOps 체험: kustomization.yaml 의 newTag 를 1.28-alpine 으로 바꾸고 commit, push
kubectl get pods -n devops-lab -w      # 3분 안에 Pod 가 교체된다 (기본 polling 주기)
```

## 되돌리기

```bash
git revert HEAD && git push            # Argo CD 가 이전 tag 로 다시 맞춘다
```

## 자주 막히는 곳

| 증상 | 원인 | 대응 |
| --- | --- | --- |
| `metadata.annotations: Too long` | `--server-side` 없이 apply | 설치 명령을 그대로 다시 실행 |
| Application 이 `Unknown` | repoURL 오타, private repository | URL 확인, private 이면 Settings → Repositories 에 등록 |
| `OutOfSync` 가 안 풀림 | automated 가 꺼져 있음 | UI 에서 SYNC 클릭 또는 syncPolicy 확인 |
| push 했는데 반영이 느림 | 기본 polling 3분 | UI 에서 REFRESH, 급하면 webhook 연결 |
