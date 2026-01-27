# Hooks 내부 동작 원리

React Hooks가 내부적으로 어떻게 동작하는지 이해합니다.

---

## Hooks의 본질

### Hooks는 배열이다

```javascript
// React 내부 (단순화)
let hooks = []        // Hook 저장소
let currentIndex = 0  // 현재 Hook 인덱스

function useState(initialValue) {
  const index = currentIndex

  // 첫 렌더: 초기화
  if (hooks[index] === undefined) {
    hooks[index] = initialValue
  }

  const setState = (newValue) => {
    hooks[index] = newValue
    render()  // 리렌더링 트리거
  }

  currentIndex++
  return [hooks[index], setState]
}

function render() {
  currentIndex = 0  // 인덱스 리셋
  Component()       // 컴포넌트 재실행
}
```

### 왜 조건문 안에서 Hook을 쓰면 안 되는가?

```tsx
function Component({ condition }) {
  // 첫 번째 렌더: condition = true
  if (condition) {
    const [a, setA] = useState(0)  // index 0
  }
  const [b, setB] = useState(0)    // index 1

  // 두 번째 렌더: condition = false
  // useState(0) 호출 안 됨          // index 0 건너뜀
  const [b, setB] = useState(0)    // index 0 ← 어긋남!

  // hooks[0]에는 a의 값이 있는데 b로 읽음 → 버그!
}
```

```
렌더 1: [a값, b값]  → a는 hooks[0], b는 hooks[1]
렌더 2: [a값, b값]  → b는 hooks[0]을 읽음 (a값을 b로 착각)
```

---

## 실제 React의 Hook 구조

### Fiber와 Hooks

```javascript
// 각 Fiber 노드가 Hook 정보를 가짐
fiber = {
  memoizedState: hook1,  // 첫 번째 Hook (링크드 리스트 시작)
  // ...
}

// Hook은 링크드 리스트로 연결
hook1 = {
  memoizedState: value1,  // 상태 값
  queue: updateQueue1,    // 업데이트 큐
  next: hook2,           // 다음 Hook
}

hook2 = {
  memoizedState: value2,
  queue: updateQueue2,
  next: hook3,
}
```

### 렌더링 시 Hook 처리

```javascript
// 현재 작업 중인 Fiber와 Hook
let currentlyRenderingFiber = null
let workInProgressHook = null

function renderWithHooks(fiber, Component, props) {
  currentlyRenderingFiber = fiber

  // Hook 리스트 초기화
  fiber.memoizedState = null

  // 컴포넌트 실행 (Hook 호출됨)
  const children = Component(props)

  currentlyRenderingFiber = null
  workInProgressHook = null

  return children
}
```

---

## useState 내부 동작

### 마운트 시

```javascript
function mountState(initialState) {
  // Hook 객체 생성
  const hook = {
    memoizedState: typeof initialState === 'function'
      ? initialState()
      : initialState,
    queue: {
      pending: null,
    },
    next: null,
  }

  // Fiber에 연결
  if (workInProgressHook === null) {
    currentlyRenderingFiber.memoizedState = hook
  } else {
    workInProgressHook.next = hook
  }
  workInProgressHook = hook

  // dispatch 함수 생성
  const dispatch = dispatchSetState.bind(null, currentlyRenderingFiber, hook.queue)

  return [hook.memoizedState, dispatch]
}
```

### 업데이트 시

```javascript
function updateState() {
  // 기존 Hook 가져오기
  const hook = updateWorkInProgressHook()

  // 업데이트 큐 처리
  const queue = hook.queue
  let newState = hook.memoizedState

  if (queue.pending !== null) {
    let update = queue.pending.next
    do {
      // 업데이트 적용
      const action = update.action
      newState = typeof action === 'function'
        ? action(newState)
        : action
      update = update.next
    } while (update !== queue.pending.next)

    queue.pending = null
  }

  hook.memoizedState = newState
  return [newState, hook.dispatch]
}
```

### setState 호출 시

```javascript
function dispatchSetState(fiber, queue, action) {
  // 업데이트 객체 생성
  const update = {
    action,
    next: null,
  }

  // 순환 링크드 리스트로 큐에 추가
  if (queue.pending === null) {
    update.next = update
  } else {
    update.next = queue.pending.next
    queue.pending.next = update
  }
  queue.pending = update

  // 리렌더링 스케줄
  scheduleUpdateOnFiber(fiber)
}
```

---

## useEffect 내부 동작

### Effect 구조

```javascript
const effect = {
  tag: HookPassive,        // effect 종류 (Passive = useEffect)
  create: () => {},        // effect 함수
  destroy: undefined,      // cleanup 함수
  deps: [dep1, dep2],      // 의존성 배열
  next: null,              // 다음 effect
}
```

### 마운트 시

```javascript
function mountEffect(create, deps) {
  const hook = {
    memoizedState: null,
    next: null,
  }

  // Effect 생성
  const effect = {
    tag: HookPassive,
    create,
    destroy: undefined,
    deps,
    next: null,
  }

  // 순환 리스트로 연결
  hook.memoizedState = effect

  // Fiber의 effect 목록에 추가
  pushEffect(HookPassive, effect)
}
```

### 업데이트 시

```javascript
function updateEffect(create, deps) {
  const hook = updateWorkInProgressHook()
  const prevEffect = hook.memoizedState

  if (deps !== null) {
    const prevDeps = prevEffect.deps

    // 의존성 비교
    if (areHookInputsEqual(deps, prevDeps)) {
      // 변경 없음: effect 실행 안 함
      pushEffect(HookPassive, {
        tag: HookPassive,
        create,
        destroy: prevEffect.destroy,
        deps,
        next: null,
      })
      return
    }
  }

  // 변경됨: effect 실행 예약
  pushEffect(HookPassive | HookHasEffect, {
    tag: HookPassive | HookHasEffect,
    create,
    destroy: prevEffect.destroy,
    deps,
    next: null,
  })
}
```

### Effect 실행 시점

```javascript
// Commit Phase 이후 비동기로 실행
function flushPassiveEffects() {
  // 1. 모든 cleanup 실행 (이전 effect의 destroy)
  commitPassiveUnmountEffects(root)

  // 2. 모든 effect 실행 (새 effect의 create)
  commitPassiveMountEffects(root)
}

function commitPassiveUnmountEffects(fiber) {
  const effect = fiber.memoizedState
  if (effect.destroy !== undefined) {
    effect.destroy()  // cleanup 실행
  }
}

function commitPassiveMountEffects(fiber) {
  const effect = fiber.memoizedState
  effect.destroy = effect.create()  // effect 실행, cleanup 저장
}
```

---

## useRef 내부 동작

### 단순한 구조

```javascript
function mountRef(initialValue) {
  const hook = {
    memoizedState: { current: initialValue },
    next: null,
  }

  return hook.memoizedState
}

function updateRef() {
  const hook = updateWorkInProgressHook()
  return hook.memoizedState  // 항상 같은 객체 반환
}
```

### 왜 리렌더링을 트리거하지 않는가?

```javascript
// useState
const [state, setState] = useState(0)
setState(1)  // dispatchSetState 호출 → 리렌더링

// useRef
const ref = useRef(0)
ref.current = 1  // 그냥 객체 속성 변경 → 리렌더링 없음
```

---

## useMemo와 useCallback

### useMemo 내부

```javascript
function mountMemo(nextCreate, deps) {
  const hook = {
    memoizedState: null,
    next: null,
  }

  // 값 계산 및 저장
  const nextValue = nextCreate()
  hook.memoizedState = [nextValue, deps]

  return nextValue
}

function updateMemo(nextCreate, deps) {
  const hook = updateWorkInProgressHook()
  const prevState = hook.memoizedState

  if (prevState !== null && deps !== null) {
    const prevDeps = prevState[1]

    // 의존성 비교
    if (areHookInputsEqual(deps, prevDeps)) {
      return prevState[0]  // 캐시된 값 반환
    }
  }

  // 재계산
  const nextValue = nextCreate()
  hook.memoizedState = [nextValue, deps]
  return nextValue
}
```

### useCallback은 useMemo의 특수 케이스

```javascript
function mountCallback(callback, deps) {
  const hook = {
    memoizedState: [callback, deps],
    next: null,
  }
  return callback
}

function updateCallback(callback, deps) {
  const hook = updateWorkInProgressHook()
  const prevState = hook.memoizedState

  if (prevState !== null && deps !== null) {
    if (areHookInputsEqual(deps, prevState[1])) {
      return prevState[0]  // 캐시된 함수 반환
    }
  }

  hook.memoizedState = [callback, deps]
  return callback
}

// useCallback(fn, deps)는 useMemo(() => fn, deps)와 동일
```

---

## useContext 내부 동작

### Context 읽기

```javascript
function readContext(context) {
  // 현재 Provider에서 값 읽기
  const value = isPrimaryRenderer
    ? context._currentValue
    : context._currentValue2

  // 의존성 추가 (Context 변경 시 리렌더링)
  if (lastContextDependency === null) {
    currentlyRenderingFiber.dependencies = {
      lanes: NoLanes,
      firstContext: { context, next: null },
    }
  } else {
    lastContextDependency = lastContextDependency.next = {
      context,
      next: null,
    }
  }

  return value
}
```

### Provider 값 변경 시

```javascript
function propagateContextChange(workInProgress, context, renderLanes) {
  // Fiber 트리 순회
  let fiber = workInProgress.child

  while (fiber !== null) {
    // 이 context를 사용하는 컴포넌트 찾기
    const dependencies = fiber.dependencies

    if (dependencies !== null) {
      let dependency = dependencies.firstContext

      while (dependency !== null) {
        if (dependency.context === context) {
          // 리렌더링 스케줄
          scheduleWorkOnFiber(fiber, renderLanes)
          break
        }
        dependency = dependency.next
      }
    }

    fiber = fiber.sibling || fiber.return
  }
}
```

---

## useReducer 내부 동작

### useState는 useReducer의 특수 케이스

```javascript
// useState 내부 구현
function mountState(initialState) {
  return mountReducer(basicStateReducer, initialState)
}

function basicStateReducer(state, action) {
  return typeof action === 'function' ? action(state) : action
}

// useReducer
function mountReducer(reducer, initialArg, init) {
  const hook = {
    memoizedState: init !== undefined ? init(initialArg) : initialArg,
    queue: {
      pending: null,
      dispatch: null,
      lastRenderedReducer: reducer,
      lastRenderedState: initialState,
    },
    next: null,
  }

  const dispatch = dispatchReducerAction.bind(null, currentlyRenderingFiber, hook.queue)
  hook.queue.dispatch = dispatch

  return [hook.memoizedState, dispatch]
}
```

---

## 의존성 배열 비교

### areHookInputsEqual

```javascript
function areHookInputsEqual(nextDeps, prevDeps) {
  if (prevDeps === null) {
    return false
  }

  // 길이 비교
  if (nextDeps.length !== prevDeps.length) {
    console.warn('의존성 배열 길이가 변경됨')
  }

  // 각 요소 비교 (Object.is 사용)
  for (let i = 0; i < prevDeps.length && i < nextDeps.length; i++) {
    if (Object.is(nextDeps[i], prevDeps[i])) {
      continue
    }
    return false
  }

  return true
}
```

### Object.is vs ===

```javascript
// Object.is가 다른 경우
Object.is(NaN, NaN)   // true (=== 는 false)
Object.is(0, -0)      // false (=== 는 true)

// React에서의 의미
const [state, setState] = useState(NaN)
setState(NaN)  // 리렌더링 안 됨 (같은 값으로 판단)
```

---

## 커스텀 Hook의 동작

### 커스텀 Hook은 그냥 함수

```javascript
// 커스텀 Hook
function useCounter(initial = 0) {
  const [count, setCount] = useState(initial)
  const increment = useCallback(() => setCount(c => c + 1), [])
  return { count, increment }
}

// 컴포넌트에서 호출
function Component() {
  const { count, increment } = useCounter(0)
  // useCounter 내부의 useState, useCallback이
  // 이 컴포넌트의 Hook 배열에 추가됨
}

// Hooks 배열:
// [0, dispatch]  ← useState from useCounter
// [callback, []] ← useCallback from useCounter
```

### 여러 번 호출해도 독립적

```javascript
function Component() {
  const counter1 = useCounter(0)   // hooks[0], hooks[1]
  const counter2 = useCounter(10)  // hooks[2], hooks[3]

  // 각각 독립적인 상태
  counter1.count  // 0
  counter2.count  // 10
}
```

---

## 실전 이해

### 클로저와 stale closure

```javascript
function Component() {
  const [count, setCount] = useState(0)

  useEffect(() => {
    const id = setInterval(() => {
      console.log(count)  // 항상 0! (클로저가 캡처한 값)
    }, 1000)
    return () => clearInterval(id)
  }, [])  // 빈 의존성: 마운트 시 한 번만 실행

  return <button onClick={() => setCount(c => c + 1)}>+</button>
}

// 해결 1: 의존성에 추가
useEffect(() => {
  const id = setInterval(() => {
    console.log(count)  // 최신 count
  }, 1000)
  return () => clearInterval(id)
}, [count])  // count가 바뀔 때마다 재설정

// 해결 2: ref 사용
const countRef = useRef(count)
countRef.current = count

useEffect(() => {
  const id = setInterval(() => {
    console.log(countRef.current)  // 항상 최신 값
  }, 1000)
  return () => clearInterval(id)
}, [])
```

### 무한 루프 방지

```javascript
// Bad: 무한 루프
function Component() {
  const [data, setData] = useState([])

  useEffect(() => {
    setData([...data, newItem])  // data 변경 → effect 재실행 → data 변경...
  }, [data])
}

// Good: 함수형 업데이트
function Component() {
  const [data, setData] = useState([])

  useEffect(() => {
    setData(prev => [...prev, newItem])  // prev 사용, data 의존성 불필요
  }, [])
}
```

---

## 요약

### Hooks 규칙의 이유

```
1. 최상위에서만 호출
   → Hook은 순서(인덱스)로 식별됨
   → 조건문/반복문 안에서 호출하면 순서 어긋남

2. React 함수 내에서만 호출
   → Fiber와 연결되어야 상태 저장 가능
   → 일반 함수에서는 Fiber가 없음
```

### Hook 타입별 저장 데이터

```javascript
// useState
hook.memoizedState = value

// useEffect
hook.memoizedState = { create, destroy, deps }

// useRef
hook.memoizedState = { current: value }

// useMemo
hook.memoizedState = [value, deps]

// useCallback
hook.memoizedState = [callback, deps]
```

### 렌더링 흐름

```
렌더 시작
    ↓
currentIndex = 0
    ↓
Hook 1 호출 → hooks[0] 읽기/쓰기
    ↓
Hook 2 호출 → hooks[1] 읽기/쓰기
    ↓
...
    ↓
렌더 완료
```

---

## 다음 단계

[06-built-in-hooks.md](./06-built-in-hooks.md)에서 내장 Hooks의 사용법을 자세히 알아봅니다.
