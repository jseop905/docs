# setup-git

> 프로젝트의 Git 히스토리와 설정을 분석하여 커밋, 브랜치, PR 관련 규칙 문서와 헬퍼 스크립트를 생성한다.

## 사용법

```bash
# CLI에서 실행
claude -p "setup-git.md를 읽고 이 프로젝트의 Git 워크플로우를 세팅해줘"

# setup-project 이후 실행하면 기존 분석 결과(docs/project/04-conventions.md)를 활용한다
claude -p "setup-git.md를 읽고, docs/project/04-conventions.md도 참고해서 세팅해줘"
```

---

## 생성 결과물

```
docs/git/
├── context.md              # 인덱스 — Git 워크플로우 전체 요약
├── 01-commit.md            # 커밋 메시지 컨벤션
├── 02-branch.md            # 브랜치 전략 및 네이밍
├── 03-pr.md                # PR 생성 규칙 및 템플릿
├── 04-workflow.md          # Git 워크플로우 (merge/rebase, 릴리스 등)
└── 05-hooks.md             # Git hooks (pre-commit, commit-msg 등)
```

---

## Phase 1: Git 환경 분석

### 1-1. 커밋 히스토리 분석

```bash
git log --oneline -50       # 최근 50개 커밋 메시지
git log --format="%s" -50   # 메시지만 추출
git shortlog -sn --no-merges # 기여자별 커밋 수
```

파악할 것:
- 커밋 메시지 패턴 (Conventional Commits 여부, prefix 종류)
- 언어 (한국어/영어/혼용)
- 스코프 사용 여부와 목록
- 메시지 길이 경향 (한줄 vs 본문 포함)
- 공동 작업자 표기 패턴 (Co-Authored-By 등)

### 1-2. 브랜치 분석

```bash
git branch -a                   # 모든 브랜치 목록
git branch -r                   # 리모트 브랜치
git log --all --oneline --graph -20  # 브랜치 그래프
```

파악할 것:
- 메인 브랜치 이름 (main / master / develop)
- 브랜치 네이밍 패턴 (feat/xxx, feature/xxx, fix/xxx 등)
- 브랜치 전략 (Git Flow, GitHub Flow, Trunk-based 등)
- 릴리스 브랜치 존재 여부

### 1-3. PR/Merge 패턴 분석

```bash
git log --merges --oneline -20          # 머지 커밋
git log --format="%s" --merges -20      # 머지 커밋 메시지 패턴
```

파악할 것:
- 머지 커밋 메시지 패턴
- squash merge vs merge commit vs rebase
- PR 번호 포함 여부 (#123)

### 1-4. 기존 Git 설정 확인

```bash
cat .gitignore                          # gitignore 내용
cat .gitattributes 2>/dev/null          # gitattributes
ls .husky/ 2>/dev/null                  # Husky hooks
cat .commitlintrc* 2>/dev/null          # commitlint 설정
cat .lintstagedrc* 2>/dev/null          # lint-staged 설정
ls .github/ 2>/dev/null                 # GitHub 설정 (PR 템플릿 등)
cat .github/pull_request_template.md 2>/dev/null
```

파악할 것:
- 기존 Git hook 도구 (Husky, lefthook, pre-commit)
- commitlint 설정 여부 및 규칙
- lint-staged 설정 여부
- PR 템플릿 존재 여부
- GitHub Actions 중 Git 관련 워크플로우

### 1-5. docs/project/ 참조 (있는 경우)

`docs/project/04-conventions.md`가 존재하면 읽어서 이미 분석된 컨벤션을 활용한다. 중복 분석을 피하고, 일관성을 유지하기 위함이다.

---

## Phase 2: 문서 작성

### 기존 파일 처리

- `docs/git/`가 이미 존재하면 사용자에게 확인한다
- 기본값: **백업 후 재생성** (`docs/git.bak-{timestamp}/`)

### 공통 작성 규칙

- 모든 문서 상단에 제목과 한줄 설명
- 분석 근거가 있는 규칙은 출처(커밋 해시, 설정 파일 경로)를 기재
- 관찰에서 추론한 규칙은 `> ⚠️ 추측: ...`으로 표기
- 팀에서 아직 합의되지 않은 것은 `<!-- TODO: 팀 합의 필요 -->`로 표기

---

### 01-commit.md — 커밋 메시지 컨벤션

프로젝트의 커밋 메시지 규칙을 정의한다.

**포함 항목:**

- **형식 정의**

  ```
  <type>(<scope>): <subject>

  <body>

  <footer>
  ```

- **type 목록** — 프로젝트에서 관찰된 타입 + 표준 타입

  | type | 설명 | 예시 |
  |------|------|------|
  | feat | 새 기능 | feat(auth): 소셜 로그인 추가 |
  | fix | 버그 수정 | fix(api): 토큰 만료 처리 |
  | refactor | 리팩토링 | refactor(db): 쿼리 최적화 |
  | docs | 문서 | docs: README 업데이트 |
  | test | 테스트 | test(user): 회원가입 테스트 |
  | chore | 빌드/도구 | chore: deps 업데이트 |
  | style | 포맷팅 | style: 세미콜론 추가 |
  | perf | 성능 | perf(render): 메모이제이션 적용 |
  | ci | CI/CD | ci: deploy 워크플로우 수정 |

- **scope 목록** — 프로젝트 디렉토리에서 자동 추출

  디렉토리 구조를 기반으로 유효한 scope을 나열한다. 예: `auth`, `api`, `ui`, `db`, `config`

- **subject 규칙** — 언어, 시제, 길이 제한
- **body/footer 규칙** — 본문 작성 기준, Breaking Change 표기, 이슈 참조
- **실제 예시 5개** — git log에서 발췌한 좋은 커밋 메시지

**작성 팁:**

- commitlint 설정이 있으면 그 규칙을 기준으로 한다
- 설정이 없으면 관찰된 패턴을 기준으로 하되, Conventional Commits를 권장사항으로 제시한다
- 기존 커밋이 비정형이면, 현재 상태를 기록하고 권장 형식을 별도로 제안한다

---

### 02-branch.md — 브랜치 전략 및 네이밍

**포함 항목:**

- **브랜치 전략** — 관찰된 전략 (Git Flow / GitHub Flow / Trunk-based)

  ```
  main (프로덕션)
   └── develop (개발)
        ├── feat/xxx (기능)
        ├── fix/xxx (버그)
        └── hotfix/xxx (긴급)
  ```

- **네이밍 규칙** — `{type}/{issue-number}-{description}` 형식 등
- **메인 브랜치 보호 규칙** — 직접 push 금지, PR 필수 등 (관찰된 경우)
- **브랜치 생명주기** — 생성 → 작업 → PR → 머지 → 삭제 흐름
- **예시** — 실제 브랜치 이름 3~5개

**작성 팁:**

- `git branch -r`에서 패턴을 추출한다
- 브랜치가 적으면 (1인 프로젝트 등) 권장 전략을 제안한다

---

### 03-pr.md — PR 생성 규칙 및 템플릿

**포함 항목:**

- **PR 제목 형식** — 커밋 컨벤션과의 관계
- **PR 본문 구조** — 기존 템플릿이 있으면 그대로, 없으면 제안

  ```markdown
  ## 변경 사항
  - 무엇을 왜 변경했는지

  ## 테스트
  - [ ] 단위 테스트 통과
  - [ ] 수동 테스트 완료

  ## 스크린샷 (UI 변경 시)

  ## 관련 이슈
  closes #123
  ```

- **리뷰 규칙** — 최소 리뷰어 수, 자동 할당 등 (관찰된 경우)
- **머지 전략** — squash / merge commit / rebase
- **라벨** — 사용 중인 라벨 목록 (있는 경우)

**작성 팁:**

- `.github/pull_request_template.md`가 있으면 내용을 기반으로 한다
- 없으면 프로젝트 규모에 맞는 템플릿을 제안한다
- 머지 커밋 패턴에서 squash 여부를 추론한다

---

### 04-workflow.md — Git 워크플로우

**포함 항목:**

- **일반 개발 흐름** — 브랜치 생성부터 머지까지 단계별 가이드

  ```
  1. main에서 브랜치 생성: git checkout -b feat/123-description
  2. 작업 및 커밋
  3. 리모트 push: git push -u origin feat/123-description
  4. PR 생성
  5. 리뷰 및 수정
  6. 머지 후 브랜치 삭제
  ```

- **충돌 해결 전략** — rebase vs merge, 권장 방법
- **릴리스 프로세스** — 태깅, 체인지로그, 배포 (관찰된 경우)
- **핫픽스 프로세스** — 긴급 수정 흐름 (있는 경우)
- **모노레포 특이사항** — 패키지별 버저닝 등 (해당 시)

**작성 팁:**

- CI/CD 워크플로우 파일이 있으면 배포 트리거 조건을 파악한다
- 릴리스 태그 패턴을 `git tag -l`에서 확인한다

---

### 05-hooks.md — Git Hooks

**포함 항목:**

- **현재 설정된 Hook 목록** — Husky, lefthook 등에서 추출
- **pre-commit** — 실행 내용 (lint-staged, 타입체크 등)
- **commit-msg** — commitlint 규칙
- **pre-push** — 테스트 실행 등
- **권장 Hook** — 현재 없지만 추가하면 좋은 Hook 제안

**작성 팁:**

- `.husky/` 또는 `.lefthook.yml`의 실제 내용을 기반으로 한다
- Hook이 없는 프로젝트라면, 프로젝트 스택에 맞는 Hook을 제안한다

---

## Phase 3: context.md 작성

### context.md 형식

```markdown
# Git Context Index

> 이 파일은 docs/git/ 하위 문서의 인덱스다.
> 생성일: {날짜} | 분석 대상: {프로젝트명}

## 문서 목록

| # | 파일 | 주제 | 요약 |
|---|------|------|------|
| 1 | [01-commit.md](./01-commit.md) | 커밋 컨벤션 | {한줄 요약} |
| 2 | [02-branch.md](./02-branch.md) | 브랜치 전략 | {한줄 요약} |
| 3 | [03-pr.md](./03-pr.md) | PR 규칙 | {한줄 요약} |
| 4 | [04-workflow.md](./04-workflow.md) | 워크플로우 | {한줄 요약} |
| 5 | [05-hooks.md](./05-hooks.md) | Git Hooks | {한줄 요약} |

## 요약

| 항목 | 값 |
|------|-----|
| 커밋 스타일 | {Conventional Commits / 자유형 / 기타} |
| 브랜치 전략 | {GitHub Flow / Git Flow / Trunk-based} |
| 메인 브랜치 | {main / master / develop} |
| 머지 전략 | {squash / merge commit / rebase} |
| Hook 도구 | {Husky / lefthook / 없음} |
| commitlint | {있음 / 없음} |
| lint-staged | {있음 / 없음} |

## 빠른 참조

| 작업 | 명령 |
|------|------|
| 기능 브랜치 생성 | `git checkout -b feat/{issue}-{desc}` |
| 커밋 | `git commit -m "feat(scope): description"` |
| PR 생성 | `gh pr create --title "feat(scope): ..." --body "..."` |
| 머지 후 정리 | `git branch -d feat/xxx && git push origin --delete feat/xxx` |

## 활용 방법

- CLAUDE.md에서 참조: `@docs/git/context.md`
- 개별 문서 참조: `@docs/git/01-commit.md`
- CLI에서: `claude -p "docs/git/context.md를 읽고 커밋 규칙 알려줘"`
```

---

## Phase 4: 검증

1. 5개 문서 + context.md 총 6개 파일이 모두 생성되었는지 확인
2. context.md의 테이블이 실제 파일과 일치하는지 확인
3. `<!-- TODO -->` 태그가 있는 항목을 사용자에게 리포트
4. 생성된 문서의 파일 목록과 줄 수를 출력

---

## Phase 5: 완료 리포트

사용자에게 다음을 안내한다:

- 생성된 파일 목록과 위치
- TODO 항목이 있다면 보완 필요 부분
- context.md 활용 방법
- setup-project의 `docs/project/04-conventions.md`와의 관계 (Git 컨벤션은 이 문서가 더 상세)
- 이후 setup-claude와의 연계 (Git hooks → Claude hooks 통합)
