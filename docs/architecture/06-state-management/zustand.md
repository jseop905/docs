# Zustand

**간단하고 가벼운 상태 관리** 라이브러리입니다. Redux의 복잡함 없이 전역 상태를 관리할 수 있습니다.

---

## 설치

```bash
npm install zustand
```

---

## 기본 사용법

### Store 생성

```tsx
// stores/counterStore.ts
import { create } from 'zustand'

interface CounterState {
  count: number
  increment: () => void
  decrement: () => void
  reset: () => void
}

export const useCounterStore = create<CounterState>((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
  decrement: () => set((state) => ({ count: state.count - 1 })),
  reset: () => set({ count: 0 }),
}))
```

### 컴포넌트에서 사용

```tsx
'use client'

import { useCounterStore } from '@/stores/counterStore'

export function Counter() {
  const count = useCounterStore((state) => state.count)
  const increment = useCounterStore((state) => state.increment)
  const decrement = useCounterStore((state) => state.decrement)

  return (
    <div>
      <span>{count}</span>
      <button onClick={decrement}>-</button>
      <button onClick={increment}>+</button>
    </div>
  )
}
```

### 선택적 구독 (최적화)

```tsx
// ❌ 전체 상태 구독 - state가 바뀔 때마다 리렌더
const state = useCounterStore()

// ✅ 필요한 값만 구독 - count가 바뀔 때만 리렌더
const count = useCounterStore((state) => state.count)

// ✅ 여러 값 선택 - shallow 비교
import { shallow } from 'zustand/shallow'

const { count, increment } = useCounterStore(
  (state) => ({ count: state.count, increment: state.increment }),
  shallow
)
```

---

## 실전 예시: 장바구니

```tsx
// stores/cartStore.ts
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface CartItem {
  id: string
  name: string
  price: number
  image: string
  quantity: number
}

interface CartState {
  items: CartItem[]
  isOpen: boolean

  // Actions
  addItem: (item: Omit<CartItem, 'quantity'>) => void
  removeItem: (id: string) => void
  updateQuantity: (id: string, quantity: number) => void
  clearCart: () => void
  toggleCart: () => void

  // Computed (getter 함수)
  getTotalItems: () => number
  getTotalPrice: () => number
}

export const useCartStore = create<CartState>()(
  persist(
    (set, get) => ({
      items: [],
      isOpen: false,

      addItem: (item) =>
        set((state) => {
          const existingItem = state.items.find((i) => i.id === item.id)

          if (existingItem) {
            // 이미 있으면 수량 증가
            return {
              items: state.items.map((i) =>
                i.id === item.id ? { ...i, quantity: i.quantity + 1 } : i
              ),
            }
          }

          // 없으면 새로 추가
          return {
            items: [...state.items, { ...item, quantity: 1 }],
          }
        }),

      removeItem: (id) =>
        set((state) => ({
          items: state.items.filter((item) => item.id !== id),
        })),

      updateQuantity: (id, quantity) =>
        set((state) => ({
          items: state.items.map((item) =>
            item.id === id ? { ...item, quantity: Math.max(0, quantity) } : item
          ).filter((item) => item.quantity > 0),
        })),

      clearCart: () => set({ items: [] }),

      toggleCart: () => set((state) => ({ isOpen: !state.isOpen })),

      getTotalItems: () => {
        const state = get()
        return state.items.reduce((sum, item) => sum + item.quantity, 0)
      },

      getTotalPrice: () => {
        const state = get()
        return state.items.reduce(
          (sum, item) => sum + item.price * item.quantity,
          0
        )
      },
    }),
    {
      name: 'cart-storage', // localStorage 키
      partialize: (state) => ({ items: state.items }), // 저장할 필드만 선택
    }
  )
)
```

```tsx
// components/CartIcon.tsx
'use client'

import { useCartStore } from '@/stores/cartStore'

export function CartIcon() {
  const totalItems = useCartStore((state) => state.getTotalItems())
  const toggleCart = useCartStore((state) => state.toggleCart)

  return (
    <button onClick={toggleCart} className="cart-icon">
      🛒
      {totalItems > 0 && <span className="badge">{totalItems}</span>}
    </button>
  )
}
```

```tsx
// components/AddToCartButton.tsx
'use client'

import { useCartStore } from '@/stores/cartStore'

interface Product {
  id: string
  name: string
  price: number
  image: string
}

export function AddToCartButton({ product }: { product: Product }) {
  const addItem = useCartStore((state) => state.addItem)

  return (
    <button onClick={() => addItem(product)}>
      장바구니 담기
    </button>
  )
}
```

```tsx
// components/CartDrawer.tsx
'use client'

import { useCartStore } from '@/stores/cartStore'
import { shallow } from 'zustand/shallow'

export function CartDrawer() {
  const { items, isOpen, toggleCart, removeItem, updateQuantity, getTotalPrice } =
    useCartStore(
      (state) => ({
        items: state.items,
        isOpen: state.isOpen,
        toggleCart: state.toggleCart,
        removeItem: state.removeItem,
        updateQuantity: state.updateQuantity,
        getTotalPrice: state.getTotalPrice,
      }),
      shallow
    )

  if (!isOpen) return null

  return (
    <div className="cart-drawer">
      <div className="cart-header">
        <h2>장바구니</h2>
        <button onClick={toggleCart}>✕</button>
      </div>

      <div className="cart-items">
        {items.length === 0 ? (
          <p>장바구니가 비어있습니다</p>
        ) : (
          items.map((item) => (
            <div key={item.id} className="cart-item">
              <img src={item.image} alt={item.name} />
              <div>
                <h3>{item.name}</h3>
                <p>{item.price.toLocaleString()}원</p>
              </div>
              <div className="quantity">
                <button onClick={() => updateQuantity(item.id, item.quantity - 1)}>
                  -
                </button>
                <span>{item.quantity}</span>
                <button onClick={() => updateQuantity(item.id, item.quantity + 1)}>
                  +
                </button>
              </div>
              <button onClick={() => removeItem(item.id)}>삭제</button>
            </div>
          ))
        )}
      </div>

      <div className="cart-footer">
        <p>총 금액: {getTotalPrice().toLocaleString()}원</p>
        <button className="checkout-btn">결제하기</button>
      </div>
    </div>
  )
}
```

---

## 실전 예시: 인증

```tsx
// stores/authStore.ts
import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'

interface User {
  id: string
  email: string
  name: string
  avatar?: string
}

interface AuthState {
  user: User | null
  token: string | null
  isAuthenticated: boolean
  isLoading: boolean

  login: (email: string, password: string) => Promise<void>
  logout: () => void
  updateUser: (data: Partial<User>) => void
  checkAuth: () => Promise<void>
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      isLoading: true,

      login: async (email, password) => {
        try {
          const response = await fetch('/api/auth/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password }),
          })

          if (!response.ok) {
            throw new Error('Login failed')
          }

          const { user, token } = await response.json()

          set({
            user,
            token,
            isAuthenticated: true,
          })
        } catch (error) {
          set({ user: null, token: null, isAuthenticated: false })
          throw error
        }
      },

      logout: () => {
        set({
          user: null,
          token: null,
          isAuthenticated: false,
        })
      },

      updateUser: (data) => {
        const currentUser = get().user
        if (currentUser) {
          set({ user: { ...currentUser, ...data } })
        }
      },

      checkAuth: async () => {
        const token = get().token

        if (!token) {
          set({ isLoading: false })
          return
        }

        try {
          const response = await fetch('/api/auth/me', {
            headers: { Authorization: `Bearer ${token}` },
          })

          if (response.ok) {
            const user = await response.json()
            set({ user, isAuthenticated: true, isLoading: false })
          } else {
            set({ user: null, token: null, isAuthenticated: false, isLoading: false })
          }
        } catch {
          set({ user: null, token: null, isAuthenticated: false, isLoading: false })
        }
      },
    }),
    {
      name: 'auth-storage',
      storage: createJSONStorage(() => localStorage),
      partialize: (state) => ({
        token: state.token,
        user: state.user,
      }),
    }
  )
)
```

---

## 미들웨어

### persist - localStorage 저장

```tsx
import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'

const useStore = create(
  persist(
    (set) => ({
      theme: 'light',
      setTheme: (theme) => set({ theme }),
    }),
    {
      name: 'theme-storage', // 저장 키
      storage: createJSONStorage(() => localStorage), // 기본값
      partialize: (state) => ({ theme: state.theme }), // 저장할 필드만
    }
  )
)
```

### devtools - Redux DevTools 연동

```tsx
import { create } from 'zustand'
import { devtools } from 'zustand/middleware'

const useStore = create(
  devtools(
    (set) => ({
      count: 0,
      increment: () =>
        set(
          (state) => ({ count: state.count + 1 }),
          false,
          'increment' // 액션 이름 (DevTools에 표시)
        ),
    }),
    { name: 'CounterStore' } // 스토어 이름
  )
)
```

### immer - 불변성 쉽게 관리

```tsx
import { create } from 'zustand'
import { immer } from 'zustand/middleware/immer'

interface TodoState {
  todos: { id: string; text: string; done: boolean }[]
  addTodo: (text: string) => void
  toggleTodo: (id: string) => void
}

const useTodoStore = create<TodoState>()(
  immer((set) => ({
    todos: [],

    addTodo: (text) =>
      set((state) => {
        // immer로 직접 수정 가능!
        state.todos.push({
          id: crypto.randomUUID(),
          text,
          done: false,
        })
      }),

    toggleTodo: (id) =>
      set((state) => {
        const todo = state.todos.find((t) => t.id === id)
        if (todo) {
          todo.done = !todo.done // 직접 수정 가능!
        }
      }),
  }))
)
```

### 미들웨어 조합

```tsx
import { create } from 'zustand'
import { devtools, persist } from 'zustand/middleware'
import { immer } from 'zustand/middleware/immer'

const useStore = create<State>()(
  devtools(
    persist(
      immer((set) => ({
        // ...
      })),
      { name: 'store' }
    ),
    { name: 'MyStore' }
  )
)
```

---

## Slice 패턴 (큰 스토어 분리)

```tsx
// stores/slices/userSlice.ts
import { StateCreator } from 'zustand'

export interface UserSlice {
  user: User | null
  setUser: (user: User) => void
  clearUser: () => void
}

export const createUserSlice: StateCreator<UserSlice> = (set) => ({
  user: null,
  setUser: (user) => set({ user }),
  clearUser: () => set({ user: null }),
})
```

```tsx
// stores/slices/cartSlice.ts
import { StateCreator } from 'zustand'

export interface CartSlice {
  items: CartItem[]
  addItem: (item: CartItem) => void
  removeItem: (id: string) => void
}

export const createCartSlice: StateCreator<CartSlice> = (set) => ({
  items: [],
  addItem: (item) => set((state) => ({ items: [...state.items, item] })),
  removeItem: (id) => set((state) => ({ items: state.items.filter((i) => i.id !== id) })),
})
```

```tsx
// stores/index.ts
import { create } from 'zustand'
import { UserSlice, createUserSlice } from './slices/userSlice'
import { CartSlice, createCartSlice } from './slices/cartSlice'

type StoreState = UserSlice & CartSlice

export const useStore = create<StoreState>()((...a) => ({
  ...createUserSlice(...a),
  ...createCartSlice(...a),
}))
```

---

## Store 외부에서 접근

```tsx
// 컴포넌트 외부에서 상태 접근
const state = useCartStore.getState()
const totalItems = state.getTotalItems()

// 컴포넌트 외부에서 상태 변경
useCartStore.getState().addItem(item)

// 상태 구독
const unsubscribe = useCartStore.subscribe(
  (state) => console.log('상태 변경:', state)
)

// 특정 값만 구독
const unsubscribe = useCartStore.subscribe(
  (state) => state.items,
  (items, prevItems) => {
    console.log('아이템 변경:', items)
  }
)
```

---

## Next.js SSR 주의사항

```tsx
// Hydration mismatch 방지
'use client'

import { useEffect, useState } from 'react'
import { useCartStore } from '@/stores/cartStore'

export function CartItemCount() {
  const [mounted, setMounted] = useState(false)
  const totalItems = useCartStore((state) => state.getTotalItems())

  useEffect(() => {
    setMounted(true)
  }, [])

  // 서버와 클라이언트 렌더링 일치
  if (!mounted) return <span>0</span>

  return <span>{totalItems}</span>
}
```

또는 `useStore` 훅을 만들어 사용:

```tsx
// hooks/useStore.ts
import { useState, useEffect } from 'react'

export function useStore<T, F>(
  store: (callback: (state: T) => unknown) => unknown,
  callback: (state: T) => F
) {
  const result = store(callback) as F
  const [data, setData] = useState<F>()

  useEffect(() => {
    setData(result)
  }, [result])

  return data
}
```

```tsx
// 사용
const items = useStore(useCartStore, (state) => state.items)
```

---

## 장단점

### 장점

- 매우 가벼움 (~1KB)
- 간단한 API
- TypeScript 지원 우수
- Provider 불필요
- 미들웨어 지원 (persist, devtools, immer)
- React 외부에서도 사용 가능

### 단점

- 복잡한 상태 로직에는 구조화 필요
- 대규모 앱에서는 추가 패턴 필요 (Slice 등)

---

## 참고 자료

- [Zustand 공식 문서](https://docs.pmnd.rs/zustand)
- [Zustand GitHub](https://github.com/pmndrs/zustand)
