# React Query (TanStack Query)

**서버 상태 관리**를 위한 라이브러리입니다. API 데이터의 캐싱, 동기화, 업데이트를 자동으로 처리합니다.

---

## 설치 및 설정

```bash
npm install @tanstack/react-query
# DevTools (선택)
npm install @tanstack/react-query-devtools
```

### Provider 설정

```tsx
// app/providers.tsx
'use client'

import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'
import { useState } from 'react'

export function QueryProvider({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 60 * 1000, // 1분
            gcTime: 5 * 60 * 1000, // 5분 (이전의 cacheTime)
            retry: 1,
            refetchOnWindowFocus: false,
          },
        },
      })
  )

  return (
    <QueryClientProvider client={queryClient}>
      {children}
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  )
}
```

```tsx
// app/layout.tsx
import { QueryProvider } from './providers'

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <QueryProvider>{children}</QueryProvider>
      </body>
    </html>
  )
}
```

---

## 기본 사용법

### useQuery - 데이터 조회

```tsx
'use client'

import { useQuery } from '@tanstack/react-query'

interface User {
  id: string
  name: string
  email: string
}

async function fetchUsers(): Promise<User[]> {
  const response = await fetch('/api/users')
  if (!response.ok) {
    throw new Error('Failed to fetch users')
  }
  return response.json()
}

export function UserList() {
  const {
    data: users,
    isLoading,
    isError,
    error,
    refetch,
  } = useQuery({
    queryKey: ['users'],
    queryFn: fetchUsers,
  })

  if (isLoading) return <div>로딩 중...</div>
  if (isError) return <div>에러: {error.message}</div>

  return (
    <div>
      <button onClick={() => refetch()}>새로고침</button>
      <ul>
        {users?.map((user) => (
          <li key={user.id}>{user.name}</li>
        ))}
      </ul>
    </div>
  )
}
```

### 파라미터가 있는 쿼리

```tsx
'use client'

import { useQuery } from '@tanstack/react-query'

interface Product {
  id: string
  name: string
  price: number
}

async function fetchProduct(id: string): Promise<Product> {
  const response = await fetch(`/api/products/${id}`)
  if (!response.ok) throw new Error('Product not found')
  return response.json()
}

export function ProductDetail({ productId }: { productId: string }) {
  const { data: product, isLoading } = useQuery({
    queryKey: ['product', productId],  // productId가 바뀌면 새로 요청
    queryFn: () => fetchProduct(productId),
    enabled: !!productId,  // productId가 있을 때만 요청
  })

  if (isLoading) return <div>로딩 중...</div>

  return (
    <div>
      <h1>{product?.name}</h1>
      <p>{product?.price}원</p>
    </div>
  )
}
```

### useMutation - 데이터 변경

```tsx
'use client'

import { useMutation, useQueryClient } from '@tanstack/react-query'

interface CreateUserInput {
  name: string
  email: string
}

async function createUser(data: CreateUserInput) {
  const response = await fetch('/api/users', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  })

  if (!response.ok) throw new Error('Failed to create user')
  return response.json()
}

export function CreateUserForm() {
  const queryClient = useQueryClient()

  const mutation = useMutation({
    mutationFn: createUser,
    onSuccess: () => {
      // 성공 시 users 쿼리 무효화 → 자동으로 다시 가져옴
      queryClient.invalidateQueries({ queryKey: ['users'] })
    },
    onError: (error) => {
      alert(`에러: ${error.message}`)
    },
  })

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    const formData = new FormData(e.currentTarget)
    mutation.mutate({
      name: formData.get('name') as string,
      email: formData.get('email') as string,
    })
  }

  return (
    <form onSubmit={handleSubmit}>
      <input name="name" placeholder="이름" required />
      <input name="email" type="email" placeholder="이메일" required />
      <button type="submit" disabled={mutation.isPending}>
        {mutation.isPending ? '처리 중...' : '생성'}
      </button>
    </form>
  )
}
```

---

## 쿼리 키 설계

쿼리 키는 **캐시의 식별자**입니다. 배열 형태로 계층적으로 구성합니다.

### 기본 패턴

```tsx
// 단순 목록
queryKey: ['users']

// 상세 데이터
queryKey: ['users', userId]

// 필터링된 목록
queryKey: ['users', { status: 'active' }]

// 관계 데이터
queryKey: ['users', userId, 'posts']

// 필터 + 정렬 + 페이지네이션
queryKey: ['products', { category, sortBy, page }]
```

### Query Key Factory 패턴

```tsx
// lib/queryKeys.ts
export const userKeys = {
  all: ['users'] as const,
  lists: () => [...userKeys.all, 'list'] as const,
  list: (filters: UserFilters) => [...userKeys.lists(), filters] as const,
  details: () => [...userKeys.all, 'detail'] as const,
  detail: (id: string) => [...userKeys.details(), id] as const,
}

export const productKeys = {
  all: ['products'] as const,
  lists: () => [...productKeys.all, 'list'] as const,
  list: (filters: ProductFilters) => [...productKeys.lists(), filters] as const,
  details: () => [...productKeys.all, 'detail'] as const,
  detail: (id: string) => [...productKeys.details(), id] as const,
}
```

```tsx
// 사용 예시
import { userKeys } from '@/lib/queryKeys'

// 목록 조회
useQuery({
  queryKey: userKeys.list({ status: 'active' }),
  queryFn: () => fetchUsers({ status: 'active' }),
})

// 상세 조회
useQuery({
  queryKey: userKeys.detail(userId),
  queryFn: () => fetchUser(userId),
})

// 캐시 무효화
queryClient.invalidateQueries({ queryKey: userKeys.all })          // 모든 user 관련
queryClient.invalidateQueries({ queryKey: userKeys.lists() })       // 목록만
queryClient.invalidateQueries({ queryKey: userKeys.detail(userId) }) // 특정 상세
```

---

## 캐싱 전략

### staleTime vs gcTime

```tsx
const { data } = useQuery({
  queryKey: ['users'],
  queryFn: fetchUsers,
  staleTime: 5 * 60 * 1000,  // 5분 동안 "신선함"
  gcTime: 30 * 60 * 1000,    // 30분 후 캐시에서 삭제
})
```

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `staleTime` | 데이터가 "신선"한 시간. 이 시간 동안은 재요청 안 함 | 0 |
| `gcTime` | 캐시 유지 시간. 이 시간 후 가비지 컬렉션 | 5분 |

### 시나리오별 설정

```tsx
// 자주 변하지 않는 데이터 (설정, 카테고리 등)
useQuery({
  queryKey: ['categories'],
  queryFn: fetchCategories,
  staleTime: 24 * 60 * 60 * 1000, // 24시간
})

// 적당히 변하는 데이터 (상품 목록)
useQuery({
  queryKey: ['products'],
  queryFn: fetchProducts,
  staleTime: 5 * 60 * 1000, // 5분
})

// 자주 변하는 데이터 (알림)
useQuery({
  queryKey: ['notifications'],
  queryFn: fetchNotifications,
  staleTime: 30 * 1000, // 30초
  refetchInterval: 30 * 1000, // 30초마다 폴링
})

// 실시간 데이터 (주식 가격)
useQuery({
  queryKey: ['stockPrice', symbol],
  queryFn: () => fetchStockPrice(symbol),
  staleTime: 0,
  refetchInterval: 5 * 1000, // 5초마다
})
```

---

## 페이지네이션

### 기본 페이지네이션

```tsx
'use client'

import { useQuery, keepPreviousData } from '@tanstack/react-query'
import { useState } from 'react'

interface ProductsResponse {
  products: Product[]
  totalPages: number
  currentPage: number
}

export function ProductList() {
  const [page, setPage] = useState(1)

  const { data, isLoading, isPlaceholderData } = useQuery({
    queryKey: ['products', { page }],
    queryFn: () => fetchProducts({ page, limit: 10 }),
    placeholderData: keepPreviousData, // 페이지 전환 시 이전 데이터 유지
  })

  return (
    <div>
      {isLoading ? (
        <div>로딩 중...</div>
      ) : (
        <>
          <div style={{ opacity: isPlaceholderData ? 0.5 : 1 }}>
            {data?.products.map((product) => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>

          <div>
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page === 1}
            >
              이전
            </button>
            <span>
              {page} / {data?.totalPages}
            </span>
            <button
              onClick={() => setPage((p) => p + 1)}
              disabled={page === data?.totalPages}
            >
              다음
            </button>
          </div>
        </>
      )}
    </div>
  )
}
```

### 무한 스크롤

```tsx
'use client'

import { useInfiniteQuery } from '@tanstack/react-query'
import { useInView } from 'react-intersection-observer'
import { useEffect } from 'react'

interface ProductsPage {
  products: Product[]
  nextCursor: string | null
}

async function fetchProductsPage({ pageParam }: { pageParam?: string }): Promise<ProductsPage> {
  const url = pageParam
    ? `/api/products?cursor=${pageParam}`
    : '/api/products'
  const response = await fetch(url)
  return response.json()
}

export function InfiniteProductList() {
  const { ref, inView } = useInView()

  const {
    data,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    isLoading,
  } = useInfiniteQuery({
    queryKey: ['products', 'infinite'],
    queryFn: fetchProductsPage,
    getNextPageParam: (lastPage) => lastPage.nextCursor,
    initialPageParam: undefined,
  })

  // 스크롤이 하단에 도달하면 다음 페이지 로드
  useEffect(() => {
    if (inView && hasNextPage && !isFetchingNextPage) {
      fetchNextPage()
    }
  }, [inView, hasNextPage, isFetchingNextPage, fetchNextPage])

  if (isLoading) return <div>로딩 중...</div>

  return (
    <div>
      {data?.pages.map((page, i) => (
        <div key={i}>
          {page.products.map((product) => (
            <ProductCard key={product.id} product={product} />
          ))}
        </div>
      ))}

      <div ref={ref}>
        {isFetchingNextPage ? '더 불러오는 중...' : null}
      </div>
    </div>
  )
}
```

---

## 낙관적 업데이트

서버 응답을 기다리지 않고 **즉시 UI를 업데이트**합니다.

```tsx
'use client'

import { useMutation, useQueryClient } from '@tanstack/react-query'

interface Todo {
  id: string
  title: string
  completed: boolean
}

export function TodoItem({ todo }: { todo: Todo }) {
  const queryClient = useQueryClient()

  const toggleMutation = useMutation({
    mutationFn: (completed: boolean) =>
      fetch(`/api/todos/${todo.id}`, {
        method: 'PATCH',
        body: JSON.stringify({ completed }),
      }),

    // 낙관적 업데이트
    onMutate: async (newCompleted) => {
      // 진행 중인 쿼리 취소 (충돌 방지)
      await queryClient.cancelQueries({ queryKey: ['todos'] })

      // 이전 값 저장 (롤백용)
      const previousTodos = queryClient.getQueryData<Todo[]>(['todos'])

      // 낙관적으로 캐시 업데이트
      queryClient.setQueryData<Todo[]>(['todos'], (old) =>
        old?.map((t) =>
          t.id === todo.id ? { ...t, completed: newCompleted } : t
        )
      )

      // 이전 값 반환 (onError에서 사용)
      return { previousTodos }
    },

    // 에러 시 롤백
    onError: (err, newCompleted, context) => {
      queryClient.setQueryData(['todos'], context?.previousTodos)
    },

    // 성공/실패 상관없이 서버 데이터로 동기화
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['todos'] })
    },
  })

  return (
    <label>
      <input
        type="checkbox"
        checked={todo.completed}
        onChange={(e) => toggleMutation.mutate(e.target.checked)}
      />
      {todo.title}
    </label>
  )
}
```

---

## 에러 처리

### 전역 에러 처리

```tsx
// app/providers.tsx
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: (failureCount, error) => {
        // 404는 재시도 안 함
        if (error instanceof Error && error.message.includes('404')) {
          return false
        }
        return failureCount < 3
      },
    },
    mutations: {
      onError: (error) => {
        // 전역 에러 토스트
        toast.error(error.message)
      },
    },
  },
})
```

### 컴포넌트별 에러 처리

```tsx
import { useQuery } from '@tanstack/react-query'

export function UserProfile({ userId }: { userId: string }) {
  const { data, error, isError, isLoading } = useQuery({
    queryKey: ['user', userId],
    queryFn: () => fetchUser(userId),
    retry: false, // 이 쿼리는 재시도 안 함
  })

  if (isLoading) return <Skeleton />

  if (isError) {
    if (error.message.includes('404')) {
      return <div>사용자를 찾을 수 없습니다</div>
    }
    return <div>에러가 발생했습니다: {error.message}</div>
  }

  return <div>{data?.name}</div>
}
```

### Error Boundary와 함께 사용

```tsx
// app/products/page.tsx
import { Suspense } from 'react'
import { ErrorBoundary } from 'react-error-boundary'

function ErrorFallback({ error, resetErrorBoundary }) {
  return (
    <div>
      <p>에러가 발생했습니다</p>
      <button onClick={resetErrorBoundary}>다시 시도</button>
    </div>
  )
}

export default function ProductsPage() {
  return (
    <ErrorBoundary FallbackComponent={ErrorFallback}>
      <Suspense fallback={<div>로딩 중...</div>}>
        <ProductList />
      </Suspense>
    </ErrorBoundary>
  )
}
```

---

## Custom Hooks 패턴

```tsx
// hooks/useUsers.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { userKeys } from '@/lib/queryKeys'
import { userApi } from '@/api/userApi'

export function useUsers(filters?: UserFilters) {
  return useQuery({
    queryKey: userKeys.list(filters ?? {}),
    queryFn: () => userApi.getUsers(filters),
  })
}

export function useUser(id: string) {
  return useQuery({
    queryKey: userKeys.detail(id),
    queryFn: () => userApi.getUser(id),
    enabled: !!id,
  })
}

export function useCreateUser() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: userApi.createUser,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: userKeys.lists() })
    },
  })
}

export function useUpdateUser() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: UpdateUserInput }) =>
      userApi.updateUser(id, data),
    onSuccess: (_, { id }) => {
      queryClient.invalidateQueries({ queryKey: userKeys.detail(id) })
      queryClient.invalidateQueries({ queryKey: userKeys.lists() })
    },
  })
}

export function useDeleteUser() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: userApi.deleteUser,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: userKeys.all })
    },
  })
}
```

```tsx
// 사용 예시
function UsersPage() {
  const { data: users, isLoading } = useUsers({ status: 'active' })
  const createUser = useCreateUser()

  const handleCreate = async (data: CreateUserInput) => {
    await createUser.mutateAsync(data)
  }

  // ...
}
```

---

## Prefetching

### 호버 시 프리페칭

```tsx
import { useQueryClient } from '@tanstack/react-query'
import Link from 'next/link'

export function ProductCard({ product }: { product: Product }) {
  const queryClient = useQueryClient()

  const prefetchProduct = () => {
    queryClient.prefetchQuery({
      queryKey: ['product', product.id],
      queryFn: () => fetchProduct(product.id),
      staleTime: 60 * 1000, // 1분
    })
  }

  return (
    <Link
      href={`/products/${product.id}`}
      onMouseEnter={prefetchProduct}
      onFocus={prefetchProduct}
    >
      {product.name}
    </Link>
  )
}
```

### 서버에서 프리페칭 (Next.js)

```tsx
// app/products/page.tsx
import { dehydrate, HydrationBoundary, QueryClient } from '@tanstack/react-query'
import { ProductList } from './ProductList'

export default async function ProductsPage() {
  const queryClient = new QueryClient()

  // 서버에서 데이터 프리페칭
  await queryClient.prefetchQuery({
    queryKey: ['products'],
    queryFn: fetchProducts,
  })

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <ProductList />
    </HydrationBoundary>
  )
}
```

---

## 장단점

### 장점

- 강력한 캐싱 및 동기화
- 자동 리페칭 및 재시도
- DevTools로 디버깅 용이
- TypeScript 지원 우수
- 선언적 API

### 단점

- 러닝 커브
- 번들 크기 (약 12KB gzip)
- 단순한 앱에는 과도할 수 있음

---

## 참고 자료

- [TanStack Query 공식 문서](https://tanstack.com/query/latest)
- [React Query DevTools](https://tanstack.com/query/latest/docs/devtools)
