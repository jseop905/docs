# Pages Router (Next.js 12 이하)

Next.js의 전통적인 라우팅 방식입니다. `pages` 폴더 안에 파일을 만들면 자동으로 라우트가 생성됩니다.

---

## 핵심 개념

**파일 기반 라우팅**: 파일/폴더 구조가 URL 구조가 됩니다.

```
pages/
├── index.tsx           # → /
├── about.tsx           # → /about
├── contact.tsx         # → /contact
└── blog/
    ├── index.tsx       # → /blog
    └── [slug].tsx      # → /blog/:slug (동적)
```

---

## 폴더 구조

```
pages/
├── index.tsx                 # 홈페이지 (/)
├── about.tsx                 # 소개 페이지 (/about)
├── blog/
│   ├── index.tsx             # 블로그 목록 (/blog)
│   └── [slug].tsx            # 블로그 상세 (/blog/hello-world)
├── products/
│   ├── index.tsx             # 상품 목록 (/products)
│   ├── [id].tsx              # 상품 상세 (/products/123)
│   └── [id]/
│       └── reviews.tsx       # 상품 리뷰 (/products/123/reviews)
├── _app.tsx                  # 앱 전체 래퍼
├── _document.tsx             # HTML 문서 구조
├── 404.tsx                   # 404 페이지
└── api/
    ├── users/
    │   ├── index.ts          # /api/users
    │   └── [id].ts           # /api/users/:id
    └── auth/
        └── login.ts          # /api/auth/login
```

---

## 동적 라우트

URL에서 변하는 부분을 대괄호(`[]`)로 감쌉니다.

### 단일 동적 세그먼트

```tsx
// pages/blog/[slug].tsx
import { useRouter } from 'next/router'

export default function BlogPost() {
  const router = useRouter()
  const { slug } = router.query

  // /blog/hello-world → slug = "hello-world"
  // /blog/my-first-post → slug = "my-first-post"

  return <h1>블로그 글: {slug}</h1>
}
```

### 여러 동적 세그먼트

```tsx
// pages/shop/[category]/[product].tsx
import { useRouter } from 'next/router'

export default function ProductPage() {
  const router = useRouter()
  const { category, product } = router.query

  // /shop/electronics/laptop
  // → category = "electronics", product = "laptop"

  return (
    <div>
      <p>카테고리: {category}</p>
      <p>상품: {product}</p>
    </div>
  )
}
```

### Catch-all 라우트

```tsx
// pages/docs/[...slug].tsx
// /docs/a → slug = ["a"]
// /docs/a/b → slug = ["a", "b"]
// /docs/a/b/c → slug = ["a", "b", "c"]

export default function DocsPage() {
  const router = useRouter()
  const { slug } = router.query  // 배열로 받음

  return <div>경로: {slug?.join(' > ')}</div>
}
```

### Optional Catch-all 라우트

```tsx
// pages/docs/[[...slug]].tsx
// /docs → slug = undefined
// /docs/a → slug = ["a"]
// /docs/a/b → slug = ["a", "b"]
```

---

## 데이터 페칭

Pages Router에서는 특수 함수로 데이터를 가져옵니다.

### getServerSideProps (SSR)

**매 요청마다 서버에서 실행**됩니다.

```tsx
// pages/products/index.tsx
import { GetServerSideProps } from 'next'

interface Product {
  id: string
  name: string
  price: number
}

interface Props {
  products: Product[]
}

export const getServerSideProps: GetServerSideProps<Props> = async (context) => {
  // context에서 요청 정보 접근 가능
  const { req, res, query, params } = context

  // API 호출
  const response = await fetch('https://api.example.com/products')
  const products = await response.json()

  return {
    props: {
      products,
    },
  }
}

export default function ProductsPage({ products }: Props) {
  return (
    <ul>
      {products.map((product) => (
        <li key={product.id}>
          {product.name} - {product.price}원
        </li>
      ))}
    </ul>
  )
}
```

**사용 시점:**
- 요청 시점의 데이터가 필요할 때
- 쿠키/헤더 기반 인증이 필요할 때
- 항상 최신 데이터가 필요할 때

### getStaticProps (SSG)

**빌드 시 한 번만 실행**됩니다.

```tsx
// pages/blog/index.tsx
import { GetStaticProps } from 'next'

interface Post {
  id: string
  title: string
  excerpt: string
}

interface Props {
  posts: Post[]
}

export const getStaticProps: GetStaticProps<Props> = async () => {
  const response = await fetch('https://api.example.com/posts')
  const posts = await response.json()

  return {
    props: {
      posts,
    },
    // ISR: 60초마다 재생성
    revalidate: 60,
  }
}

export default function BlogPage({ posts }: Props) {
  return (
    <ul>
      {posts.map((post) => (
        <li key={post.id}>
          <h2>{post.title}</h2>
          <p>{post.excerpt}</p>
        </li>
      ))}
    </ul>
  )
}
```

**사용 시점:**
- 데이터가 자주 변하지 않을 때
- SEO가 중요할 때
- 빠른 페이지 로딩이 필요할 때

### getStaticPaths + getStaticProps

동적 라우트를 **미리 생성**할 때 사용합니다.

```tsx
// pages/blog/[slug].tsx
import { GetStaticPaths, GetStaticProps } from 'next'

interface Post {
  slug: string
  title: string
  content: string
}

interface Props {
  post: Post
}

// 어떤 경로들을 미리 생성할지 지정
export const getStaticPaths: GetStaticPaths = async () => {
  const response = await fetch('https://api.example.com/posts')
  const posts: Post[] = await response.json()

  // 모든 글의 경로 생성
  const paths = posts.map((post) => ({
    params: { slug: post.slug },
  }))

  return {
    paths,
    // fallback 옵션:
    // false: paths에 없는 경로는 404
    // true: 없는 경로는 로딩 후 생성
    // 'blocking': 없는 경로는 SSR처럼 서버에서 생성
    fallback: 'blocking',
  }
}

export const getStaticProps: GetStaticProps<Props> = async ({ params }) => {
  const slug = params?.slug as string
  const response = await fetch(`https://api.example.com/posts/${slug}`)
  const post = await response.json()

  if (!post) {
    return { notFound: true }
  }

  return {
    props: { post },
    revalidate: 60,
  }
}

export default function BlogPostPage({ post }: Props) {
  return (
    <article>
      <h1>{post.title}</h1>
      <div dangerouslySetInnerHTML={{ __html: post.content }} />
    </article>
  )
}
```

### fallback 옵션 비교

| fallback | 동작 |
|----------|------|
| `false` | paths에 없는 경로 → 404 |
| `true` | 없는 경로 → 로딩 UI 표시 후 생성 |
| `'blocking'` | 없는 경로 → 서버에서 생성될 때까지 대기 |

---

## 특수 파일들

### _app.tsx

모든 페이지를 감싸는 **공통 래퍼**입니다.

```tsx
// pages/_app.tsx
import type { AppProps } from 'next/app'
import { ThemeProvider } from '@/providers/ThemeProvider'
import { Layout } from '@/components/Layout'
import '@/styles/globals.css'

export default function App({ Component, pageProps }: AppProps) {
  return (
    <ThemeProvider>
      <Layout>
        <Component {...pageProps} />
      </Layout>
    </ThemeProvider>
  )
}
```

**사용 용도:**
- 전역 CSS import
- 공통 레이아웃
- Context Provider 설정
- 페이지 전환 효과

### _document.tsx

**HTML 문서 구조**를 커스터마이즈합니다.

```tsx
// pages/_document.tsx
import { Html, Head, Main, NextScript } from 'next/document'

export default function Document() {
  return (
    <Html lang="ko">
      <Head>
        {/* 전역 메타 태그, 폰트 등 */}
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link
          href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR&display=swap"
          rel="stylesheet"
        />
      </Head>
      <body>
        <Main />
        <NextScript />
      </body>
    </Html>
  )
}
```

**주의:** 이 파일은 서버에서만 렌더링됩니다. 이벤트 핸들러나 CSS-in-JS 설정에 사용됩니다.

---

## API Routes

`pages/api` 폴더 안에 API 엔드포인트를 만들 수 있습니다.

```tsx
// pages/api/users/index.ts
import type { NextApiRequest, NextApiResponse } from 'next'

interface User {
  id: string
  name: string
  email: string
}

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  // HTTP 메서드에 따라 분기
  switch (req.method) {
    case 'GET':
      const users = await getUsers()
      return res.status(200).json(users)

    case 'POST':
      const { name, email } = req.body
      const newUser = await createUser({ name, email })
      return res.status(201).json(newUser)

    default:
      res.setHeader('Allow', ['GET', 'POST'])
      return res.status(405).end(`Method ${req.method} Not Allowed`)
  }
}
```

```tsx
// pages/api/users/[id].ts
import type { NextApiRequest, NextApiResponse } from 'next'

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  const { id } = req.query

  switch (req.method) {
    case 'GET':
      const user = await getUserById(id as string)
      if (!user) {
        return res.status(404).json({ error: 'User not found' })
      }
      return res.status(200).json(user)

    case 'PUT':
      const updated = await updateUser(id as string, req.body)
      return res.status(200).json(updated)

    case 'DELETE':
      await deleteUser(id as string)
      return res.status(204).end()

    default:
      res.setHeader('Allow', ['GET', 'PUT', 'DELETE'])
      return res.status(405).end()
  }
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

      {/* 동적 라우트 */}
      <Link href="/blog/hello-world">첫 번째 글</Link>

      {/* 객체로 전달 */}
      <Link
        href={{
          pathname: '/products/[id]',
          query: { id: '123' },
        }}
      >
        상품 보기
      </Link>
    </nav>
  )
}
```

### useRouter 훅

```tsx
import { useRouter } from 'next/router'

export function SearchForm() {
  const router = useRouter()

  const handleSearch = (query: string) => {
    // 프로그래매틱 네비게이션
    router.push(`/search?q=${query}`)

    // 또는 객체로
    router.push({
      pathname: '/search',
      query: { q: query },
    })
  }

  const goBack = () => {
    router.back()
  }

  const refresh = () => {
    router.reload()
  }

  // 현재 경로 정보
  console.log(router.pathname)  // /products/[id]
  console.log(router.query)     // { id: '123' }
  console.log(router.asPath)    // /products/123?ref=home

  return (
    <form onSubmit={(e) => {
      e.preventDefault()
      handleSearch(e.currentTarget.search.value)
    }}>
      <input name="search" />
      <button type="submit">검색</button>
    </form>
  )
}
```

---

## 장단점

### 장점

- 직관적이고 배우기 쉬움
- 오랜 기간 검증된 안정적인 방식
- 풍부한 커뮤니티 자료와 예제
- 기존 React 지식으로 쉽게 적응

### 단점

- 레이아웃 공유가 번거로움
- 로딩/에러 상태 처리를 직접 구현해야 함
- React Server Components 미지원
- 데이터 페칭이 페이지 레벨에서만 가능

---

## 언제 사용할까?

- 기존 Pages Router 프로젝트 유지보수
- 팀이 Pages Router에 익숙한 경우
- 빠르게 프로토타입을 만들어야 할 때
- React Server Components가 필요 없는 경우

**새 프로젝트라면** [App Router](./app-router.md)를 권장합니다.
