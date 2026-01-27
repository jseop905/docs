# Feature-Sliced Design (FSD)

러시아 개발자 커뮤니티에서 시작된 아키텍처로, **레이어와 슬라이스**로 코드를 체계적으로 구성합니다. 대규모 프로젝트에서 코드의 의존성을 명확하게 관리할 수 있습니다.

---

## 핵심 개념

FSD는 코드를 **6개의 레이어**로 나눕니다. 각 레이어는 명확한 책임을 가집니다.

```
src/
├── app/        # 레이어 1: 앱 설정, 프로바이더
├── pages/      # 레이어 2: 페이지 컴포넌트
├── widgets/    # 레이어 3: 독립적인 UI 블록
├── features/   # 레이어 4: 사용자 인터랙션
├── entities/   # 레이어 5: 비즈니스 엔티티
└── shared/     # 레이어 6: 공유 코드
```

### 핵심 규칙: 단방향 의존성

**상위 레이어는 하위 레이어만 import할 수 있습니다.**

```
app → pages → widgets → features → entities → shared
 ↓      ↓        ↓         ↓          ↓          ↓
(높음)                                        (낮음)
```

- ✅ `features`에서 `entities` import → 가능
- ✅ `widgets`에서 `features` import → 가능
- ❌ `entities`에서 `features` import → **불가능**
- ❌ `shared`에서 `entities` import → **불가능**

---

## 각 레이어 상세 설명

### 1. shared (공유 레이어)

다른 모든 레이어에서 사용하는 **공통 코드**입니다. 비즈니스 로직이 없어야 합니다.

```
shared/
├── ui/                     # 재사용 UI 컴포넌트
│   ├── Button/
│   │   ├── Button.tsx
│   │   ├── Button.module.css
│   │   └── index.ts
│   ├── Input/
│   │   ├── Input.tsx
│   │   └── index.ts
│   ├── Modal/
│   ├── Card/
│   └── index.ts            # 모든 UI 컴포넌트 export
│
├── lib/                    # 유틸리티 함수
│   ├── formatDate.ts
│   ├── formatPrice.ts
│   ├── cn.ts               # className 합치는 함수
│   └── index.ts
│
├── api/                    # API 클라이언트 설정
│   ├── instance.ts         # axios/fetch 인스턴스
│   ├── types.ts            # 공통 API 타입
│   └── index.ts
│
├── config/                 # 환경 설정
│   ├── env.ts
│   └── constants.ts
│
├── hooks/                  # 공통 훅
│   ├── useDebounce.ts
│   ├── useLocalStorage.ts
│   └── index.ts
│
└── types/                  # 공통 타입
    └── index.ts
```

#### 예시 코드

```tsx
// shared/ui/Button/Button.tsx
import { ButtonHTMLAttributes } from 'react'
import styles from './Button.module.css'
import { cn } from '@/shared/lib'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'danger'
  size?: 'sm' | 'md' | 'lg'
  isLoading?: boolean
}

export function Button({
  children,
  variant = 'primary',
  size = 'md',
  isLoading = false,
  className,
  disabled,
  ...props
}: ButtonProps) {
  return (
    <button
      className={cn(
        styles.button,
        styles[variant],
        styles[size],
        className
      )}
      disabled={disabled || isLoading}
      {...props}
    >
      {isLoading ? <span className={styles.spinner} /> : children}
    </button>
  )
}
```

```tsx
// shared/ui/index.ts
export { Button } from './Button'
export { Input } from './Input'
export { Modal } from './Modal'
export { Card } from './Card'
```

```tsx
// shared/lib/formatPrice.ts
export function formatPrice(price: number): string {
  return new Intl.NumberFormat('ko-KR', {
    style: 'currency',
    currency: 'KRW',
  }).format(price)
}
```

```tsx
// shared/api/instance.ts
const API_URL = process.env.NEXT_PUBLIC_API_URL

export async function apiClient<T>(
  endpoint: string,
  options?: RequestInit
): Promise<T> {
  const response = await fetch(`${API_URL}${endpoint}`, {
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
    ...options,
  })

  if (!response.ok) {
    throw new Error(`API Error: ${response.status}`)
  }

  return response.json()
}
```

---

### 2. entities (엔티티 레이어)

비즈니스 도메인의 **핵심 데이터 모델**입니다. User, Product, Order 같은 것들이요.

```
entities/
├── user/
│   ├── model/                  # 상태 관리, 타입
│   │   ├── types.ts
│   │   └── store.ts
│   ├── api/                    # API 호출
│   │   └── userApi.ts
│   ├── ui/                     # UI 컴포넌트
│   │   ├── UserAvatar.tsx
│   │   ├── UserCard.tsx
│   │   └── index.ts
│   └── index.ts                # Public API
│
├── product/
│   ├── model/
│   │   └── types.ts
│   ├── api/
│   │   └── productApi.ts
│   ├── ui/
│   │   ├── ProductCard.tsx
│   │   ├── ProductPrice.tsx
│   │   └── index.ts
│   └── index.ts
│
├── cart/
│   ├── model/
│   │   ├── types.ts
│   │   └── store.ts
│   ├── ui/
│   │   └── CartIcon.tsx
│   └── index.ts
│
└── order/
    └── ...
```

#### 예시 코드

```tsx
// entities/user/model/types.ts
export interface User {
  id: string
  email: string
  name: string
  avatar?: string
  role: 'user' | 'admin'
  createdAt: string
}

export interface UserProfile extends User {
  bio?: string
  website?: string
  socialLinks?: {
    twitter?: string
    github?: string
  }
}
```

```tsx
// entities/user/api/userApi.ts
import { apiClient } from '@/shared/api'
import { User, UserProfile } from '../model/types'

export const userApi = {
  getById: (id: string) =>
    apiClient<User>(`/users/${id}`),

  getProfile: (id: string) =>
    apiClient<UserProfile>(`/users/${id}/profile`),

  getAll: () =>
    apiClient<User[]>('/users'),
}
```

```tsx
// entities/user/ui/UserAvatar.tsx
import Image from 'next/image'
import styles from './UserAvatar.module.css'

interface UserAvatarProps {
  src?: string
  name: string
  size?: 'sm' | 'md' | 'lg'
}

export function UserAvatar({ src, name, size = 'md' }: UserAvatarProps) {
  if (!src) {
    // 이니셜 표시
    const initial = name.charAt(0).toUpperCase()
    return (
      <div className={`${styles.avatar} ${styles[size]}`}>
        {initial}
      </div>
    )
  }

  return (
    <Image
      src={src}
      alt={name}
      className={`${styles.avatar} ${styles[size]}`}
      width={size === 'sm' ? 32 : size === 'md' ? 48 : 64}
      height={size === 'sm' ? 32 : size === 'md' ? 48 : 64}
    />
  )
}
```

```tsx
// entities/user/ui/UserCard.tsx
import { User } from '../model/types'
import { UserAvatar } from './UserAvatar'
import { Card } from '@/shared/ui'
import styles from './UserCard.module.css'

interface UserCardProps {
  user: User
  onClick?: () => void
}

export function UserCard({ user, onClick }: UserCardProps) {
  return (
    <Card className={styles.userCard} onClick={onClick}>
      <UserAvatar src={user.avatar} name={user.name} />
      <div className={styles.info}>
        <h3 className={styles.name}>{user.name}</h3>
        <p className={styles.email}>{user.email}</p>
      </div>
    </Card>
  )
}
```

```tsx
// entities/user/index.ts
// Public API - 다른 레이어에서 사용할 것만 export

// Types
export type { User, UserProfile } from './model/types'

// API
export { userApi } from './api/userApi'

// UI Components
export { UserAvatar } from './ui/UserAvatar'
export { UserCard } from './ui/UserCard'
```

```tsx
// entities/product/model/types.ts
export interface Product {
  id: string
  name: string
  description: string
  price: number
  originalPrice?: number
  images: string[]
  category: string
  stock: number
  rating: number
  reviewCount: number
}
```

```tsx
// entities/product/ui/ProductCard.tsx
import Image from 'next/image'
import { Product } from '../model/types'
import { Card } from '@/shared/ui'
import { formatPrice } from '@/shared/lib'
import styles from './ProductCard.module.css'

interface ProductCardProps {
  product: Product
  // Action slot - features 레이어에서 제공
  action?: React.ReactNode
}

export function ProductCard({ product, action }: ProductCardProps) {
  const hasDiscount = product.originalPrice && product.originalPrice > product.price
  const discountRate = hasDiscount
    ? Math.round((1 - product.price / product.originalPrice!) * 100)
    : 0

  return (
    <Card className={styles.productCard}>
      <div className={styles.imageWrapper}>
        <Image
          src={product.images[0]}
          alt={product.name}
          fill
          className={styles.image}
        />
        {hasDiscount && (
          <span className={styles.discount}>-{discountRate}%</span>
        )}
      </div>

      <div className={styles.content}>
        <h3 className={styles.name}>{product.name}</h3>

        <div className={styles.rating}>
          {'★'.repeat(Math.round(product.rating))}
          <span>({product.reviewCount})</span>
        </div>

        <div className={styles.priceWrapper}>
          {hasDiscount && (
            <span className={styles.originalPrice}>
              {formatPrice(product.originalPrice!)}
            </span>
          )}
          <span className={styles.price}>
            {formatPrice(product.price)}
          </span>
        </div>

        {/* Feature에서 제공하는 액션 버튼 */}
        {action && <div className={styles.action}>{action}</div>}
      </div>
    </Card>
  )
}
```

---

### 3. features (기능 레이어)

사용자가 수행하는 **액션/인터랙션**입니다. "로그인하기", "장바구니에 담기", "검색하기" 같은 것들이요.

```
features/
├── auth/
│   ├── login/
│   │   ├── ui/
│   │   │   └── LoginForm.tsx
│   │   ├── model/
│   │   │   └── useLogin.ts
│   │   ├── api/
│   │   │   └── loginApi.ts
│   │   └── index.ts
│   ├── logout/
│   │   ├── ui/
│   │   │   └── LogoutButton.tsx
│   │   └── index.ts
│   └── register/
│       └── ...
│
├── cart/
│   ├── add-to-cart/
│   │   ├── ui/
│   │   │   └── AddToCartButton.tsx
│   │   ├── model/
│   │   │   └── useAddToCart.ts
│   │   └── index.ts
│   ├── remove-from-cart/
│   │   └── ...
│   └── update-quantity/
│       └── ...
│
├── search/
│   └── search-products/
│       ├── ui/
│       │   └── SearchBar.tsx
│       └── index.ts
│
└── wishlist/
    ├── add-to-wishlist/
    └── remove-from-wishlist/
```

#### 예시 코드

```tsx
// features/auth/login/model/useLogin.ts
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { loginApi } from '../api/loginApi'

interface LoginCredentials {
  email: string
  password: string
}

export function useLogin() {
  const router = useRouter()
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const login = async (credentials: LoginCredentials) => {
    setIsLoading(true)
    setError(null)

    try {
      await loginApi.login(credentials)
      router.push('/dashboard')
    } catch (err) {
      setError('이메일 또는 비밀번호가 올바르지 않습니다')
    } finally {
      setIsLoading(false)
    }
  }

  return {
    login,
    isLoading,
    error,
  }
}
```

```tsx
// features/auth/login/ui/LoginForm.tsx
'use client'

import { useState } from 'react'
import { Button, Input } from '@/shared/ui'
import { useLogin } from '../model/useLogin'
import styles from './LoginForm.module.css'

export function LoginForm() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const { login, isLoading, error } = useLogin()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    await login({ email, password })
  }

  return (
    <form className={styles.form} onSubmit={handleSubmit}>
      <h2 className={styles.title}>로그인</h2>

      <div className={styles.field}>
        <label htmlFor="email">이메일</label>
        <Input
          id="email"
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="이메일을 입력하세요"
          required
        />
      </div>

      <div className={styles.field}>
        <label htmlFor="password">비밀번호</label>
        <Input
          id="password"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          placeholder="비밀번호를 입력하세요"
          required
        />
      </div>

      {error && <p className={styles.error}>{error}</p>}

      <Button type="submit" isLoading={isLoading} className={styles.submitBtn}>
        로그인
      </Button>
    </form>
  )
}
```

```tsx
// features/auth/login/index.ts
export { LoginForm } from './ui/LoginForm'
export { useLogin } from './model/useLogin'
```

```tsx
// features/cart/add-to-cart/ui/AddToCartButton.tsx
'use client'

import { Button } from '@/shared/ui'
import { Product } from '@/entities/product'
import { useCartStore } from '@/entities/cart'
import { useState } from 'react'

interface AddToCartButtonProps {
  product: Product
  variant?: 'primary' | 'secondary'
}

export function AddToCartButton({
  product,
  variant = 'primary'
}: AddToCartButtonProps) {
  const [isAdded, setIsAdded] = useState(false)
  const addItem = useCartStore((state) => state.addItem)

  const handleClick = () => {
    addItem({
      id: product.id,
      name: product.name,
      price: product.price,
      image: product.images[0],
    })
    setIsAdded(true)
    setTimeout(() => setIsAdded(false), 2000)
  }

  return (
    <Button
      variant={variant}
      onClick={handleClick}
      disabled={product.stock === 0}
    >
      {product.stock === 0
        ? '품절'
        : isAdded
          ? '담았습니다!'
          : '장바구니 담기'}
    </Button>
  )
}
```

```tsx
// features/search/search-products/ui/SearchBar.tsx
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Input, Button } from '@/shared/ui'
import { useDebounce } from '@/shared/hooks'
import styles from './SearchBar.module.css'

export function SearchBar() {
  const router = useRouter()
  const [query, setQuery] = useState('')

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    if (query.trim()) {
      router.push(`/search?q=${encodeURIComponent(query)}`)
    }
  }

  return (
    <form className={styles.searchBar} onSubmit={handleSearch}>
      <Input
        type="search"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder="상품을 검색하세요"
        className={styles.input}
      />
      <Button type="submit" className={styles.button}>
        검색
      </Button>
    </form>
  )
}
```

---

### 4. widgets (위젯 레이어)

페이지에 배치되는 **독립적인 UI 블록**입니다. 여러 entities와 features를 조합합니다.

```
widgets/
├── header/
│   ├── ui/
│   │   └── Header.tsx
│   └── index.ts
│
├── footer/
│   ├── ui/
│   │   └── Footer.tsx
│   └── index.ts
│
├── sidebar/
│   └── ...
│
├── product-list/
│   ├── ui/
│   │   └── ProductList.tsx
│   └── index.ts
│
├── shopping-cart/
│   ├── ui/
│   │   └── ShoppingCart.tsx
│   └── index.ts
│
└── user-menu/
    └── ...
```

#### 예시 코드

```tsx
// widgets/header/ui/Header.tsx
import Link from 'next/link'
import { Logo } from '@/shared/ui'
import { SearchBar } from '@/features/search'
import { CartIcon } from '@/entities/cart'
import { UserMenu } from '@/widgets/user-menu'
import styles from './Header.module.css'

export function Header() {
  return (
    <header className={styles.header}>
      <div className={styles.container}>
        <Link href="/" className={styles.logo}>
          <Logo />
        </Link>

        <nav className={styles.nav}>
          <Link href="/products">상품</Link>
          <Link href="/categories">카테고리</Link>
          <Link href="/deals">특가</Link>
        </nav>

        <SearchBar />

        <div className={styles.actions}>
          <Link href="/cart" className={styles.cartLink}>
            <CartIcon />
          </Link>
          <UserMenu />
        </div>
      </div>
    </header>
  )
}
```

```tsx
// widgets/product-list/ui/ProductList.tsx
import { Product, ProductCard } from '@/entities/product'
import { AddToCartButton } from '@/features/cart'
import { AddToWishlistButton } from '@/features/wishlist'
import styles from './ProductList.module.css'

interface ProductListProps {
  products: Product[]
  columns?: 2 | 3 | 4
}

export function ProductList({ products, columns = 4 }: ProductListProps) {
  return (
    <div
      className={styles.grid}
      style={{ '--columns': columns } as React.CSSProperties}
    >
      {products.map((product) => (
        <ProductCard
          key={product.id}
          product={product}
          action={
            <div className={styles.actions}>
              <AddToCartButton product={product} />
              <AddToWishlistButton productId={product.id} />
            </div>
          }
        />
      ))}
    </div>
  )
}
```

```tsx
// widgets/shopping-cart/ui/ShoppingCart.tsx
'use client'

import { useCartStore } from '@/entities/cart'
import { RemoveFromCartButton, UpdateQuantity } from '@/features/cart'
import { Button } from '@/shared/ui'
import { formatPrice } from '@/shared/lib'
import styles from './ShoppingCart.module.css'

export function ShoppingCart() {
  const items = useCartStore((state) => state.items)
  const totalPrice = useCartStore((state) => state.totalPrice)

  if (items.length === 0) {
    return (
      <div className={styles.empty}>
        <p>장바구니가 비어있습니다</p>
      </div>
    )
  }

  return (
    <div className={styles.cart}>
      <h2>장바구니</h2>

      <ul className={styles.items}>
        {items.map((item) => (
          <li key={item.id} className={styles.item}>
            <img src={item.image} alt={item.name} />
            <div className={styles.info}>
              <h3>{item.name}</h3>
              <p>{formatPrice(item.price)}</p>
            </div>
            <UpdateQuantity itemId={item.id} quantity={item.quantity} />
            <RemoveFromCartButton itemId={item.id} />
          </li>
        ))}
      </ul>

      <div className={styles.summary}>
        <p>총 금액: {formatPrice(totalPrice())}</p>
        <Button size="lg">결제하기</Button>
      </div>
    </div>
  )
}
```

---

### 5. pages (페이지 레이어)

실제 라우트에 대응하는 페이지 컴포넌트입니다. Widgets를 조합하여 페이지를 구성합니다.

```
pages/
├── home/
│   ├── ui/
│   │   └── HomePage.tsx
│   └── index.ts
│
├── product-list/
│   ├── ui/
│   │   └── ProductListPage.tsx
│   └── index.ts
│
├── product-detail/
│   ├── ui/
│   │   └── ProductDetailPage.tsx
│   └── index.ts
│
└── checkout/
    └── ...
```

#### 예시 코드

```tsx
// pages/home/ui/HomePage.tsx
import { Header } from '@/widgets/header'
import { Footer } from '@/widgets/footer'
import { ProductList } from '@/widgets/product-list'
import { HeroBanner } from '@/widgets/hero-banner'
import { Product } from '@/entities/product'
import styles from './HomePage.module.css'

interface HomePageProps {
  featuredProducts: Product[]
  newProducts: Product[]
}

export function HomePage({ featuredProducts, newProducts }: HomePageProps) {
  return (
    <div className={styles.page}>
      <Header />

      <main className={styles.main}>
        <HeroBanner />

        <section className={styles.section}>
          <h2>인기 상품</h2>
          <ProductList products={featuredProducts} />
        </section>

        <section className={styles.section}>
          <h2>신상품</h2>
          <ProductList products={newProducts} />
        </section>
      </main>

      <Footer />
    </div>
  )
}
```

```tsx
// pages/home/index.ts
export { HomePage } from './ui/HomePage'
```

---

### 6. app (앱 레이어)

애플리케이션의 **진입점**입니다. 전역 설정, 프로바이더, 라우팅 등을 담당합니다.

Next.js App Router를 사용하는 경우, 이 레이어는 Next.js의 `app` 폴더와 통합됩니다.

```
app/                        # Next.js app 폴더
├── layout.tsx              # 루트 레이아웃
├── page.tsx                # 홈페이지
├── providers.tsx           # Context Providers
├── globals.css
│
├── products/
│   ├── page.tsx            # pages/product-list 사용
│   └── [id]/
│       └── page.tsx        # pages/product-detail 사용
│
└── cart/
    └── page.tsx            # pages/cart 사용
```

```tsx
// app/providers.tsx
'use client'

import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ThemeProvider } from 'next-themes'
import { useState } from 'react'

export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => new QueryClient())

  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider attribute="class" defaultTheme="system">
        {children}
      </ThemeProvider>
    </QueryClientProvider>
  )
}
```

```tsx
// app/layout.tsx
import { Providers } from './providers'
import './globals.css'

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="ko" suppressHydrationWarning>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}
```

```tsx
// app/page.tsx
import { HomePage } from '@/pages/home'
import { productApi } from '@/entities/product'

export default async function Page() {
  const [featuredProducts, newProducts] = await Promise.all([
    productApi.getFeatured(),
    productApi.getNew(),
  ])

  return (
    <HomePage
      featuredProducts={featuredProducts}
      newProducts={newProducts}
    />
  )
}
```

---

## Slice 구조

각 레이어 안의 폴더를 **Slice**라고 합니다. 모든 Slice는 동일한 내부 구조를 가집니다.

```
[slice-name]/
├── ui/                 # UI 컴포넌트
│   ├── Component.tsx
│   └── index.ts
├── model/              # 비즈니스 로직, 상태
│   ├── types.ts
│   ├── store.ts
│   └── index.ts
├── api/                # API 호출
│   └── api.ts
├── lib/                # 유틸리티 (해당 slice 전용)
│   └── helpers.ts
└── index.ts            # Public API
```

### Public API 규칙

각 Slice는 `index.ts`를 통해 **공개할 것만** export합니다:

```tsx
// entities/user/index.ts

// ✅ 공개 API만 export
export type { User, UserProfile } from './model/types'
export { UserCard, UserAvatar } from './ui'
export { userApi } from './api/userApi'

// ❌ 내부 구현은 export하지 않음
// export { validateUser } from './lib/validation'  // 내부용
// export { UserContext } from './model/context'    // 내부용
```

다른 레이어에서 import할 때:

```tsx
// ✅ 올바른 import - index.ts를 통해
import { User, UserCard } from '@/entities/user'

// ❌ 잘못된 import - 내부 파일 직접 접근
import { User } from '@/entities/user/model/types'
```

---

## 의존성 규칙 시각화

```
┌─────────────────────────────────────────────────────────────┐
│                           app                               │
│  (프로바이더, 라우팅, 전역 설정)                              │
└─────────────────────────────────────────────────────────────┘
                              │ import 가능
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                          pages                              │
│  (페이지 컴포넌트)                                           │
└─────────────────────────────────────────────────────────────┘
                              │ import 가능
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         widgets                             │
│  (Header, Sidebar, ProductList 등)                          │
└─────────────────────────────────────────────────────────────┘
                              │ import 가능
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         features                            │
│  (로그인, 장바구니 담기, 검색 등)                              │
└─────────────────────────────────────────────────────────────┘
                              │ import 가능
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         entities                            │
│  (User, Product, Order 등)                                  │
└─────────────────────────────────────────────────────────────┘
                              │ import 가능
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                          shared                             │
│  (Button, Input, formatDate, apiClient 등)                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 자주 묻는 질문

### Q: entities끼리 서로 참조해야 하면?

같은 레이어끼리는 직접 참조하지 않습니다. 대신:
1. 상위 레이어(features, widgets)에서 조합
2. 공통 부분을 shared로 추출

```tsx
// ❌ entities끼리 직접 참조
// entities/order/ui/OrderCard.tsx
import { UserAvatar } from '@/entities/user'  // 안됨!

// ✅ widgets에서 조합
// widgets/order-list/ui/OrderItem.tsx
import { OrderCard } from '@/entities/order'
import { UserAvatar } from '@/entities/user'

export function OrderItem({ order, user }) {
  return (
    <div>
      <UserAvatar user={user} />
      <OrderCard order={order} />
    </div>
  )
}
```

### Q: 작은 프로젝트에서도 FSD를 써야 할까?

작은 프로젝트에서는 과도할 수 있습니다. 다음 경우에 FSD를 권장합니다:
- 팀원이 3명 이상
- 6개월 이상 유지보수 예정
- 도메인이 복잡한 경우

작은 프로젝트는 [Feature-based](./feature-based.md) 구조가 더 적합할 수 있습니다.

### Q: Next.js App Router와 어떻게 통합하나요?

```
project/
├── app/                    # Next.js 라우팅 (FSD의 app 레이어)
│   ├── layout.tsx
│   ├── page.tsx
│   └── products/
│       └── page.tsx
└── src/
    ├── pages/              # FSD pages (UI 컴포넌트)
    ├── widgets/
    ├── features/
    ├── entities/
    └── shared/
```

Next.js의 `app` 폴더는 라우팅만 담당하고, 실제 UI는 `src/pages`에서 가져옵니다.

---

## 장단점

### 장점

- 명확한 의존성 방향으로 유지보수 용이
- 레이어별 책임이 분명
- 팀원 간 코드 위치에 대한 합의가 쉬움
- 대규모 프로젝트에서 확장성 좋음
- 코드 재사용성 높음

### 단점

- 초기 학습 비용이 높음
- 작은 프로젝트에는 과도한 구조
- 레이어 구분이 모호한 경우가 있음
- 보일러플레이트가 많을 수 있음

---

## 참고 자료

- [Feature-Sliced Design 공식 문서](https://feature-sliced.design/)
- [FSD Examples](https://github.com/feature-sliced/examples)
