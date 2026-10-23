# 7장 파이프라인 연결 실습

코드 push 한 번으로 광주 클러스터(skala-gj)의 Pod 가 바뀌는 데까지 이어 본다.

```
git push ─▶ GitHub Actions ─▶ 광주 Harbor ─▶ manifest repo tag commit ─▶ 광주 Argo CD ─▶ Pod 교체
            (test, build, push)              (kustomize edit)              (sync)
```

| repository | 내용 | 누가 읽나 |
| --- | --- | --- |
| `devops-lab` (이 저장소) | `app/`, `.github/workflows/ci-cd.yml` | GitHub Actions |
| `devops-lab-manifests` | `manifest-repo-template/` 에 반 번호·개인 ID·GitHub ID 를 채운 것 | Argo CD |

`manifest-repo-template/` 은 `gwangju/manifest-repo-template/` 과 같다. 6장에서 `./gwangju/make-manifests.sh` 로 만든
`~/devops-lab-manifests` 를 7장에서도 그대로 사용한다.

## 준비물

| 항목 | 어디서 | 메모 |
| --- | --- | --- |
| `~/devops-lab-manifests` | 6장 `./gwangju/make-manifests.sh <N> <ID> <github-id>` | GitHub 에 public repository 로 push 해 둔다 |
| Harbor Secret 두 개 | `HARBOR_USERNAME`(skala-gj<N>), `HARBOR_PASSWORD`(반 Harbor 비밀번호) | 4장에서 devops-lab 저장소에 등록 |
| `MANIFEST_REPO_TOKEN` | GitHub → Settings → Developer settings → Fine-grained tokens | 대상 repository: devops-lab-manifests, 권한: Contents Read and write |
| Argo CD 로그인 | `argocd login argocd.skala-gj.com --username skala-gj<N> --grpc-web` | `argocd app list --grpc-web` 에 `<ID>-nginx-demo` |
| 시간 | 08:00~23:00 | 그 밖의 시간에는 노드가 0대다 |

`GITHUB_TOKEN` 은 workflow 가 도는 저장소에만 쓸 수 있다. 다른 저장소(manifest)에 push 하려면 PAT 가 필요하다.

## 따라 하기

```bash
# 1. workflow 의 <N> <ID> 채우기 (devops-lab 폴더)
cd ~/devops-lab
./gwangju/use-harbor-workflow.sh <N> <ID>

# 2. Secret 세 개 확인
gh secret set MANIFEST_REPO_TOKEN -R <github-id>/devops-lab   # 값은 프롬프트에 붙여 넣는다
gh secret list -R <github-id>/devops-lab                      # HARBOR_USERNAME, HARBOR_PASSWORD, MANIFEST_REPO_TOKEN

# 3. push → Actions 실행
git add .github && git commit -m "ci: push to gwangju harbor" && git push
gh run watch                                                  # test → build-push → update-manifest

# 4. Harbor 웹(harbor.skala-gj.com) → 프로젝트 skala-gj<N> → <ID>-devops-lab-app 에 sha tag

# 5. 광주 Argo CD 에 등록 (첫 CI 가 끝난 뒤 한 번만)
argocd app create -f ~/devops-lab-manifests/argocd/application.yaml --grpc-web
argocd app wait <ID>-devops-lab-app --health --timeout 300 --grpc-web

# 6. 공개 주소로 확인
curl http://skala-gj<N>-<ID>-devops.skala-gj.com/api/hello    # version 에 git sha 7자리
```

Application 을 너무 일찍 등록하면 tag 가 `0000000` 이라 `ImagePullBackOff` 가 발생한다. 첫 CI 가 tag 를 바꿔 넣으면 자동으로 해소된다.
두 번째부터는 앱 코드를 수정하고 3번만 한다. 메시지를 바꿀 때는 `HelloControllerTest.java` 의 기대값도 함께 수정한다.

## 어디서 막혔나

| 단계 | 증상 | 원인 → 대응 |
| --- | --- | --- |
| test | `./gradlew: Permission denied` | 실행 권한 없음 → `git update-index --chmod=+x app/gradlew` |
| test | `HelloControllerTest > helloReturnsMessageAndVersion() FAILED` | 메시지를 바꿨으면 테스트 기대값도 고친다 |
| build-push | `IMAGE 에 <N> <ID> 가 남아 있다` | 1번 `use-harbor-workflow.sh` 를 실행하지 않았다 |
| build-push | login 단계 `unauthorized` | `HARBOR_USERNAME`·`HARBOR_PASSWORD` 값 |
| build-push | push 단계 `401 Unauthorized` | IMAGE 의 프로젝트가 자기 반 `skala-gj<N>` 인지 |
| update-manifest | `Permission denied` / 403 | token 권한(Contents write) 또는 대상 repository 누락, 만료 |
| update-manifest | `remote: Repository not found` | manifest repository 이름 오타 |
| Argo CD | `permission denied … default/` | application.yaml 의 project 가 `skala-gj<N>` 인지 |
| Argo CD | `do not match any of the allowed destinations` | destination namespace 의 반 번호 |
| Pod | `ImagePullBackOff` | 첫 CI 전 tag `0000000`, `imagePullSecrets` 의 `harbor-cred` |

## 운영으로 가져갈 때 바꿀 것

- [ ] 반 공용 Harbor 계정 대신 프로젝트별 robot 계정을 사용한다
- [ ] PAT 대신 GitHub App token 을 사용한다(개인 계정에 묶이지 않게, 만료 관리)
- [ ] manifest repository 에 branch protection 과 CODEOWNERS 를 건다
- [ ] 환경(dev, prod)을 폴더나 overlay 로 나누고, prod 는 PR 로만 tag 를 바꾼다
