# setup-claude

> 프로젝트의 기술 스택과 도구를 분석하여 `.claude/` 디렉토리에 Claude Code 설정(CLAUDE.md, hooks, settings, rules)을 자동 생성한다.

## 사용법

```bash
# CLI에서 실행
claude -p "setup-claude.md를 읽고 이 프로젝트에 맞는 Claude 설정을 생성해줘"

# setup-project, setup-git 이후 실행하면 기존 분석 결과를 활용한다
claude -p "setup-claude.md를 읽고, docs/project/context.md와 docs/git/context.md도 참고해서 세팅해줘"
```

---

## 생성 결과물

```
.claude/
├── CLAUDE.md                   # 프로젝트 메모리 (팀 공유)
├── settings.json               # 프로젝트 설정 (권한, hooks, 환경변수)
├── settings.local.json         # 개인 설정 (gitignore 대상)
├── hooks/                      # Hook 스크립트
│   ├── session-start.sh        # 세션 시작 시 환경 체크
│   ├── protect-files.sh        # 보호 파일 편집 차단
│   ├── auto-format.sh          # 파일 수정 후 자동 포맷팅
│   └── final-check.sh          # 응답 완료 시 최종 검증
└── rules/                      # 모듈화된 규칙
    ├── code-style.md           # 코드 스타일 규칙
    ├── testing.md              # 테스트 작성 규칙
    └── {stack-specific}.md     # 스택별 규칙 (react.md, api.md 등)
```

---

## Phase 1: 프로젝트 환경 분석

### 1-1. 기존 Claude 설정 확인

```bash
ls -la .claude/ 2>/dev/null             # .claude 디렉토리 존재 여부
cat .claude/CLAUDE.md 2>/dev/null       # 기존 CLAUDE.md
cat .claude/settings.json 2>/dev/null   # 기존 settings
cat CLAUDE.md 2>/dev/null               # 루트 CLAUDE.md
cat CLAUDE.local.md 2>/dev/null         # 로컬 CLAUDE.md
```

기존 설정이 있으면 내용을 분석하고, 덮어쓰기/병합/백업 여부를 사용자에게 확인한다.

### 1-2. 도구 감지 (Hook 구성을 위해)

각 도구의 존재 여부가 Hook 구성을 결정한다:

| 도구 | 감지 방법 | Hook 영향 |
|------|----------|----------|
| Prettier | `.prettierrc*`, `prettier.config.*` | PostToolUse → 자동 포맷 |
| ESLint | `.eslintrc*`, `eslint.config.*` | PostToolUse → 자동 린트 |
| Biome | `biome.json` | PostToolUse → 자동 포맷+린트 |
| TypeScript | `tsconfig.json` | Stop → 타입 체크 |
| Jest/Vitest | `jest.config.*`, `vitest.config.*` | Stop → 테스트 실행 |
| Playwright/Cypress | `playwright.config.*`, `cypress.config.*` | Stop → e2e 체크 (선택) |

### 1-3. 기존 문서 참조 (있는 경우)

`docs/project/context.md`가 있으면 기술 스택 요약과 명령어를 가져온다.
`docs/git/context.md`가 있으면 커밋 규칙과 브랜치 전략을 가져온다.

이전 setup의 분석 결과를 재활용하여 일관성을 유지한다.

---

## Phase 2: CLAUDE.md 생성

프로젝트의 핵심 컨텍스트를 담는 파일이다. Claude가 세션을 시작할 때마다 자동으로 읽는다.

### CLAUDE.md 형식

```markdown
# {프로젝트명}

{프로젝트 한줄 설명}

## 기술 스택

- 언어: {언어}
- 프레임워크: {프레임워크}
- 패키지 매니저: {PM}
- 테스트: {테스트 도구}

## 주요 명령어

| 명령 | 용도 |
|------|------|
| {dev 명령} | 개발 서버 실행 |
| {build 명령} | 빌드 |
| {test 명령} | 테스트 실행 |
| {lint 명령} | 린트 |

## 프로젝트 구조

{최상위 디렉토리 설명 — 간략하게}

## 컨벤션

- 커밋: {커밋 메시지 형식 한줄 요약}
- 브랜치: {브랜치 네이밍 한줄 요약}
- 코드 스타일: {핵심 규칙 2~3개}

## 참고 문서

@docs/project/context.md
@docs/git/context.md
```

**작성 원칙:**

- 간결하게 유지한다 — CLAUDE.md는 매 세션마다 로드되므로 짧을수록 좋다
- 상세 내용은 `@` 참조로 연결한다
- 명령어는 실제 package.json scripts에서 추출한다
- 이미 CLAUDE.md가 있으면 기존 내용과 병합을 제안한다

---

## Phase 3: settings.json 생성

### 3-1. 권한 설정

프로젝트 스택에 맞는 허용/차단 규칙을 설정한다:

```json
{
  "permissions": {
    "allow": [],
    "deny": []
  }
}
```

**allow 규칙 결정 기준:**

| 조건 | 추가할 규칙 |
|------|-----------|
| package.json에 test 스크립트 | `"Bash({pm} test *)"`, `"Bash({pm} run test *)"` |
| package.json에 lint 스크립트 | `"Bash({pm} run lint *)"` |
| package.json에 build 스크립트 | `"Bash({pm} run build *)"` |
| TypeScript 프로젝트 | `"Bash(npx tsc --noEmit *)"` |
| src/ 디렉토리 존재 | `"Read(src/**)"`, `"Write(src/**)"` |
| tests/ 디렉토리 존재 | `"Read(tests/**)"`, `"Write(tests/**)"` |

`{pm}`은 감지된 패키지 매니저(npm, pnpm, yarn, bun)로 치환한다.

**deny 규칙 (공통):**

```json
"deny": [
  "Read(.env)",
  "Read(.env.*)",
  "Read(**/credentials*)",
  "Read(**/*secret*)",
  "Bash(rm -rf *)",
  "Bash(git push --force *)",
  "Bash(git reset --hard *)"
]
```

### 3-2. 환경 변수

```json
{
  "env": {
    "NODE_ENV": "development"
  }
}
```

프로젝트에서 필요한 환경 변수가 있으면 추가한다 (비밀값 제외).

### 3-3. Hook 등록

Phase 4에서 생성하는 Hook 스크립트를 등록한다. 상세 구조는 Phase 4 참조.

---

## Phase 4: Hook 스크립트 생성

감지된 도구에 따라 필요한 Hook만 생성한다. 모든 Hook 스크립트는 `.claude/hooks/`에 배치한다.

### 4-1. session-start.sh — 세션 시작 체크

**항상 생성한다.** 세션 시작 시 프로젝트 환경을 확인한다.

```bash
#!/bin/bash
# .claude/hooks/session-start.sh
# 이벤트: SessionStart | 매처: startup

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

ISSUES=""

# Node.js 프로젝트: node_modules 존재 확인
if [ -f "$CWD/package.json" ] && [ ! -d "$CWD/node_modules" ]; then
  ISSUES="${ISSUES}⚠ node_modules가 없습니다. 의존성 설치가 필요합니다.\n"
fi

# .env 파일 확인
if [ -f "$CWD/.env.example" ] && [ ! -f "$CWD/.env" ]; then
  ISSUES="${ISSUES}⚠ .env 파일이 없습니다. .env.example을 복사하세요.\n"
fi

# Git 상태 확인
if [ -d "$CWD/.git" ]; then
  BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null)
  STATUS=$(git -C "$CWD" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  echo "{\"branch\": \"$BRANCH\", \"uncommitted_changes\": $STATUS}"
fi

if [ -n "$ISSUES" ]; then
  printf "$ISSUES" >&2
fi

exit 0
```

**settings.json 등록:**

```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "startup",
      "hooks": [{
        "type": "command",
        "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh",
        "timeout": 10
      }]
    }]
  }
}
```

### 4-2. protect-files.sh — 보호 파일 편집 차단

**항상 생성한다.** 민감한 파일의 편집을 차단한다.

```bash
#!/bin/bash
# .claude/hooks/protect-files.sh
# 이벤트: PreToolUse | 매처: Edit|Write

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

# 보호 대상 패턴
PROTECTED_PATTERNS=(
  "\.env$"
  "\.env\..*"
  "credentials"
  "secret"
  "\.pem$"
  "\.key$"
  "package-lock\.json$"
  "pnpm-lock\.yaml$"
  "yarn\.lock$"
)

for PATTERN in "${PROTECTED_PATTERNS[@]}"; do
  if echo "$FILE_PATH" | grep -qE "$PATTERN"; then
    echo "보호된 파일입니다: $FILE_PATH" >&2
    exit 2
  fi
done

exit 0
```

**settings.json 등록:**

```json
"PreToolUse": [{
  "matcher": "Edit|Write",
  "hooks": [{
    "type": "command",
    "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/protect-files.sh",
    "timeout": 5
  }]
}]
```

### 4-3. auto-format.sh — 자동 포맷팅

**Prettier, ESLint, 또는 Biome이 있을 때만 생성한다.**

```bash
#!/bin/bash
# .claude/hooks/auto-format.sh
# 이벤트: PostToolUse | 매처: Edit|Write

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

# 파일이 존재하는지 확인
[ -f "$FILE_PATH" ] || exit 0

# 대상 확장자 필터 (프로젝트에 맞게 조정)
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.scss|*.md)
    # --- Prettier가 있는 경우 ---
    # npx prettier --write "$FILE_PATH" 2>/dev/null

    # --- Biome이 있는 경우 ---
    # npx biome format --write "$FILE_PATH" 2>/dev/null

    # --- ESLint만 있는 경우 ---
    # npx eslint --fix "$FILE_PATH" 2>/dev/null
    ;;
esac

exit 0
```

실제 생성 시 감지된 도구에 맞게 주석을 해제한다.

**settings.json 등록:**

```json
"PostToolUse": [{
  "matcher": "Edit|Write",
  "hooks": [{
    "type": "command",
    "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/auto-format.sh",
    "timeout": 30
  }]
}]
```

### 4-4. final-check.sh — 최종 검증

**항상 생성한다.** Claude 응답 완료 시 빌드/타입/린트 상태를 확인한다.

```bash
#!/bin/bash
# .claude/hooks/final-check.sh
# 이벤트: Stop | 매처: (없음 — 모든 Stop에서 실행)

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
cd "$CWD" || exit 0

ERRORS=""

# --- TypeScript 프로젝트인 경우 ---
# if [ -f "tsconfig.json" ]; then
#   TSC_OUTPUT=$(npx tsc --noEmit 2>&1)
#   if [ $? -ne 0 ]; then
#     ERRORS="${ERRORS}❌ TypeScript 에러:\n${TSC_OUTPUT}\n\n"
#   fi
# fi

# --- lint 스크립트가 있는 경우 ---
# LINT_OUTPUT=$({pm} run lint 2>&1)
# if [ $? -ne 0 ]; then
#   ERRORS="${ERRORS}❌ Lint 에러:\n${LINT_OUTPUT}\n\n"
# fi

# --- test 스크립트가 있는 경우 ---
# TEST_OUTPUT=$({pm} test 2>&1)
# if [ $? -ne 0 ]; then
#   ERRORS="${ERRORS}❌ 테스트 실패:\n${TEST_OUTPUT}\n\n"
# fi

if [ -n "$ERRORS" ]; then
  printf "$ERRORS" >&2
  exit 2
fi

exit 0
```

실제 생성 시 프로젝트에 존재하는 도구만 주석을 해제하고, `{pm}`을 실제 패키지 매니저로 치환한다.

**settings.json 등록:**

```json
"Stop": [{
  "matcher": "",
  "hooks": [{
    "type": "command",
    "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/final-check.sh",
    "timeout": 120
  }]
}]
```

---

## Phase 5: rules 생성

`.claude/rules/` 디렉토리에 주제별 규칙 파일을 생성한다.

rules 파일은 `paths` 스코핑을 지원하므로, 특정 디렉토리의 파일을 수정할 때만 해당 규칙이 적용된다.

### 5-1. code-style.md — 코드 스타일 규칙

```yaml
---
paths:
  - "src/**"
  - "lib/**"
---
```

ESLint/Prettier/Biome 설정과 `docs/project/04-conventions.md`에서 추출한 핵심 규칙을 요약한다. 포맷터가 처리하는 규칙(들여쓰기, 세미콜론 등)은 제외하고, 의미적 규칙(네이밍, import 순서, 에러 처리 패턴 등)에 집중한다.

### 5-2. testing.md — 테스트 규칙

```yaml
---
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "__tests__/**"
  - "tests/**"
---
```

테스트 프레임워크, 파일 위치 규칙, 네이밍 컨벤션, 모킹 패턴, 커버리지 기준 등을 기술한다.

### 5-3. 스택별 규칙 — 감지된 기술에 따라

| 감지된 스택 | 생성 파일 | paths |
|-----------|----------|-------|
| React/Next.js | `react.md` | `src/components/**`, `src/app/**`, `src/pages/**` |
| API (Express/NestJS) | `api.md` | `src/api/**`, `src/routes/**`, `src/controllers/**` |
| DB (Prisma/TypeORM) | `database.md` | `prisma/**`, `src/db/**`, `src/entities/**` |

각 규칙 파일에는 해당 스택의 코딩 패턴, 금지사항, 권장사항을 기술한다.

---

## Phase 6: settings.local.json 생성

개인 설정 파일을 생성한다. 이 파일은 `.gitignore`에 추가해야 한다.

```json
{
  "permissions": {
    "allow": []
  }
}
```

`.gitignore`에 다음 라인이 없으면 추가를 제안한다:

```
.claude/settings.local.json
CLAUDE.local.md
```

---

## Phase 7: 검증

1. 생성된 모든 파일 목록을 출력한다
2. Hook 스크립트에 실행 권한(`chmod +x`)이 있는지 확인한다
3. settings.json이 유효한 JSON인지 확인한다
4. Hook 스크립트를 dry-run (빈 JSON `{}`을 stdin으로)하여 에러가 없는지 확인한다
5. CLAUDE.md의 `@` 참조 경로가 실제 파일과 일치하는지 확인한다

```bash
# Hook 스크립트 dry-run 예시
echo '{}' | bash .claude/hooks/session-start.sh
echo '{"tool_input":{"file_path":"test.ts"}}' | bash .claude/hooks/protect-files.sh
echo '{"tool_input":{"file_path":"test.ts"}}' | bash .claude/hooks/auto-format.sh
echo '{"cwd":"'$(pwd)'"}' | bash .claude/hooks/final-check.sh
```

---

## Phase 8: 완료 리포트

사용자에게 다음을 안내한다:

- 생성된 파일 목록과 각각의 역할
- 활성화된 Hook 목록과 트리거 조건
- settings.local.json을 .gitignore에 추가해야 하는지 여부
- CLAUDE.md에서 참조하는 문서 목록
- Claude 세션 재시작 시 새 설정이 자동 적용된다는 점
- 커스터마이즈 방법 (Hook 스크립트 수정, rules 추가, settings 조정)
