# 배치 업데이트와 동시성 (Batch Update & Concurrency)

React의 배치 업데이트 메커니즘과 React 18의 동시성 기능을 이해합니다.

---

## 배치 업데이트란?

### 기본 개념

```tsx
function handleClick() {
  setCount(1)     // 리렌더링 예약
  setFlag(true)   // 리렌더링 예약
  setName('new')  // 리렌더링 예약
  // → 3번이 아닌 1번만 리렌더링
}
```

여러 상태 업데이트를 **하나의 리렌더링으로 묶는** 최적화입니다.

### 왜 필요한가?

```tsx
// 배칭 없이 각각 리렌더링된다면:
setLoading(true)   // 렌더 1: loading=true, data=null
setData(newData)   // 렌더 2: loading=true, data=newData
setLoading(false)  // 렌더 3: loading=false, data=newData

// UI가 일시적으로 불일치 상태를 보여줌
// + 불필요한 렌더링 2회 추가
```

```tsx
// 배칭으로 한 번에:
setLoading(true)
setData(newData)
setLoading(false)
// → 렌더 1회: loading=false, data=newData
// 일관된 UI, 성능 최적화
```

---

## React 17 vs 18 배칭

### React 17: 이벤트 핸들러에서만 배칭

```tsx
// React 17
function App() {
  const [count, setCount] = useState(0)
  const [flag, setFlag] = useState(false)

  // 이벤트 핸들러: 배칭 O
  const handleClick = () => {
    setCount(c => c + 1)
    setFlag(f => !f)
    // → 1번 리렌더링
  }

  // setTimeout: 배칭 X
  const handleAsync = () => {
    setTimeout(() => {
      setCount(c => c + 1)  // 리렌더링 1
      setFlag(f => !f)      // 리렌더링 2
    }, 0)
  }

  // Promise: 배칭 X
  const handleFetch = async () => {
    await fetch('/api')
    setCount(c => c + 1)  // 리렌더링 1
    setFlag(f => !f)      // 리렌더링 2
  }
}
```

### React 18: 자동 배칭 (Automatic Batching)

```tsx
// React 18
function App() {
  const [count, setCount] = useState(0)
  const [flag, setFlag] = useState(false)

  // 이벤트 핸들러: 배칭 O
  const handleClick = () => {
    setCount(c => c + 1)
    setFlag(f => !f)
    // → 1번 리렌더링
  }

  // setTimeout: 배칭 O ✨
  const handleAsync = () => {
    setTimeout(() => {
      setCount(c => c + 1)
      setFlag(f => !f)
      // → 1번 리렌더링
    }, 0)
  }

  // Promise: 배칭 O ✨
  const handleFetch = async () => {
    await fetch('/api')
    setCount(c => c + 1)
    setFlag(f => !f)
    // → 1번 리렌더링
  }

  // 어디서든 배칭됨
  const handleNative = () => {
    element.addEventListener('click', () => {
      setCount(c => c + 1)
      setFlag(f => !f)
      // → 1번 리렌더링
    })
  }
}
```

---

## 배칭 제어하기

### flushSync로 즉시 반영

```tsx
import { flushSync } from 'react-dom'

function handleClick() {
  flushSync(() => {
    setCount(c => c + 1)
  })
  // 여기서 DOM이 이미 업데이트됨
  console.log(document.getElementById('count').textContent)  // 새 값

  flushSync(() => {
    setFlag(f => !f)
  })
  // 다시 DOM 업데이트됨
}
```

### 언제 flushSync가 필요한가?

```tsx
// 1. DOM 측정이 필요한 경우
function handleAdd() {
  flushSync(() => {
    setItems(prev => [...prev, newItem])
  })
  // DOM이 업데이트된 후 스크롤
  listRef.current.scrollTop = listRef.current.scrollHeight
}

// 2. 서드파티 라이브러리와 동기화
function handleUpdate() {
  flushSync(() => {
    setState(newValue)
  })
  // DOM 업데이트 후 외부 라이브러리 호출
  externalLibrary.refresh()
}
```

### 주의: flushSync 남용 금지

```tsx
// Bad: 불필요한 flushSync
function handleClick() {
  flushSync(() => setA(1))
  flushSync(() => setB(2))
  flushSync(() => setC(3))
  // 3번 리렌더링 (배칭 이점 없음)
}

// Good: 필요한 경우만
function handleClick() {
  setA(1)
  setB(2)
  setC(3)
  // 1번 리렌더링
}
```

---

## 동시성 (Concurrency)

### 동시성이란?

```
기존 (동기적):
[====== 긴 렌더링 ======]
         입력 무시됨

동시성 (비동기적):
[렌더1][입력][렌더2][렌더3]
         ↑
    즉시 응답
```

React 18에서 렌더링 작업을 **중단하고 재개**할 수 있습니다.

### 긴급 vs 전환 업데이트

```tsx
// 긴급 업데이트: 즉시 반영 필요
// - 타이핑
// - 클릭
// - 드래그

// 전환 업데이트: 지연 가능
// - 검색 결과
// - 필터링된 목록
// - 탭 전환
```

---

## useTransition

### 기본 사용법

```tsx
import { useState, useTransition } from 'react'

function SearchPage() {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState([])
  const [isPending, startTransition] = useTransition()

  const handleChange = (e) => {
    // 긴급: 입력 즉시 반영
    setQuery(e.target.value)

    // 전환: 결과 업데이트는 지연 가능
    startTransition(() => {
      setResults(searchItems(e.target.value))
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

### 동작 원리

```
입력 발생
    ↓
setQuery: 긴급 (즉시 처리)
    ↓
입력창 업데이트됨
    ↓
startTransition 내부: 낮은 우선순위
    ↓
백그라운드에서 results 계산
    ↓
(도중에 새 입력 발생하면 현재 작업 중단)
    ↓
완료되면 결과 표시
```

### 실전 예시: 탭 전환

```tsx
function TabContainer() {
  const [tab, setTab] = useState('home')
  const [isPending, startTransition] = useTransition()

  const selectTab = (nextTab) => {
    startTransition(() => {
      setTab(nextTab)
    })
  }

  return (
    <div>
      <TabButton
        isActive={tab === 'home'}
        onClick={() => selectTab('home')}
      >
        Home
      </TabButton>
      <TabButton
        isActive={tab === 'posts'}
        onClick={() => selectTab('posts')}
      >
        Posts (slow)
      </TabButton>

      {isPending && <Spinner />}

      {tab === 'home' && <HomeTab />}
      {tab === 'posts' && <PostsTab />}  {/* 무거운 컴포넌트 */}
    </div>
  )
}
```

---

## useDeferredValue

### 기본 사용법

```tsx
import { useState, useDeferredValue } from 'react'

function SearchResults({ query }) {
  // query가 바뀌어도 deferredQuery는 천천히 따라감
  const deferredQuery = useDeferredValue(query)

  // deferredQuery로 무거운 계산
  const results = useMemo(
    () => searchItems(deferredQuery),
    [deferredQuery]
  )

  // query와 deferredQuery가 다르면 로딩 중
  const isStale = query !== deferredQuery

  return (
    <div style={{ opacity: isStale ? 0.5 : 1 }}>
      {results.map(item => <Item key={item.id} data={item} />)}
    </div>
  )
}
```

### useTransition vs useDeferredValue

```tsx
// useTransition: 상태 업데이트를 지연
function Parent() {
  const [query, setQuery] = useState('')
  const [isPending, startTransition] = useTransition()

  const handleChange = (e) => {
    startTransition(() => {
      setQuery(e.target.value)  // 이 업데이트가 지연됨
    })
  }

  return <Child query={query} />
}

// useDeferredValue: props를 지연
function Parent() {
  const [query, setQuery] = useState('')
  return <Child query={query} />  // query는 즉시 변경
}

function Child({ query }) {
  const deferredQuery = useDeferredValue(query)  // 사용을 지연
  // ...
}
```

### 언제 무엇을 사용?

```tsx
// useTransition: 상태를 직접 제어할 때
function SearchBox() {
  const [query, setQuery] = useState('')
  const [isPending, startTransition] = useTransition()

  // setQuery를 startTransition으로 감쌀 수 있음
}

// useDeferredValue: props로 받을 때
function FilteredList({ filter }) {
  // filter는 props라서 직접 제어 불가
  // useDeferredValue로 지연
  const deferredFilter = useDeferredValue(filter)
}
```

---

## Suspense와 동시성

### Suspense 기본

```tsx
import { Suspense } from 'react'

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <ProfilePage />
    </Suspense>
  )
}

// ProfilePage에서 데이터 로딩 시
// Loading 컴포넌트가 표시됨
```

### Suspense + Transition

```tsx
function App() {
  const [tab, setTab] = useState('home')
  const [isPending, startTransition] = useTransition()

  return (
    <div>
      <TabButton onClick={() => {
        startTransition(() => setTab('comments'))
      }}>
        Comments
      </TabButton>

      <Suspense fallback={<Spinner />}>
        {tab === 'home' && <Home />}
        {tab === 'comments' && <Comments />}
      </Suspense>
    </div>
  )
}

// startTransition으로 감싸면:
// - 새 탭이 준비될 때까지 이전 탭 유지
// - Suspense fallback 대신 이전 UI + isPending 상태
```

### SuspenseList (실험적)

```tsx
import { SuspenseList, Suspense } from 'react'

function Feed() {
  return (
    <SuspenseList revealOrder="forwards" tail="collapsed">
      <Suspense fallback={<Skeleton />}>
        <Post id={1} />
      </Suspense>
      <Suspense fallback={<Skeleton />}>
        <Post id={2} />
      </Suspense>
      <Suspense fallback={<Skeleton />}>
        <Post id={3} />
      </Suspense>
    </SuspenseList>
  )
}

// revealOrder="forwards": 순서대로 표시
// tail="collapsed": 로딩 중인 것 중 하나만 skeleton 표시
```

---

## 동시성 패턴

### 패턴 1: 입력 + 결과 분리

```tsx
function Search() {
  const [query, setQuery] = useState('')
  const [isPending, startTransition] = useTransition()

  return (
    <>
      <input
        value={query}
        onChange={(e) => {
          // 입력은 즉시
          setQuery(e.target.value)
        }}
      />
      <SearchResults
        query={query}
        isPending={isPending}
        startTransition={startTransition}
      />
    </>
  )
}

function SearchResults({ query, isPending, startTransition }) {
  const [results, setResults] = useState([])

  useEffect(() => {
    startTransition(() => {
      setResults(search(query))
    })
  }, [query])

  return (
    <div style={{ opacity: isPending ? 0.7 : 1 }}>
      {results.map(r => <Result key={r.id} data={r} />)}
    </div>
  )
}
```

### 패턴 2: 디바운스 대체

```tsx
// 기존: 디바운스로 요청 줄이기
function SearchOld() {
  const [query, setQuery] = useState('')
  const debouncedQuery = useDebounce(query, 300)

  useEffect(() => {
    search(debouncedQuery)
  }, [debouncedQuery])
}

// 동시성: 더 나은 UX
function SearchNew() {
  const [query, setQuery] = useState('')
  const deferredQuery = useDeferredValue(query)

  // 입력은 즉시 반영
  // 검색은 지연되지만 취소 가능
  const results = useMemo(() => search(deferredQuery), [deferredQuery])
}
```

### 패턴 3: 이전 결과 유지

```tsx
function FilteredList({ filter }) {
  const deferredFilter = useDeferredValue(filter)
  const isStale = filter !== deferredFilter

  // 필터 변경 시:
  // 1. filter 즉시 변경
  // 2. deferredFilter는 천천히 따라감
  // 3. 그 동안 이전 결과를 흐리게 표시

  const items = useMemo(
    () => filterItems(allItems, deferredFilter),
    [deferredFilter]
  )

  return (
    <ul style={{
      opacity: isStale ? 0.6 : 1,
      transition: 'opacity 0.2s'
    }}>
      {items.map(item => <li key={item.id}>{item.name}</li>)}
    </ul>
  )
}
```

---

## 성능 고려사항

### 과도한 Transition 사용 금지

```tsx
// Bad: 모든 것을 transition으로
function handleClick() {
  startTransition(() => {
    setA(1)
    setB(2)
    setC(3)
  })
}

// Good: 무거운 것만 transition으로
function handleClick() {
  setA(1)  // 가벼운 업데이트
  setB(2)  // 가벼운 업데이트

  startTransition(() => {
    setHeavyState(compute())  // 무거운 것만
  })
}
```

### useDeferredValue와 메모이제이션

```tsx
// Bad: useDeferredValue만 사용
function List({ filter }) {
  const deferredFilter = useDeferredValue(filter)

  // 매번 새로 계산됨
  const items = filterItems(data, deferredFilter)

  return items.map(...)
}

// Good: useMemo와 함께
function List({ filter }) {
  const deferredFilter = useDeferredValue(filter)

  // deferredFilter가 같으면 재사용
  const items = useMemo(
    () => filterItems(data, deferredFilter),
    [deferredFilter]
  )

  return items.map(...)
}
```

---

## 요약

### 배치 업데이트

```tsx
// React 18: 모든 곳에서 자동 배칭
setTimeout(() => {
  setA(1)
  setB(2)
  // → 1번 리렌더링
}, 0)

// 즉시 반영 필요시
flushSync(() => {
  setState(value)
})
```

### 동시성 API

```tsx
// useTransition: 상태 업데이트 지연
const [isPending, startTransition] = useTransition()
startTransition(() => {
  setExpensiveState(value)
})

// useDeferredValue: 값 지연
const deferredValue = useDeferredValue(value)
```

### 사용 시점

| 상황 | 해결책 |
|------|--------|
| 입력과 검색 결과 | useTransition |
| Props로 받은 무거운 값 | useDeferredValue |
| DOM 측정 후 업데이트 | flushSync |
| 데이터 로딩 대기 | Suspense |

---

## 다음 단계

[05-hooks-internals.md](./05-hooks-internals.md)에서 Hooks의 내부 동작 원리를 알아봅니다.
