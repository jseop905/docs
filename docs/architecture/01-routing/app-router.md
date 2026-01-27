# App Router (Next.js 13+)

Next.js 13부터 도입된 새로운 라우팅 방식입니다. React Server Components를 기본으로 지원하며, 레이아웃, 로딩, 에러 처리가 내장되어 있습니다.

---

## 핵심 개념

### 파일 기반 라우팅

`app` 폴더 안의 구조가 URL이 됩니다. 단, **`page.tsx` 파일이 있어야** 라우트가 됩니다.

```
app/
├── page.tsx              # → /
├── about/
│   └── page.tsx          # → /about
└── blog/
    ├── page.tsx          # → /blog
    └── [slug]/
        └── page.tsx      # → /blog/:slug
```

### Server Components가 기본

모든 컴포넌트는 기본적으로 **Server Component**입니다. 클라이언트에서 실행되어야 하는 컴포넌트는 `'use client'`를 선언합니다.

---

## 폴더 구조

```
app/
├── layout.tsx              # 루트 레이아웃 (필수)
├── page.tsx                # 홈페이지 (/)
├── globals.css             # 전역 스타일
├── loading.tsx             # 전역 로딩 UI
├── error.tsx               # 전역 에러 UI
├── not-found.tsx           # 404 페이지
│
├── about/
│   └── page.tsx            # /about
│
├── blog/
│   ├── layout.tsx          # 블로그 전용 레이아웃
│   ├── page.tsx            # /blog
│   ├── loading.tsx         # 블로그 로딩 UI
│   └── [slug]/
│       ├── page.tsx        # /blog/:slug
│       └── loading.tsx
│
├── products/
│   ├── page.tsx            # /products
│   └── [id]/
│       ├── page.tsx        # /products/:id
│       └── reviews/
│           └── page.tsx    # /products/:id/reviews
│
├── (auth)/                 # Route Group (URL에 영향 없음)
│   ├── login/
│   │   └── page.tsx        # /login
│   └── register/
│       └── page.tsx        # /register
│
├── @modal/                 # Parallel Route
│   └── login/
│       └── page.tsx
│
└── api/
    └── users/
        └── route.ts        # API: /api/users
```

---

## 특수 파일들

App Router에서는 파일 이름이 특별한 역할을 합니다.

| 파일 | 역할 |
|------|------|
| `page.tsx` | 해당 경로의 페이지 컴포넌트 |
| `layout.tsx` | 하위 페이지들이 공유하는 레이아웃 |
| `loading.tsx` | 로딩 중일 때 보여줄 UI (Suspense) |
| `error.tsx` | 에러 발생 시 보여줄 UI (Error Boundary) |
| `not-found.tsx` | 404 페이지 |
| `route.ts` | API 엔드포인트 (Route Handler) |
| `template.tsx` | 매번 새로 마운트되는 레이아웃 |
| `default.tsx` | Parallel Route의 기본값 |

---

## Layout 시스템

레이아웃은 **여러 페이지에서 공유되는 UI**입니다. 페이지가 바뀌어도 레이아웃은 **상태를 유지**합니다.

### 루트 레이아웃 (필수)

```tsx
// app/layout.tsx
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata = {
  title: 'My App',
  description: 'My awesome application',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="ko">
      <body className={inter.className}>
        <header>
          <nav>
            <a href="/">홈</a>
            <a href="/about">소개</a>
            <a href="/blog">블로그</a>
          </nav>
        </header>

        <main>{children}</main>

        <footer>© 2024 My App</footer>
      </body>
    </html>
  )
}
```

### 중첩 레이아웃

레이아웃은 **중첩**됩니다. 하위 폴더에 `layout.tsx`를 만들면 해당 경로에만 적용됩니다.

```tsx
// app/blog/layout.tsx
export default function BlogLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="blog-layout">
      <aside className="sidebar">
        <h3>카테고리</h3>
        <ul>
          <li>기술</li>
          <li>일상</li>
          <li>여행</li>
        </ul>
      </aside>

      <article className="content">
        {children}
      </article>
    </div>
  )
}
```

`/blog/hello-world` 접속 시 레이아웃 중첩:

```
RootLayout
└── BlogLayout
    └── BlogPostPage (page.tsx)
```

---

## 동적 라우트

### 기본 동적 라우트

```tsx
// app/blog/[slug]/page.tsx
interface Props {
  params: { slug: string }
}

export default function BlogPost({ params }: Props) {
  // /blog/hello-world → params.slug = "hello-world"
  return <h1>블로그 글: {params.slug}</h1>
}
```

### 여러 동적 세그먼트

```tsx
// app/shop/[category]/[product]/page.tsx
interface Props {
  params: {
    category: string
    product: string
  }
}

export default function ProductPage({ params }: Props) {
  // /shop/electronics/laptop
  // → params = { category: "electronics", product: "laptop" }

  return (
    <div>
      <p>카테고리: {params.category}</p>
      <p>상품: {params.product}</p>
    </div>
  )
}
```

### Catch-all 라우트

```tsx
// app/docs/[...slug]/page.tsx
interface Props {
  params: { slug: string[] }
}

export default function DocsPage({ params }: Props) {
  // /docs/a → params.slug = ["a"]
  // /docs/a/b → params.slug = ["a", "b"]
  // /docs/a/b/c → params.slug = ["a", "b", "c"]

  return <div>경로: {params.slug.join(' > ')}</div>
}
```

### Optional Catch-all 라우트

```tsx
// app/docs/[[...slug]]/page.tsx
interface Props {
  params: { slug?: string[] }
}

export default function DocsPage({ params }: Props) {
  // /docs → params.slug = undefined
  // /docs/a → params.slug = ["a"]

  if (!params.slug) {
    return <h1>문서 홈</h1>
  }

  return <div>경로: {params.slug.join(' > ')}</div>
}
```

---

## Server Components vs Client Components

App Router의 가장 큰 특징입니다.

### Server Component (기본값)

```tsx
// app/products/page.tsx
// 'use client' 없음 = Server Component

async function getProducts() {
  // 서버에서 직접 데이터베이스 접근 가능!
  const products = await db.product.findMany()
  return products
}

export default async function ProductsPage() {
  // async 컴포넌트 가능
  const products = await getProducts()

  return (
    <ul>
      {products.map((product) => (
        <li key={product.id}>{product.name}</li>
      ))}
    </ul>
  )
}
```

**특징:**
- 서버에서만 실행됨
- 브라우저로 JavaScript가 전송되지 않음
- 데이터베이스, 파일 시스템에 직접 접근 가능
- `async/await` 사용 가능
- `useState`, `useEffect` 등 **사용 불가**

### Client Component

```tsx
// app/components/Counter.tsx
'use client'  // 이 줄이 필수!

import { useState } from 'react'

export default function Counter() {
  const [count, setCount] = useState(0)

  return (
    <div>
      <p>카운트: {count}</p>
      <button onClick={() => setCount(count + 1)}>
        증가
      </button>
    </div>
  )
}
```

**특징:**
- 브라우저에서 실행됨
- 인터랙션 처리 가능
- `useState`, `useEffect`, 이벤트 핸들러 사용 가능
- 브라우저 API (localStorage 등) 사용 가능

### 언제 어떤 것을 사용할까?

| 상황 | 컴포넌트 타입 |
|------|--------------|
| 데이터 페칭 | Server |
| 정적 UI 렌더링 | Server |
| 민감한 정보 (API 키 등) | Server |
| 버튼 클릭, 폼 입력 | Client |
| useState, useEffect | Client |
| 브라우저 API | Client |

### 조합 패턴

Server Component 안에 Client Component를 넣을 수 있습니다.

```tsx
// app/page.tsx (Server Component)
import Counter from './components/Counter'  // Client Component

async function getData() {
  const res = await fetch('https://api.example.com/data')
  return res.json()
}

export default async function Page() {
  const data = await getData()  // 서버에서 데이터 페칭

  return (
    <div>
      <h1>{data.title}</h1>
      <Counter />  {/* 클라이언트에서 인터랙티브 */}
    </div>
  )
}
```

**주의:** Client Component 안에서 Server Component를 직접 import할 수 없습니다. 대신 `children`으로 전달하세요.

```tsx
// ❌ 잘못된 예
'use client'
import ServerComponent from './ServerComponent'

export function ClientComponent() {
  return <ServerComponent />  // 에러!
}
```

```tsx
// ✅ 올바른 예
'use client'

export function ClientComponent({ children }) {
  return <div onClick={...}>{children}</div>
}

// page.tsx에서
<ClientComponent>
  <ServerComponent />  {/* children으로 전달 */}
</ClientComponent>
```

---

## 데이터 페칭

### Server Component에서 직접 페칭

```tsx
// app/products/page.tsx
async function getProducts() {
  const res = await fetch('https://api.example.com/products', {
    // 캐싱 옵션
    cache: 'force-cache',  // 기본값 (SSG처럼 동작)
    // cache: 'no-store',   // SSR처럼 동작
  })

  if (!res.ok) {
    throw new Error('Failed to fetch products')
  }

  return res.json()
}

export default async function ProductsPage() {
  const products = await getProducts()

  return (
    <ul>
      {products.map((p) => (
        <li key={p.id}>{p.name}</li>
      ))}
    </ul>
  )
}
```

### 캐싱 옵션

```tsx
// 1. 정적 데이터 (기본값) - SSG처럼 동작
fetch('https://...', { cache: 'force-cache' })

// 2. 동적 데이터 - SSR처럼 동작
fetch('https://...', { cache: 'no-store' })

// 3. 시간 기반 재검증 - ISR처럼 동작
fetch('https://...', { next: { revalidate: 60 } })  // 60초

// 4. 태그 기반 재검증
fetch('https://...', { next: { tags: ['products'] } })
// 나중에 revalidateTag('products')로 무효화
```

### 병렬 데이터 페칭

```tsx
// app/dashboard/page.tsx
async function getUser() {
  const res = await fetch('https://api.example.com/user')
  return res.json()
}

async function getOrders() {
  const res = await fetch('https://api.example.com/orders')
  return res.json()
}

async function getNotifications() {
  const res = await fetch('https://api.example.com/notifications')
  return res.json()
}

export default async function DashboardPage() {
  // 병렬로 데이터 페칭 - 더 빠름!
  const [user, orders, notifications] = await Promise.all([
    getUser(),
    getOrders(),
    getNotifications(),
  ])

  return (
    <div>
      <h1>Welcome, {user.name}</h1>
      <p>Orders: {orders.length}</p>
      <p>Notifications: {notifications.length}</p>
    </div>
  )
}
```

---

## 로딩 & 에러 처리

### loading.tsx

`loading.tsx`를 만들면 **자동으로 Suspense**가 적용됩니다.

```tsx
// app/products/loading.tsx
export default function Loading() {
  return (
    <div className="loading">
      <div className="spinner" />
      <p>상품을 불러오는 중...</p>
    </div>
  )
}
```

### error.tsx

`error.tsx`를 만들면 **자동으로 Error Boundary**가 적용됩니다.

```tsx
// app/products/error.tsx
'use client'  // 에러 컴포넌트는 Client Component여야 함

interface Props {
  error: Error & { digest?: string }
  reset: () => void
}

export default function Error({ error, reset }: Props) {
  return (
    <div className="error">
      <h2>문제가 발생했습니다</h2>
      <p>{error.message}</p>
      <button onClick={() => reset()}>
        다시 시도
      </button>
    </div>
  )
}
```

### 수동 Suspense 사용

```tsx
// app/dashboard/page.tsx
import { Suspense } from 'react'

async function SlowComponent() {
  const data = await slowFetch()
  return <div>{data}</div>
}

export default function DashboardPage() {
  return (
    <div>
      <h1>대시보드</h1>

      {/* 이 부분만 로딩 UI 표시 */}
      <Suspense fallback={<p>로딩 중...</p>}>
        <SlowComponent />
      </Suspense>
    </div>
  )
}
```

---

## Route Groups

폴더명을 괄호로 감싸면 **URL에 영향을 주지 않습니다**. 코드 정리에 유용합니다.

```
app/
├── (marketing)/          # URL에 포함되지 않음
│   ├── layout.tsx        # 마케팅 페이지용 레이아웃
│   ├── about/
│   │   └── page.tsx      # → /about
│   └── pricing/
│       └── page.tsx      # → /pricing
│
├── (shop)/               # URL에 포함되지 않음
│   ├── layout.tsx        # 쇼핑 페이지용 레이아웃
│   ├── products/
│   │   └── page.tsx      # → /products
│   └── cart/
│       └── page.tsx      # → /cart
│
└── (auth)/
    ├── login/
    │   └── page.tsx      # → /login
    └── register/
        └── page.tsx      # → /register
```

---

## Parallel Routes

같은 URL에서 **여러 페이지를 동시에** 렌더링합니다. `@folder` 형식을 사용합니다.

```
app/
├── layout.tsx
├── page.tsx
├── @team/
│   └── page.tsx
└── @analytics/
    └── page.tsx
```

```tsx
// app/layout.tsx
export default function Layout({
  children,
  team,
  analytics,
}: {
  children: React.ReactNode
  team: React.ReactNode
  analytics: React.ReactNode
}) {
  return (
    <div>
      {children}
      <div className="sidebar">
        {team}
        {analytics}
      </div>
    </div>
  )
}
```

### 모달에 활용

```
app/
├── layout.tsx
├── page.tsx
├── @modal/
│   ├── default.tsx       # 모달이 없을 때
│   └── login/
│       └── page.tsx      # /login 접속 시 모달로 표시
└── login/
    └── page.tsx          # 직접 /login 접속 시
```

---

## Intercepting Routes

다른 라우트를 **가로채서** 현재 레이아웃에서 표시합니다. 모달 패턴에 유용합니다.

| 표기법 | 의미 |
|--------|------|
| `(.)` | 같은 레벨 |
| `(..)` | 한 레벨 위 |
| `(..)(..)` | 두 레벨 위 |
| `(...)` | 루트부터 |

```
app/
├── feed/
│   ├── page.tsx
│   └── @modal/
│       └── (.)photo/[id]/
│           └── page.tsx   # feed에서 photo 클릭 시 모달로
└── photo/
    └── [id]/
        └── page.tsx       # 직접 URL 접속 시 전체 페이지
```

---

## Route Handlers (API Routes)

`route.ts` 파일로 API 엔드포인트를 만듭니다.

```tsx
// app/api/users/route.ts
import { NextResponse } from 'next/server'

// GET /api/users
export async function GET() {
  const users = await db.user.findMany()
  return NextResponse.json(users)
}

// POST /api/users
export async function POST(request: Request) {
  const body = await request.json()
  const user = await db.user.create({ data: body })
  return NextResponse.json(user, { status: 201 })
}
```

```tsx
// app/api/users/[id]/route.ts
import { NextResponse } from 'next/server'

interface Props {
  params: { id: string }
}

// GET /api/users/:id
export async function GET(request: Request, { params }: Props) {
  const user = await db.user.findUnique({
    where: { id: params.id },
  })

  if (!user) {
    return NextResponse.json(
      { error: 'User not found' },
      { status: 404 }
    )
  }

  return NextResponse.json(user)
}

// PUT /api/users/:id
export async function PUT(request: Request, { params }: Props) {
  const body = await request.json()
  const user = await db.user.update({
    where: { id: params.id },
    data: body,
  })
  return NextResponse.json(user)
}

// DELETE /api/users/:id
export async function DELETE(request: Request, { params }: Props) {
  await db.user.delete({
    where: { id: params.id },
  })
  return new NextResponse(null, { status: 204 })
}
```

---

## 네비게이션

### Link 컴포넌트

```tsx
import Link from 'next/link'

export function Navigation() {
  return (
    <nav>
      <Link href="/">홈</Link>
      <Link href="/about">소개</Link>
      <Link href="/blog">블로그</Link>

      {/* prefetch 비활성화 */}
      <Link href="/heavy-page" prefetch={false}>
        무거운 페이지
      </Link>

      {/* replace (히스토리에 추가하지 않음) */}
      <Link href="/login" replace>
        로그인
      </Link>
    </nav>
  )
}
```

### useRouter 훅

```tsx
'use client'

import { useRouter } from 'next/navigation'  // 'next/router' 아님!

export function SearchForm() {
  const router = useRouter()

  const handleSearch = (query: string) => {
    router.push(`/search?q=${query}`)
  }

  const goBack = () => {
    router.back()
  }

  const refresh = () => {
    router.refresh()  // 서버 컴포넌트 다시 렌더링
  }

  return (
    <form>
      <input name="search" />
      <button type="submit">검색</button>
    </form>
  )
}
```

### usePathname, useSearchParams

```tsx
'use client'

import { usePathname, useSearchParams } from 'next/navigation'

export function CurrentPath() {
  const pathname = usePathname()        // /products
  const searchParams = useSearchParams() // URLSearchParams 객체

  const category = searchParams.get('category')  // ?category=shoes → "shoes"

  return (
    <div>
      <p>현재 경로: {pathname}</p>
      <p>카테고리: {category}</p>
    </div>
  )
}
```

---

## Metadata

### 정적 Metadata

```tsx
// app/about/page.tsx
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: '소개',
  description: '우리 회사를 소개합니다',
  openGraph: {
    title: '소개 | My App',
    description: '우리 회사를 소개합니다',
    images: ['/og-about.png'],
  },
}

export default function AboutPage() {
  return <h1>소개</h1>
}
```

### 동적 Metadata

```tsx
// app/blog/[slug]/page.tsx
import type { Metadata } from 'next'

interface Props {
  params: { slug: string }
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const post = await getPost(params.slug)

  return {
    title: post.title,
    description: post.excerpt,
    openGraph: {
      title: post.title,
      description: post.excerpt,
      images: [post.thumbnail],
    },
  }
}

export default async function BlogPost({ params }: Props) {
  const post = await getPost(params.slug)
  return <article>{post.content}</article>
}
```

---

## 장단점

### 장점

- React Server Components 기본 지원
- 자동 코드 분할 및 최적화
- 내장된 로딩/에러 UI
- 강력한 레이아웃 시스템
- 스트리밍 지원
- 번들 크기 감소

### 단점

- 학습 곡선이 있음
- Server/Client 컴포넌트 구분이 처음엔 헷갈림
- 일부 라이브러리가 아직 호환되지 않음

---

## 마이그레이션 가이드

Pages Router에서 App Router로 점진적 마이그레이션이 가능합니다.

```
// 두 라우터를 동시에 사용 가능
my-app/
├── app/              # App Router (새 페이지)
│   └── new-feature/
│       └── page.tsx
└── pages/            # Pages Router (기존 페이지)
    └── old-page.tsx
```

1. `app` 폴더 생성
2. 새 기능은 App Router로 개발
3. 기존 페이지를 점진적으로 마이그레이션
4. 모든 페이지 마이그레이션 후 `pages` 폴더 삭제
