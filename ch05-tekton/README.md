# 5장 Tekton 실습 파일

로컬 kind(또는 docker-desktop) 클러스터 기준이다. 시작 전에 context 부터 확인한다.

```bash
kubectl config current-context        # kind-kind 또는 docker-desktop 이어야 한다
```

## 0. 설치

```bash
kubectl apply -f https://infra.tekton.dev/tekton-releases/pipeline/latest/release.yaml
kubectl get pods -n tekton-pipelines -w    # controller, webhook 이 1/1 Running 이면 완료

# 선택: Triggers(4번 실습), Dashboard
kubectl apply -f https://infra.tekton.dev/tekton-releases/triggers/latest/release.yaml
kubectl apply -f https://infra.tekton.dev/tekton-releases/triggers/latest/interceptors.yaml
kubectl apply -f https://infra.tekton.dev/tekton-releases/dashboard/latest/release.yaml

brew install tektoncd-cli                   # tkn
```

예전 자료의 `storage.googleapis.com/tekton-releases/...` 주소는 옛 주소다.

## 폴더

| 폴더 | 내용 | 슬라이드 |
|---|---|---|
| `01-hello` | step 하나짜리 Task, TaskRun | Task 작성 및 실행 |
| `02-basic` | params 를 받는 Task 두 개와 Pipeline, results 예제 | Task 생성, Pipeline 및 PipelineRun, params 와 results |
| `03-ci` | devops-lab 앱 clone → gradle test → image build & push | CI Pipeline, PipelineRun, registry 인증 |
| `04-triggers` | GitHub push 로 PipelineRun 자동 생성 | Triggers |

## 실행

```bash
# 01, 02
kubectl apply -f 01-hello/hello-task.yaml -f 01-hello/hello-taskrun.yaml
tkn taskrun logs hello-task-run -f

kubectl apply -f 02-basic/build-task.yaml -f 02-basic/test-task.yaml -f 02-basic/pipeline.yaml
kubectl apply -f 02-basic/pipelinerun.yaml
tkn pipelinerun logs sample-pipeline-run -f
# 다시 돌릴 때: 같은 이름의 Run 이 있으면 바뀐 게 없어 아무 일도 안 일어난다. 지우고 다시 apply

kubectl apply -f 02-basic/results-demo.yaml
tkn pipeline start results-demo --showlog

# 03: 03-ci 의 Run 은 generateName 이라 apply 가 아니라 create 로 만든다
# 반 Harbor 계정으로 push 용 Secret 을 만든다 (비밀번호는 반별 안내문)
HARBOR_USER=skala-gj<N> HARBOR_PASS='<반 Harbor 비밀번호>' ./03-ci/create-secret.sh
kubectl apply -f 03-ci/serviceaccount.yaml -f 03-ci/short-sha-task.yaml -f 03-ci/gradle-test-task.yaml
kubectl apply -f 03-ci/ci-pipeline.yaml
# ci-pipelinerun.yaml, triggertemplate.yaml 의 <github-id> <N> <ID> 를 바꾼 뒤
kubectl create -f 03-ci/ci-pipelinerun.yaml
tkn pipelinerun logs --last -f

# 04
./04-triggers/create-webhook-secret.sh          # 출력된 값을 GitHub Webhook Secret 에 넣는다
kubectl apply -f 04-triggers/
kubectl port-forward svc/el-github-listener 8080:8080
ngrok http 8080                                 # 나온 https 주소를 GitHub Webhook Payload URL 에
```

## 알아 둘 것

- `git-clone`, `buildah` 는 직접 설치하지 않는다. `resolver: hub` 가 실행할 때 Artifact Hub 에서 받아 온다.
  예전 자료의 `kind: ClusterTask` 는 Tekton Pipelines 1.0 에서 제거되어 지금은 거부된다.
- `buildah` Task 는 `privileged: true` 로 돈다. 로컬 실습은 괜찮지만 공용 클러스터에서는 막혀 있을 수 있다.
- 로컬 kind 에서 광주 Harbor(harbor.skala-gj.com)로 push 하므로 인터넷 연결이 필요하다. 교육장 Wi-Fi 가 막히면 핫스팟을 쓴다.
- Apple Silicon Mac 의 kind 가 만든 image 는 arm64 이다. 그래서 repository 를 `<ID>-devops-lab-app-tekton` 으로 따로 둔다.
  같은 commit 이면 tag(sha 7자리)가 같으므로, Actions 가 올린 amd64 image 와 같은 repository 에 넣으면 덮어써서 배포한 Pod 가 `exec format error` 로 죽는다.
- 실행 기록은 PipelineRun 이 남아 있는 동안만 볼 수 있다. 정리: `tkn pipelinerun delete --keep 5`

## 검증

YAML 은 Tekton v1.16.0 의 OpenAPI 정의(`pkg/apis/pipeline/v1/swagger.json`)로 필드 이름까지 검사했다.
클러스터에서는 `kubectl apply --dry-run=server -f <파일>` 로 webhook 검증까지 받을 수 있다.
