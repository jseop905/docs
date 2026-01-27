# Jotai

**원자적(Atomic) 상태 관리** 라이브러리입니다. 작은 단위의 상태(atom)를 조합하여 상태를 관리합니다.

---

## 핵심 개념

Jotai는 **bottom-up** 접근 방식을 사용합니다:

- **Atom**: 상태의 최소 단위
- **Derived Atom**: 다른 atom에서 파생된 상태
- **Primitive Atom**: 기본 값을 가진 atom
- **Writable Atom**: 읽기/쓰기 가능한 atom
- **Read-only Atom**: 읽기만 가능한 atom

---

## 설치

```bash
npm install jotai
```

---

## 기본 사용법

### Primitive Atom

```tsx
// atoms/counterAtom.ts
import { atom } from 'jotai'

// 기본 atom 생성
export const countAtom = atom(0)
```

```tsx
// components/Counter.tsx
'use client'

import { useAtom } from 'jotai'
import { countAtom } from '@/atoms/counterAtom'

export function Counter() {
  const [count, setCount] = useAtom(countAtom)

  return (
    <div>
      <span>{count}</span>
      <button onClick={() => setCount((c) => c - 1)}>-</button>
      <button onClick={() => setCount((c) => c + 1)}>+</button>
    </div>
  )
}
```

### Read-only vs Write-only

```tsx
'use client'

import { useAtomValue, useSetAtom } from 'jotai'
import { countAtom } from '@/atoms/counterAtom'

// 읽기만 필요할 때
function DisplayCount() {
  const count = useAtomValue(countAtom)
  return <span>{count}</span>
}

// 쓰기만 필요할 때
function IncrementButton() {
  const setCount = useSetAtom(countAtom)
  return <button onClick={() => setCount((c) => c + 1)}>+</button>
}
```

---

## Derived Atom (파생 상태)

### 읽기 전용 파생 atom

```tsx
// atoms/cartAtoms.ts
import { atom } from 'jotai'

interface CartItem {
  id: string
  name: string
  price: number
  quantity: number
}

// 기본 atom
export const cartItemsAtom = atom<CartItem[]>([])

// 파생 atom - 총 수량
export const totalItemsAtom = atom((get) => {
  const items = get(cartItemsAtom)
  return items.reduce((sum, item) => sum + item.quantity, 0)
})

// 파생 atom - 총 가격
export const totalPriceAtom = atom((get) => {
  const items = get(cartItemsAtom)
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0)
})

// 여러 atom 조합
export const cartSummaryAtom = atom((get) => ({
  items: get(cartItemsAtom),
  totalItems: get(totalItemsAtom),
  totalPrice: get(totalPriceAtom),
}))
```

### 읽기/쓰기 파생 atom

```tsx
// atoms/cartAtoms.ts
import { atom } from 'jotai'

export const cartItemsAtom = atom<CartItem[]>([])

// 읽기/쓰기 가능한 파생 atom
export const addItemAtom = atom(
  null, // read 값 (null = write-only)
  (get, set, newItem: Omit<CartItem, 'quantity'>) => {
    const items = get(cartItemsAtom)
    const existingItem = items.find((item) => item.id === newItem.id)

    if (existingItem) {
      set(
        cartItemsAtom,
        items.map((item) =>
          item.id === newItem.id
            ? { ...item, quantity: item.quantity + 1 }
            : item
        )
      )
    } else {
      set(cartItemsAtom, [...items, { ...newItem, quantity: 1 }])
    }
  }
)

export const removeItemAtom = atom(null, (get, set, id: string) => {
  const items = get(cartItemsAtom)
  set(
    cartItemsAtom,
    items.filter((item) => item.id !== id)
  )
})

export const updateQuantityAtom = atom(
  null,
  (get, set, { id, quantity }: { id: string; quantity: number }) => {
    const items = get(cartItemsAtom)

    if (quantity <= 0) {
      set(
        cartItemsAtom,
        items.filter((item) => item.id !== id)
      )
    } else {
      set(
        cartItemsAtom,
        items.map((item) =>
          item.id === id ? { ...item, quantity } : item
        )
      )
    }
  }
)

export const clearCartAtom = atom(null, (get, set) => {
  set(cartItemsAtom, [])
})
```

```tsx
// components/AddToCartButton.tsx
'use client'

import { useSetAtom } from 'jotai'
import { addItemAtom } from '@/atoms/cartAtoms'

export function AddToCartButton({ product }: { product: Product }) {
  const addItem = useSetAtom(addItemAtom)

  return (
    <button onClick={() => addItem(product)}>
      장바구니 담기
    </button>
  )
}
```

---

## 비동기 Atom

### async atom

```tsx
// atoms/userAtoms.ts
import { atom } from 'jotai'

interface User {
  id: string
  name: string
  email: string
}

// 비동기 읽기 atom
export const userAtom = atom(async () => {
  const response = await fetch('/api/user')
  if (!response.ok) throw new Error('Failed to fetch user')
  return response.json() as Promise<User>
})

// 의존성이 있는 비동기 atom
export const userIdAtom = atom<string | null>(null)

export const userProfileAtom = atom(async (get) => {
  const userId = get(userIdAtom)
  if (!userId) return null

  const response = await fetch(`/api/users/${userId}`)
  return response.json()
})
```

```tsx
// components/UserProfile.tsx
'use client'

import { Suspense } from 'react'
import { useAtomValue } from 'jotai'
import { userAtom } from '@/atoms/userAtoms'

function UserProfileContent() {
  const user = useAtomValue(userAtom)

  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
    </div>
  )
}

export function UserProfile() {
  return (
    <Suspense fallback={<div>로딩 중...</div>}>
      <UserProfileContent />
    </Suspense>
  )
}
```

### loadable (에러 처리)

```tsx
import { atom } from 'jotai'
import { loadable } from 'jotai/utils'

const asyncUserAtom = atom(async () => {
  const response = await fetch('/api/user')
  return response.json()
})

// loadable로 감싸면 상태를 직접 관리
const loadableUserAtom = loadable(asyncUserAtom)
```

```tsx
'use client'

import { useAtomValue } from 'jotai'
import { loadableUserAtom } from '@/atoms/userAtoms'

export function UserProfile() {
  const userLoadable = useAtomValue(loadableUserAtom)

  if (userLoadable.state === 'loading') {
    return <div>로딩 중...</div>
  }

  if (userLoadable.state === 'hasError') {
    return <div>에러: {userLoadable.error.message}</div>
  }

  return <div>{userLoadable.data.name}</div>
}
```

---

## 유용한 유틸리티

### atomWithStorage (localStorage)

```tsx
import { atomWithStorage } from 'jotai/utils'

// localStorage에 자동 저장
export const themeAtom = atomWithStorage<'light' | 'dark'>('theme', 'light')

export const favoritesAtom = atomWithStorage<string[]>('favorites', [])
```

```tsx
'use client'

import { useAtom } from 'jotai'
import { themeAtom } from '@/atoms/themeAtom'

export function ThemeToggle() {
  const [theme, setTheme] = useAtom(themeAtom)

  return (
    <button onClick={() => setTheme(theme === 'light' ? 'dark' : 'light')}>
      현재: {theme}
    </button>
  )
}
```

### atomWithReset (리셋 가능)

```tsx
import { atomWithReset, useResetAtom } from 'jotai/utils'

export const filtersAtom = atomWithReset({
  category: '',
  minPrice: 0,
  maxPrice: 1000000,
  sortBy: 'newest',
})
```

```tsx
'use client'

import { useAtom } from 'jotai'
import { useResetAtom } from 'jotai/utils'
import { filtersAtom } from '@/atoms/filtersAtom'

export function Filters() {
  const [filters, setFilters] = useAtom(filtersAtom)
  const resetFilters = useResetAtom(filtersAtom)

  return (
    <div>
      <select
        value={filters.sortBy}
        onChange={(e) => setFilters({ ...filters, sortBy: e.target.value })}
      >
        <option value="newest">최신순</option>
        <option value="price">가격순</option>
      </select>

      <button onClick={resetFilters}>필터 초기화</button>
    </div>
  )
}
```

### atomFamily (동적 atom 생성)

```tsx
import { atom } from 'jotai'
import { atomFamily } from 'jotai/utils'

// 파라미터로 동적 atom 생성
export const todoAtomFamily = atomFamily((id: string) =>
  atom({
    id,
    text: '',
    completed: false,
  })
)

// 비동기 버전
export const userAtomFamily = atomFamily((userId: string) =>
  atom(async () => {
    const response = await fetch(`/api/users/${userId}`)
    return response.json()
  })
)
```

```tsx
'use client'

import { useAtom } from 'jotai'
import { todoAtomFamily } from '@/atoms/todoAtoms'

export function TodoItem({ id }: { id: string }) {
  const [todo, setTodo] = useAtom(todoAtomFamily(id))

  return (
    <label>
      <input
        type="checkbox"
        checked={todo.completed}
        onChange={(e) => setTodo({ ...todo, completed: e.target.checked })}
      />
      {todo.text}
    </label>
  )
}
```

### selectAtom (부분 선택)

```tsx
import { atom } from 'jotai'
import { selectAtom } from 'jotai/utils'

const userAtom = atom({
  name: 'John',
  email: 'john@example.com',
  settings: {
    theme: 'light',
    notifications: true,
  },
})

// 특정 필드만 선택 (메모이제이션)
const userNameAtom = selectAtom(userAtom, (user) => user.name)
const userThemeAtom = selectAtom(userAtom, (user) => user.settings.theme)
```

---

## 실전 예시: Todo 앱

```tsx
// atoms/todoAtoms.ts
import { atom } from 'jotai'
import { atomWithStorage } from 'jotai/utils'

export interface Todo {
  id: string
  text: string
  completed: boolean
  createdAt: number
}

// 기본 atoms
export const todosAtom = atomWithStorage<Todo[]>('todos', [])
export const filterAtom = atom<'all' | 'active' | 'completed'>('all')

// 파생 atoms
export const filteredTodosAtom = atom((get) => {
  const todos = get(todosAtom)
  const filter = get(filterAtom)

  switch (filter) {
    case 'active':
      return todos.filter((todo) => !todo.completed)
    case 'completed':
      return todos.filter((todo) => todo.completed)
    default:
      return todos
  }
})

export const statsAtom = atom((get) => {
  const todos = get(todosAtom)
  return {
    total: todos.length,
    completed: todos.filter((t) => t.completed).length,
    active: todos.filter((t) => !t.completed).length,
  }
})

// 액션 atoms
export const addTodoAtom = atom(null, (get, set, text: string) => {
  const newTodo: Todo = {
    id: crypto.randomUUID(),
    text,
    completed: false,
    createdAt: Date.now(),
  }
  set(todosAtom, [...get(todosAtom), newTodo])
})

export const toggleTodoAtom = atom(null, (get, set, id: string) => {
  set(
    todosAtom,
    get(todosAtom).map((todo) =>
      todo.id === id ? { ...todo, completed: !todo.completed } : todo
    )
  )
})

export const deleteTodoAtom = atom(null, (get, set, id: string) => {
  set(
    todosAtom,
    get(todosAtom).filter((todo) => todo.id !== id)
  )
})

export const clearCompletedAtom = atom(null, (get, set) => {
  set(
    todosAtom,
    get(todosAtom).filter((todo) => !todo.completed)
  )
})
```

```tsx
// components/TodoApp.tsx
'use client'

import { useAtom, useAtomValue, useSetAtom } from 'jotai'
import {
  filteredTodosAtom,
  filterAtom,
  statsAtom,
  addTodoAtom,
  toggleTodoAtom,
  deleteTodoAtom,
  clearCompletedAtom,
} from '@/atoms/todoAtoms'
import { useState } from 'react'

export function TodoApp() {
  const [inputValue, setInputValue] = useState('')
  const todos = useAtomValue(filteredTodosAtom)
  const [filter, setFilter] = useAtom(filterAtom)
  const stats = useAtomValue(statsAtom)
  const addTodo = useSetAtom(addTodoAtom)
  const toggleTodo = useSetAtom(toggleTodoAtom)
  const deleteTodo = useSetAtom(deleteTodoAtom)
  const clearCompleted = useSetAtom(clearCompletedAtom)

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (inputValue.trim()) {
      addTodo(inputValue.trim())
      setInputValue('')
    }
  }

  return (
    <div>
      <form onSubmit={handleSubmit}>
        <input
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          placeholder="할 일 추가"
        />
        <button type="submit">추가</button>
      </form>

      <ul>
        {todos.map((todo) => (
          <li key={todo.id}>
            <input
              type="checkbox"
              checked={todo.completed}
              onChange={() => toggleTodo(todo.id)}
            />
            <span style={{ textDecoration: todo.completed ? 'line-through' : 'none' }}>
              {todo.text}
            </span>
            <button onClick={() => deleteTodo(todo.id)}>삭제</button>
          </li>
        ))}
      </ul>

      <div>
        <span>{stats.active}개 남음</span>
        <button onClick={() => setFilter('all')} disabled={filter === 'all'}>
          전체
        </button>
        <button onClick={() => setFilter('active')} disabled={filter === 'active'}>
          진행중
        </button>
        <button onClick={() => setFilter('completed')} disabled={filter === 'completed'}>
          완료
        </button>
        {stats.completed > 0 && (
          <button onClick={clearCompleted}>완료 항목 삭제</button>
        )}
      </div>
    </div>
  )
}
```

---

## Provider 사용

기본적으로 Jotai는 Provider 없이도 동작합니다. 하지만 다음 경우에는 Provider가 필요합니다:

### SSR 지원

```tsx
// app/providers.tsx
'use client'

import { Provider } from 'jotai'

export function JotaiProvider({ children }: { children: React.ReactNode }) {
  return <Provider>{children}</Provider>
}
```

### 스코프 분리

```tsx
import { Provider } from 'jotai'

function App() {
  return (
    <Provider>
      <ComponentA />
      <Provider>
        {/* 이 안에서는 별도의 atom 스토어 사용 */}
        <ComponentB />
      </Provider>
    </Provider>
  )
}
```

---

## DevTools

```bash
npm install jotai-devtools
```

```tsx
// app/providers.tsx
'use client'

import { Provider } from 'jotai'
import { DevTools } from 'jotai-devtools'

export function JotaiProvider({ children }: { children: React.ReactNode }) {
  return (
    <Provider>
      <DevTools />
      {children}
    </Provider>
  )
}
```

---

## Zustand vs Jotai

| 특징 | Zustand | Jotai |
|------|---------|-------|
| 접근 방식 | Top-down (스토어 중심) | Bottom-up (atom 중심) |
| 상태 정의 | 하나의 스토어 | 여러 개의 atom |
| 파생 상태 | 수동으로 계산 | atom으로 선언적 |
| 비동기 | 액션에서 처리 | async atom |
| 리렌더링 | 선택자로 최적화 | 자동 최적화 |
| 번들 크기 | ~1KB | ~2KB |

**Zustand가 적합한 경우:**
- 단일 스토어로 상태 관리
- Redux 스타일 선호
- 간단한 전역 상태

**Jotai가 적합한 경우:**
- 세밀한 상태 관리
- 파생 상태가 많음
- React스러운 API 선호
- Suspense 활용

---

## 장단점

### 장점

- 가벼움 (~2KB)
- React 친화적 API
- 자동 리렌더링 최적화
- 파생 상태 선언적 표현
- Suspense 지원
- TypeScript 지원 우수

### 단점

- atom이 많아지면 관리 복잡
- 러닝 커브 (atom 사고방식)
- Zustand보다 커뮤니티 작음

---

## 참고 자료

- [Jotai 공식 문서](https://jotai.org/)
- [Jotai GitHub](https://github.com/pmndrs/jotai)
