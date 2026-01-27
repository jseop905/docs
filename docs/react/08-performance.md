# React 성능 최적화

React 애플리케이션의 성능을 최적화하는 방법을 알아봅니다.

---

## 성능 문제 진단

### React DevTools Profiler

```
1. React DevTools 설치
2. Profiler 탭 열기
3. Record 버튼 클릭
4. 앱 조작
5. Stop 버튼 클릭
6. Flamegraph/Ranked 확인
```

### 확인할 지표

```
- 렌더링 횟수
- 렌더링 시간
- 불필요한 리렌더링
- 커밋 횟수
```

### 콘솔에서 리렌더링 확인

```tsx
// 개발 중 리렌더링 추적
function Component() {
  console.log('Component rendered')

  // 또는 useEffect로
  useEffect(() => {
    console.log('Component rendered')
  })

  return <div>...</div>
}
```

---

## 리렌더링 최적화

### 문제: 불필요한 리렌더링

```tsx
function Parent() {
  const [count, setCount] = useState(0)

  return (
    <div>
      <button onClick={() => setCount(c => c + 1)}>
        {count}
      </button>
      {/* count가 변해도 Child는 변할 필요 없음 */}
      <Child name="constant" />
    </div>
  )
}

function Child({ name }) {
  console.log('Child rendered')  // 매번 호출됨
  return <div>{name}</div>
}
```

### 해결 1: React.memo

```tsx
// props가 같으면 리렌더링 스킵
const Child = React.memo(function Child({ name }) {
  console.log('Child rendered')  // props 변경 시만 호출
  return <div>{name}</div>
})

// 커스텀 비교 함수
const Child = React.memo(
  function Child({ user }) {
    return <div>{user.name}</div>
  },
  (prevProps, nextProps) => {
    // true: 리렌더링 스킵
    // false: 리렌더링
    return prevProps.user.id === nextProps.user.id
  }
)
```

### 해결 2: 컴포넌트 분리

```tsx
// Before: 전체가 리렌더링
function App() {
  const [count, setCount] = useState(0)

  return (
    <div>
      <ExpensiveTree />  {/* count 변경 시 불필요하게 리렌더링 */}
      <button onClick={() => setCount(c => c + 1)}>{count}</button>
    </div>
  )
}

// After: 상태를 사용하는 부분만 분리
function Counter() {
  const [count, setCount] = useState(0)
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>
}

function App() {
  return (
    <div>
      <ExpensiveTree />  {/* 리렌더링 안 됨 */}
      <Counter />
    </div>
  )
}
```

### 해결 3: children으로 전달

```tsx
// Before
function ScrollContainer() {
  const [scrollY, setScrollY] = useState(0)

  return (
    <div onScroll={e => setScrollY(e.target.scrollTop)}>
      <ExpensiveTree />  {/* 스크롤마다 리렌더링 */}
    </div>
  )
}

// After: children은 부모에서 생성되므로 리렌더링 안 됨
function ScrollContainer({ children }) {
  const [scrollY, setScrollY] = useState(0)

  return (
    <div onScroll={e => setScrollY(e.target.scrollTop)}>
      {children}  {/* 리렌더링 안 됨 */}
    </div>
  )
}

function App() {
  return (
    <ScrollContainer>
      <ExpensiveTree />
    </ScrollContainer>
  )
}
```

---

## 메모이제이션

### useMemo: 값 캐싱

```tsx
function FilteredList({ items, filter }) {
  // Bad: 매 렌더마다 필터링
  const filtered = items.filter(item => item.includes(filter))

  // Good: filter나 items가 변경될 때만 필터링
  const filtered = useMemo(
    () => items.filter(item => item.includes(filter)),
    [items, filter]
  )

  return <List items={filtered} />
}
```

### useMemo: 참조 동등성 유지

```tsx
function Parent() {
  const [count, setCount] = useState(0)

  // Bad: 매 렌더마다 새 객체
  const style = { color: 'blue' }

  // Good: 캐시된 객체
  const style = useMemo(() => ({ color: 'blue' }), [])

  return <Child style={style} />
}

const Child = React.memo(function Child({ style }) {
  return <div style={style}>Child</div>
})
```

### useCallback: 함수 캐싱

```tsx
function Parent() {
  const [count, setCount] = useState(0)

  // Bad: 매 렌더마다 새 함수
  const handleClick = () => console.log('clicked')

  // Good: 캐시된 함수
  const handleClick = useCallback(() => {
    console.log('clicked')
  }, [])

  return <Child onClick={handleClick} />
}

const Child = React.memo(function Child({ onClick }) {
  return <button onClick={onClick}>Click</button>
})
```

### 언제 useMemo/useCallback을 사용할까?

```tsx
// 1. 비싼 계산
const sorted = useMemo(() => {
  return [...items].sort((a, b) => a.value - b.value)
}, [items])

// 2. memo된 자식에 전달
const Child = React.memo(ChildComponent)
const handleClick = useCallback(() => {}, [])
return <Child onClick={handleClick} />

// 3. 다른 Hook의 의존성
const data = useMemo(() => ({ id, name }), [id, name])
useEffect(() => {
  process(data)
}, [data])

// 불필요한 경우
// - 단순한 계산
// - memo 안 된 컴포넌트에 전달
// - 최상위 렌더링 (최적화 대상 자체가 없음)
```

### 과도한 메모이제이션 피하기

```tsx
// Bad: 모든 것을 메모이제이션
function Component({ items }) {
  const count = useMemo(() => items.length, [items])  // 불필요
  const doubled = useMemo(() => count * 2, [count])   // 불필요
  const text = useMemo(() => `Count: ${doubled}`, [doubled])  // 불필요

  return <div>{text}</div>
}

// Good: 필요한 것만
function Component({ items }) {
  const count = items.length
  const doubled = count * 2
  const text = `Count: ${doubled}`

  return <div>{text}</div>
}
```

---

## 상태 최적화

### 상태 분할

```tsx
// Bad: 하나의 큰 상태
function Form() {
  const [state, setState] = useState({
    name: '',
    email: '',
    address: '',
    phone: '',
    // ... 많은 필드
  })

  // 하나만 변경해도 전체 리렌더링
  const handleNameChange = (e) => {
    setState(s => ({ ...s, name: e.target.value }))
  }
}

// Good: 분리된 상태 또는 useReducer
function Form() {
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  // 또는 useReducer 사용

  // 해당 필드만 리렌더링에 영향
}
```

### 상태 끌어내리기

```tsx
// Bad: 상위에서 관리
function App() {
  const [inputValue, setInputValue] = useState('')

  return (
    <div>
      <Header />  {/* inputValue와 무관한데 리렌더링 */}
      <SearchInput value={inputValue} onChange={setInputValue} />
      <Footer />  {/* inputValue와 무관한데 리렌더링 */}
    </div>
  )
}

// Good: 상태를 사용하는 곳에서 관리
function App() {
  return (
    <div>
      <Header />
      <SearchInput />  {/* 내부에서 상태 관리 */}
      <Footer />
    </div>
  )
}

function SearchInput() {
  const [inputValue, setInputValue] = useState('')
  return <input value={inputValue} onChange={e => setInputValue(e.target.value)} />
}
```

### Context 최적화

```tsx
// Bad: 모든 값을 하나의 Context에
const AppContext = createContext({
  user: null,
  theme: 'light',
  locale: 'en',
  // ... 많은 값
})

// user만 변경되어도 theme, locale 사용하는 컴포넌트도 리렌더링

// Good: Context 분리
const UserContext = createContext(null)
const ThemeContext = createContext('light')
const LocaleContext = createContext('en')

// 각 Context 변경 시 해당 Consumer만 리렌더링
```

```tsx
// Good: 값과 업데이터 분리
const StateContext = createContext(null)
const DispatchContext = createContext(null)

function Provider({ children }) {
  const [state, dispatch] = useReducer(reducer, initialState)

  return (
    <StateContext.Provider value={state}>
      <DispatchContext.Provider value={dispatch}>
        {children}
      </DispatchContext.Provider>
    </StateContext.Provider>
  )
}

// dispatch만 필요한 컴포넌트는 state 변경에 리렌더링 안 됨
function ActionButton() {
  const dispatch = useContext(DispatchContext)
  return <button onClick={() => dispatch({ type: 'ACTION' })}>Act</button>
}
```

---

## 리스트 최적화

### 가상화 (Virtualization)

```tsx
// react-window 사용
import { FixedSizeList } from 'react-window'

function VirtualList({ items }) {
  return (
    <FixedSizeList
      height={400}
      width={300}
      itemCount={items.length}
      itemSize={50}
    >
      {({ index, style }) => (
        <div style={style}>
          {items[index].name}
        </div>
      )}
    </FixedSizeList>
  )
}

// 10,000개 항목도 화면에 보이는 것만 렌더링
```

### 올바른 key 사용

```tsx
// Bad: index를 key로
{items.map((item, index) => (
  <Item key={index} data={item} />
))}

// Good: 고유 ID를 key로
{items.map(item => (
  <Item key={item.id} data={item} />
))}
```

### 리스트 아이템 메모이제이션

```tsx
const ListItem = React.memo(function ListItem({ item, onSelect }) {
  return (
    <div onClick={() => onSelect(item.id)}>
      {item.name}
    </div>
  )
})

function List({ items }) {
  const handleSelect = useCallback((id) => {
    // handle selection
  }, [])

  return (
    <div>
      {items.map(item => (
        <ListItem key={item.id} item={item} onSelect={handleSelect} />
      ))}
    </div>
  )
}
```

---

## 번들 최적화

### 코드 스플리팅

```tsx
import { lazy, Suspense } from 'react'

// 동적 import
const HeavyComponent = lazy(() => import('./HeavyComponent'))

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <HeavyComponent />
    </Suspense>
  )
}
```

### 라우트 기반 스플리팅

```tsx
import { lazy, Suspense } from 'react'
import { Routes, Route } from 'react-router-dom'

const Home = lazy(() => import('./pages/Home'))
const About = lazy(() => import('./pages/About'))
const Dashboard = lazy(() => import('./pages/Dashboard'))

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/about" element={<About />} />
        <Route path="/dashboard" element={<Dashboard />} />
      </Routes>
    </Suspense>
  )
}
```

### 프리로딩

```tsx
const HeavyComponent = lazy(() => import('./HeavyComponent'))

// 마우스 오버 시 프리로드
function NavLink() {
  const preload = () => {
    import('./HeavyComponent')
  }

  return (
    <Link to="/heavy" onMouseEnter={preload}>
      Heavy Page
    </Link>
  )
}
```

---

## 이미지 최적화

### 지연 로딩

```tsx
// loading="lazy" 속성
function ImageGallery({ images }) {
  return (
    <div>
      {images.map(image => (
        <img
          key={image.id}
          src={image.src}
          alt={image.alt}
          loading="lazy"
        />
      ))}
    </div>
  )
}
```

### Intersection Observer

```tsx
function LazyImage({ src, alt }) {
  const [isVisible, setIsVisible] = useState(false)
  const ref = useRef(null)

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsVisible(true)
          observer.disconnect()
        }
      },
      { threshold: 0.1 }
    )

    if (ref.current) {
      observer.observe(ref.current)
    }

    return () => observer.disconnect()
  }, [])

  return (
    <div ref={ref}>
      {isVisible ? (
        <img src={src} alt={alt} />
      ) : (
        <div className="placeholder" />
      )}
    </div>
  )
}
```

---

## 애니메이션 최적화

### CSS Transform 사용

```tsx
// Bad: layout 속성 애니메이션
const style = {
  transition: 'left 0.3s, top 0.3s',  // 리플로우 발생
  left: isOpen ? 0 : -200,
  top: isOpen ? 0 : -200,
}

// Good: transform 애니메이션
const style = {
  transition: 'transform 0.3s',
  transform: isOpen ? 'translate(0, 0)' : 'translate(-200px, -200px)',
}
```

### will-change 힌트

```tsx
// 애니메이션 전에 브라우저에 힌트
const style = {
  willChange: 'transform',  // GPU 레이어 생성
  transform: `translateX(${position}px)`,
}
```

### requestAnimationFrame

```tsx
function useAnimationFrame(callback) {
  const requestRef = useRef()

  useEffect(() => {
    const animate = (time) => {
      callback(time)
      requestRef.current = requestAnimationFrame(animate)
    }

    requestRef.current = requestAnimationFrame(animate)
    return () => cancelAnimationFrame(requestRef.current)
  }, [callback])
}
```

---

## 동시성 활용

### useTransition

```tsx
function SearchResults() {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState([])
  const [isPending, startTransition] = useTransition()

  const handleChange = (e) => {
    const value = e.target.value
    setQuery(value)  // 긴급: 즉시 반영

    startTransition(() => {
      setResults(search(value))  // 전환: 지연 가능
    })
  }

  return (
    <div>
      <input value={query} onChange={handleChange} />
      {isPending && <Spinner />}
      <ResultList results={results} />
    </div>
  )
}
```

### useDeferredValue

```tsx
function FilteredList({ items, filter }) {
  const deferredFilter = useDeferredValue(filter)
  const isStale = filter !== deferredFilter

  const filteredItems = useMemo(
    () => items.filter(item => item.includes(deferredFilter)),
    [items, deferredFilter]
  )

  return (
    <ul style={{ opacity: isStale ? 0.6 : 1 }}>
      {filteredItems.map(item => <li key={item}>{item}</li>)}
    </ul>
  )
}
```

---

## 성능 체크리스트

### 리렌더링

```
□ React.memo로 불필요한 리렌더링 방지
□ 상태를 사용하는 곳 가까이에 배치
□ Context를 적절히 분리
□ children 패턴으로 리렌더링 범위 줄이기
```

### 메모이제이션

```
□ 비싼 계산에 useMemo 사용
□ memo된 컴포넌트에 전달하는 함수에 useCallback
□ 과도한 메모이제이션 피하기
```

### 리스트

```
□ 고유한 key 사용
□ 긴 리스트는 가상화 (react-window)
□ 리스트 아이템 메모이제이션
```

### 번들

```
□ 코드 스플리팅 (lazy, Suspense)
□ 라우트 기반 스플리팅
□ 트리 쉐이킹 확인
```

### 측정

```
□ React DevTools Profiler 사용
□ Lighthouse 성능 점수 확인
□ Web Vitals 모니터링
```

---

## 요약

### 핵심 원칙

```
1. 측정 먼저: 추측하지 말고 Profiler로 확인
2. 필요한 곳만: 과도한 최적화는 복잡성만 증가
3. 리렌더링 범위: 상태를 사용하는 곳 가까이에
4. 메모이제이션: memo + useCallback 조합
5. 무거운 작업: useMemo, 가상화, 코드 스플리팅
```

### 최적화 순서

```
1. 불필요한 리렌더링 제거
2. 상태 구조 개선
3. 메모이제이션 적용
4. 리스트 가상화
5. 코드 스플리팅
```

---

## 다음 단계

[09-common-patterns.md](./09-common-patterns.md)에서 실전에서 자주 사용하는 React 패턴을 알아봅니다.
