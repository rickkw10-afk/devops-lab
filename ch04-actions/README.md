# 4장 Github Action 샘플

`workflows/` 안의 파일은 **그대로는 실행되지 않는다.** GitHub 은 저장소 루트의
`.github/workflows/` 에 있는 파일만 workflow 로 인식한다. 쓰고 싶은 파일을 복사해서 push 한다.

```bash
mkdir -p .github/workflows
cp ch04-actions/workflows/hello.yml .github/workflows/
git add .github/workflows/hello.yml
git commit -m "ci: add hello workflow"
git push origin main
# GitHub 저장소 > Actions 탭에서 실행 결과 확인
```

## 파일 지도

| 파일 | 슬라이드 | 무엇을 보여 주나 |
| --- | --- | --- |
| `hello.yml` | 첫 Workflow 만들기 | 가장 작은 workflow, contexts 출력 |
| `structure.yml` | Workflow 문법 해부 | name · run-name · on · permissions · env · jobs · needs · if |
| `events.yml` | 이벤트별 예시 | push paths, pull_request types, workflow_dispatch inputs, schedule |
| `needs.yml` | needs 로 Job 순서 정하기 | 병렬 → 합류, job outputs 전달 |
| `matrix.yml` | matrix | OS × Java 버전 조합 |
| `ci.yml` | devops-lab 앱 CI | gradle test, bootJar, cache, artifact |
| `docker.yml` | Docker image build & push | 광주 Harbor 로그인, sha·latest tag, buildx 캐시 |
| `deploy-approval.yml` | environment 로 배포 승인 | environment, vars, secrets |

모든 파일은 `actionlint` 로 검사했다.

```bash
docker run --rm -v "$PWD":/repo -w /repo rhysd/actionlint:latest
```

## 미리 해 둘 설정

| 파일 | 설정 위치 | 할 일 |
| --- | --- | --- |
| `docker.yml` | 파일 안 `env` | `<N>` `<ID>` 를 반 번호와 개인 ID 로 바꾼다 |
| `docker.yml` | Settings > Secrets and variables > Actions | secret `HARBOR_USERNAME`(skala-gj<N>), `HARBOR_PASSWORD`(반 Harbor 비밀번호) |
| `deploy-approval.yml` | Settings > Environments | `staging`, `production` 생성. production 에 Required reviewers 지정 |
| `deploy-approval.yml` | Settings > Secrets and variables > Actions | secret `DEPLOY_TOKEN`, variable `DEPLOY_HOST` |

## Harbor push 참고 사항

- 반 프로젝트 `skala-gj<N>` 은 이미 있다. repository `<ID>-devops-lab-app` 은 첫 push 때 만들어진다
- Harbor 에는 `GITHUB_TOKEN` 이 아니라 반 계정으로 로그인하므로 `permissions` 에 쓰기 권한을 올리지 않는다
- 광주 Harbor 는 Let's Encrypt 인증서라 GitHub-hosted runner 에서 바로 접속된다
- 주소는 호스트 이름(`harbor.skala-gj.com`)만 적는다. image 이름에는 `https://` 가 들어갈 수 없다

## 트러블슈팅

| 증상 | 원인 | 해결 |
| --- | --- | --- |
| Actions 탭에 아무것도 안 나온다 | 파일이 `.github/workflows/` 밖에 있다 | 경로 확인. 확장자는 `.yml` / `.yaml` |
| `Invalid workflow file` | 들여쓰기, 탭 문자, ’ 같은 둥근 따옴표 | 에디터에서 곧은 따옴표로, actionlint 로 검사 |
| `./gradlew: Permission denied` | Windows 에서 commit 해 실행 권한이 빠짐 | `git update-index --chmod=+x app/gradlew` 후 commit |
| login step `unauthorized` | `HARBOR_USERNAME`·`HARBOR_PASSWORD` 값 | `gh secret set` 으로 다시 등록 |
| push 에서 `401 Unauthorized` | `IMAGE` 의 프로젝트가 다른 반 | `skala-gj<N>` 이 자기 반인지 |
| schedule 이 안 돈다 | 기본 branch 에만 적용, 60일 활동 없는 public repo 는 비활성화 | 기본 branch 확인, Actions 탭에서 다시 Enable |
