# 프론트엔드 아키텍처 가이드

> React, Next.js, Turborepo에서 사용되는 주요 아키텍처 패턴 모음

---

## 문서 구조

```
docs/
├── 00-overview.md              # 현재 문서 (목차)
│
├── 01-routing/                 # 라우팅 아키텍처
│   ├── pages-router.md         # Next.js Pages Router
│   └── app-router.md           # Next.js App Router
│
├── 02-project-structure/       # 프로젝트 구조 패턴
│   ├── fsd.md                  # Feature-Sliced Design
│   ├── atomic-design.md        # Atomic Design
│   └── feature-based.md        # Feature-based Structure
│
├── 03-backend-integration/     # 백엔드 통합 패턴
│   ├── bff-pattern.md          # BFF (Backend For Frontend)
│   ├── api-routes.md           # Next.js API Routes
│   └── server-actions.md       # Next.js Server Actions
│
├── 04-monorepo/                # 모노레포 아키텍처
│   └── turborepo.md            # Turborepo
│
├── 05-rendering/               # 렌더링 전략
│   └── rendering-strategies.md # CSR, SSR, SSG, ISR, RSC
│
├── 06-state-management/        # 상태 관리
│   ├── overview.md             # 상태 관리 개요
│   ├── react-query.md          # React Query (TanStack Query)
│   ├── zustand.md              # Zustand
│   └── jotai.md                # Jotai
│
└── 07-practical-guide.md       # 실전 적용 가이드
```

---

## 빠른 참조

### 어떤 라우팅을 써야 할까?

| 상황 | 권장 |
|------|------|
| 새 프로젝트 | [App Router](./01-routing/app-router.md) |
| 레거시 프로젝트 | [Pages Router](./01-routing/pages-router.md) |
| RSC가 필요함 | [App Router](./01-routing/app-router.md) |

### 어떤 프로젝트 구조를 써야 할까?

| 상황 | 권장 |
|------|------|
| 소규모 (1-3명) | [Feature-based](./02-project-structure/feature-based.md) |
| 중규모 (3-10명) | [FSD](./02-project-structure/fsd.md) |
| 디자인 시스템 구축 | [Atomic Design](./02-project-structure/atomic-design.md) |

### 어떤 렌더링 전략을 써야 할까?

| 상황 | 권장 |
|------|------|
| SEO 중요 + 정적 콘텐츠 | SSG / ISR |
| SEO 중요 + 동적 콘텐츠 | SSR |
| 대시보드, 관리자 | CSR |
| 대부분의 경우 | RSC (App Router 기본) |

자세한 내용: [렌더링 전략](./05-rendering/rendering-strategies.md)

### 어떤 상태 관리를 써야 할까?

| 상태 종류 | 권장 |
|----------|------|
| 서버 데이터 (API) | [React Query](./06-state-management/react-query.md) |
| 전역 UI 상태 | [Zustand](./06-state-management/zustand.md) |
| 원자적 상태 | [Jotai](./06-state-management/jotai.md) |
| 지역 상태 | useState |

---

## 권장 학습 순서

1. **[App Router](./01-routing/app-router.md)** - Next.js의 새로운 라우팅 시스템
2. **[Feature-based](./02-project-structure/feature-based.md)** - 가장 실용적인 프로젝트 구조
3. **[렌더링 전략](./05-rendering/rendering-strategies.md)** - CSR/SSR/SSG/ISR/RSC 이해
4. **[React Query](./06-state-management/react-query.md)** - 서버 상태 관리
5. **[Zustand](./06-state-management/zustand.md)** - 클라이언트 상태 관리
6. **[FSD](./02-project-structure/fsd.md)** - 대규모 프로젝트 구조
7. **[Turborepo](./04-monorepo/turborepo.md)** - 모노레포 관리
8. **[실전 가이드](./07-practical-guide.md)** - 종합 적용

---

## 참고 자료

- [Next.js 공식 문서](https://nextjs.org/docs)
- [Feature-Sliced Design](https://feature-sliced.design/)
- [Atomic Design by Brad Frost](https://bradfrost.com/blog/post/atomic-web-design/)
- [Turborepo](https://turbo.build/repo/docs)
- [TanStack Query](https://tanstack.com/query/latest)
- [Zustand](https://github.com/pmndrs/zustand)
- [Jotai](https://jotai.org/)
