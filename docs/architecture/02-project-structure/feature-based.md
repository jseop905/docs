# Feature-based Structure

**기능 단위**로 관련 코드를 모아두는 실용적인 프로젝트 구조입니다. 중소규모 프로젝트에서 가장 널리 사용되며, 직관적이고 배우기 쉽습니다.

---

## 핵심 개념

관련된 모든 코드를 **기능(Feature)** 폴더 안에 함께 둡니다:

```
features/
└── auth/                 # 인증 기능
    ├── components/       # UI 컴포넌트
    ├── hooks/            # 커스텀 훅
    ├── api/              # API 호출
    ├── types/            # 타입 정의
    ├── utils/            # 유틸리티
    └── index.ts          # Public API
```

"인증" 관련 코드가 필요하면 `features/auth`만 보면 됩니다.

---

## 폴더 구조

```
src/
├── app/                    # Next.js App Router
│   ├── layout.tsx
│   ├── page.tsx
│   ├── products/
│   │   ├── page.tsx
│   │   └── [id]/
│   │       └── page.tsx
│   ├── cart/
│   │   └── page.tsx
│   └── api/
│       └── ...
│
├── features/               # 기능별 폴더
│   ├── auth/               # 인증
│   ├── products/           # 상품
│   ├── cart/               # 장바구니
│   ├── checkout/           # 결제
│   ├── orders/             # 주문
│   └── user/               # 사용자
│
├── shared/                 # 공통 코드
│   ├── components/         # 공통 UI 컴포넌트
│   ├── hooks/              # 공통 훅
│   ├── utils/              # 유틸리티
│   ├── types/              # 공통 타입
│   └── lib/                # 외부 라이브러리 설정
│
├── providers/              # Context Providers
│   └── index.tsx
│
└── styles/                 # 전역 스타일
    └── globals.css
```

---

## Feature 폴더 내부 구조

각 Feature는 동일한 구조를 가집니다:

```
features/
└── products/
    ├── components/           # UI 컴포넌트
    │   ├── ProductCard.tsx
    │   ├── ProductList.tsx
    │   ├── ProductDetail.tsx
    │   ├── ProductFilters.tsx
    │   └── index.ts
    │
    ├── hooks/                # 커스텀 훅
    │   ├── useProducts.ts
    │   ├── useProduct.ts
    │   └── index.ts
    │
    ├── api/                  # API 호출
    │   └── productApi.ts
    │
    ├── types/                # 타입 정의
    │   └── product.types.ts
    │
    ├── utils/                # 유틸리티 (해당 기능 전용)
    │   └── productHelpers.ts
    │
    ├── store/                # 상태 관리 (선택적)
    │   └── productStore.ts
    │
    ├── constants/            # 상수 (선택적)
    │   └── productConstants.ts
    │
    └── index.ts              # Public API
```

---

## 실제 코드 예시

### 1. Types 정의

```tsx
// features/products/types/product.types.ts
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
  createdAt: string
}

export interface ProductFilters {
  category?: string
  minPrice?: number
  maxPrice?: number
  sortBy?: 'price' | 'rating' | 'newest'
  sortOrder?: 'asc' | 'desc'
}

export interface ProductsResponse {
  products: Product[]
  total: number
  page: number
  limit: number
}
```

### 2. API 호출

```tsx
// features/products/api/productApi.ts
import { Product, ProductFilters, ProductsResponse } from '../types/product.types'

const API_URL = process.env.NEXT_PUBLIC_API_URL

export const productApi = {
  // 상품 목록 조회
  async getProducts(filters?: ProductFilters): Promise<ProductsResponse> {
    const params = new URLSearchParams()

    if (filters?.category) params.append('category', filters.category)
    if (filters?.minPrice) params.append('minPrice', String(filters.minPrice))
    if (filters?.maxPrice) params.append('maxPrice', String(filters.maxPrice))
    if (filters?.sortBy) params.append('sortBy', filters.sortBy)
    if (filters?.sortOrder) params.append('sortOrder', filters.sortOrder)

    const response = await fetch(`${API_URL}/products?${params}`)

    if (!response.ok) {
      throw new Error('상품 목록을 불러오는데 실패했습니다')
    }

    return response.json()
  },

  // 단일 상품 조회
  async getProduct(id: string): Promise<Product> {
    const response = await fetch(`${API_URL}/products/${id}`)

    if (!response.ok) {
      throw new Error('상품을 찾을 수 없습니다')
    }

    return response.json()
  },

  // 추천 상품 조회
  async getRecommendations(productId: string): Promise<Product[]> {
    const response = await fetch(`${API_URL}/products/${productId}/recommendations`)

    if (!response.ok) {
      throw new Error('추천 상품을 불러오는데 실패했습니다')
    }

    return response.json()
  },
}
```

### 3. Custom Hooks

```tsx
// features/products/hooks/useProducts.ts
'use client'

import { useQuery } from '@tanstack/react-query'
import { productApi } from '../api/productApi'
import { ProductFilters } from '../types/product.types'

export function useProducts(filters?: ProductFilters) {
  return useQuery({
    queryKey: ['products', filters],
    queryFn: () => productApi.getProducts(filters),
    staleTime: 1000 * 60 * 5, // 5분
  })
}
```

```tsx
// features/products/hooks/useProduct.ts
'use client'

import { useQuery } from '@tanstack/react-query'
import { productApi } from '../api/productApi'

export function useProduct(id: string) {
  return useQuery({
    queryKey: ['product', id],
    queryFn: () => productApi.getProduct(id),
    enabled: !!id,
  })
}

export function useRecommendations(productId: string) {
  return useQuery({
    queryKey: ['recommendations', productId],
    queryFn: () => productApi.getRecommendations(productId),
    enabled: !!productId,
  })
}
```

```tsx
// features/products/hooks/index.ts
export { useProducts } from './useProducts'
export { useProduct, useRecommendations } from './useProduct'
```

### 4. Components

```tsx
// features/products/components/ProductCard.tsx
import Image from 'next/image'
import Link from 'next/link'
import { Product } from '../types/product.types'
import { formatPrice } from '@/shared/utils'
import styles from './ProductCard.module.css'

interface ProductCardProps {
  product: Product
  onAddToCart?: (product: Product) => void
}

export function ProductCard({ product, onAddToCart }: ProductCardProps) {
  const hasDiscount = product.originalPrice && product.originalPrice > product.price
  const discountRate = hasDiscount
    ? Math.round((1 - product.price / product.originalPrice!) * 100)
    : 0

  return (
    <article className={styles.card}>
      <Link href={`/products/${product.id}`} className={styles.imageLink}>
        <div className={styles.imageWrapper}>
          <Image
            src={product.images[0]}
            alt={product.name}
            fill
            sizes="(max-width: 768px) 50vw, 25vw"
            className={styles.image}
          />
          {hasDiscount && (
            <span className={styles.discount}>-{discountRate}%</span>
          )}
        </div>
      </Link>

      <div className={styles.content}>
        <Link href={`/products/${product.id}`}>
          <h3 className={styles.name}>{product.name}</h3>
        </Link>

        <div className={styles.rating}>
          <span className={styles.stars}>
            {'★'.repeat(Math.round(product.rating))}
            {'☆'.repeat(5 - Math.round(product.rating))}
          </span>
          <span className={styles.reviewCount}>
            ({product.reviewCount})
          </span>
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

        {onAddToCart && (
          <button
            className={styles.addToCartBtn}
            onClick={() => onAddToCart(product)}
            disabled={product.stock === 0}
          >
            {product.stock === 0 ? '품절' : '장바구니 담기'}
          </button>
        )}
      </div>
    </article>
  )
}
```

```tsx
// features/products/components/ProductList.tsx
'use client'

import { useProducts } from '../hooks/useProducts'
import { ProductCard } from './ProductCard'
import { ProductFilters, Product } from '../types/product.types'
import styles from './ProductList.module.css'

interface ProductListProps {
  filters?: ProductFilters
  onAddToCart?: (product: Product) => void
}

export function ProductList({ filters, onAddToCart }: ProductListProps) {
  const { data, isLoading, error } = useProducts(filters)

  if (isLoading) {
    return (
      <div className={styles.loading}>
        <div className={styles.spinner} />
        <p>상품을 불러오는 중...</p>
      </div>
    )
  }

  if (error) {
    return (
      <div className={styles.error}>
        <p>상품을 불러오는데 실패했습니다</p>
        <button onClick={() => window.location.reload()}>
          다시 시도
        </button>
      </div>
    )
  }

  if (!data?.products.length) {
    return (
      <div className={styles.empty}>
        <p>상품이 없습니다</p>
      </div>
    )
  }

  return (
    <div className={styles.grid}>
      {data.products.map((product) => (
        <ProductCard
          key={product.id}
          product={product}
          onAddToCart={onAddToCart}
        />
      ))}
    </div>
  )
}
```

```tsx
// features/products/components/ProductDetail.tsx
'use client'

import Image from 'next/image'
import { useState } from 'react'
import { useProduct, useRecommendations } from '../hooks/useProduct'
import { ProductCard } from './ProductCard'
import { formatPrice } from '@/shared/utils'
import styles from './ProductDetail.module.css'

interface ProductDetailProps {
  productId: string
  onAddToCart?: (quantity: number) => void
}

export function ProductDetail({ productId, onAddToCart }: ProductDetailProps) {
  const { data: product, isLoading, error } = useProduct(productId)
  const { data: recommendations } = useRecommendations(productId)
  const [selectedImage, setSelectedImage] = useState(0)
  const [quantity, setQuantity] = useState(1)

  if (isLoading) {
    return <div className={styles.loading}>로딩 중...</div>
  }

  if (error || !product) {
    return <div className={styles.error}>상품을 찾을 수 없습니다</div>
  }

  return (
    <div className={styles.container}>
      {/* 이미지 갤러리 */}
      <div className={styles.gallery}>
        <div className={styles.mainImage}>
          <Image
            src={product.images[selectedImage]}
            alt={product.name}
            fill
            className={styles.image}
          />
        </div>
        <div className={styles.thumbnails}>
          {product.images.map((image, index) => (
            <button
              key={index}
              className={`${styles.thumbnail} ${
                index === selectedImage ? styles.active : ''
              }`}
              onClick={() => setSelectedImage(index)}
            >
              <Image src={image} alt="" fill />
            </button>
          ))}
        </div>
      </div>

      {/* 상품 정보 */}
      <div className={styles.info}>
        <h1 className={styles.name}>{product.name}</h1>

        <div className={styles.rating}>
          {'★'.repeat(Math.round(product.rating))}
          <span>({product.reviewCount}개 리뷰)</span>
        </div>

        <div className={styles.price}>
          {product.originalPrice && (
            <span className={styles.originalPrice}>
              {formatPrice(product.originalPrice)}
            </span>
          )}
          <span className={styles.currentPrice}>
            {formatPrice(product.price)}
          </span>
        </div>

        <p className={styles.description}>{product.description}</p>

        {/* 수량 선택 */}
        <div className={styles.quantitySelector}>
          <label>수량:</label>
          <button
            onClick={() => setQuantity((q) => Math.max(1, q - 1))}
            disabled={quantity <= 1}
          >
            -
          </button>
          <span>{quantity}</span>
          <button
            onClick={() => setQuantity((q) => Math.min(product.stock, q + 1))}
            disabled={quantity >= product.stock}
          >
            +
          </button>
        </div>

        {/* 장바구니 버튼 */}
        <button
          className={styles.addToCartBtn}
          onClick={() => onAddToCart?.(quantity)}
          disabled={product.stock === 0}
        >
          {product.stock === 0 ? '품절' : '장바구니 담기'}
        </button>
      </div>

      {/* 추천 상품 */}
      {recommendations && recommendations.length > 0 && (
        <section className={styles.recommendations}>
          <h2>함께 보면 좋은 상품</h2>
          <div className={styles.recommendationGrid}>
            {recommendations.slice(0, 4).map((product) => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>
        </section>
      )}
    </div>
  )
}
```

```tsx
// features/products/components/index.ts
export { ProductCard } from './ProductCard'
export { ProductList } from './ProductList'
export { ProductDetail } from './ProductDetail'
export { ProductFilters } from './ProductFilters'
```

### 5. Public API (index.ts)

```tsx
// features/products/index.ts
// Types
export type {
  Product,
  ProductFilters,
  ProductsResponse,
} from './types/product.types'

// API
export { productApi } from './api/productApi'

// Hooks
export { useProducts } from './hooks/useProducts'
export { useProduct, useRecommendations } from './hooks/useProduct'

// Components
export { ProductCard } from './components/ProductCard'
export { ProductList } from './components/ProductList'
export { ProductDetail } from './components/ProductDetail'
export { ProductFilters as ProductFiltersPanel } from './components/ProductFilters'
```

---

## Auth Feature 예시

```
features/auth/
├── components/
│   ├── LoginForm.tsx
│   ├── RegisterForm.tsx
│   ├── ForgotPasswordForm.tsx
│   └── index.ts
├── hooks/
│   ├── useAuth.ts
│   ├── useLogin.ts
│   └── index.ts
├── api/
│   └── authApi.ts
├── types/
│   └── auth.types.ts
├── store/
│   └── authStore.ts
└── index.ts
```

```tsx
// features/auth/types/auth.types.ts
export interface User {
  id: string
  email: string
  name: string
  avatar?: string
  role: 'user' | 'admin'
}

export interface LoginCredentials {
  email: string
  password: string
}

export interface RegisterData {
  email: string
  password: string
  name: string
}

export interface AuthState {
  user: User | null
  isAuthenticated: boolean
  isLoading: boolean
}
```

```tsx
// features/auth/api/authApi.ts
import { User, LoginCredentials, RegisterData } from '../types/auth.types'

const API_URL = process.env.NEXT_PUBLIC_API_URL

export const authApi = {
  async login(credentials: LoginCredentials): Promise<User> {
    const response = await fetch(`${API_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(credentials),
      credentials: 'include',
    })

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.message || '로그인에 실패했습니다')
    }

    return response.json()
  },

  async register(data: RegisterData): Promise<User> {
    const response = await fetch(`${API_URL}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    })

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.message || '회원가입에 실패했습니다')
    }

    return response.json()
  },

  async logout(): Promise<void> {
    await fetch(`${API_URL}/auth/logout`, {
      method: 'POST',
      credentials: 'include',
    })
  },

  async getCurrentUser(): Promise<User | null> {
    try {
      const response = await fetch(`${API_URL}/auth/me`, {
        credentials: 'include',
      })

      if (!response.ok) return null

      return response.json()
    } catch {
      return null
    }
  },
}
```

```tsx
// features/auth/store/authStore.ts
import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { User, LoginCredentials, RegisterData, AuthState } from '../types/auth.types'
import { authApi } from '../api/authApi'

interface AuthStore extends AuthState {
  login: (credentials: LoginCredentials) => Promise<void>
  register: (data: RegisterData) => Promise<void>
  logout: () => Promise<void>
  checkAuth: () => Promise<void>
}

export const useAuthStore = create<AuthStore>()(
  persist(
    (set) => ({
      user: null,
      isAuthenticated: false,
      isLoading: true,

      login: async (credentials) => {
        const user = await authApi.login(credentials)
        set({ user, isAuthenticated: true })
      },

      register: async (data) => {
        const user = await authApi.register(data)
        set({ user, isAuthenticated: true })
      },

      logout: async () => {
        await authApi.logout()
        set({ user: null, isAuthenticated: false })
      },

      checkAuth: async () => {
        set({ isLoading: true })
        const user = await authApi.getCurrentUser()
        set({
          user,
          isAuthenticated: !!user,
          isLoading: false,
        })
      },
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        user: state.user,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
)
```

```tsx
// features/auth/hooks/useAuth.ts
'use client'

import { useEffect } from 'react'
import { useAuthStore } from '../store/authStore'

export function useAuth() {
  const store = useAuthStore()

  useEffect(() => {
    store.checkAuth()
  }, [])

  return store
}
```

```tsx
// features/auth/components/LoginForm.tsx
'use client'

import { useState, FormEvent } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { useAuthStore } from '../store/authStore'
import { Button, Input } from '@/shared/components'
import styles from './LoginForm.module.css'

export function LoginForm() {
  const router = useRouter()
  const login = useAuthStore((state) => state.login)

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [isLoading, setIsLoading] = useState(false)

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setError('')
    setIsLoading(true)

    try {
      await login({ email, password })
      router.push('/dashboard')
    } catch (err) {
      setError(err instanceof Error ? err.message : '로그인에 실패했습니다')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <form className={styles.form} onSubmit={handleSubmit}>
      <h2 className={styles.title}>로그인</h2>

      {error && <div className={styles.error}>{error}</div>}

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

      <Button type="submit" isLoading={isLoading} fullWidth>
        로그인
      </Button>

      <div className={styles.links}>
        <Link href="/forgot-password">비밀번호 찾기</Link>
        <Link href="/register">회원가입</Link>
      </div>
    </form>
  )
}
```

```tsx
// features/auth/index.ts
// Types
export type {
  User,
  LoginCredentials,
  RegisterData,
  AuthState,
} from './types/auth.types'

// Store
export { useAuthStore } from './store/authStore'

// Hooks
export { useAuth } from './hooks/useAuth'

// Components
export { LoginForm } from './components/LoginForm'
export { RegisterForm } from './components/RegisterForm'
```

---

## Cart Feature 예시

```tsx
// features/cart/types/cart.types.ts
export interface CartItem {
  id: string
  productId: string
  name: string
  price: number
  image: string
  quantity: number
}

export interface CartState {
  items: CartItem[]
  isOpen: boolean
}
```

```tsx
// features/cart/store/cartStore.ts
import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { CartItem, CartState } from '../types/cart.types'

interface CartStore extends CartState {
  addItem: (item: Omit<CartItem, 'quantity'>) => void
  removeItem: (id: string) => void
  updateQuantity: (id: string, quantity: number) => void
  clearCart: () => void
  toggleCart: () => void
  getTotalItems: () => number
  getTotalPrice: () => number
}

export const useCartStore = create<CartStore>()(
  persist(
    (set, get) => ({
      items: [],
      isOpen: false,

      addItem: (item) =>
        set((state) => {
          const existing = state.items.find((i) => i.productId === item.productId)

          if (existing) {
            return {
              items: state.items.map((i) =>
                i.productId === item.productId
                  ? { ...i, quantity: i.quantity + 1 }
                  : i
              ),
            }
          }

          return {
            items: [...state.items, { ...item, id: crypto.randomUUID(), quantity: 1 }],
          }
        }),

      removeItem: (id) =>
        set((state) => ({
          items: state.items.filter((item) => item.id !== id),
        })),

      updateQuantity: (id, quantity) =>
        set((state) => ({
          items: state.items.map((item) =>
            item.id === id ? { ...item, quantity } : item
          ),
        })),

      clearCart: () => set({ items: [] }),

      toggleCart: () => set((state) => ({ isOpen: !state.isOpen })),

      getTotalItems: () => {
        return get().items.reduce((sum, item) => sum + item.quantity, 0)
      },

      getTotalPrice: () => {
        return get().items.reduce(
          (sum, item) => sum + item.price * item.quantity,
          0
        )
      },
    }),
    {
      name: 'cart-storage',
      partialize: (state) => ({ items: state.items }),
    }
  )
)
```

```tsx
// features/cart/components/CartIcon.tsx
'use client'

import { useCartStore } from '../store/cartStore'
import { Icon } from '@/shared/components'
import styles from './CartIcon.module.css'

export function CartIcon() {
  const totalItems = useCartStore((state) => state.getTotalItems())
  const toggleCart = useCartStore((state) => state.toggleCart)

  return (
    <button className={styles.cartIcon} onClick={toggleCart}>
      <Icon name="cart" />
      {totalItems > 0 && (
        <span className={styles.badge}>{totalItems}</span>
      )}
    </button>
  )
}
```

```tsx
// features/cart/components/AddToCartButton.tsx
'use client'

import { useState } from 'react'
import { useCartStore } from '../store/cartStore'
import { Button } from '@/shared/components'
import { Product } from '@/features/products'

interface AddToCartButtonProps {
  product: Product
}

export function AddToCartButton({ product }: AddToCartButtonProps) {
  const [isAdded, setIsAdded] = useState(false)
  const addItem = useCartStore((state) => state.addItem)

  const handleClick = () => {
    addItem({
      productId: product.id,
      name: product.name,
      price: product.price,
      image: product.images[0],
    })

    setIsAdded(true)
    setTimeout(() => setIsAdded(false), 2000)
  }

  return (
    <Button
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
// features/cart/index.ts
export type { CartItem, CartState } from './types/cart.types'
export { useCartStore } from './store/cartStore'
export { CartIcon } from './components/CartIcon'
export { AddToCartButton } from './components/AddToCartButton'
export { CartDrawer } from './components/CartDrawer'
export { CartSummary } from './components/CartSummary'
```

---

## Shared 폴더 구조

```
shared/
├── components/             # 공통 UI 컴포넌트
│   ├── Button/
│   │   ├── Button.tsx
│   │   ├── Button.module.css
│   │   └── index.ts
│   ├── Input/
│   ├── Modal/
│   ├── Icon/
│   ├── Spinner/
│   └── index.ts
│
├── hooks/                  # 공통 훅
│   ├── useDebounce.ts
│   ├── useLocalStorage.ts
│   ├── useMediaQuery.ts
│   └── index.ts
│
├── utils/                  # 유틸리티 함수
│   ├── formatDate.ts
│   ├── formatPrice.ts
│   ├── cn.ts
│   └── index.ts
│
├── types/                  # 공통 타입
│   └── index.ts
│
└── lib/                    # 외부 라이브러리 설정
    ├── prisma.ts
    ├── stripe.ts
    └── index.ts
```

```tsx
// shared/utils/formatPrice.ts
export function formatPrice(price: number, currency = 'KRW'): string {
  return new Intl.NumberFormat('ko-KR', {
    style: 'currency',
    currency,
  }).format(price)
}
```

```tsx
// shared/utils/cn.ts
import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs))
}
```

```tsx
// shared/hooks/useDebounce.ts
import { useState, useEffect } from 'react'

export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState(value)

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedValue(value)
    }, delay)

    return () => clearTimeout(timer)
  }, [value, delay])

  return debouncedValue
}
```

---

## Next.js App Router와 통합

```tsx
// app/products/page.tsx
import { ProductList, ProductFiltersPanel } from '@/features/products'

export default function ProductsPage() {
  return (
    <div className="container">
      <h1>상품 목록</h1>
      <div className="layout">
        <aside>
          <ProductFiltersPanel />
        </aside>
        <main>
          <ProductList />
        </main>
      </div>
    </div>
  )
}
```

```tsx
// app/products/[id]/page.tsx
import { ProductDetail } from '@/features/products'

interface Props {
  params: { id: string }
}

export default function ProductDetailPage({ params }: Props) {
  return <ProductDetail productId={params.id} />
}
```

```tsx
// app/login/page.tsx
import { LoginForm } from '@/features/auth'

export default function LoginPage() {
  return (
    <div className="auth-container">
      <LoginForm />
    </div>
  )
}
```

---

## Import 규칙

```tsx
// 좋은 예: index.ts를 통해 import
import { ProductCard, useProducts, Product } from '@/features/products'
import { LoginForm, useAuth } from '@/features/auth'
import { Button, Input } from '@/shared/components'

// 나쁜 예: 내부 파일 직접 import
import { ProductCard } from '@/features/products/components/ProductCard'
import { useProducts } from '@/features/products/hooks/useProducts'
```

---

## 장단점

### 장점

- **직관적**: 관련 코드가 한 곳에 모여있어 찾기 쉬움
- **독립적**: 기능 추가/삭제가 용이
- **유연함**: 복잡한 규칙 없이 필요에 따라 구조 조정 가능
- **학습 곡선 낮음**: 새로운 팀원도 빠르게 적응

### 단점

- **기능 간 공유**: 여러 기능에서 사용하는 코드 위치가 모호할 수 있음
- **확장성**: 프로젝트가 커지면 features 폴더가 비대해질 수 있음
- **의존성 관리**: FSD처럼 명확한 규칙이 없어 순환 의존성 발생 가능

---

## 언제 사용할까?

- 중소규모 프로젝트 (1-5명)
- 빠른 개발이 필요한 프로젝트
- 팀원들이 아직 복잡한 아키텍처에 익숙하지 않을 때
- MVP나 프로토타입 개발

프로젝트가 커지면 [FSD](./fsd.md)로 점진적 마이그레이션을 고려하세요.
