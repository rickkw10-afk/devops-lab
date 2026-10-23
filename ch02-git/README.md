# 2장 Git 실습

| 파일 | 내용 | 슬라이드 |
| --- | --- | --- |
| `practice.sh` | init → add/commit → diff → branch → merge(fast-forward, merge commit) | 첫 repository, branch, merge |
| `conflict.sh` | 같은 줄을 두 branch 에서 고쳐 conflict 를 일부러 만든다 | conflict 해결 실습 |
| `gitignore.example` | Java/Gradle 프로젝트용 .gitignore | .gitignore |

```bash
bash practice.sh              # 임시 폴더에서 전체 흐름 실행
bash practice.sh ~/git-lab    # 결과를 남겨 두고 싶으면 폴더 지정
bash conflict.sh              # conflict 상태에서 멈춤 → 안내대로 직접 해결
bash conflict.sh --resolve    # 해결 과정까지 자동 실행
```

강의에서는 스크립트를 실행하는 대신 명령을 한 줄씩 직접 친다. 스크립트는 "원래 이런 결과가
나와야 한다"를 확인하는 답안지다.

## 자주 막히는 곳

| 증상 | 원인 | 해결 |
| --- | --- | --- |
| `Author identity unknown` | user.name / user.email 미설정 | `git config --global user.name ...` |
| push 할 때 password 를 물어보고 거절 | GitHub 은 2021년부터 비밀번호 인증을 막았다 | PAT 또는 SSH key |
| `rejected (fetch first)` | 원격에 내가 없는 commit 이 있다 | `git pull` 후 다시 push |
| `.gitignore` 에 넣었는데 계속 보인다 | 이미 추적 중인 파일 | `git rm --cached <파일>` |
