# 내장 Hooks 완벽 가이드

React의 모든 내장 Hooks를 상세히 알아봅니다.

---

## 상태 관리 Hooks

### useState

```tsx
const [state, setState] = useState(initialState)
```

#### 기본 사용

```tsx
function Counter() {
  const [count, setCount] = useState(0)

  return (
    <button onClick={() => setCount(count + 1)}>
      {count}
    </button>
  )
}
```

#### 함수형 업데이트

```tsx
// 이전 상태 기반 업데이트
setCount(prev => prev + 1)

// 여러 번 호출해도 누적됨
function handleClick() {
  setCount(c => c + 1)  // 0 → 1
  setCount(c => c + 1)  // 1 → 2
  setCount(c => c + 1)  // 2 → 3
}

// 일반 업데이트는 마지막만 적용
function handleClick() {
  setCount(count + 1)  // 0 → 1
  setCount(count + 1)  // 0 → 1 (같은 count 참조)
  setCount(count + 1)  // 0 → 1
}
```

#### 지연 초기화

```tsx
// Bad: 매 렌더마다 computeExpensiveValue 실행
const [state, setState] = useState(computeExpensiveValue())

// Good: 초기 렌더에만 실행
const [state, setState] = useState(() => computeExpensiveValue())
```

#### 객체/배열 상태

```tsx
const [user, setUser] = useState({ name: '', age: 0 })

// Bad: 직접 수정
user.name = 'John'  // 리렌더링 안 됨

// Good: 새 객체 생성
setUser({ ...user, name: 'John' })
setUser(prev => ({ ...prev, name: 'John' }))

// 배열
const [items, setItems] = useState([])

// 추가
setItems([...items, newItem])
setItems(prev => [...prev, newItem])

// 제거
setItems(items.filter(item => item.id !== id))

// 수정
setItems(items.map(item =>
  item.id === id ? { ...item, done: true } : item
))
```

---

### useReducer

```tsx
const [state, dispatch] = useReducer(reducer, initialArg, init?)
```

#### 기본 사용

```tsx
type State = { count: number }
type Action =
  | { type: 'increment' }
  | { type: 'decrement' }
  | { type: 'reset'; payload: number }

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'increment':
      return { count: state.count + 1 }
    case 'decrement':
      return { count: state.count - 1 }
    case 'reset':
      return { count: action.payload }
    default:
      throw new Error('Unknown action')
  }
}

function Counter() {
  const [state, dispatch] = useReducer(reducer, { count: 0 })

  return (
    <>
      Count: {state.count}
      <button onClick={() => dispatch({ type: 'increment' })}>+</button>
      <button onClick={() => dispatch({ type: 'decrement' })}>-</button>
      <button onClick={() => dispatch({ type: 'reset', payload: 0 })}>Reset</button>
    </>
  )
}
```

#### 지연 초기화

```tsx
function init(initialCount: number): State {
  return { count: initialCount }
}

function Counter({ initialCount }: { initialCount: number }) {
  const [state, dispatch] = useReducer(reducer, initialCount, init)
  // ...
}
```

#### useState vs useReducer

```tsx
// useState: 단순한 상태
const [count, setCount] = useState(0)

// useReducer: 복잡한 상태 로직
// - 여러 값이 연관됨
// - 다음 상태가 이전 상태에 의존
// - 액션 기반 업데이트
const [state, dispatch] = useReducer(reducer, initialState)
```

---

## 부수 효과 Hooks

### useEffect

```tsx
useEffect(setup, dependencies?)
```

#### 기본 사용

```tsx
function ChatRoom({ roomId }) {
  useEffect(() => {
    // Setup: 컴포넌트가 DOM에 추가된 후 실행
    const connection = createConnection(roomId)
    connection.connect()

    // Cleanup: 컴포넌트 제거 전 또는 다음 effect 전 실행
    return () => {
      connection.disconnect()
    }
  }, [roomId])  // roomId가 변경될 때마다 재실행
}
```

#### 의존성 배열

```tsx
// 매 렌더 후 실행
useEffect(() => {
  console.log('Every render')
})

// 마운트 시 한 번만
useEffect(() => {
  console.log('Mount only')
}, [])

// 특정 값 변경 시
useEffect(() => {
  console.log('When count changes')
}, [count])
```

#### 실행 타이밍

```
렌더링 → DOM 업데이트 → 화면 페인트 → useEffect 실행
```

```tsx
function Component() {
  const [count, setCount] = useState(0)

  useEffect(() => {
    // 페인트 후 비동기 실행
    // DOM 측정, 데이터 페칭 등
    document.title = `Count: ${count}`
  }, [count])

  return <div>{count}</div>
}
```

#### 일반적인 패턴

```tsx
// 데이터 페칭
useEffect(() => {
  let ignore = false

  async function fetchData() {
    const result = await fetch(`/api/user/${userId}`)
    if (!ignore) {
      setUser(await result.json())
    }
  }

  fetchData()
  return () => { ignore = true }  // 경쟁 조건 방지
}, [userId])

// 이벤트 리스너
useEffect(() => {
  function handleResize() {
    setSize({ width: window.innerWidth, height: window.innerHeight })
  }

  window.addEventListener('resize', handleResize)
  return () => window.removeEventListener('resize', handleResize)
}, [])

// 구독
useEffect(() => {
  const unsubscribe = store.subscribe(() => {
    setSnapshot(store.getState())
  })
  return unsubscribe
}, [store])
```

---

### useLayoutEffect

```tsx
useLayoutEffect(setup, dependencies?)
```

#### useEffect와 차이

```
useLayoutEffect: 렌더링 → DOM 업데이트 → useLayoutEffect → 화면 페인트
useEffect:       렌더링 → DOM 업데이트 → 화면 페인트 → useEffect
```

#### 사용 시점

```tsx
// DOM 측정이 필요할 때
function Tooltip({ children, targetRect }) {
  const ref = useRef(null)
  const [position, setPosition] = useState({ top: 0, left: 0 })

  useLayoutEffect(() => {
    // DOM 측정 후 위치 계산 (페인트 전에 완료)
    const { height } = ref.current.getBoundingClientRect()
    setPosition({
      top: targetRect.top - height,
      left: targetRect.left,
    })
  }, [targetRect])

  return (
    <div ref={ref} style={{ position: 'absolute', ...position }}>
      {children}
    </div>
  )
}
```

```tsx
// 스크롤 위치 복원
useLayoutEffect(() => {
  // 페인트 전에 스크롤 위치 설정
  window.scrollTo(0, savedScrollPosition)
}, [])
```

#### 주의사항

```tsx
// useLayoutEffect는 동기적으로 실행됨
// 너무 무거운 작업은 피하기
useLayoutEffect(() => {
  // Bad: 무거운 계산
  for (let i = 0; i < 1000000; i++) { /* ... */ }

  // Good: 간단한 DOM 측정/조작만
  const rect = element.getBoundingClientRect()
}, [])
```

---

### useInsertionEffect

CSS-in-JS 라이브러리용. 일반적으로 직접 사용하지 않음.

```tsx
// DOM 변경 전에 실행 (스타일 주입용)
useInsertionEffect(() => {
  const style = document.createElement('style')
  style.textContent = css
  document.head.appendChild(style)
  return () => style.remove()
}, [css])
```

---

## 참조 Hooks

### useRef

```tsx
const ref = useRef(initialValue)
```

#### DOM 참조

```tsx
function TextInput() {
  const inputRef = useRef<HTMLInputElement>(null)

  const handleClick = () => {
    inputRef.current?.focus()
  }

  return (
    <>
      <input ref={inputRef} />
      <button onClick={handleClick}>Focus</button>
    </>
  )
}
```

#### 값 저장 (리렌더링 없이)

```tsx
function Timer() {
  const [count, setCount] = useState(0)
  const intervalRef = useRef<number | null>(null)

  const start = () => {
    if (intervalRef.current !== null) return

    intervalRef.current = setInterval(() => {
      setCount(c => c + 1)
    }, 1000)
  }

  const stop = () => {
    if (intervalRef.current === null) return

    clearInterval(intervalRef.current)
    intervalRef.current = null
  }

  useEffect(() => {
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current)
    }
  }, [])

  return (
    <>
      <div>{count}</div>
      <button onClick={start}>Start</button>
      <button onClick={stop}>Stop</button>
    </>
  )
}
```

#### 이전 값 저장

```tsx
function usePrevious<T>(value: T): T | undefined {
  const ref = useRef<T | undefined>(undefined)

  useEffect(() => {
    ref.current = value
  }, [value])

  return ref.current
}

// 사용
function Component({ count }) {
  const prevCount = usePrevious(count)

  return (
    <div>
      현재: {count}, 이전: {prevCount}
    </div>
  )
}
```

---

### useImperativeHandle

```tsx
useImperativeHandle(ref, createHandle, dependencies?)
```

부모에게 노출할 메서드를 커스터마이징합니다.

```tsx
interface InputHandle {
  focus: () => void
  scrollIntoView: () => void
}

const FancyInput = forwardRef<InputHandle, Props>((props, ref) => {
  const inputRef = useRef<HTMLInputElement>(null)

  useImperativeHandle(ref, () => ({
    focus() {
      inputRef.current?.focus()
    },
    scrollIntoView() {
      inputRef.current?.scrollIntoView()
    },
  }), [])

  return <input ref={inputRef} {...props} />
})

// 부모에서 사용
function Parent() {
  const inputRef = useRef<InputHandle>(null)

  return (
    <>
      <FancyInput ref={inputRef} />
      <button onClick={() => inputRef.current?.focus()}>
        Focus
      </button>
    </>
  )
}
```

---

## 성능 최적화 Hooks

### useMemo

```tsx
const memoizedValue = useMemo(() => computeExpensiveValue(a, b), [a, b])
```

#### 기본 사용

```tsx
function TodoList({ todos, filter }) {
  // filter가 변경될 때만 재계산
  const filteredTodos = useMemo(() => {
    return todos.filter(todo => {
      if (filter === 'active') return !todo.completed
      if (filter === 'completed') return todo.completed
      return true
    })
  }, [todos, filter])

  return (
    <ul>
      {filteredTodos.map(todo => (
        <li key={todo.id}>{todo.text}</li>
      ))}
    </ul>
  )
}
```

#### 참조 동등성 유지

```tsx
function Parent() {
  const [count, setCount] = useState(0)

  // 매 렌더마다 새 객체 생성 → Child 리렌더링
  const config = { theme: 'dark' }

  // useMemo로 참조 유지 → Child 리렌더링 방지
  const config = useMemo(() => ({ theme: 'dark' }), [])

  return <Child config={config} />
}
```

---

### useCallback

```tsx
const memoizedCallback = useCallback(fn, dependencies)
```

#### 기본 사용

```tsx
function Parent() {
  const [count, setCount] = useState(0)

  // 매 렌더마다 새 함수 → Child 리렌더링
  const handleClick = () => console.log(count)

  // useCallback으로 함수 유지
  const handleClick = useCallback(() => {
    console.log(count)
  }, [count])

  return <Child onClick={handleClick} />
}
```

#### useMemo와의 관계

```tsx
// useCallback(fn, deps)는 useMemo(() => fn, deps)와 동일
const memoizedFn = useCallback((a, b) => a + b, [])
const memoizedFn = useMemo(() => (a, b) => a + b, [])
```

---

### memo

Hook은 아니지만 함께 사용됩니다.

```tsx
const MemoizedComponent = memo(Component)
const MemoizedComponent = memo(Component, arePropsEqual)
```

```tsx
const ExpensiveList = memo(function ExpensiveList({ items, onSelect }) {
  return (
    <ul>
      {items.map(item => (
        <li key={item.id} onClick={() => onSelect(item)}>
          {item.name}
        </li>
      ))}
    </ul>
  )
})

// 커스텀 비교 함수
const MemoizedItem = memo(
  function Item({ item, isSelected }) {
    return <div className={isSelected ? 'selected' : ''}>{item.name}</div>
  },
  (prevProps, nextProps) => {
    return (
      prevProps.item.id === nextProps.item.id &&
      prevProps.isSelected === nextProps.isSelected
    )
  }
)
```

---

## Context Hooks

### useContext

```tsx
const value = useContext(SomeContext)
```

#### 기본 사용

```tsx
// Context 생성
const ThemeContext = createContext<'light' | 'dark'>('light')

// Provider
function App() {
  const [theme, setTheme] = useState<'light' | 'dark'>('light')

  return (
    <ThemeContext.Provider value={theme}>
      <Page />
      <button onClick={() => setTheme(t => t === 'light' ? 'dark' : 'light')}>
        Toggle
      </button>
    </ThemeContext.Provider>
  )
}

// Consumer
function ThemedButton() {
  const theme = useContext(ThemeContext)

  return (
    <button className={theme}>
      I'm {theme}!
    </button>
  )
}
```

#### 여러 Context 조합

```tsx
const ThemeContext = createContext('light')
const UserContext = createContext<User | null>(null)

function App() {
  return (
    <ThemeContext.Provider value="dark">
      <UserContext.Provider value={user}>
        <Page />
      </UserContext.Provider>
    </ThemeContext.Provider>
  )
}

function Component() {
  const theme = useContext(ThemeContext)
  const user = useContext(UserContext)
  // ...
}
```

---

## 동시성 Hooks

### useTransition

```tsx
const [isPending, startTransition] = useTransition()
```

#### 기본 사용

```tsx
function TabContainer() {
  const [tab, setTab] = useState('home')
  const [isPending, startTransition] = useTransition()

  function selectTab(nextTab) {
    startTransition(() => {
      setTab(nextTab)
    })
  }

  return (
    <>
      <TabButton isActive={tab === 'home'} onClick={() => selectTab('home')}>
        Home
      </TabButton>
      <TabButton isActive={tab === 'posts'} onClick={() => selectTab('posts')}>
        Posts
      </TabButton>

      {isPending && <Spinner />}

      <TabPanel tab={tab} />
    </>
  )
}
```

---

### useDeferredValue

```tsx
const deferredValue = useDeferredValue(value)
```

#### 기본 사용

```tsx
function SearchResults({ query }) {
  const deferredQuery = useDeferredValue(query)
  const isStale = query !== deferredQuery

  const results = useMemo(
    () => searchItems(deferredQuery),
    [deferredQuery]
  )

  return (
    <ul style={{ opacity: isStale ? 0.5 : 1 }}>
      {results.map(item => <li key={item.id}>{item.name}</li>)}
    </ul>
  )
}
```

---

## 기타 Hooks

### useId

```tsx
const id = useId()
```

고유 ID 생성 (SSR에서도 안정적).

```tsx
function PasswordField() {
  const id = useId()

  return (
    <>
      <label htmlFor={id}>Password:</label>
      <input id={id} type="password" />
    </>
  )
}

// 여러 요소에 사용
function FormField() {
  const id = useId()

  return (
    <>
      <label htmlFor={`${id}-firstName`}>First Name</label>
      <input id={`${id}-firstName`} />

      <label htmlFor={`${id}-lastName`}>Last Name</label>
      <input id={`${id}-lastName`} />
    </>
  )
}
```

---

### useSyncExternalStore

```tsx
const snapshot = useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot?)
```

외부 저장소와 동기화합니다.

```tsx
// 브라우저 API 구독
function useOnlineStatus() {
  return useSyncExternalStore(
    // subscribe
    (callback) => {
      window.addEventListener('online', callback)
      window.addEventListener('offline', callback)
      return () => {
        window.removeEventListener('online', callback)
        window.removeEventListener('offline', callback)
      }
    },
    // getSnapshot
    () => navigator.onLine,
    // getServerSnapshot (SSR)
    () => true
  )
}

// 외부 상태 관리 라이브러리
function useTodosFromStore() {
  return useSyncExternalStore(
    store.subscribe,
    store.getSnapshot
  )
}
```

---

### useDebugValue

```tsx
useDebugValue(value, format?)
```

React DevTools에서 커스텀 Hook의 정보를 표시합니다.

```tsx
function useOnlineStatus() {
  const isOnline = useSyncExternalStore(...)

  // DevTools에서 "OnlineStatus: Online" 또는 "OnlineStatus: Offline" 표시
  useDebugValue(isOnline ? 'Online' : 'Offline')

  return isOnline
}

// 지연 포매팅 (비용이 큰 경우)
useDebugValue(date, date => date.toDateString())
```

---

## React 19 새 Hooks

### use

Promise나 Context를 읽습니다.

```tsx
// Promise 읽기 (Suspense와 함께)
function Comments({ commentsPromise }) {
  const comments = use(commentsPromise)
  return comments.map(c => <Comment key={c.id} data={c} />)
}

// Context 읽기 (조건부 가능)
function HorizontalRule({ show }) {
  if (show) {
    const theme = use(ThemeContext)
    return <hr className={theme} />
  }
  return null
}
```

### useFormStatus

폼 제출 상태를 읽습니다.

```tsx
function SubmitButton() {
  const { pending } = useFormStatus()
  return (
    <button disabled={pending}>
      {pending ? 'Submitting...' : 'Submit'}
    </button>
  )
}
```

### useFormState

폼 액션의 결과 상태를 관리합니다.

```tsx
async function createUser(prevState, formData) {
  const name = formData.get('name')
  // 서버에서 처리...
  return { message: `Created ${name}` }
}

function Form() {
  const [state, formAction] = useFormState(createUser, null)

  return (
    <form action={formAction}>
      <input name="name" />
      <button>Create</button>
      {state?.message && <p>{state.message}</p>}
    </form>
  )
}
```

### useOptimistic

낙관적 업데이트를 관리합니다.

```tsx
function Thread({ messages, sendMessage }) {
  const [optimisticMessages, addOptimisticMessage] = useOptimistic(
    messages,
    (state, newMessage) => [...state, { ...newMessage, sending: true }]
  )

  async function handleSend(formData) {
    const message = { text: formData.get('message'), id: Date.now() }
    addOptimisticMessage(message)
    await sendMessage(message)
  }

  return (
    <>
      {optimisticMessages.map(m => (
        <Message key={m.id} data={m} isPending={m.sending} />
      ))}
      <form action={handleSend}>
        <input name="message" />
        <button>Send</button>
      </form>
    </>
  )
}
```

---

## 요약

### 상태

```tsx
useState      // 단순 상태
useReducer    // 복잡한 상태 로직
```

### 부수 효과

```tsx
useEffect           // 페인트 후 비동기
useLayoutEffect     // 페인트 전 동기
useInsertionEffect  // DOM 변경 전 (CSS-in-JS용)
```

### 참조

```tsx
useRef              // DOM 참조, 값 저장
useImperativeHandle // ref 커스터마이징
```

### 성능

```tsx
useMemo      // 값 메모이제이션
useCallback  // 함수 메모이제이션
memo         // 컴포넌트 메모이제이션
```

### 동시성

```tsx
useTransition    // 상태 업데이트 지연
useDeferredValue // 값 지연
```

---

## 다음 단계

[07-custom-hooks.md](./07-custom-hooks.md)에서 커스텀 Hooks 작성법을 알아봅니다.
