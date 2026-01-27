# 렌더링 과정 (Rendering Process)

React가 컴포넌트를 화면에 그리는 전체 과정을 상세히 알아봅니다.

---

## 렌더링 트리거

### 렌더링이 발생하는 경우

```tsx
// 1. 초기 렌더링
const root = createRoot(document.getElementById('root'))
root.render(<App />)

// 2. 상태 변경
const [count, setCount] = useState(0)
setCount(1)  // 리렌더링 트리거

// 3. 부모 리렌더링
function Parent() {
  const [state, setState] = useState(0)
  return <Child />  // Parent 리렌더링 시 Child도 리렌더링
}

// 4. Context 변경
const ThemeContext = createContext('light')
// Provider value 변경 시 Consumer 리렌더링

// 5. forceUpdate (클래스 컴포넌트)
this.forceUpdate()
```

### 리렌더링이 발생하지 않는 경우

```tsx
// 1. 같은 값으로 상태 변경 (Object.is 비교)
const [count, setCount] = useState(0)
setCount(0)  // 리렌더링 안 됨

// 2. React.memo로 감싼 컴포넌트 (props 변경 없을 때)
const MemoChild = React.memo(Child)
// props가 같으면 리렌더링 스킵

// 3. useMemo로 캐시된 요소
const element = useMemo(() => <ExpensiveComponent />, [dep])
// dep이 같으면 재사용
```

---

## Render Phase 상세

### 1단계: 트리거 처리

```javascript
// setState 호출 시
function dispatchSetState(fiber, queue, action) {
  // 1. 업데이트 객체 생성
  const update = {
    action,      // 새 값 또는 업데이터 함수
    next: null,
  }

  // 2. 업데이트 큐에 추가
  enqueueUpdate(fiber, update)

  // 3. 리렌더링 스케줄
  scheduleUpdateOnFiber(fiber)
}
```

### 2단계: 작업 시작

```javascript
function performSyncWorkOnRoot(root) {
  // Work In Progress 트리 준비
  prepareFreshStack(root)

  // 작업 루프 시작
  workLoopSync()

  // 완료된 트리를 root에 저장
  root.finishedWork = root.current.alternate
}

function workLoopSync() {
  while (workInProgress !== null) {
    performUnitOfWork(workInProgress)
  }
}
```

### 3단계: 컴포넌트 렌더링

```javascript
function performUnitOfWork(unitOfWork) {
  // beginWork: 컴포넌트 처리, 자식 생성
  const next = beginWork(current, unitOfWork, renderLanes)

  if (next === null) {
    // 자식 없음: 완료 처리
    completeUnitOfWork(unitOfWork)
  } else {
    // 자식으로 이동
    workInProgress = next
  }
}
```

### beginWork 상세

```javascript
function beginWork(current, workInProgress, renderLanes) {
  // 컴포넌트 타입에 따라 분기
  switch (workInProgress.tag) {
    case FunctionComponent:
      return updateFunctionComponent(current, workInProgress)

    case ClassComponent:
      return updateClassComponent(current, workInProgress)

    case HostComponent:  // div, span 등
      return updateHostComponent(current, workInProgress)

    case HostText:  // 텍스트 노드
      return updateHostText(current, workInProgress)

    // ...
  }
}

function updateFunctionComponent(current, workInProgress) {
  // 1. Hooks 준비
  prepareHooks(workInProgress)

  // 2. 컴포넌트 함수 호출
  const children = Component(props)

  // 3. 자식 Fiber 생성/업데이트
  reconcileChildren(current, workInProgress, children)

  return workInProgress.child
}
```

### 재조정 (Reconciliation)

```javascript
function reconcileChildren(current, workInProgress, nextChildren) {
  if (current === null) {
    // 마운트: 새 Fiber 생성
    workInProgress.child = mountChildFibers(workInProgress, null, nextChildren)
  } else {
    // 업데이트: 기존과 비교
    workInProgress.child = reconcileChildFibers(
      workInProgress,
      current.child,
      nextChildren
    )
  }
}

function reconcileChildFibers(returnFiber, currentFirstChild, newChildren) {
  // 단일 요소
  if (typeof newChildren === 'object' && newChildren !== null) {
    return reconcileSingleElement(returnFiber, currentFirstChild, newChildren)
  }

  // 배열
  if (Array.isArray(newChildren)) {
    return reconcileChildrenArray(returnFiber, currentFirstChild, newChildren)
  }

  // 텍스트
  if (typeof newChildren === 'string' || typeof newChildren === 'number') {
    return reconcileSingleTextNode(returnFiber, currentFirstChild, newChildren)
  }
}
```

### completeWork 상세

```javascript
function completeWork(current, workInProgress) {
  switch (workInProgress.tag) {
    case HostComponent: {
      if (current !== null && workInProgress.stateNode !== null) {
        // 업데이트: props 변경사항 계산
        updateHostComponent(current, workInProgress)
      } else {
        // 마운트: DOM 노드 생성
        const instance = createInstance(workInProgress.type, props)
        appendAllChildren(instance, workInProgress)
        workInProgress.stateNode = instance
      }
      return null
    }
    // ...
  }
}
```

---

## Commit Phase 상세

### 전체 흐름

```
Commit Phase
    │
    ├── Before Mutation (변경 전)
    │   └── getSnapshotBeforeUpdate
    │
    ├── Mutation (DOM 변경)
    │   ├── DOM 삽입/업데이트/삭제
    │   └── ref 분리
    │
    ├── Layout (변경 후)
    │   ├── useLayoutEffect
    │   ├── componentDidMount/Update
    │   └── ref 연결
    │
    └── (비동기) Passive Effects
        └── useEffect
```

### Before Mutation Phase

```javascript
function commitBeforeMutationEffects(root, firstChild) {
  let fiber = firstChild
  while (fiber !== null) {
    // 클래스 컴포넌트의 getSnapshotBeforeUpdate
    if (fiber.flags & Snapshot) {
      const snapshot = fiber.stateNode.getSnapshotBeforeUpdate(
        fiber.memoizedProps,
        fiber.memoizedState
      )
      fiber.stateNode.__reactInternalSnapshotBeforeUpdate = snapshot
    }
    fiber = fiber.nextEffect
  }
}
```

### Mutation Phase

```javascript
function commitMutationEffects(root, firstChild) {
  let fiber = firstChild
  while (fiber !== null) {
    const flags = fiber.flags

    // DOM 삽입
    if (flags & Placement) {
      commitPlacement(fiber)
    }

    // DOM 업데이트
    if (flags & Update) {
      commitUpdate(fiber.stateNode, updatePayload)
    }

    // DOM 삭제
    if (flags & Deletion) {
      commitDeletion(root, fiber)
    }

    fiber = fiber.nextEffect
  }
}

function commitPlacement(fiber) {
  // 부모 DOM 찾기
  const parentFiber = getHostParentFiber(fiber)
  const parentDOM = parentFiber.stateNode

  // 삽입 위치 찾기 (형제 기준)
  const before = getHostSibling(fiber)

  // DOM에 삽입
  if (before) {
    parentDOM.insertBefore(fiber.stateNode, before)
  } else {
    parentDOM.appendChild(fiber.stateNode)
  }
}
```

### Layout Phase

```javascript
function commitLayoutEffects(root, firstChild) {
  let fiber = firstChild
  while (fiber !== null) {
    const flags = fiber.flags

    if (flags & (Update | Callback)) {
      // 클래스: componentDidMount/Update
      // 함수: useLayoutEffect
      commitLayoutEffectOnFiber(root, fiber)
    }

    // ref 연결
    if (flags & Ref) {
      commitAttachRef(fiber)
    }

    fiber = fiber.nextEffect
  }
}

function commitLayoutEffectOnFiber(root, fiber) {
  switch (fiber.tag) {
    case FunctionComponent: {
      // useLayoutEffect 콜백 실행
      commitHookEffectListMount(HookLayout, fiber)
      break
    }
    case ClassComponent: {
      const instance = fiber.stateNode
      if (fiber.flags & Update) {
        if (current === null) {
          instance.componentDidMount()
        } else {
          instance.componentDidUpdate(prevProps, prevState, snapshot)
        }
      }
      break
    }
  }
}
```

### Passive Effects (useEffect)

```javascript
// Layout Phase 이후 비동기로 스케줄
function schedulePassiveEffects(fiber) {
  // 브라우저 페인트 후 실행
  scheduleCallback(NormalPriority, () => {
    flushPassiveEffects()
  })
}

function flushPassiveEffects() {
  // 1. 이전 effect의 cleanup 실행
  commitPassiveUnmountEffects(root.current)

  // 2. 새 effect 실행
  commitPassiveMountEffects(root, root.current)
}
```

---

## 실제 렌더링 예시

### 예시 컴포넌트

```tsx
function App() {
  const [count, setCount] = useState(0)

  useEffect(() => {
    console.log('Effect')
    return () => console.log('Cleanup')
  }, [count])

  useLayoutEffect(() => {
    console.log('Layout Effect')
  }, [count])

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(c => c + 1)}>+1</button>
    </div>
  )
}
```

### 초기 렌더링

```
1. Render Phase
   - App 함수 호출
   - useState: count = 0 초기화
   - useEffect: effect 등록
   - useLayoutEffect: effect 등록
   - <div>, <p>, <button> Fiber 생성

2. Commit Phase
   - Before Mutation: (없음)
   - Mutation: DOM 생성 및 삽입
   - Layout: "Layout Effect" 출력
   - (비동기) Passive: "Effect" 출력
```

### 버튼 클릭 (업데이트)

```
1. 트리거
   - setCount(1) 호출
   - 업데이트 스케줄

2. Render Phase
   - App 함수 재호출
   - useState: count = 1 반환
   - useEffect: 의존성 변경 감지, effect 등록
   - useLayoutEffect: 의존성 변경 감지, effect 등록
   - Fiber 비교 및 업데이트

3. Commit Phase
   - Before Mutation: (없음)
   - Mutation: <p> 텍스트 업데이트
   - Layout: "Layout Effect" 출력
   - (비동기) Passive:
     - "Cleanup" 출력 (이전 effect)
     - "Effect" 출력 (새 effect)
```

---

## 배치 처리

### React 18 자동 배칭

```tsx
function handleClick() {
  setCount(c => c + 1)  // 큐에 추가
  setFlag(f => !f)      // 큐에 추가
  setName('new')        // 큐에 추가
  // → 여기서 한 번만 리렌더링
}

// 비동기에서도 배칭
setTimeout(() => {
  setCount(c => c + 1)
  setFlag(f => !f)
  // React 18: 한 번만 리렌더링
  // React 17: 두 번 리렌더링
}, 1000)
```

### 배칭 동작 원리

```javascript
// 업데이트가 큐에 쌓임
updateQueue = [
  { action: c => c + 1 },  // setCount
  { action: f => !f },     // setFlag
]

// 다음 틱에서 한 번에 처리
function processUpdateQueue(fiber, queue) {
  let newState = fiber.memoizedState

  // 모든 업데이트 순차 적용
  let update = queue.firstUpdate
  while (update !== null) {
    newState = typeof update.action === 'function'
      ? update.action(newState)
      : update.action
    update = update.next
  }

  fiber.memoizedState = newState
}
```

### 배칭 탈출 (필요시)

```tsx
import { flushSync } from 'react-dom'

function handleClick() {
  flushSync(() => {
    setCount(c => c + 1)
  })
  // 여기서 DOM이 이미 업데이트됨

  flushSync(() => {
    setFlag(f => !f)
  })
  // 여기서 다시 DOM 업데이트
}
```

---

## 렌더링 최적화

### Bailout (렌더링 스킵)

```javascript
function updateFunctionComponent(current, workInProgress) {
  // props와 context가 같으면 스킵 가능
  if (current !== null) {
    const oldProps = current.memoizedProps
    const newProps = workInProgress.pendingProps

    if (oldProps === newProps && !hasContextChanged()) {
      // 변경 없음: 자식 재사용
      return bailoutOnAlreadyFinishedWork(current, workInProgress)
    }
  }

  // 변경됨: 렌더링 진행
  const children = Component(newProps)
  reconcileChildren(current, workInProgress, children)
  return workInProgress.child
}
```

### React.memo

```tsx
const MemoizedComponent = React.memo(
  function Component({ value }) {
    return <div>{value}</div>
  },
  (prevProps, nextProps) => {
    // true 반환: 리렌더링 스킵
    // false 반환: 리렌더링
    return prevProps.value === nextProps.value
  }
)
```

### useMemo와 useCallback

```tsx
function Parent() {
  const [count, setCount] = useState(0)

  // 매 렌더마다 새 객체 (자식 리렌더링 유발)
  const data = { value: 'constant' }

  // useMemo: 객체 재사용
  const memoData = useMemo(() => ({ value: 'constant' }), [])

  // useCallback: 함수 재사용
  const handler = useCallback(() => {
    console.log('click')
  }, [])

  return <Child data={memoData} onClick={handler} />
}
```

---

## 요약

### 렌더링 단계

```
Trigger → Render Phase → Commit Phase
           (계산)         (반영)

Render Phase:
- beginWork: 컴포넌트 호출, 자식 생성
- reconcile: 비교, diff
- completeWork: DOM 준비

Commit Phase:
- Before Mutation: 스냅샷
- Mutation: DOM 변경
- Layout: useLayoutEffect, componentDidX
- (async) Passive: useEffect
```

### 핵심 포인트

```tsx
// 1. Render는 순수해야 함
function Component() {
  // 부수 효과 X
  return <div />
}

// 2. 배칭으로 여러 업데이트 합쳐짐
setA(1)
setB(2)  // 한 번 리렌더링

// 3. useLayoutEffect는 DOM 후 동기 실행
useLayoutEffect(() => {
  // DOM 측정 가능
})

// 4. useEffect는 페인트 후 비동기 실행
useEffect(() => {
  // 데이터 페칭 등
})
```

---

## 다음 단계

[04-batch-update.md](./04-batch-update.md)에서 배치 업데이트와 동시성을 자세히 알아봅니다.
