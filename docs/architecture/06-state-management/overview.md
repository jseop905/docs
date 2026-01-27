# 상태 관리 개요

React 애플리케이션에서 **데이터(상태)를 관리하는 방법**에 대한 개요입니다.

---

## 상태의 종류

상태를 **종류별로 분리**해서 관리하면 효율적입니다.

```
상태 (State)
│
├── Server State (서버 상태)
│   └── API에서 가져온 데이터
│   └── 예: 사용자 목록, 상품 정보, 게시글
│   └── 도구: React Query, SWR, RTK Query
│
├── Client State (클라이언트 상태)
│   │
│   ├── Global State (전역 상태)
│   │   └── 앱 전체에서 공유되는 상태
│   │   └── 예: 로그인 사용자, 테마, 언어, 장바구니
│   │   └── 도구: Zustand, Jotai, Redux
│   │
│   └── Local State (지역 상태)
│       └── 특정 컴포넌트에서만 사용
│       └── 예: 모달 열림 상태, 폼 입력값, 토글
│       └── 도구: useState, useReducer
│
└── URL State (URL 상태)
    └── URL에 저장되는 상태
    └── 예: 검색어, 필터, 페이지 번호, 정렬
    └── 도구: useSearchParams, nuqs
```

---

## 상태별 특성

### Server State

- **출처**: 외부 서버/API
- **소유권**: 서버가 소유, 클라이언트는 캐시
- **비동기**: 항상 비동기 (로딩, 에러 상태 필요)
- **Stale**: 시간이 지나면 오래된 데이터가 됨
- **공유**: 여러 컴포넌트가 같은 데이터 사용 가능

```tsx
// Server State 예시
const { data, isLoading, error } = useQuery({
  queryKey: ['users'],
  queryFn: () => fetch('/api/users').then(r => r.json()),
})
```

### Client Global State

- **출처**: 클라이언트에서 생성
- **소유권**: 클라이언트가 소유
- **동기**: 보통 동기적
- **지속성**: 메모리에만 존재 (새로고침 시 초기화)
- **공유**: 여러 컴포넌트에서 접근

```tsx
// Client Global State 예시
const useThemeStore = create((set) => ({
  theme: 'light',
  setTheme: (theme) => set({ theme }),
}))
```

### Client Local State

- **출처**: 컴포넌트 내부
- **소유권**: 해당 컴포넌트
- **범위**: 컴포넌트 + 자식 컴포넌트
- **생명주기**: 컴포넌트와 함께

```tsx
// Local State 예시
const [isOpen, setIsOpen] = useState(false)
const [inputValue, setInputValue] = useState('')
```

### URL State

- **출처**: URL
- **공유**: 링크로 공유 가능
- **히스토리**: 브라우저 뒤로가기 지원
- **북마크**: 저장 가능

```tsx
// URL State 예시
// URL: /products?category=shoes&page=2
const searchParams = useSearchParams()
const category = searchParams.get('category')
const page = searchParams.get('page')
```

---

## 상태 관리 도구 비교

### Server State 관리

| 도구 | 특징 |
|------|------|
| **React Query** | 가장 인기, 강력한 캐싱, DevTools |
| **SWR** | Vercel 제작, 가벼움, 간단한 API |
| **RTK Query** | Redux 생태계, Redux와 통합 |

### Client State 관리

| 도구 | 크기 | 특징 |
|------|------|------|
| **Zustand** | 1.1KB | 간단, Flux 패턴, 미들웨어 |
| **Jotai** | 2KB | 원자적, Bottom-up, React스러움 |
| **Valtio** | 3KB | Proxy 기반, 뮤터블 스타일 |
| **Redux Toolkit** | 큼 | 성숙함, 대규모 앱, DevTools |
| **Recoil** | 큼 | Facebook 제작, 원자적 |

---

## 권장 조합

### 소규모 프로젝트

```
- Server State: React Query 또는 SWR
- Global State: useState + Context 또는 Zustand (필요시)
- Local State: useState
- URL State: useSearchParams
```

### 중규모 프로젝트

```
- Server State: React Query
- Global State: Zustand 또는 Jotai
- Local State: useState, useReducer
- Form State: React Hook Form
- URL State: nuqs 또는 useSearchParams
```

### 대규모 프로젝트

```
- Server State: React Query + 캐싱 전략
- Global State: Zustand (또는 Redux Toolkit)
- Local State: useState, useReducer
- Form State: React Hook Form + Zod
- URL State: nuqs
```

---

## 상태 위치 결정 가이드

```
이 상태는...
│
├─ 서버에서 오는 데이터인가?
│   └─ Yes → React Query / SWR
│
├─ URL에 있어야 하는가? (공유, 북마크)
│   └─ Yes → URL State (useSearchParams)
│
├─ 여러 컴포넌트에서 필요한가?
│   ├─ Yes, 멀리 떨어진 컴포넌트들 → Global State
│   └─ Yes, 가까운 컴포넌트들 → Context 또는 Props
│
└─ 이 컴포넌트에서만 필요한가?
    └─ Yes → Local State (useState)
```

---

## 흔한 실수

### 1. 모든 것을 전역 상태로 관리

```tsx
// ❌ 나쁜 예: 모든 것을 전역 스토어에
const useStore = create((set) => ({
  users: [],
  products: [],
  orders: [],
  modalOpen: false,        // 이건 local state여야 함
  searchQuery: '',         // 이건 URL state여야 함
  fetchUsers: async () => { ... },
  fetchProducts: async () => { ... },
}))

// ✅ 좋은 예: 상태 종류별로 분리
// Server State
const { data: users } = useQuery(['users'], fetchUsers)

// URL State
const [searchParams, setSearchParams] = useSearchParams()
const searchQuery = searchParams.get('q')

// Local State
const [modalOpen, setModalOpen] = useState(false)

// Global State (정말 필요한 것만)
const useAuthStore = create((set) => ({
  user: null,
  login: (user) => set({ user }),
  logout: () => set({ user: null }),
}))
```

### 2. Server State를 Client State처럼 관리

```tsx
// ❌ 나쁜 예: useEffect + useState로 서버 데이터 관리
function Users() {
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    fetchUsers()
      .then(setUsers)
      .catch(setError)
      .finally(() => setLoading(false))
  }, [])

  // 캐싱 없음, 중복 요청, 리페칭 수동 구현 필요...
}

// ✅ 좋은 예: React Query 사용
function Users() {
  const { data: users, isLoading, error } = useQuery({
    queryKey: ['users'],
    queryFn: fetchUsers,
    staleTime: 5 * 60 * 1000, // 5분 캐싱
  })

  // 자동 캐싱, 중복 요청 방지, 백그라운드 리페칭...
}
```

### 3. Props Drilling 해결책으로 바로 전역 상태 사용

```tsx
// ❌ 나쁜 예: 단순 props drilling 피하려고 전역 상태 사용
const useStore = create((set) => ({
  selectedItem: null,
  setSelectedItem: (item) => set({ selectedItem: item }),
}))

// ✅ 좋은 예: Context나 Composition으로 해결
function ParentComponent() {
  const [selectedItem, setSelectedItem] = useState(null)

  return (
    <ItemContext.Provider value={{ selectedItem, setSelectedItem }}>
      <ChildComponent />
    </ItemContext.Provider>
  )
}

// 또는 컴포넌트 합성
function ParentComponent() {
  const [selectedItem, setSelectedItem] = useState(null)

  return (
    <Layout
      sidebar={<Sidebar onSelect={setSelectedItem} />}
      main={<Main item={selectedItem} />}
    />
  )
}
```

---

## 다음 문서

- [React Query](./react-query.md) - 서버 상태 관리
- [Zustand](./zustand.md) - 간단한 전역 상태 관리
- [Jotai](./jotai.md) - 원자적 상태 관리
