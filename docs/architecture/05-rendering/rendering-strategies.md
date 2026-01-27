# 렌더링 전략

웹 페이지를 **언제, 어디서 렌더링할지**에 대한 전략입니다. Next.js는 페이지별로 다른 렌더링 전략을 선택할 수 있습니다.

---

## 렌더링 전략 한눈에 보기

| 전략 | 렌더링 시점 | 실행 위치 | SEO | 데이터 신선도 |
|------|------------|----------|-----|--------------|
| CSR | 런타임 | 브라우저 | ❌ | 실시간 |
| SSR | 매 요청 | 서버 | ✅ | 실시간 |
| SSG | 빌드 시 | 서버 | ✅ | 빌드 시점 |
| ISR | 빌드 + 주기적 | 서버 | ✅ | 주기적 |
| RSC | 요청 시 | 서버 | ✅ | 실시간 |

---

## 1. CSR (Client-Side Rendering)

**브라우저에서 JavaScript로 페이지를 렌더링**합니다.

### 동작 방식

```
1. 브라우저 → 서버: HTML 요청
2. 서버 → 브라우저: 빈 HTML + JS 번들
3. 브라우저: JS 다운로드 및 실행
4. 브라우저 → 서버: API 요청 (데이터 페칭)
5. 서버 → 브라우저: JSON 데이터
6. 브라우저: 화면 렌더링

타임라인:
[빈 화면]──[JS 로딩]──[API 요청]──[렌더링]──[인터랙티브]
```

### 구현 방법

```tsx
// app/dashboard/page.tsx
'use client'

import { useState, useEffect } from 'react'

interface User {
  id: string
  name: string
  email: string
}

export default function DashboardPage() {
  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    async function fetchUsers() {
      try {
        const response = await fetch('/api/users')
        if (!response.ok) throw new Error('Failed to fetch')
        const data = await response.json()
        setUsers(data)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Error occurred')
      } finally {
        setLoading(false)
      }
    }

    fetchUsers()
  }, [])

  if (loading) return <div>로딩 중...</div>
  if (error) return <div>에러: {error}</div>

  return (
    <ul>
      {users.map(user => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  )
}
```

### React Query 사용 (권장)

```tsx
// app/dashboard/page.tsx
'use client'

import { useQuery } from '@tanstack/react-query'

async function fetchUsers() {
  const response = await fetch('/api/users')
  if (!response.ok) throw new Error('Failed to fetch')
  return response.json()
}

export default function DashboardPage() {
  const { data: users, isLoading, error } = useQuery({
    queryKey: ['users'],
    queryFn: fetchUsers,
  })

  if (isLoading) return <div>로딩 중...</div>
  if (error) return <div>에러 발생</div>

  return (
    <ul>
      {users?.map(user => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  )
}
```

### 장단점

**장점**
- 서버 부하 최소화
- 풍부한 인터랙션
- 페이지 전환이 빠름 (SPA)

**단점**
- 초기 로딩 느림 (JS 다운로드 필요)
- SEO 불리 (검색 엔진이 JS 실행 못함)
- 첫 화면까지 시간 오래 걸림 (FCP)

### 적합한 사용 케이스

- 로그인 후 대시보드
- 관리자 페이지
- 실시간 데이터 (채팅, 알림)
- SEO가 필요 없는 페이지

---

## 2. SSR (Server-Side Rendering)

**매 요청마다 서버에서 HTML을 생성**합니다.

### 동작 방식

```
1. 브라우저 → 서버: 페이지 요청
2. 서버: 데이터 페칭 + HTML 생성
3. 서버 → 브라우저: 완성된 HTML
4. 브라우저: 즉시 화면 표시
5. 브라우저: JS 다운로드 (Hydration)
6. 브라우저: 인터랙티브

타임라인:
[서버 처리]──[HTML 수신]──[화면 표시]──[Hydration]──[인터랙티브]
```

### 구현 방법 (App Router)

```tsx
// app/products/page.tsx
// Server Component가 기본이므로 'use client' 없이 async 사용

interface Product {
  id: string
  name: string
  price: number
}

async function getProducts(): Promise<Product[]> {
  const response = await fetch('https://api.example.com/products', {
    cache: 'no-store',  // 매번 새로 가져옴 (SSR)
  })

  if (!response.ok) {
    throw new Error('Failed to fetch products')
  }

  return response.json()
}

export default async function ProductsPage() {
  const products = await getProducts()

  return (
    <div>
      <h1>상품 목록</h1>
      <ul>
        {products.map(product => (
          <li key={product.id}>
            {product.name} - {product.price}원
          </li>
        ))}
      </ul>
    </div>
  )
}
```

### 동적 데이터 (쿠키, 헤더 기반)

```tsx
// app/profile/page.tsx
import { cookies, headers } from 'next/headers'

export default async function ProfilePage() {
  const cookieStore = cookies()
  const headersList = headers()

  const token = cookieStore.get('token')?.value
  const userAgent = headersList.get('user-agent')

  // 토큰으로 사용자 정보 조회
  const user = await getUserByToken(token)

  return (
    <div>
      <h1>프로필</h1>
      <p>이름: {user?.name}</p>
      <p>브라우저: {userAgent}</p>
    </div>
  )
}
```

### 강제 동적 렌더링

```tsx
// app/live-data/page.tsx

// 이 설정으로 항상 SSR 강제
export const dynamic = 'force-dynamic'

export default async function LiveDataPage() {
  const data = await fetchLiveData()
  return <div>{data}</div>
}
```

### 장단점

**장점**
- SEO 친화적
- 항상 최신 데이터
- 초기 화면 빠름 (FCP)
- 사용자별 개인화 가능

**단점**
- 서버 부하 증가
- 매 요청마다 렌더링 (느림)
- 서버 리소스 필요

### 적합한 사용 케이스

- 개인화된 콘텐츠 (마이페이지)
- 실시간으로 바뀌는 데이터
- 로그인 상태에 따른 페이지
- 검색 결과 페이지

---

## 3. SSG (Static Site Generation)

**빌드 시점에 HTML을 미리 생성**합니다.

### 동작 방식

```
빌드 시:
1. 서버: 모든 페이지의 데이터 페칭
2. 서버: HTML 파일 생성
3. CDN에 배포

요청 시:
1. 브라우저 → CDN: 페이지 요청
2. CDN → 브라우저: 미리 생성된 HTML
3. 브라우저: 즉시 표시

타임라인:
[CDN 응답]──[화면 표시]──[Hydration]──[인터랙티브]
             ↑ 매우 빠름!
```

### 구현 방법 (App Router)

```tsx
// app/blog/page.tsx
// fetch의 기본 캐싱이 SSG처럼 동작

interface Post {
  id: string
  title: string
  excerpt: string
}

async function getPosts(): Promise<Post[]> {
  const response = await fetch('https://api.example.com/posts', {
    cache: 'force-cache',  // 빌드 시 캐싱 (기본값)
  })

  return response.json()
}

export default async function BlogPage() {
  const posts = await getPosts()

  return (
    <div>
      <h1>블로그</h1>
      {posts.map(post => (
        <article key={post.id}>
          <h2>{post.title}</h2>
          <p>{post.excerpt}</p>
        </article>
      ))}
    </div>
  )
}
```

### 동적 경로 정적 생성

```tsx
// app/blog/[slug]/page.tsx
import { notFound } from 'next/navigation'

interface Props {
  params: { slug: string }
}

// 빌드 시 생성할 경로 지정
export async function generateStaticParams() {
  const posts = await fetch('https://api.example.com/posts').then(r => r.json())

  return posts.map((post: { slug: string }) => ({
    slug: post.slug,
  }))
}

async function getPost(slug: string) {
  const response = await fetch(`https://api.example.com/posts/${slug}`, {
    cache: 'force-cache',
  })

  if (!response.ok) return null

  return response.json()
}

export default async function BlogPostPage({ params }: Props) {
  const post = await getPost(params.slug)

  if (!post) {
    notFound()
  }

  return (
    <article>
      <h1>{post.title}</h1>
      <div dangerouslySetInnerHTML={{ __html: post.content }} />
    </article>
  )
}
```

### 장단점

**장점**
- 가장 빠른 응답 속도
- SEO 최적화
- 서버 부하 없음 (CDN에서 제공)
- 비용 효율적

**단점**
- 데이터 변경 시 재빌드 필요
- 빌드 시간 증가 (페이지가 많을 경우)
- 동적 데이터에 부적합

### 적합한 사용 케이스

- 블로그, 문서 사이트
- 마케팅/랜딩 페이지
- 자주 변하지 않는 콘텐츠
- 정적 웹사이트

---

## 4. ISR (Incremental Static Regeneration)

**정적 생성 + 백그라운드 재생성**. SSG의 속도와 SSR의 신선함을 결합합니다.

### 동작 방식

```
빌드 시:
1. 초기 정적 페이지 생성

첫 번째 요청 (0초):
1. 캐시된 페이지 반환

두 번째 요청 (60초 후, revalidate=60):
1. 캐시된 페이지 반환 (빠름)
2. 백그라운드에서 새 페이지 생성

세 번째 요청:
1. 새로 생성된 페이지 반환

타임라인:
요청 ──[캐시 반환]
          ↓ (백그라운드)
       [새 페이지 생성]
          ↓
다음 요청 ──[새 페이지 반환]
```

### 구현 방법 (시간 기반)

```tsx
// app/news/page.tsx

interface NewsItem {
  id: string
  title: string
  publishedAt: string
}

async function getNews(): Promise<NewsItem[]> {
  const response = await fetch('https://api.example.com/news', {
    next: { revalidate: 60 },  // 60초마다 재검증
  })

  return response.json()
}

export default async function NewsPage() {
  const news = await getNews()

  return (
    <div>
      <h1>뉴스</h1>
      {news.map(item => (
        <article key={item.id}>
          <h2>{item.title}</h2>
          <time>{item.publishedAt}</time>
        </article>
      ))}
    </div>
  )
}
```

### Route Segment Config

```tsx
// app/products/page.tsx

// 페이지 레벨에서 재검증 시간 설정
export const revalidate = 60  // 60초

export default async function ProductsPage() {
  const products = await fetch('https://api.example.com/products')
    .then(r => r.json())

  return <ProductList products={products} />
}
```

### On-Demand Revalidation (태그 기반)

```tsx
// app/products/page.tsx
async function getProducts() {
  const response = await fetch('https://api.example.com/products', {
    next: { tags: ['products'] },  // 태그 지정
  })
  return response.json()
}

export default async function ProductsPage() {
  const products = await getProducts()
  return <ProductList products={products} />
}
```

```tsx
// app/api/revalidate/route.ts
import { revalidateTag } from 'next/cache'
import { NextResponse } from 'next/server'

export async function POST(request: Request) {
  const { tag, secret } = await request.json()

  // 보안 확인
  if (secret !== process.env.REVALIDATE_SECRET) {
    return NextResponse.json({ error: 'Invalid secret' }, { status: 401 })
  }

  // 태그로 캐시 무효화
  revalidateTag(tag)

  return NextResponse.json({ revalidated: true })
}
```

```bash
# 외부에서 재검증 요청
curl -X POST https://your-site.com/api/revalidate \
  -H "Content-Type: application/json" \
  -d '{"tag": "products", "secret": "your-secret"}'
```

### 경로 기반 재검증

```tsx
// app/api/revalidate/route.ts
import { revalidatePath } from 'next/cache'
import { NextResponse } from 'next/server'

export async function POST(request: Request) {
  const { path } = await request.json()

  // 특정 경로 재검증
  revalidatePath(path)

  // 또는 레이아웃 포함 재검증
  revalidatePath(path, 'layout')

  return NextResponse.json({ revalidated: true })
}
```

### 장단점

**장점**
- SSG의 빠른 속도
- 주기적 데이터 갱신
- 서버 부하 최소화
- On-demand 재검증 가능

**단점**
- 실시간 데이터에는 부적합
- 재검증 전까지 오래된 데이터 가능
- 첫 요청 후 재검증이므로 약간의 지연

### 적합한 사용 케이스

- 상품 목록/상세 페이지
- 뉴스/기사
- 자주 변하지만 실시간일 필요 없는 데이터
- 대규모 사이트 (모든 페이지를 빌드하기 어려울 때)

---

## 5. RSC (React Server Components)

**컴포넌트 레벨에서 서버/클라이언트를 분리**합니다. Next.js 13+ App Router의 기본 방식입니다.

### 동작 방식

```
Server Component:
- 서버에서만 실행
- JS 번들에 포함되지 않음
- 데이터베이스 직접 접근 가능

Client Component:
- 브라우저에서 실행
- 인터랙션 처리
- useState, useEffect 사용

렌더링 흐름:
1. 서버: Server Components 렌더링 → HTML/RSC Payload
2. 브라우저: HTML 즉시 표시
3. 브라우저: Client Components Hydration
4. 브라우저: 인터랙티브
```

### Server Component (기본)

```tsx
// app/products/page.tsx
// 'use client' 없음 = Server Component

import { db } from '@/lib/db'

export default async function ProductsPage() {
  // 서버에서 직접 DB 접근!
  const products = await db.product.findMany({
    orderBy: { createdAt: 'desc' },
    take: 20,
  })

  return (
    <div>
      <h1>상품 목록</h1>
      {products.map(product => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  )
}

// 이것도 Server Component
function ProductCard({ product }) {
  return (
    <div>
      <h2>{product.name}</h2>
      <p>{product.price}원</p>
    </div>
  )
}
```

### Client Component

```tsx
// app/components/AddToCartButton.tsx
'use client'  // 클라이언트 컴포넌트 선언

import { useState } from 'react'

export function AddToCartButton({ productId }: { productId: string }) {
  const [isAdding, setIsAdding] = useState(false)

  const handleClick = async () => {
    setIsAdding(true)
    await addToCart(productId)
    setIsAdding(false)
  }

  return (
    <button onClick={handleClick} disabled={isAdding}>
      {isAdding ? '담는 중...' : '장바구니 담기'}
    </button>
  )
}
```

### 조합 패턴

```tsx
// app/products/[id]/page.tsx (Server Component)
import { db } from '@/lib/db'
import { AddToCartButton } from '@/components/AddToCartButton'
import { ImageGallery } from '@/components/ImageGallery'

export default async function ProductPage({ params }: { params: { id: string } }) {
  // 서버에서 데이터 조회
  const product = await db.product.findUnique({
    where: { id: params.id },
  })

  return (
    <div>
      {/* Server Component - 정적 데이터 */}
      <h1>{product.name}</h1>
      <p>{product.description}</p>
      <p>{product.price}원</p>

      {/* Client Component - 인터랙션 필요 */}
      <ImageGallery images={product.images} />
      <AddToCartButton productId={product.id} />
    </div>
  )
}
```

### Server Component에서 할 수 있는 것

```tsx
// Server Component
import { db } from '@/lib/db'
import { cookies, headers } from 'next/headers'
import fs from 'fs'

export default async function Page() {
  // ✅ 데이터베이스 직접 접근
  const users = await db.user.findMany()

  // ✅ 파일 시스템 접근
  const config = fs.readFileSync('./config.json', 'utf-8')

  // ✅ 쿠키/헤더 접근
  const token = cookies().get('token')
  const userAgent = headers().get('user-agent')

  // ✅ 서버 전용 API 호출
  const secret = process.env.SECRET_KEY  // 클라이언트에 노출 안됨

  // ✅ async/await 사용
  const data = await fetchSomething()

  return <div>...</div>
}
```

### Client Component에서 할 수 있는 것

```tsx
'use client'

import { useState, useEffect } from 'react'

export function ClientComponent() {
  // ✅ React Hooks
  const [count, setCount] = useState(0)

  // ✅ useEffect
  useEffect(() => {
    console.log('Mounted')
  }, [])

  // ✅ 이벤트 핸들러
  const handleClick = () => setCount(c => c + 1)

  // ✅ 브라우저 API
  const width = window.innerWidth  // (useEffect 안에서)

  return <button onClick={handleClick}>{count}</button>
}
```

### 장단점

**장점**
- 번들 크기 감소 (Server Component는 JS에 포함 안됨)
- 직접적인 백엔드 접근
- 보안 (민감한 로직이 서버에만 존재)
- 자동 코드 분할

**단점**
- Server/Client 구분 필요
- 일부 라이브러리 호환성 문제
- 학습 곡선

---

## 렌더링 전략 선택 가이드

```
시작
  │
  ├─ SEO가 필요한가?
  │   ├─ No → CSR
  │   └─ Yes ↓
  │
  ├─ 데이터가 자주 변하는가?
  │   ├─ No → SSG
  │   └─ Yes ↓
  │
  ├─ 실시간 데이터가 필요한가?
  │   ├─ No → ISR
  │   └─ Yes ↓
  │
  ├─ 사용자별 개인화가 필요한가?
  │   ├─ No → ISR (짧은 revalidate)
  │   └─ Yes → SSR
  │
  └─ 대부분의 경우 → RSC (App Router 기본)
```

### 페이지별 전략 예시

| 페이지 | 전략 | 이유 |
|--------|------|------|
| 홈페이지 | ISR (60초) | SEO + 적당한 신선도 |
| 블로그 글 | SSG | 자주 안 변함 |
| 상품 목록 | ISR (60초) | SEO + 재고 갱신 |
| 상품 상세 | ISR (60초) | SEO + 가격/재고 갱신 |
| 검색 결과 | SSR | 동적 쿼리 |
| 장바구니 | CSR | 로그인 필요, SEO 불필요 |
| 마이페이지 | SSR | 개인화 필요 |
| 대시보드 | CSR | SEO 불필요, 실시간 |
| 관리자 | CSR | SEO 불필요 |

---

## 하이브리드 렌더링

한 페이지 안에서 여러 전략을 조합할 수 있습니다.

```tsx
// app/products/[id]/page.tsx
import { Suspense } from 'react'

// 정적 부분 (Server Component)
async function ProductInfo({ id }: { id: string }) {
  const product = await getProduct(id)  // 캐싱됨
  return <div>{product.name}</div>
}

// 동적 부분 (Server Component, no-cache)
async function ProductStock({ id }: { id: string }) {
  const stock = await getStock(id)  // 실시간
  return <div>재고: {stock}개</div>
}

// 인터랙티브 부분 (Client Component)
import { AddToCartButton } from './AddToCartButton'

export default function ProductPage({ params }: { params: { id: string } }) {
  return (
    <div>
      {/* 정적 (캐싱) */}
      <ProductInfo id={params.id} />

      {/* 동적 (스트리밍) */}
      <Suspense fallback={<div>재고 확인 중...</div>}>
        <ProductStock id={params.id} />
      </Suspense>

      {/* 클라이언트 */}
      <AddToCartButton productId={params.id} />
    </div>
  )
}
```

---

## 캐싱 옵션 정리

```tsx
// SSG (정적)
fetch(url, { cache: 'force-cache' })  // 기본값

// SSR (동적)
fetch(url, { cache: 'no-store' })

// ISR (주기적 재검증)
fetch(url, { next: { revalidate: 60 } })

// 태그 기반 재검증
fetch(url, { next: { tags: ['products'] } })
```

### Route Segment Config

```tsx
// 페이지/레이아웃 레벨 설정
export const dynamic = 'auto' | 'force-dynamic' | 'force-static' | 'error'
export const revalidate = false | 0 | number
export const fetchCache = 'auto' | 'default-cache' | 'force-cache' | ...
export const runtime = 'nodejs' | 'edge'
```
