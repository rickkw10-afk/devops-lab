# 광주캠퍼스 실습 (skala-gj)

광주캠퍼스 EKS 클러스터 `skala-gj` 에서 혼자 따라 하기 위한 파일이다. 3~7장의 원래 파일과 같은 앱을 쓰고,
image 저장소를 광주 Harbor 로, 배포 대상을 반 namespace 로 바꿨다.

## 반 공용 자원과 개인 자원

같은 반이 계정 하나와 namespace 하나를 함께 쓴다. 이름 앞에 **개인 ID**(훈련생 번호, 예: `g001`)를 붙여 겹치지 않게 한다.

| 자원 | 이름 | 함께 쓰는 범위 | 개인 구분 |
| --- | --- | --- | --- |
| AWS profile · kubeconfig | `skala-gj<N>` | 반 전체 | 없음 (같은 키) |
| namespace | `skala-gj<N>` | 반 전체 | 리소스 이름 `<ID>-…`, label `owner: <ID>` |
| Harbor 프로젝트 | `harbor.skala-gj.com/skala-gj<N>` | 반 전체 | repository `<ID>-devops-lab-app` |
| Argo CD 계정 · AppProject | `skala-gj<N>` | 반 전체 | Application `<ID>-nginx-demo`, `<ID>-devops-lab-app` |
| Ingress host | `*.skala-gj.com` | 4개 반 전체 | `skala-gj<N>-<ID>-nginx`, `skala-gj<N>-<ID>-devops` |
| GitHub repository | `devops-lab`, `devops-lab-manifests` | 본인 | 본인 계정 |

`<N>` 은 반 번호(1~4)이다. 계정 값(액세스 키, Harbor·Argo CD 비밀번호)은 반별 안내문에만 있다.

## 파일

| 파일 | 장 | 하는 일 |
| --- | --- | --- |
| `check-gj.sh` | 0장 | 광주 EKS 접속 확인 (읽기만 한다) |
| `Jenkinsfile` | 3장 | `ch03-jenkins/Jenkinsfile` 의 Harbor 판. `--platform linux/amd64` |
| `workflows/docker.yml` | 4장 | app image 를 Harbor 로 push (sha·latest tag). `.github/workflows/` 로 복사하고 `<N>` `<ID>` 를 채운다 |
| `make-manifests.sh` | 6장 | `~/devops-lab-manifests` 를 만들고 `<N>` `<ID>` `<github-id>` 를 채운다 |
| `manifest-repo-template/` | 6~7장 | `nginx-demo/`(6장), `devops-lab-app/`(7장), `argocd/`(Application 두 개) |
| `tekton/create-harbor-secret.sh`, `tekton/ci-pipelinerun.yaml` | 5장 | 로컬 kind 의 Tekton 이 Harbor 로 push |
| `workflows/ci-cd.yml` | 7장 | test → Harbor push → manifest tag 수정 |
| `use-harbor-workflow.sh` | 7장 | 위 workflow 를 `.github/workflows/ci-cd.yml` 로 복사하고 값을 채운다 |

`ch07-capstone/manifest-repo-template` 과 `.github/workflows/ci-cd.yml` 도 같은 광주 Harbor 기준이다. 템플릿은 이 폴더 것과 같고,
`ci-cd.yml` 은 `use-harbor-workflow.sh` 가 `<N>` `<ID>` 를 채운다.

## 순서

```bash
# 0장. 광주 EKS 연결 (안내문의 키로 profile 등록 후)
aws eks update-kubeconfig --name skala-gj --region ap-northeast-2 --profile skala-gj<N> --alias skala-gj
kubectl config set-context skala-gj --namespace=skala-gj<N>
./gwangju/check-gj.sh <N>                      # 마지막 줄 "준비 완료"

# 6장. manifest repository 와 Argo CD
./gwangju/make-manifests.sh <N> <ID> <github-id>
cd ~/devops-lab-manifests && git init -b main && git add . && git commit -m "init manifests"
# GitHub 에 public repository devops-lab-manifests 를 만들고 push
argocd login argocd.skala-gj.com --username skala-gj<N> --grpc-web
argocd app create -f argocd/nginx-demo.yaml --grpc-web
curl http://skala-gj<N>-<ID>-nginx.skala-gj.com

# 7장. Harbor workflow
cd ~/devops-lab
./gwangju/use-harbor-workflow.sh <N> <ID>
# Secrets: HARBOR_USERNAME=skala-gj<N>, HARBOR_PASSWORD=반 Harbor 비밀번호, MANIFEST_REPO_TOKEN=PAT
git add .github && git commit -m "ci: push to gwangju harbor" && git push
argocd app create -f ~/devops-lab-manifests/argocd/application.yaml --grpc-web   # 첫 CI 가 끝난 뒤
curl http://skala-gj<N>-<ID>-devops.skala-gj.com/api/hello

# 정리
argocd app delete <ID>-devops-lab-app --grpc-web -y
argocd app delete <ID>-nginx-demo --grpc-web -y
```

## 배포 현황판

`https://board.skala-gj.com/<N>` 은 같은 반 훈련생의 `/api/hello` 를 5초마다 호출해 ID, 응답 코드, message, version, 마지막 배포 시각을 표로 보여 준다.
`/` 는 네 반을 한 화면에 보여 준다. 명단 없이 반 namespace 의 Ingress host(`skala-gj<N>-<ID>-devops`)를 읽어 줄을 만들므로
7장 Application 을 등록하면 자동으로 나온다. message 는 공개 화면에 그대로 보이므로 개인정보를 넣지 않는다.
현황판 설치는 운영 폴더의 `setup-scoreboard.sh` 가 한다.

## 시간

광주 클러스터는 매일 23:00 에 노드가 0대로 내려가고 08:00 에 다시 뜬다. 그 사이에는 Harbor · Argo CD 도 응답하지 않고,
Pod 는 `Pending` 이다.

## 어디까지 확인했나

2026-10-21 오전, 노드가 떠 있는 시간에 3반 계정(AWS·Harbor·Argo CD)과 테스트 ID `t000` 으로 이 README의 순서를 처음부터 끝까지 실행했다.
GitHub 저장소는 임시로 만들었다가 지웠고, 클러스터·Harbor 자원도 정리했다.

| 단계 | 결과 |
| --- | --- |
| `check-gj.sh 3` | 1)~6) 모두 OK, `준비 완료` (훈련생 노드 Ready 6대) |
| `docker login harbor.skala-gj.com` | `Login Succeeded` |
| `make-manifests.sh 3 t000 …` → `argocd app create -f argocd/nginx-demo.yaml` | 16초 안에 Synced·Healthy, `curl` 에 `<title>Welcome to nginx!</title>` |
| `nginx-demo` 의 newTag 1.27 → 1.28 push 후 `argocd app get --refresh` | 7초 안에 Pod 교체 |
| `use-harbor-workflow.sh 3 t000` → push | Actions test 57초 · build-push 81초 · update-manifest 6초 성공 |
| `argocd app create -f argocd/application.yaml` | Healthy, `/api/hello` → `{"message":"hello, devops","version":"545121b"}` |
| 앱 메시지와 테스트 기대값을 바꿔 다시 push | 256초 뒤 공개 주소의 version 이 새 sha 로 바뀜 |
| 메시지만 바꾸고 테스트는 그대로 push | `HelloControllerTest > helloReturnsMessageAndVersion() FAILED`, build-push·update-manifest 건너뜀 |
| Apple Silicon 에서 `docker build --platform linux/amd64` | 110초, amd64 image push 성공 |
| `argocd app delete … -y` 후 `k get all,ingress -l owner=t000` | `No resources found in skala-gj3 namespace.` |

2026-10-22 저녁, 레지스트리를 Harbor 하나로 정리한 뒤 3~7장을 다시 처음부터 실행했다(3반 계정, 테스트 ID `t000`, 임시 GitHub 저장소).

| 장 | 실행한 것 | 결과 |
| --- | --- | --- |
| 3장 | Jenkins 컨테이너(`ch03-jenkins/Dockerfile`)에서 `ch03-jenkins/Jenkinsfile`, credentials `harbor-login` | Version → Test → Image → Push 성공 2분 1초, Harbor 에 linux/amd64 image |
| 4장 | `ci.yml`, `docker.yml` 을 `.github/workflows/` 로 복사해 push | 파일을 올리자마자 실행. test 65초, image 133초, Harbor 에 sha·latest tag |
| 5장 | kind(Tekton Pipelines v1.17.0)에서 `03-ci/create-secret.sh` → `ci-pipelinerun.yaml` | 4개 Task Succeeded, `<ID>-devops-lab-app-tekton` 에 arm64 image |
| 6장 | `make-manifests.sh` → `argocd app create -f argocd/nginx-demo.yaml` | 23초 안에 Healthy, `<title>Welcome to nginx!</title>` |
| 7장 | `use-harbor-workflow.sh` → push → `argocd app create -f argocd/application.yaml` | test 23초, build-push 72초, update-manifest 7초, `/api/hello` 응답, 현황판에 줄 생성 |
| 7장 | 메시지와 테스트 기대값을 바꿔 다시 push | push 후 251초에 새 Pod Ready, version 이 새 sha |

이때 고친 것
- Tekton 이 처음에는 배포용과 같은 repository 에 push 해서, 같은 commit 의 amd64 image 를 arm64 로 덮어썼다. Tekton 은 `<ID>-devops-lab-app-tekton` 으로 나눴다
- `ci.yml`·`docker.yml` 은 `app/**` 이 바뀔 때만 실행돼서 파일만 올리면 아무 일도 없었다. 자기 파일 경로도 `paths` 에 넣었다
- `create-secret.sh` 가 `docker-desktop` context 만 받았다. `kind-*` 도 받고, 그 밖의 context 에서는 멈춘다

일부러 틀리게 실행해 받은 오류 문구

| 상황 | 출력 |
| --- | --- |
| 다른 반 프로젝트로 push | `401 Unauthorized` |
| Harbor 비밀번호 오타 | `unauthorized:` |
| Application 의 project 가 default | `permission denied: applications, create, default/…` |
| destination namespace 가 다른 반 | `do not match any of the allowed destinations in project 'skala-gj3'` |
| 같은 이름 Application 을 다시 create | `existing application spec is different, use upsert flag to force update` |
| `kubectl apply -f argocd/…yaml` | `applications.argoproj.io … is forbidden` |

`docker login https://harbor.skala-gj.com` 처럼 주소에 `https://` 를 붙여도 Docker 29.4 에서는 로그인과 push 가 모두 됐다.
그래도 image 이름에는 `https://` 가 들어갈 수 없으므로 주소는 호스트 이름만 쓰는 쪽으로 맞춘다.
Tekton(로컬 kind)과 Jenkins 컨테이너 안에서의 실행은 이번에 다시 돌리지 않았다.
