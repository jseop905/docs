# 실전 적용 가이드

프로젝트에 아키텍처를 적용할 때 참고할 수 있는 실전 가이드입니다.

---

## 프로젝트 규모별 권장 스택

### 소규모 프로젝트 (1-3명, MVP)

```
라우팅: Next.js App Router
구조: Feature-based (간단하게)
상태: useState + React Query
스타일: Tailwind CSS
```

```
my-project/
├── app/
│   ├── layout.tsx
│   ├── page.tsx
│   └── products/
│       └── page.tsx
├── components/           # 공통 컴포넌트
│   ├── Button.tsx
│   └── Input.tsx
├── features/             # 기능별 폴더
│   ├── auth/
│   │   ├── LoginForm.tsx
│   │   └── useAuth.ts
│   └── products/
│       ├── ProductCard.tsx
│       └── useProducts.ts
├── lib/                  # 유틸리티
│   └── utils.ts
└── package.json
```

### 중규모 프로젝트 (3-10명)

```
라우팅: Next.js App Router
구조: Feature-based (체계적) 또는 FSD (간소화)
상태: Zustand + React Query
스타일: Tailwind CSS + CSS Modules
폼: React Hook Form + Zod
```

```
my-project/
├── app/
│   ├── layout.tsx
│   ├── page.tsx
│   └── (routes)/
│       └── ...
├── features/
│   ├── auth/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── api/
│   │   ├── types/
│   │   └── index.ts
│   ├── products/
│   └── cart/
├── shared/
│   ├── components/
│   ├── hooks/
│   ├── utils/
│   └── types/
├── stores/               # Zustand 스토어
│   ├── authStore.ts
│   └── cartStore.ts
└── package.json
```

### 대규모 프로젝트 (10명+, 여러 서비스)

```
구조: Turborepo 모노레포 + FSD
라우팅: Next.js App Router
상태: Zustand + React Query
BFF: API Routes
스타일: 디자인 시스템 패키지
```

```
my-company/
├── apps/
│   ├── web/              # 메인 웹앱
│   ├── admin/            # 어드민
│   └── docs/             # 문서
├── packages/
│   ├── ui/               # 디자인 시스템
│   ├── api-client/       # API 클라이언트
│   ├── utils/            # 공유 유틸리티
│   └── config/           # 공유 설정
├── turbo.json
└── package.json
```

---

## 의사결정 플로우차트

### 렌더링 전략 선택

```
시작
│
├─ SEO가 필요한가?
│   ├─ No → CSR
│   │   └─ 대시보드, 관리자 페이지
│   └─ Yes ↓
│
├─ 데이터가 자주 변하는가?
│   ├─ No → SSG
│   │   └─ 블로그, 문서, 마케팅 페이지
│   └─ Yes ↓
│
├─ 실시간 데이터가 필요한가?
│   ├─ No → ISR (60초~)
│   │   └─ 상품 목록, 뉴스
│   └─ Yes ↓
│
└─ 사용자별 개인화가 필요한가?
    ├─ No → ISR (짧은 주기)
    └─ Yes → SSR
        └─ 마이페이지, 대시보드
```

### 상태 관리 도구 선택

```
이 상태는...
│
├─ 서버에서 오는 데이터인가?
│   └─ Yes → React Query
│
├─ URL에 표시되어야 하는가?
│   └─ Yes → useSearchParams / nuqs
│
├─ 여러 컴포넌트에서 공유되는가?
│   ├─ No → useState
│   └─ Yes ↓
│
├─ 가까운 컴포넌트들인가?
│   ├─ Yes → Context 또는 Props
│   └─ No → 전역 상태 (Zustand/Jotai)
│
└─ 파생 상태가 많은가?
    ├─ Yes → Jotai
    └─ No → Zustand
```

### 프로젝트 구조 선택

```
프로젝트 규모는?
│
├─ 소규모 (1-3명)
│   └─ Feature-based (간단)
│
├─ 중규모 (3-10명)
│   ├─ 비즈니스 로직 복잡? → FSD
│   └─ UI 중심? → Feature-based + Atomic Design
│
└─ 대규모 (10명+)
    └─ Turborepo + FSD
```

---

## 페이지별 전략 예시

### 전자상거래 사이트

| 페이지 | 렌더링 | 상태 | 이유 |
|--------|--------|------|------|
| 홈페이지 | ISR (60초) | React Query | SEO + 적당한 신선도 |
| 상품 목록 | ISR (60초) | React Query + URL | SEO + 필터/정렬 공유 |
| 상품 상세 | ISR (60초) | React Query | SEO + 재고 갱신 |
| 검색 결과 | SSR | React Query + URL | SEO + 동적 쿼리 |
| 장바구니 | CSR | Zustand (persist) | 로그인 불필요, SEO 불필요 |
| 체크아웃 | CSR | Local State | 민감 정보, SEO 불필요 |
| 마이페이지 | SSR | React Query | 개인화 |
| 주문 내역 | SSR | React Query | 개인화 |

### 블로그/콘텐츠 사이트

| 페이지 | 렌더링 | 상태 | 이유 |
|--------|--------|------|------|
| 홈페이지 | SSG | - | 정적, SEO |
| 글 목록 | SSG + ISR | URL | SEO + 페이지네이션 |
| 글 상세 | SSG | - | SEO + 변경 드묾 |
| 검색 | SSR | URL | 동적 쿼리 |
| 관리자 | CSR | React Query | SEO 불필요 |

### SaaS 대시보드

| 페이지 | 렌더링 | 상태 | 이유 |
|--------|--------|------|------|
| 랜딩 | SSG | - | SEO + 마케팅 |
| 로그인 | SSR | Local State | 보안 |
| 대시보드 | CSR | React Query | 실시간, SEO 불필요 |
| 설정 | CSR | React Query | 개인화, SEO 불필요 |
| 팀 관리 | CSR | React Query | 개인화, SEO 불필요 |

---

## 폴더 구조 템플릿

### Next.js App Router + Feature-based

```
src/
├── app/                          # Next.js App Router
│   ├── layout.tsx
│   ├── page.tsx
│   ├── globals.css
│   │
│   ├── (auth)/                   # 인증 관련 라우트 그룹
│   │   ├── login/
│   │   │   └── page.tsx
│   │   └── register/
│   │       └── page.tsx
│   │
│   ├── (main)/                   # 메인 라우트 그룹
│   │   ├── layout.tsx            # 공통 레이아웃 (헤더, 푸터)
│   │   ├── products/
│   │   │   ├── page.tsx
│   │   │   └── [id]/
│   │   │       └── page.tsx
│   │   └── cart/
│   │       └── page.tsx
│   │
│   └── api/                      # API Routes
│       └── ...
│
├── features/                     # 기능별 모듈
│   ├── auth/
│   │   ├── components/
│   │   │   ├── LoginForm.tsx
│   │   │   └── index.ts
│   │   ├── hooks/
│   │   │   ├── useAuth.ts
│   │   │   └── index.ts
│   │   ├── api/
│   │   │   └── authApi.ts
│   │   ├── types/
│   │   │   └── auth.types.ts
│   │   └── index.ts              # Public API
│   │
│   ├── products/
│   │   └── ...
│   │
│   └── cart/
│       └── ...
│
├── shared/                       # 공유 코드
│   ├── components/               # 공통 UI
│   │   ├── Button/
│   │   ├── Input/
│   │   └── index.ts
│   ├── hooks/                    # 공통 훅
│   │   ├── useDebounce.ts
│   │   └── index.ts
│   ├── utils/                    # 유틸리티
│   │   ├── formatDate.ts
│   │   └── index.ts
│   ├── types/                    # 공통 타입
│   │   └── index.ts
│   └── lib/                      # 외부 라이브러리 설정
│       └── queryClient.ts
│
├── stores/                       # Zustand 스토어
│   ├── authStore.ts
│   └── cartStore.ts
│
└── providers/                    # Context Providers
    └── index.tsx
```

### 파일 네이밍 규칙

```
컴포넌트:    PascalCase.tsx      (Button.tsx, ProductCard.tsx)
훅:          camelCase.ts        (useAuth.ts, useProducts.ts)
유틸리티:    camelCase.ts        (formatDate.ts, cn.ts)
타입:        *.types.ts          (user.types.ts, product.types.ts)
스토어:      *Store.ts           (authStore.ts, cartStore.ts)
API:         *Api.ts             (userApi.ts, productApi.ts)
상수:        SCREAMING_SNAKE     (constants/API_ENDPOINTS.ts)
```

---

## 자주 하는 실수와 해결책

### 1. 과도한 전역 상태

```tsx
// ❌ 모든 것을 전역 상태로
const useStore = create((set) => ({
  users: [],
  products: [],
  currentProduct: null,
  isModalOpen: false,
  searchQuery: '',
  // ...모든 것
}))

// ✅ 상태 종류별 분리
// Server State → React Query
const { data: users } = useQuery(['users'], fetchUsers)

// URL State → useSearchParams
const searchParams = useSearchParams()
const searchQuery = searchParams.get('q')

// Local State → useState
const [isModalOpen, setIsModalOpen] = useState(false)

// 진짜 전역 상태만 Zustand
const useAuthStore = create((set) => ({
  user: null,
  login: (user) => set({ user }),
}))
```

### 2. Props Drilling 공포

```tsx
// ❌ 바로 전역 상태로 도피
const useStore = create((set) => ({
  selectedItem: null,
}))

// ✅ 먼저 다른 방법 시도
// 1. Component Composition
function Parent() {
  const [selected, setSelected] = useState(null)
  return (
    <Layout
      sidebar={<Sidebar onSelect={setSelected} />}
      main={<Main selected={selected} />}
    />
  )
}

// 2. Context (범위 제한)
const SelectionContext = createContext(null)
function Parent() {
  const [selected, setSelected] = useState(null)
  return (
    <SelectionContext.Provider value={{ selected, setSelected }}>
      <Children />
    </SelectionContext.Provider>
  )
}
```

### 3. useEffect 남용

```tsx
// ❌ useEffect로 데이터 페칭
useEffect(() => {
  fetch('/api/users')
    .then((r) => r.json())
    .then(setUsers)
}, [])

// ✅ React Query 사용
const { data: users } = useQuery(['users'], fetchUsers)

// ❌ useEffect로 파생 상태 계산
useEffect(() => {
  setTotal(items.reduce((sum, i) => sum + i.price, 0))
}, [items])

// ✅ useMemo 사용
const total = useMemo(
  () => items.reduce((sum, i) => sum + i.price, 0),
  [items]
)
```

### 4. 너무 이른 최적화

```tsx
// ❌ 처음부터 복잡한 구조
src/
├── shared/
│   ├── ui/
│   │   ├── atoms/
│   │   ├── molecules/
│   │   └── organisms/
│   └── ...
├── entities/
├── features/
├── widgets/
└── pages/

// ✅ 필요할 때 점진적으로
// 시작: 간단하게
components/
├── Button.tsx
├── ProductCard.tsx
└── ...

// 커지면: 기능별 분리
features/
├── auth/
├── products/
└── ...

// 더 커지면: FSD로 리팩토링
```

### 5. API 응답 그대로 사용

```tsx
// ❌ API 응답을 그대로 컴포넌트에 전달
const { data } = useQuery(['product', id], fetchProduct)
return <ProductCard product={data} />

// ✅ 필요한 형태로 변환
const { data } = useQuery(['product', id], async () => {
  const response = await fetchProduct(id)
  return {
    id: response.product_id,
    name: response.product_name,
    price: response.price_krw,
    // UI에 필요한 형태로 변환
  }
})
```

---

## 체크리스트

### 프로젝트 시작 전

- [ ] 프로젝트 규모와 팀 크기 파악
- [ ] SEO 요구사항 확인
- [ ] 데이터 특성 파악 (정적/동적/실시간)
- [ ] 기술 스택 결정
- [ ] 폴더 구조 합의

### 개발 중

- [ ] 상태 종류별로 적절한 도구 사용
- [ ] 컴포넌트 책임 분리 (단일 책임)
- [ ] 재사용 가능한 코드는 shared로
- [ ] 타입 안전성 확보
- [ ] 에러 처리 일관성

### 코드 리뷰

- [ ] 전역 상태가 적절한가?
- [ ] 렌더링 전략이 맞는가?
- [ ] 불필요한 리렌더링 없는가?
- [ ] 에러 처리 되어 있는가?
- [ ] 타입이 제대로 정의되어 있는가?

---

## 마이그레이션 가이드

### Pages Router → App Router

1. `app` 폴더 생성
2. 새 기능은 App Router로 개발
3. 기존 페이지를 점진적으로 마이그레이션
4. 모든 페이지 마이그레이션 후 `pages` 폴더 삭제

### Redux → Zustand

1. Zustand 스토어 생성
2. 한 기능씩 마이그레이션
3. 테스트로 동작 확인
4. Redux 코드 제거

### 단일 저장소 → 모노레포

1. Turborepo 설정
2. 공유 코드를 packages로 추출
3. 앱들을 apps로 이동
4. 의존성 정리

---

## 참고 자료

### 공식 문서

- [Next.js](https://nextjs.org/docs)
- [React](https://react.dev)
- [TanStack Query](https://tanstack.com/query)
- [Zustand](https://docs.pmnd.rs/zustand)
- [Jotai](https://jotai.org)
- [Turborepo](https://turbo.build/repo)

### 아키텍처

- [Feature-Sliced Design](https://feature-sliced.design)
- [Atomic Design](https://bradfrost.com/blog/post/atomic-web-design)
- [Bulletproof React](https://github.com/alan2207/bulletproof-react)

### 커뮤니티

- [Next.js Discord](https://discord.gg/nextjs)
- [Reactiflux Discord](https://discord.gg/reactiflux)
