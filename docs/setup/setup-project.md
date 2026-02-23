# setup-project

> 프로젝트 코드베이스를 분석하여 `docs/project/` 디렉토리에 구조화된 문서를 자동 생성한다.

## 사용법

```bash
# CLI에서 실행
claude -p "setup-project.md를 읽고 이 프로젝트를 분석해서 문서를 생성해줘"

# 특정 경로 지정
claude -p "setup-project.md를 읽고 /path/to/project를 분석해줘"

# MCP에서 Read 도구로 이 파일을 읽은 뒤 지시를 따른다
```

---

## 생성 결과물

```
docs/project/
├── context.md          # 인덱스 — 전체 문서 목록, 기술 스택 요약, 주요 명령어
├── 01-overview.md      # 프로젝트 개요
├── 02-environment.md   # 개발 환경 및 도구
├── 03-architecture.md  # 아키텍처 및 디렉토리 구조
├── 04-conventions.md   # 네이밍, 코딩, 커밋 컨벤션
├── 05-coding-guide.md  # 코딩 가이드 및 패턴
└── 06-libraries.md     # 주요 라이브러리 및 의존성
```

---

## Phase 1: 프로젝트 분석

아래 항목을 순서대로 조사한다. 각 결과는 Phase 2에서 문서 작성의 재료가 된다.

### 1-1. 기본 구조 파악

프로젝트 루트를 탐색한다:

```
- ls -la (루트 파일 목록)
- 디렉토리 트리 (최대 3단계, node_modules 등 제외)
- README.md 내용
```

파악할 것:
- 프로젝트 이름과 목적 (README, package.json의 description 등)
- 모노레포 여부 (packages/, apps/, workspaces 설정, pnpm-workspace.yaml)
- 루트의 설정 파일 목록

### 1-2. 기술 스택 감지

| 감지 대상 | 확인 파일 |
|----------|----------|
| 언어 | `*.ts`, `*.py`, `*.go`, `*.rs`, `*.java` 등의 분포 |
| 패키지 매니저 | `package-lock.json`(npm), `pnpm-lock.yaml`(pnpm), `yarn.lock`(yarn), `bun.lockb`(bun) |
| 프레임워크 | `next.config.*`, `nuxt.config.*`, `angular.json`, `vite.config.*`, `nest-cli.json` 등 |
| 런타임 버전 | `.node-version`, `.nvmrc`, `.python-version`, `.tool-versions`, `engines` |
| 빌드 도구 | `tsconfig.json`, `webpack.config.*`, `turbo.json`, `nx.json` |
| 테스트 | `jest.config.*`, `vitest.config.*`, `playwright.config.*`, `pytest.ini` |
| 린트/포맷 | `.eslintrc.*`, `eslint.config.*`, `.prettierrc.*`, `biome.json` |
| CI/CD | `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile` |
| 인프라 | `Dockerfile`, `docker-compose.*`, `*.tf`, `serverless.yml`, `fly.toml`, `vercel.json` |

### 1-3. 의존성 분석

패키지 매니저 설정 파일에서 주요 의존성을 추출한다:

- `package.json` → dependencies / devDependencies
- `requirements.txt`, `pyproject.toml` → Python
- `go.mod` → Go, `Cargo.toml` → Rust

카테고리로 분류: 프레임워크 / UI / 상태관리 / 데이터페칭 / 테스트 / 빌드 / 유틸리티

### 1-4. 아키텍처 분석

디렉토리 구조에서 아키텍처 패턴을 추론한다:

- `src/` 하위 구조 (계층형, 기능별, 도메인별)
- API 라우트 구조 (`pages/api/`, `app/api/`, `routes/`)
- 공유 모듈 패턴 (`shared/`, `common/`, `utils/`, `lib/`)
- 상태 관리 패턴 (`store/`, `redux/`, `zustand`)
- 테스트 구조 (`__tests__/`, `*.test.*`, `*.spec.*`, `tests/`)

### 1-5. 컨벤션 분석

기존 코드와 설정에서 컨벤션을 추출한다:

- Git 커밋 히스토리 최근 30개 → 커밋 메시지 패턴
- `git branch -r` → 브랜치 네이밍 패턴
- ESLint/Prettier/Biome 설정 → 코드 스타일 규칙
- tsconfig.json → TypeScript 설정 (strict, paths 등)
- 파일/폴더 네이밍 패턴 (camelCase, kebab-case, PascalCase)

---

## Phase 2: 문서 작성

### 기존 파일 처리

- `docs/project/`가 이미 존재하면, 기존 파일 목록을 보여주고 사용자에게 확인한다
- "덮어쓰기", "병합", "백업 후 재생성" 중 선택
- 기본값: **백업 후 재생성** (`docs/project.bak-{timestamp}/`)

### 공통 작성 규칙

- 모든 문서 상단에 제목과 한줄 설명을 포함한다
- 파악하지 못한 항목: `<!-- TODO: 확인 필요 -->` 표기
- 추측이 포함된 경우: `> ⚠️ 추측: ...` 블록인용으로 명시
- 근거가 있는 경우: 해당 파일 경로를 출처로 기재

---

### 01-overview.md — 프로젝트 개요

프로젝트를 처음 접하는 사람이 5분 안에 전체 그림을 파악할 수 있어야 한다.

**포함 항목:**

- **프로젝트 이름과 한줄 설명**
- **목적과 해결하는 문제** — 이 프로젝트가 왜 존재하는지
- **핵심 기능 목록** — 주요 기능 3~7개
- **기술 스택 한눈에 보기** — 언어, 프레임워크, DB, 인프라를 테이블로
- **프로젝트 상태** — 개발 단계 (초기, 활발한 개발, 유지보수 등)
- **시작하기** — 로컬에서 실행하기까지 최소 단계 (3~5 스텝)

**작성 팁:**

- README.md가 있으면 내용을 기반으로 하되, 그대로 복사하지 않는다
- README에 없는 정보는 코드에서 추론하되, 추측임을 명시한다
- "시작하기"는 package.json scripts나 Makefile에서 추출한다

---

### 02-environment.md — 개발 환경 및 도구

개발자가 환경을 세팅할 때 필요한 모든 정보를 담는다.

**포함 항목:**

- **필수 런타임 & 버전** — Node.js, Python, Go 등 (버전 파일 기반)
- **패키지 매니저** — 종류와 버전 (`packageManager` 필드 등)
- **환경 변수** — `.env.example`에서 추출한 키 목록 (값은 절대 포함하지 않는다)
- **주요 CLI 도구** — 빌드, 테스트, 린트에 사용하는 도구
- **IDE 설정** — `.vscode/`, `.idea/` 설정이 있다면 주요 항목
- **Docker** — Dockerfile, docker-compose가 있다면 구성 설명
- **스크립트 목록** — package.json scripts 또는 Makefile 타겟을 테이블로

**작성 팁:**

- 버전은 `.node-version`, `.tool-versions`, `engines` 등 출처를 명시한다
- Docker가 있다면 "Docker 없이 실행하는 방법"도 함께 기재한다

---

### 03-architecture.md — 아키텍처 및 디렉토리 구조

코드를 수정하기 전에 "어디에 무엇이 있는지"를 파악하기 위한 문서다.

**포함 항목:**

- **디렉토리 구조 트리** — 최상위 3단계, 각 디렉토리에 한줄 설명
- **아키텍처 패턴** — 사용 중인 패턴 (레이어드, 클린, 기능별, DDD 등)
- **핵심 모듈/패키지** — 각 모듈의 역할과 의존 관계
- **데이터 흐름** — 요청→응답 흐름 (API 프로젝트의 경우)
- **상태 관리** — 프론트엔드라면 상태 관리 방식과 구조
- **라우팅** — URL/페이지 구조 또는 API 엔드포인트 구조
- **공유 코드** — `shared/`, `common/`, `utils/`의 역할 구분

**작성 팁:**

- 디렉토리 트리는 실제 `tree` 명령 결과를 기반으로 한다
- 모노레포라면 각 패키지/앱별로 별도 섹션을 둔다
- 의존 관계가 복잡하면 텍스트 다이어그램으로 표현한다:
  ```
  [Client] → [API Gateway] → [Service Layer] → [Repository] → [DB]
  ```

---

### 04-conventions.md — 네이밍, 코딩, 커밋 컨벤션

팀이 합의한(또는 코드에서 관찰되는) 규칙을 정리한다.

**포함 항목:**

- **파일/폴더 네이밍** — 관찰된 패턴과 적용 범위
- **변수/함수 네이밍** — 네이밍 규칙과 예시
- **Git 커밋 메시지** — 관찰된 패턴 + Conventional Commits 여부
  - 타입 목록 (feat, fix, chore 등)
  - 스코프 목록 (프로젝트 디렉토리에서 추출)
  - 예시 3~5개 (실제 커밋 히스토리에서 발췌)
- **브랜치 전략** — 관찰된 브랜치 네이밍 패턴
- **import 순서** — 그룹핑 규칙 (builtin → external → internal → relative)
- **타입 정의 위치** — co-located vs centralized
- **에러 처리 패턴** — try-catch 위치, 에러 타입 정의
- **코드 포맷팅** — ESLint/Prettier 주요 규칙 요약

**작성 팁:**

- 관찰된 패턴과 설정 파일에 명시된 규칙을 구분한다
- 불일치가 있으면 (`관찰: camelCase` vs `설정: kebab-case`) 그대로 기록한다
- 커밋 메시지 예시는 실제 git log에서 가져온다

---

### 05-coding-guide.md — 코딩 가이드 및 패턴

프로젝트에서 반복적으로 사용되는 코딩 패턴과 가이드라인을 정리한다.

**포함 항목:**

- **컴포넌트 작성 패턴** — 프론트엔드라면 컴포넌트 구조
- **API 핸들러 패턴** — 백엔드라면 라우트 핸들러 작성법
- **데이터 페칭** — 데이터 가져오는 방식 (SWR, React Query, fetch 등)
- **에러 핸들링** — 에러 처리 패턴과 에러 바운더리
- **테스트 작성법** — 테스트 구조, 네이밍, 모킹 패턴
  - 단위 테스트 / 통합 테스트 / 테스트 파일 위치 규칙
- **환경별 분기** — 개발/스테이징/프로덕션 분기 방법
- **로깅** — 로깅 라이브러리와 로그 레벨 사용법
- **자주 하는 작업 레시피** — 새 페이지 추가, API 엔드포인트 추가 등

**작성 팁:**

- 프로젝트의 실제 코드에서 예시를 추출한다
- "이렇게 하라"보다 "이 프로젝트에서는 이렇게 하고 있다"로 서술한다
- 테스트 작성법은 기존 테스트 파일에서 패턴을 추출한다

---

### 06-libraries.md — 주요 라이브러리 및 의존성

프로젝트에서 사용하는 라이브러리와 그 역할을 정리한다.

**포함 항목:**

- **카테고리별 라이브러리 테이블**:

  | 카테고리 | 라이브러리 | 버전 | 용도 |
  |---------|----------|------|------|
  | 프레임워크 | Next.js | 14.x | 풀스택 React 프레임워크 |
  | UI | shadcn/ui | - | 컴포넌트 라이브러리 |

- **카테고리 분류**: 프레임워크 / UI·스타일링 / 상태관리 / 데이터페칭·API / 폼·검증 / 테스트 / 빌드·번들 / 린트·포맷 / 유틸리티 / 인프라·배포

- **주요 라이브러리 상세** — 핵심 라이브러리 3~5개는 프로젝트에서 어떻게 쓰이는지 설명
- **내부 패키지** — 모노레포라면 내부 패키지 목록과 역할
- **버전 정책** — 버전 고정 여부, 업데이트 정책

**작성 팁:**

- dependencies와 devDependencies를 구분한다
- 역할이 명확한 것 위주로 정리한다 (전부 나열하지 않음)
- 사용하지 않는 것으로 보이는 의존성은 `(미사용 추정)` 표기

---

## Phase 3: context.md 작성

모든 문서 작성이 완료되면 `docs/project/context.md`를 생성한다. 이 파일은 사용자가 claude 커맨드, CLAUDE.md, 또는 다른 문서에서 참조하는 인덱스 역할을 한다.

### context.md 형식

```markdown
# Project Context Index

> 이 파일은 docs/project/ 하위 문서의 인덱스다.
> 생성일: {날짜} | 분석 대상: {프로젝트명}

## 문서 목록

| # | 파일 | 주제 | 요약 |
|---|------|------|------|
| 1 | [01-overview.md](./01-overview.md) | 프로젝트 개요 | {한줄 요약} |
| 2 | [02-environment.md](./02-environment.md) | 개발 환경 | {한줄 요약} |
| 3 | [03-architecture.md](./03-architecture.md) | 아키텍처 | {한줄 요약} |
| 4 | [04-conventions.md](./04-conventions.md) | 컨벤션 | {한줄 요약} |
| 5 | [05-coding-guide.md](./05-coding-guide.md) | 코딩 가이드 | {한줄 요약} |
| 6 | [06-libraries.md](./06-libraries.md) | 주요 라이브러리 | {한줄 요약} |

## 기술 스택 요약

| 항목 | 값 |
|------|-----|
| 언어 | {감지된 언어} |
| 프레임워크 | {감지된 프레임워크} |
| 패키지 매니저 | {감지된 PM} |
| 빌드 도구 | {감지된 빌드 도구} |
| 테스트 도구 | {감지된 테스트 도구} |
| 린트/포맷 | {감지된 린트/포맷} |
| CI/CD | {감지된 CI} |
| 인프라 | {감지된 인프라} |

## 주요 명령어

| 명령 | 용도 |
|------|------|
| {scripts에서 추출} | {설명} |

## 활용 방법

- CLAUDE.md에서 참조: `@docs/project/context.md`
- 개별 문서 참조: `@docs/project/03-architecture.md`
- CLI에서: `claude -p "docs/project/context.md를 읽고 프로젝트 설명해줘"`

## 보완 필요 항목

{TODO 태그가 있는 항목 목록}
```

---

## Phase 4: 검증

문서 작성 후 아래를 확인한다:

1. 6개 문서 + context.md 총 7개 파일이 모두 생성되었는지 확인
2. context.md의 테이블이 실제 파일과 일치하는지 확인
3. `<!-- TODO -->` 태그가 있는 항목을 집계하여 사용자에게 리포트
4. 생성된 문서의 파일 목록과 줄 수를 출력

---

## Phase 5: 완료 리포트

사용자에게 다음을 안내한다:

- 생성된 파일 목록과 위치
- TODO 항목이 있다면 보완이 필요한 부분
- context.md 활용 방법 (`@docs/project/context.md`로 CLAUDE.md에서 참조 등)
- 이후 setup-git, setup-claude 등 다른 setup과의 연계 방법
