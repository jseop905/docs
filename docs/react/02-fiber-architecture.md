# Fiber 아키텍처

React 16에서 도입된 Fiber 아키텍처의 개념과 동작 원리를 이해합니다.

---

## Fiber 이전의 문제

### Stack Reconciler (React 15 이전)

```
컴포넌트 트리 업데이트 시작
    ↓
모든 컴포넌트를 동기적으로 처리
    ↓
완료될 때까지 메인 스레드 블로킹
    ↓
사용자 입력, 애니메이션 멈춤
```

```javascript
// 큰 리스트 렌더링 예시
function BigList({ items }) {
  return (
    <ul>
      {items.map(item => (
        <ComplexItem key={item.id} data={item} />
      ))}
    </ul>
  )
}

// 10,000개 항목 업데이트
// Stack Reconciler: 전체 처리까지 ~500ms 블로킹
// → 화면 멈춤, 입력 무시
```

### 프레임 드랍 문제

```
60fps = 16.67ms per frame

[Frame 1: 16ms] [Frame 2: 16ms] [Frame 3: 16ms]
      ↓              ↓              ↓
   렌더링         렌더링         렌더링

But 큰 업데이트가 100ms 걸리면?

[====== 100ms 업데이트 ======]
 Frame 1   2   3   4   5   6
   ↓
 모두 드랍됨 → 화면 버벅임
```

---

## Fiber란?

### 개념

Fiber는 **작업 단위(unit of work)**입니다.

```
기존: 전체 트리를 한 번에 처리
Fiber: 작은 단위로 쪼개서 처리

[컴포넌트 A] → [컴포넌트 B] → [컴포넌트 C] → ...
     ↓              ↓              ↓
  작업 단위       작업 단위       작업 단위
     ↓              ↓              ↓
  처리 후         처리 후         처리 후
  양보 가능       양보 가능       양보 가능
```

### Fiber 노드 구조

```javascript
// 각 컴포넌트/요소마다 Fiber 노드 생성
const fiber = {
  // 타입 정보
  tag: FunctionComponent,     // 컴포넌트 종류
  type: MyComponent,          // 컴포넌트 함수/클래스
  key: null,

  // 트리 구조 (연결 리스트)
  return: parentFiber,        // 부모
  child: firstChildFiber,     // 첫 번째 자식
  sibling: nextSiblingFiber,  // 다음 형제

  // 상태
  memoizedState: null,        // Hooks 상태 (링크드 리스트)
  memoizedProps: {},          // 이전 props

  // 작업 정보
  pendingProps: {},           // 새 props
  effectTag: Placement,       // 수행할 작업 종류
  nextEffect: null,           // 다음 effect

  // 대체 버전 (Double Buffering)
  alternate: currentFiber,    // current ↔ workInProgress
}
```

### 트리 구조

```
        [App]
         ↓ child
      [Header] → sibling → [Main] → sibling → [Footer]
         ↓ child              ↓ child
       [Nav]              [Content]
                             ↓ child
                          [Article]

// Fiber는 연결 리스트로 순회
// child → sibling → return (부모)
```

---

## Double Buffering

### 두 개의 트리

```
Current Tree                Work In Progress Tree
(화면에 표시 중)              (백그라운드에서 작업 중)
     ↓                              ↓
   [App]  ←── alternate ──→      [App']
     ↓                              ↓
 [Header]  ←── alternate ──→   [Header']
     ↓                              ↓
   ...                            ...

작업 완료 후:
Work In Progress → Current (포인터 스왑)
```

### 동작 과정

```
1. 상태 변경 발생
   ↓
2. Work In Progress 트리에서 작업
   - 변경된 부분만 새 Fiber 생성
   - 변경 없는 부분은 재사용
   ↓
3. 모든 작업 완료
   ↓
4. Commit: WIP → Current로 교체
   - 실제 DOM 업데이트
   - 한 번에 반영 (일관된 UI)
```

```javascript
// 재사용 예시
function App() {
  const [count, setCount] = useState(0)
  return (
    <div>
      <Header />           {/* 변경 없음: Fiber 재사용 */}
      <Counter count={count} />  {/* 변경됨: 새 Fiber */}
      <Footer />           {/* 변경 없음: Fiber 재사용 */}
    </div>
  )
}
```

---

## 작업 스케줄링

### 우선순위 레벨

```javascript
// React 내부 우선순위 (Lane 모델)
const SyncLane = 1              // 즉시 (클릭, 입력)
const InputContinuousLane = 4   // 연속 입력 (드래그)
const DefaultLane = 16          // 일반 업데이트
const TransitionLane = 64       // Transition
const IdleLane = 536870912      // 유휴 시간
```

### 우선순위별 처리

```
사용자 입력 (높은 우선순위)
    ↓
현재 작업 중단
    ↓
입력 처리 (빠르게)
    ↓
중단된 작업 재개
```

```tsx
function SearchResults() {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState([])

  // 입력은 즉시 반영
  const handleChange = (e) => {
    setQuery(e.target.value)  // 높은 우선순위

    // 검색 결과는 낮은 우선순위
    startTransition(() => {
      setResults(search(e.target.value))
    })
  }

  return (
    <div>
      <input value={query} onChange={handleChange} />
      <ResultList results={results} />
    </div>
  )
}
```

---

## 작업 단위 처리

### Work Loop

```javascript
// React 내부 작업 루프 (단순화)
function workLoop(deadline) {
  // 시간이 남아있고 할 일이 있는 동안
  while (workInProgress !== null && !shouldYield()) {
    // 다음 작업 단위 처리
    workInProgress = performUnitOfWork(workInProgress)
  }

  // 시간 초과: 브라우저에 양보
  if (workInProgress !== null) {
    requestIdleCallback(workLoop)
  }
}

function shouldYield() {
  // 프레임 시간이 다 됐는지 확인
  return getCurrentTime() >= deadline
}
```

### 작업 단위 처리

```javascript
function performUnitOfWork(fiber) {
  // 1. 현재 Fiber 작업 수행
  //    - 컴포넌트 렌더링
  //    - 자식 Fiber 생성

  // 2. 다음 작업 찾기
  if (fiber.child) {
    return fiber.child        // 자식이 있으면 자식으로
  }

  let nextFiber = fiber
  while (nextFiber) {
    if (nextFiber.sibling) {
      return nextFiber.sibling  // 형제가 있으면 형제로
    }
    nextFiber = nextFiber.return  // 부모로 올라감
  }

  return null  // 모든 작업 완료
}
```

### 순회 순서

```
        [1.App]
           ↓
    [2.Header]─────→[5.Main]────→[8.Footer]
         ↓              ↓
    [3.Logo]       [6.Content]
         ↓              ↓
    [4.Nav]       [7.Article]

순서: 1→2→3→4→(위로)→5→6→7→(위로)→8→완료

각 노드에서:
1. beginWork: 자식으로 내려가며 작업
2. completeWork: 올라가며 완료 처리
```

---

## Render vs Commit

### Render Phase (중단 가능)

```
목적: 무엇이 변경되었는지 계산

작업:
- 컴포넌트 함수 호출
- 새 Virtual DOM 생성
- 이전과 비교
- 변경 목록 생성

특징:
- 순수해야 함 (부수 효과 X)
- 중단/재개 가능
- 여러 번 실행될 수 있음
```

```tsx
function Component() {
  // Render Phase에서 실행
  console.log('렌더링')  // 여러 번 호출될 수 있음!

  // Bad: 부수 효과
  document.title = 'New Title'  // 여기서 하면 안 됨

  return <div>Hello</div>
}
```

### Commit Phase (중단 불가)

```
목적: 변경사항을 DOM에 반영

단계:
1. Before Mutation
   - getSnapshotBeforeUpdate
   - DOM 변경 전 읽기

2. Mutation
   - 실제 DOM 변경
   - ref 업데이트

3. Layout
   - useLayoutEffect 실행
   - componentDidMount/Update

4. (이후 비동기로)
   - useEffect 실행
```

```tsx
function Component() {
  useLayoutEffect(() => {
    // Commit Phase (Layout)에서 동기 실행
    // DOM 측정, 동기적 업데이트
  })

  useEffect(() => {
    // Commit 이후 비동기 실행
    // 데이터 페칭, 구독 등
  })

  return <div>Hello</div>
}
```

---

## 동시성 (Concurrency)

### React 18의 동시성

```tsx
import { startTransition, useTransition } from 'react'

function App() {
  const [isPending, startTransition] = useTransition()
  const [list, setList] = useState([])

  const handleClick = () => {
    // 긴급한 업데이트
    setInputValue(e.target.value)

    // 긴급하지 않은 업데이트 (중단 가능)
    startTransition(() => {
      setList(generateBigList())
    })
  }

  return (
    <div>
      {isPending && <Spinner />}
      <List items={list} />
    </div>
  )
}
```

### Time Slicing

```
Without Time Slicing:
[========== 긴 렌더링 ==========]
         사용자 입력 무시됨

With Time Slicing:
[렌더1][입력][렌더2][렌더3][입력][렌더4]
         ↑              ↑
    즉시 응답       즉시 응답
```

---

## Effect 처리

### Effect List

```javascript
// Commit 단계에서 처리할 effect들의 연결 리스트
fiber.flags = Update | Placement | Deletion

// Effect가 있는 Fiber들만 연결
firstEffect → fiber1 → fiber2 → fiber3 → null
                 ↓        ↓        ↓
            Update   Placement  Deletion
```

### Effect 종류

```javascript
// Fiber flags
const Placement = 0b0000000000010    // 새 노드 추가
const Update = 0b0000000000100       // 업데이트
const Deletion = 0b0000000001000     // 삭제
const Snapshot = 0b0000100000000     // 스냅샷 필요
const Passive = 0b0001000000000      // useEffect
const Layout = 0b0010000000000       // useLayoutEffect
```

---

## 실전 이해

### 왜 Hooks는 조건문 안에서 쓰면 안 되는가?

```javascript
// Fiber의 memoizedState는 링크드 리스트
fiber.memoizedState = {
  // 첫 번째 Hook (useState)
  memoizedState: 0,
  next: {
    // 두 번째 Hook (useEffect)
    memoizedState: effect1,
    next: {
      // 세 번째 Hook (useState)
      memoizedState: 'hello',
      next: null
    }
  }
}

// 순서대로 읽음: 1번째 → 2번째 → 3번째
// 조건문으로 Hook이 빠지면 순서가 어긋남!
```

### 왜 key가 중요한가?

```javascript
// key는 Fiber 재사용 여부 결정에 사용
function reconcileChildFibers(returnFiber, currentFirstChild, newChildren) {
  // key와 type이 같으면 Fiber 재사용
  if (current.key === newChild.key && current.type === newChild.type) {
    return useFiber(current, newChild.props)
  }
  // 다르면 새 Fiber 생성
  return createFiberFromElement(newChild)
}
```

### 왜 리렌더링이 자식까지 전파되는가?

```javascript
// 부모가 리렌더링되면 자식 props 객체가 새로 생성
function Parent() {
  const [count, setCount] = useState(0)

  // 매 렌더마다 새 객체
  const childProps = { value: 'same' }

  return <Child {...childProps} />  // props 참조 변경 → 리렌더링
}

// 해결: useMemo, React.memo
```

---

## 요약

### Fiber의 핵심

```
1. 작업 분할: 큰 작업을 작은 단위로
2. 우선순위: 긴급한 작업 먼저
3. 중단/재개: 필요시 작업 양보
4. 일관성: Commit은 한 번에
```

### 두 단계

```
Render Phase          Commit Phase
- 계산만              - DOM 반영
- 중단 가능           - 중단 불가
- 순수해야 함         - 부수 효과 실행
```

### Double Buffering

```
Current ←→ Work In Progress
- 백그라운드 작업
- 완료 후 스왑
- 일관된 UI
```

---

## 다음 단계

[03-rendering-process.md](./03-rendering-process.md)에서 구체적인 렌더링 과정을 알아봅니다.
