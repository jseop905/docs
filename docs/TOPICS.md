# 문서화 추천 주제

프론트엔드 개발자가 알아두면 좋은 주제들을 정리했습니다.

---

## 현재 완료된 문서

- [x] **architecture/** - 프론트엔드 아키텍처 (라우팅, 프로젝트 구조, 상태 관리 등)

---

## 추천 주제 (우선순위순)

### 1. TypeScript 심화 ⭐⭐⭐
> 실무에서 바로 쓰이는 타입스크립트 패턴

```
docs/typescript/
├── 00-overview.md
├── 01-utility-types.md        # Pick, Omit, Partial, Required 등
├── 02-generics.md             # 제네릭 패턴
├── 03-type-guards.md          # 타입 가드, is, asserts
├── 04-conditional-types.md    # 조건부 타입
├── 05-mapped-types.md         # 맵드 타입
├── 06-template-literal.md     # 템플릿 리터럴 타입
├── 07-react-patterns.md       # React에서 자주 쓰는 타입 패턴
└── 08-common-mistakes.md      # 흔한 실수와 해결책
```

**다루면 좋은 내용:**
- 유틸리티 타입 활용법
- 제네릭 컴포넌트/훅 만들기
- API 응답 타입 안전하게 다루기
- `as const`, `satisfies` 활용
- 타입 좁히기 (narrowing)

---

### 2. 테스팅 ⭐⭐⭐
> 프론트엔드 테스트 전략과 도구

```
docs/testing/
├── 00-overview.md             # 테스트 피라미드, 전략
├── 01-unit-testing.md         # Jest, Vitest
├── 02-component-testing.md    # React Testing Library
├── 03-integration-testing.md  # MSW로 API 모킹
├── 04-e2e-testing.md          # Playwright, Cypress
├── 05-testing-patterns.md     # 테스트하기 좋은 코드 작성법
└── 06-ci-integration.md       # CI에서 테스트 자동화
```

**다루면 좋은 내용:**
- 뭘 테스트해야 하는가?
- React Testing Library 철학과 패턴
- MSW로 API 모킹하기
- Playwright vs Cypress
- 테스트 커버리지

---

### 3. 성능 최적화 ⭐⭐⭐
> Core Web Vitals와 최적화 기법

```
docs/performance/
├── 00-overview.md             # Core Web Vitals, 측정 도구
├── 01-loading-performance.md  # LCP, FCP 최적화
├── 02-runtime-performance.md  # 렌더링 최적화, useMemo, useCallback
├── 03-bundle-optimization.md  # 코드 스플리팅, 트리 쉐이킹
├── 04-image-optimization.md   # next/image, 포맷, lazy loading
├── 05-caching-strategies.md   # 브라우저 캐싱, CDN
├── 06-react-optimization.md   # React 특화 최적화
└── 07-monitoring.md           # Lighthouse, Web Vitals 모니터링
```

**다루면 좋은 내용:**
- LCP, FID, CLS 개선 방법
- React.memo, useMemo, useCallback 언제 쓰나
- 동적 import와 코드 스플리팅
- 이미지/폰트 최적화
- Vercel Analytics, Lighthouse CI

---

### 4. 인증 & 보안 ⭐⭐⭐
> 인증 구현과 보안 모범 사례

```
docs/auth-security/
├── 00-overview.md             # 인증 방식 비교
├── 01-nextauth.md             # NextAuth.js (Auth.js)
├── 02-jwt.md                  # JWT 토큰 관리
├── 03-oauth.md                # OAuth 2.0, 소셜 로그인
├── 04-session-management.md   # 세션 vs 토큰
├── 05-security-practices.md   # XSS, CSRF 방어
├── 06-middleware-auth.md      # Next.js 미들웨어로 인증
└── 07-rbac.md                 # 역할 기반 접근 제어
```

**다루면 좋은 내용:**
- NextAuth.js 설정과 커스터마이징
- Access Token / Refresh Token 패턴
- 쿠키 보안 설정 (httpOnly, secure, sameSite)
- API Route 보호
- 프론트엔드 보안 체크리스트

---

### 5. CI/CD & DevOps ⭐⭐
> 배포 자동화와 개발 환경

```
docs/cicd/
├── 00-overview.md             # CI/CD 개념
├── 01-github-actions.md       # GitHub Actions 워크플로우
├── 02-vercel-deployment.md    # Vercel 배포 전략
├── 03-preview-deployments.md  # PR Preview 환경
├── 04-environment-variables.md # 환경 변수 관리
├── 05-docker-basics.md        # Docker 기초 (프론트엔드용)
└── 06-monitoring-logging.md   # Sentry, 로깅
```

**다루면 좋은 내용:**
- GitHub Actions 기본 워크플로우
- Vercel/Netlify 배포 설정
- Preview 배포 활용
- 환경별 변수 관리
- Sentry 에러 모니터링

---

### 6. 코드 품질 & 컨벤션 ⭐⭐
> 일관된 코드 작성을 위한 도구

```
docs/code-quality/
├── 00-overview.md             # 코드 품질이 중요한 이유
├── 01-eslint.md               # ESLint 설정과 규칙
├── 02-prettier.md             # Prettier 설정
├── 03-husky-lint-staged.md    # Git Hooks
├── 04-conventional-commits.md # 커밋 메시지 컨벤션
├── 05-code-review.md          # 코드 리뷰 가이드
└── 06-documentation.md        # JSDoc, README 작성법
```

**다루면 좋은 내용:**
- ESLint + Prettier 충돌 해결
- Husky + lint-staged 설정
- Conventional Commits
- PR 템플릿, 코드 리뷰 체크리스트

---

### 7. 디자인 시스템 & 스타일링 ⭐⭐
> UI 일관성을 위한 시스템

```
docs/design-system/
├── 00-overview.md             # 디자인 시스템이란
├── 01-tailwind-advanced.md    # Tailwind CSS 심화
├── 02-css-modules.md          # CSS Modules 패턴
├── 03-css-in-js.md            # styled-components, Emotion
├── 04-component-library.md    # shadcn/ui, Radix UI
├── 05-theming.md              # 다크모드, 테마 시스템
├── 06-design-tokens.md        # 디자인 토큰 관리
└── 07-storybook.md            # Storybook 활용
```

**다루면 좋은 내용:**
- Tailwind CSS 커스터마이징
- shadcn/ui 활용법
- 다크모드 구현
- CSS 변수와 디자인 토큰
- Storybook으로 컴포넌트 문서화

---

### 8. 접근성 (a11y) ⭐⭐
> 모두를 위한 웹 만들기

```
docs/accessibility/
├── 00-overview.md             # 접근성 중요성, WCAG
├── 01-semantic-html.md        # 시맨틱 HTML
├── 02-keyboard-navigation.md  # 키보드 접근성
├── 03-screen-readers.md       # 스크린 리더 대응
├── 04-aria.md                 # ARIA 속성 활용
├── 05-forms.md                # 접근성 좋은 폼
├── 06-testing-a11y.md         # 접근성 테스트 도구
└── 07-checklist.md            # 접근성 체크리스트
```

---

### 9. 국제화 (i18n) ⭐
> 다국어 지원

```
docs/i18n/
├── 00-overview.md             # i18n 전략
├── 01-next-intl.md            # next-intl
├── 02-react-i18next.md        # react-i18next
├── 03-url-strategies.md       # URL 구조 전략
├── 04-date-number-format.md   # 날짜, 숫자 포맷
└── 05-rtl-support.md          # RTL 언어 지원
```

---

### 10. API & 데이터베이스 ⭐
> 풀스택 Next.js를 위한 백엔드 지식

```
docs/api-database/
├── 00-overview.md             # API 설계 원칙
├── 01-rest-best-practices.md  # REST API 모범 사례
├── 02-graphql-basics.md       # GraphQL 기초
├── 03-trpc.md                 # tRPC
├── 04-prisma.md               # Prisma ORM
├── 05-drizzle.md              # Drizzle ORM
└── 06-database-patterns.md    # 데이터베이스 패턴
```

---

## 추천 진행 순서

| 순서 | 주제 | 이유 |
|------|------|------|
| 1 | TypeScript 심화 | 모든 코드의 기반 |
| 2 | 테스팅 | 코드 품질 보장 |
| 3 | 성능 최적화 | 사용자 경험 개선 |
| 4 | 인증 & 보안 | 거의 모든 앱에 필요 |
| 5 | CI/CD | 배포 자동화 |
| 6 | 코드 품질 | 팀 협업 필수 |

---

## 원하는 주제 선택

위 주제 중 먼저 정리했으면 하는 것이 있으면 말씀해주세요.
여러 개를 동시에 진행할 수도 있습니다.
