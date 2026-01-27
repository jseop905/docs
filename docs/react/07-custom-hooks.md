# 커스텀 Hooks 패턴

재사용 가능한 로직을 커스텀 Hook으로 추출하는 방법과 실전 패턴을 알아봅니다.

---

## 커스텀 Hook이란?

### 기본 개념

```tsx
// 커스텀 Hook = use로 시작하는 함수 + 다른 Hook 사용
function useCounter(initialValue = 0) {
  const [count, setCount] = useState(initialValue)

  const increment = useCallback(() => setCount(c => c + 1), [])
  const decrement = useCallback(() => setCount(c => c - 1), [])
  const reset = useCallback(() => setCount(initialValue), [initialValue])

  return { count, increment, decrement, reset }
}

// 사용
function Counter() {
  const { count, increment, decrement, reset } = useCounter(10)

  return (
    <div>
      <p>{count}</p>
      <button onClick={increment}>+</button>
      <button onClick={decrement}>-</button>
      <button onClick={reset}>Reset</button>
    </div>
  )
}
```

### 왜 커스텀 Hook인가?

```tsx
// Before: 로직이 컴포넌트에 섞임
function UserProfile({ userId }) {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    let ignore = false
    setLoading(true)

    fetchUser(userId)
      .then(data => {
        if (!ignore) {
          setUser(data)
          setError(null)
        }
      })
      .catch(err => {
        if (!ignore) setError(err)
      })
      .finally(() => {
        if (!ignore) setLoading(false)
      })

    return () => { ignore = true }
  }, [userId])

  if (loading) return <Spinner />
  if (error) return <Error message={error.message} />
  return <Profile user={user} />
}

// After: 로직 분리
function useUser(userId) {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    let ignore = false
    setLoading(true)

    fetchUser(userId)
      .then(data => {
        if (!ignore) {
          setUser(data)
          setError(null)
        }
      })
      .catch(err => {
        if (!ignore) setError(err)
      })
      .finally(() => {
        if (!ignore) setLoading(false)
      })

    return () => { ignore = true }
  }, [userId])

  return { user, loading, error }
}

function UserProfile({ userId }) {
  const { user, loading, error } = useUser(userId)

  if (loading) return <Spinner />
  if (error) return <Error message={error.message} />
  return <Profile user={user} />
}
```

---

## 상태 관리 Hooks

### useToggle

```tsx
function useToggle(initialValue = false) {
  const [value, setValue] = useState(initialValue)

  const toggle = useCallback(() => setValue(v => !v), [])
  const setTrue = useCallback(() => setValue(true), [])
  const setFalse = useCallback(() => setValue(false), [])

  return { value, toggle, setTrue, setFalse }
}

// 사용
function Modal() {
  const { value: isOpen, toggle, setFalse: close } = useToggle()

  return (
    <>
      <button onClick={toggle}>Toggle Modal</button>
      {isOpen && (
        <div className="modal">
          <button onClick={close}>Close</button>
        </div>
      )}
    </>
  )
}
```

### useArray

```tsx
function useArray<T>(initialValue: T[] = []) {
  const [array, setArray] = useState(initialValue)

  const push = useCallback((element: T) => {
    setArray(a => [...a, element])
  }, [])

  const filter = useCallback((callback: (element: T) => boolean) => {
    setArray(a => a.filter(callback))
  }, [])

  const update = useCallback((index: number, newElement: T) => {
    setArray(a => a.map((e, i) => (i === index ? newElement : e)))
  }, [])

  const remove = useCallback((index: number) => {
    setArray(a => a.filter((_, i) => i !== index))
  }, [])

  const clear = useCallback(() => setArray([]), [])

  return { array, set: setArray, push, filter, update, remove, clear }
}

// 사용
function TodoList() {
  const { array: todos, push, remove, update } = useArray<Todo>([])

  const addTodo = (text: string) => {
    push({ id: Date.now(), text, done: false })
  }

  const toggleTodo = (index: number) => {
    update(index, { ...todos[index], done: !todos[index].done })
  }

  return (
    <ul>
      {todos.map((todo, index) => (
        <li key={todo.id}>
          <span
            style={{ textDecoration: todo.done ? 'line-through' : 'none' }}
            onClick={() => toggleTodo(index)}
          >
            {todo.text}
          </span>
          <button onClick={() => remove(index)}>Delete</button>
        </li>
      ))}
    </ul>
  )
}
```

### useMap

```tsx
function useMap<K, V>(initialValue?: Iterable<[K, V]>) {
  const [map, setMap] = useState(new Map(initialValue))

  const set = useCallback((key: K, value: V) => {
    setMap(prev => new Map(prev).set(key, value))
  }, [])

  const remove = useCallback((key: K) => {
    setMap(prev => {
      const next = new Map(prev)
      next.delete(key)
      return next
    })
  }, [])

  const clear = useCallback(() => {
    setMap(new Map())
  }, [])

  return {
    map,
    get: (key: K) => map.get(key),
    set,
    remove,
    clear,
    has: (key: K) => map.has(key),
  }
}
```

### usePrevious

```tsx
function usePrevious<T>(value: T): T | undefined {
  const ref = useRef<T | undefined>(undefined)

  useEffect(() => {
    ref.current = value
  }, [value])

  return ref.current
}

// 사용
function Counter() {
  const [count, setCount] = useState(0)
  const prevCount = usePrevious(count)

  return (
    <div>
      <p>Now: {count}, Before: {prevCount ?? 'N/A'}</p>
      <button onClick={() => setCount(c => c + 1)}>+</button>
    </div>
  )
}
```

---

## 데이터 페칭 Hooks

### useFetch

```tsx
interface UseFetchResult<T> {
  data: T | null
  loading: boolean
  error: Error | null
  refetch: () => void
}

function useFetch<T>(url: string): UseFetchResult<T> {
  const [data, setData] = useState<T | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  const fetchData = useCallback(async () => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch(url)
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      const json = await response.json()
      setData(json)
    } catch (e) {
      setError(e instanceof Error ? e : new Error('Unknown error'))
    } finally {
      setLoading(false)
    }
  }, [url])

  useEffect(() => {
    fetchData()
  }, [fetchData])

  return { data, loading, error, refetch: fetchData }
}

// 사용
function UserList() {
  const { data: users, loading, error, refetch } = useFetch<User[]>('/api/users')

  if (loading) return <Spinner />
  if (error) return <Error message={error.message} onRetry={refetch} />

  return (
    <ul>
      {users?.map(user => <li key={user.id}>{user.name}</li>)}
    </ul>
  )
}
```

### useAsync

```tsx
interface UseAsyncResult<T> {
  data: T | null
  loading: boolean
  error: Error | null
  execute: () => Promise<void>
}

function useAsync<T>(
  asyncFunction: () => Promise<T>,
  immediate = true
): UseAsyncResult<T> {
  const [data, setData] = useState<T | null>(null)
  const [loading, setLoading] = useState(immediate)
  const [error, setError] = useState<Error | null>(null)

  const execute = useCallback(async () => {
    setLoading(true)
    setError(null)

    try {
      const response = await asyncFunction()
      setData(response)
    } catch (e) {
      setError(e instanceof Error ? e : new Error('Unknown error'))
    } finally {
      setLoading(false)
    }
  }, [asyncFunction])

  useEffect(() => {
    if (immediate) {
      execute()
    }
  }, [execute, immediate])

  return { data, loading, error, execute }
}

// 사용
function UserProfile({ userId }) {
  const fetchUser = useCallback(() => fetch(`/api/users/${userId}`).then(r => r.json()), [userId])
  const { data: user, loading, error } = useAsync(fetchUser)

  // ...
}
```

### useInfiniteScroll

```tsx
function useInfiniteScroll<T>(
  fetchFn: (page: number) => Promise<T[]>,
  options?: { threshold?: number }
) {
  const [items, setItems] = useState<T[]>([])
  const [page, setPage] = useState(1)
  const [loading, setLoading] = useState(false)
  const [hasMore, setHasMore] = useState(true)

  const observerRef = useRef<IntersectionObserver | null>(null)
  const loadMoreRef = useCallback((node: HTMLElement | null) => {
    if (loading) return

    if (observerRef.current) {
      observerRef.current.disconnect()
    }

    observerRef.current = new IntersectionObserver(
      entries => {
        if (entries[0].isIntersecting && hasMore) {
          setPage(p => p + 1)
        }
      },
      { threshold: options?.threshold ?? 0.1 }
    )

    if (node) {
      observerRef.current.observe(node)
    }
  }, [loading, hasMore, options?.threshold])

  useEffect(() => {
    let ignore = false
    setLoading(true)

    fetchFn(page)
      .then(newItems => {
        if (!ignore) {
          setItems(prev => [...prev, ...newItems])
          setHasMore(newItems.length > 0)
        }
      })
      .finally(() => {
        if (!ignore) setLoading(false)
      })

    return () => { ignore = true }
  }, [page, fetchFn])

  return { items, loading, hasMore, loadMoreRef }
}

// 사용
function PostList() {
  const fetchPosts = useCallback(
    (page: number) => fetch(`/api/posts?page=${page}`).then(r => r.json()),
    []
  )
  const { items: posts, loading, loadMoreRef } = useInfiniteScroll(fetchPosts)

  return (
    <div>
      {posts.map(post => <PostCard key={post.id} post={post} />)}
      <div ref={loadMoreRef}>
        {loading && <Spinner />}
      </div>
    </div>
  )
}
```

---

## 브라우저 API Hooks

### useLocalStorage

```tsx
function useLocalStorage<T>(key: string, initialValue: T) {
  const [storedValue, setStoredValue] = useState<T>(() => {
    if (typeof window === 'undefined') return initialValue

    try {
      const item = window.localStorage.getItem(key)
      return item ? JSON.parse(item) : initialValue
    } catch (error) {
      console.warn(`Error reading localStorage key "${key}":`, error)
      return initialValue
    }
  })

  const setValue = useCallback((value: T | ((val: T) => T)) => {
    try {
      const valueToStore = value instanceof Function ? value(storedValue) : value
      setStoredValue(valueToStore)

      if (typeof window !== 'undefined') {
        window.localStorage.setItem(key, JSON.stringify(valueToStore))
      }
    } catch (error) {
      console.warn(`Error setting localStorage key "${key}":`, error)
    }
  }, [key, storedValue])

  const removeValue = useCallback(() => {
    try {
      setStoredValue(initialValue)
      if (typeof window !== 'undefined') {
        window.localStorage.removeItem(key)
      }
    } catch (error) {
      console.warn(`Error removing localStorage key "${key}":`, error)
    }
  }, [key, initialValue])

  return [storedValue, setValue, removeValue] as const
}

// 사용
function Settings() {
  const [theme, setTheme] = useLocalStorage('theme', 'light')

  return (
    <button onClick={() => setTheme(t => t === 'light' ? 'dark' : 'light')}>
      Current: {theme}
    </button>
  )
}
```

### useMediaQuery

```tsx
function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(() => {
    if (typeof window === 'undefined') return false
    return window.matchMedia(query).matches
  })

  useEffect(() => {
    const mediaQuery = window.matchMedia(query)
    const handler = (event: MediaQueryListEvent) => setMatches(event.matches)

    // 초기값 설정
    setMatches(mediaQuery.matches)

    // 리스너 등록
    mediaQuery.addEventListener('change', handler)
    return () => mediaQuery.removeEventListener('change', handler)
  }, [query])

  return matches
}

// 사용
function ResponsiveComponent() {
  const isMobile = useMediaQuery('(max-width: 768px)')
  const isTablet = useMediaQuery('(min-width: 769px) and (max-width: 1024px)')
  const isDesktop = useMediaQuery('(min-width: 1025px)')

  if (isMobile) return <MobileLayout />
  if (isTablet) return <TabletLayout />
  return <DesktopLayout />
}
```

### useOnlineStatus

```tsx
function useOnlineStatus(): boolean {
  const [isOnline, setIsOnline] = useState(() => {
    if (typeof navigator === 'undefined') return true
    return navigator.onLine
  })

  useEffect(() => {
    const handleOnline = () => setIsOnline(true)
    const handleOffline = () => setIsOnline(false)

    window.addEventListener('online', handleOnline)
    window.addEventListener('offline', handleOffline)

    return () => {
      window.removeEventListener('online', handleOnline)
      window.removeEventListener('offline', handleOffline)
    }
  }, [])

  return isOnline
}

// 사용
function App() {
  const isOnline = useOnlineStatus()

  return (
    <div>
      {!isOnline && <Banner>You are offline</Banner>}
      <MainContent />
    </div>
  )
}
```

### useWindowSize

```tsx
interface WindowSize {
  width: number
  height: number
}

function useWindowSize(): WindowSize {
  const [size, setSize] = useState<WindowSize>(() => ({
    width: typeof window !== 'undefined' ? window.innerWidth : 0,
    height: typeof window !== 'undefined' ? window.innerHeight : 0,
  }))

  useEffect(() => {
    const handleResize = () => {
      setSize({
        width: window.innerWidth,
        height: window.innerHeight,
      })
    }

    window.addEventListener('resize', handleResize)
    return () => window.removeEventListener('resize', handleResize)
  }, [])

  return size
}
```

### useClickOutside

```tsx
function useClickOutside<T extends HTMLElement>(
  handler: () => void
): RefObject<T> {
  const ref = useRef<T>(null)

  useEffect(() => {
    const listener = (event: MouseEvent | TouchEvent) => {
      if (!ref.current || ref.current.contains(event.target as Node)) {
        return
      }
      handler()
    }

    document.addEventListener('mousedown', listener)
    document.addEventListener('touchstart', listener)

    return () => {
      document.removeEventListener('mousedown', listener)
      document.removeEventListener('touchstart', listener)
    }
  }, [handler])

  return ref
}

// 사용
function Dropdown() {
  const [isOpen, setIsOpen] = useState(false)
  const ref = useClickOutside<HTMLDivElement>(() => setIsOpen(false))

  return (
    <div ref={ref}>
      <button onClick={() => setIsOpen(!isOpen)}>Toggle</button>
      {isOpen && <div className="menu">Menu content</div>}
    </div>
  )
}
```

---

## 이벤트 Hooks

### useEventListener

```tsx
function useEventListener<K extends keyof WindowEventMap>(
  eventName: K,
  handler: (event: WindowEventMap[K]) => void,
  element?: undefined
): void
function useEventListener<
  K extends keyof HTMLElementEventMap,
  T extends HTMLElement
>(
  eventName: K,
  handler: (event: HTMLElementEventMap[K]) => void,
  element: RefObject<T>
): void
function useEventListener(
  eventName: string,
  handler: (event: Event) => void,
  element?: RefObject<HTMLElement>
) {
  const savedHandler = useRef(handler)

  useEffect(() => {
    savedHandler.current = handler
  }, [handler])

  useEffect(() => {
    const targetElement = element?.current ?? window
    if (!targetElement?.addEventListener) return

    const listener = (event: Event) => savedHandler.current(event)

    targetElement.addEventListener(eventName, listener)
    return () => targetElement.removeEventListener(eventName, listener)
  }, [eventName, element])
}

// 사용
function Component() {
  useEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      // handle escape
    }
  })

  const buttonRef = useRef<HTMLButtonElement>(null)
  useEventListener('click', () => console.log('Button clicked'), buttonRef)

  return <button ref={buttonRef}>Click me</button>
}
```

### useKeyPress

```tsx
function useKeyPress(targetKey: string): boolean {
  const [keyPressed, setKeyPressed] = useState(false)

  useEffect(() => {
    const downHandler = (e: KeyboardEvent) => {
      if (e.key === targetKey) setKeyPressed(true)
    }

    const upHandler = (e: KeyboardEvent) => {
      if (e.key === targetKey) setKeyPressed(false)
    }

    window.addEventListener('keydown', downHandler)
    window.addEventListener('keyup', upHandler)

    return () => {
      window.removeEventListener('keydown', downHandler)
      window.removeEventListener('keyup', upHandler)
    }
  }, [targetKey])

  return keyPressed
}

// 사용
function Game() {
  const spacePressed = useKeyPress(' ')
  const enterPressed = useKeyPress('Enter')

  useEffect(() => {
    if (spacePressed) {
      jump()
    }
  }, [spacePressed])

  return <div>Press Space to jump</div>
}
```

### useDebounce

```tsx
function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState(value)

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedValue(value)
    }, delay)

    return () => clearTimeout(timer)
  }, [value, delay])

  return debouncedValue
}

// 사용
function SearchInput() {
  const [query, setQuery] = useState('')
  const debouncedQuery = useDebounce(query, 500)

  useEffect(() => {
    if (debouncedQuery) {
      searchApi(debouncedQuery)
    }
  }, [debouncedQuery])

  return (
    <input
      value={query}
      onChange={e => setQuery(e.target.value)}
      placeholder="Search..."
    />
  )
}
```

### useThrottle

```tsx
function useThrottle<T>(value: T, interval: number): T {
  const [throttledValue, setThrottledValue] = useState(value)
  const lastExecuted = useRef(Date.now())

  useEffect(() => {
    const now = Date.now()
    const timeSinceLastExecution = now - lastExecuted.current

    if (timeSinceLastExecution >= interval) {
      lastExecuted.current = now
      setThrottledValue(value)
    } else {
      const timer = setTimeout(() => {
        lastExecuted.current = Date.now()
        setThrottledValue(value)
      }, interval - timeSinceLastExecution)

      return () => clearTimeout(timer)
    }
  }, [value, interval])

  return throttledValue
}
```

---

## 라이프사이클 Hooks

### useMount

```tsx
function useMount(callback: () => void) {
  useEffect(() => {
    callback()
  }, [])  // 의도적으로 빈 의존성
}

// 사용
function Component() {
  useMount(() => {
    console.log('Component mounted')
    analytics.trackPageView()
  })

  return <div>Content</div>
}
```

### useUnmount

```tsx
function useUnmount(callback: () => void) {
  const callbackRef = useRef(callback)
  callbackRef.current = callback

  useEffect(() => {
    return () => callbackRef.current()
  }, [])
}

// 사용
function Component() {
  useUnmount(() => {
    console.log('Component will unmount')
    cleanup()
  })

  return <div>Content</div>
}
```

### useUpdateEffect

```tsx
function useUpdateEffect(effect: () => void, deps?: DependencyList) {
  const isFirstMount = useRef(true)

  useEffect(() => {
    if (isFirstMount.current) {
      isFirstMount.current = false
      return
    }

    return effect()
  }, deps)
}

// 사용: 마운트 시에는 실행 안 됨
function Component({ userId }) {
  useUpdateEffect(() => {
    console.log('userId changed:', userId)
    // 마운트 시에는 실행 안 됨
    // userId가 변경될 때만 실행
  }, [userId])
}
```

---

## 폼 Hooks

### useForm

```tsx
interface UseFormOptions<T> {
  initialValues: T
  validate?: (values: T) => Partial<Record<keyof T, string>>
  onSubmit: (values: T) => void | Promise<void>
}

function useForm<T extends Record<string, any>>({
  initialValues,
  validate,
  onSubmit,
}: UseFormOptions<T>) {
  const [values, setValues] = useState<T>(initialValues)
  const [errors, setErrors] = useState<Partial<Record<keyof T, string>>>({})
  const [touched, setTouched] = useState<Partial<Record<keyof T, boolean>>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)

  const handleChange = useCallback((
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>
  ) => {
    const { name, value, type } = e.target
    const newValue = type === 'checkbox' ? (e.target as HTMLInputElement).checked : value

    setValues(prev => ({ ...prev, [name]: newValue }))
  }, [])

  const handleBlur = useCallback((
    e: React.FocusEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>
  ) => {
    const { name } = e.target
    setTouched(prev => ({ ...prev, [name]: true }))

    if (validate) {
      const validationErrors = validate(values)
      setErrors(validationErrors)
    }
  }, [validate, values])

  const handleSubmit = useCallback(async (e: React.FormEvent) => {
    e.preventDefault()

    // 모든 필드 touched 처리
    const allTouched = Object.keys(values).reduce(
      (acc, key) => ({ ...acc, [key]: true }),
      {}
    )
    setTouched(allTouched)

    // 유효성 검사
    if (validate) {
      const validationErrors = validate(values)
      setErrors(validationErrors)

      if (Object.keys(validationErrors).length > 0) {
        return
      }
    }

    setIsSubmitting(true)
    try {
      await onSubmit(values)
    } finally {
      setIsSubmitting(false)
    }
  }, [values, validate, onSubmit])

  const reset = useCallback(() => {
    setValues(initialValues)
    setErrors({})
    setTouched({})
  }, [initialValues])

  return {
    values,
    errors,
    touched,
    isSubmitting,
    handleChange,
    handleBlur,
    handleSubmit,
    reset,
    setValues,
    setErrors,
  }
}

// 사용
function LoginForm() {
  const { values, errors, touched, isSubmitting, handleChange, handleBlur, handleSubmit } = useForm({
    initialValues: { email: '', password: '' },
    validate: (values) => {
      const errors: Partial<Record<string, string>> = {}
      if (!values.email) errors.email = 'Required'
      if (!values.password) errors.password = 'Required'
      return errors
    },
    onSubmit: async (values) => {
      await login(values)
    },
  })

  return (
    <form onSubmit={handleSubmit}>
      <input
        name="email"
        value={values.email}
        onChange={handleChange}
        onBlur={handleBlur}
      />
      {touched.email && errors.email && <span>{errors.email}</span>}

      <input
        name="password"
        type="password"
        value={values.password}
        onChange={handleChange}
        onBlur={handleBlur}
      />
      {touched.password && errors.password && <span>{errors.password}</span>}

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Loading...' : 'Login'}
      </button>
    </form>
  )
}
```

---

## 작성 원칙

### 1. 단일 책임

```tsx
// Bad: 너무 많은 일을 함
function useEverything() {
  const [user, setUser] = useState(null)
  const [posts, setPosts] = useState([])
  const [comments, setComments] = useState([])
  // ...
}

// Good: 하나의 역할
function useUser() { /* ... */ }
function usePosts() { /* ... */ }
function useComments() { /* ... */ }
```

### 2. use 접두사

```tsx
// Bad
function fetchData() { /* Hook 사용 */ }
function getData() { /* Hook 사용 */ }

// Good
function useFetchData() { /* Hook 사용 */ }
function useData() { /* Hook 사용 */ }
```

### 3. 불필요한 의존성 피하기

```tsx
// Bad: 불필요한 리렌더링
function useData(id) {
  const [data, setData] = useState(null)

  const options = { id }  // 매 렌더마다 새 객체

  useEffect(() => {
    fetch(options.id)
  }, [options])  // 매번 실행됨
}

// Good
function useData(id) {
  const [data, setData] = useState(null)

  useEffect(() => {
    fetch(id)
  }, [id])
}
```

### 4. 안정적인 반환값

```tsx
// Bad: 매번 새 객체
function useCounter() {
  const [count, setCount] = useState(0)

  return {
    count,
    increment: () => setCount(c => c + 1),  // 매번 새 함수
  }
}

// Good: useCallback으로 안정화
function useCounter() {
  const [count, setCount] = useState(0)

  const increment = useCallback(() => setCount(c => c + 1), [])

  return { count, increment }
}
```

---

## 요약

### 커스텀 Hook 패턴

| 패턴 | 용도 |
|------|------|
| 상태 관리 | useToggle, useArray, useMap |
| 데이터 페칭 | useFetch, useAsync, useInfiniteScroll |
| 브라우저 API | useLocalStorage, useMediaQuery, useOnlineStatus |
| 이벤트 | useEventListener, useKeyPress, useDebounce |
| 라이프사이클 | useMount, useUnmount, useUpdateEffect |
| 폼 | useForm, useInput |

### 작성 원칙

```
1. use 접두사 필수
2. 단일 책임
3. 안정적인 반환값 (useCallback, useMemo)
4. 불필요한 의존성 피하기
5. 타입 안전성 (TypeScript)
```

---

## 다음 단계

[08-performance.md](./08-performance.md)에서 React 성능 최적화를 알아봅니다.
