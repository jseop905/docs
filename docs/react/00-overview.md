# React 동작 원리 가이드

React의 내부 동작 원리와 Hooks를 깊이 있게 다루는 문서입니다.

---

## 이 문서의 목적

- React가 **왜** 그렇게 동작하는지 이해
- 성능 문제를 **근본적으로** 해결할 수 있는 지식
- Hooks 규칙이 **왜** 존재하는지 파악
- 디버깅 시 **어디서** 문제가 발생했는지 추적 가능

---

## 문서 구성

| 파일 | 주제 | 난이도 |
|------|------|--------|
| 01-virtual-dom.md | Virtual DOM과 재조정 | 초급 |
| 02-fiber-architecture.md | Fiber 아키텍처 | 중급 |
| 03-rendering-process.md | 렌더링 과정 | 중급 |
| 04-batch-update.md | 배치 업데이트와 동시성 | 중급 |
| 05-hooks-internals.md | Hooks 내부 동작 | 고급 |
| 06-built-in-hooks.md | 내장 Hooks 가이드 | 초급 |
| 07-custom-hooks.md | 커스텀 Hooks 패턴 | 중급 |
| 08-performance.md | 성능 최적화 | 중급 |
| 09-common-patterns.md | 실전 패턴 | 중급 |

---

## 권장 학습 순서

### 입문자 (React 기본은 아는 분)

```
06-built-in-hooks.md    # 내장 Hooks 제대로 이해
    ↓
07-custom-hooks.md      # 커스텀 Hooks 작성법
    ↓
01-virtual-dom.md       # Virtual DOM 개념
    ↓
08-performance.md       # 성능 최적화 기법
```

### 중급자 (실무 경험 있는 분)

```
01-virtual-dom.md       # Virtual DOM 복습
    ↓
02-fiber-architecture.md # Fiber 이해
    ↓
03-rendering-process.md  # 렌더링 과정
    ↓
04-batch-update.md       # 배치와 동시성
    ↓
05-hooks-internals.md    # Hooks 내부 원리
```

### 고급자 (깊은 이해가 필요한 분)

```
전체 순서대로 학습
01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09
```

---

## 핵심 개념 미리보기

### 1. Virtual DOM

```
실제 DOM 조작은 비싸다
    ↓
메모리에 가상 DOM을 유지
    ↓
변경사항을 비교 (Diffing)
    ↓
최소한의 실제 DOM만 업데이트
```

### 2. Fiber

```
React 16 이전: Stack Reconciler
- 동기적, 중단 불가능
- 큰 업데이트 시 프레임 드랍

React 16 이후: Fiber Reconciler
- 작업을 작은 단위로 분할
- 우선순위에 따라 중단/재개
- 부드러운 사용자 경험
```

### 3. 렌더링 2단계

```
Render Phase (렌더 단계)
- 컴포넌트 호출
- Virtual DOM 생성
- Diff 계산
- 중단 가능, 순수해야 함

Commit Phase (커밋 단계)
- 실제 DOM 업데이트
- useLayoutEffect 실행
- useEffect 스케줄링
- 중단 불가능
```

### 4. Hooks 규칙의 이유

```tsx
// Hooks는 배열로 관리됨
// 첫 번째 렌더: [state1, state2, effect1]
// 두 번째 렌더: [state1, state2, effect1]  ← 같은 순서여야 함

// Bad: 조건문 안에서 Hook 사용
if (condition) {
  const [value, setValue] = useState(0)  // 순서가 바뀔 수 있음!
}

// Good: 조건은 Hook 안에서
const [value, setValue] = useState(0)
useEffect(() => {
  if (condition) {
    // 조건부 로직
  }
}, [condition])
```

### 5. 배치 업데이트

```tsx
// React 18: 자동 배칭
function handleClick() {
  setCount(c => c + 1)  // 리렌더 X
  setFlag(f => !f)      // 리렌더 X
  // 여기서 한 번만 리렌더
}

// 비동기에서도 배칭됨 (React 18)
setTimeout(() => {
  setCount(c => c + 1)  // 리렌더 X
  setFlag(f => !f)      // 리렌더 X
  // 한 번만 리렌더
}, 1000)
```

---

## 자주 하는 오해

### "Virtual DOM이 빠르다"

> Virtual DOM은 실제 DOM보다 빠른 게 아니라, **충분히 빠르면서 선언적 UI를 가능**하게 합니다.

실제로 수동으로 최적화된 DOM 조작이 더 빠를 수 있습니다. 하지만 Virtual DOM은:
- 복잡한 UI 상태 관리를 단순화
- 예측 가능한 성능
- 개발 생산성 향상

### "useEffect는 생명주기 메서드 대체"

> useEffect는 생명주기가 아니라 **동기화(synchronization)** 메커니즘입니다.

```tsx
// 잘못된 사고: "마운트될 때 데이터 가져오기"
useEffect(() => {
  fetchData()
}, [])

// 올바른 사고: "컴포넌트를 외부 시스템과 동기화"
useEffect(() => {
  const unsubscribe = subscribe(userId)
  return () => unsubscribe()
}, [userId])
```

### "리렌더링은 나쁘다"

> 리렌더링 자체는 문제가 아닙니다. **불필요한 리렌더링**이 문제입니다.

React는 리렌더링에 최적화되어 있습니다:
- Virtual DOM diff는 빠름
- 실제 DOM 변경이 없으면 비용 없음
- 무분별한 memo/useMemo가 오히려 해로울 수 있음

---

## 버전별 주요 변화

### React 16 (2017)
- Fiber 아키텍처 도입
- Error Boundaries
- Portals

### React 16.8 (2019)
- **Hooks 도입**
- 함수형 컴포넌트에서 상태 관리 가능

### React 17 (2020)
- 점진적 업그레이드 지원
- 이벤트 위임 변경 (document → root)
- JSX Transform 개선

### React 18 (2022)
- **동시성 모드 (Concurrent Mode)**
- 자동 배칭
- Transitions (useTransition, useDeferredValue)
- Suspense 개선
- useId, useSyncExternalStore

### React 19 (2024)
- React Compiler (자동 메모이제이션)
- Server Components 안정화
- Actions (useFormStatus, useFormState)
- use() Hook

---

## 추천 리소스

### 공식 문서
- [React 공식 문서](https://react.dev)
- [React 18 변경사항](https://react.dev/blog/2022/03/29/react-v18)

### 심화 학습
- [A Cartoon Intro to Fiber](https://www.youtube.com/watch?v=ZCuYPiUIONs)
- [Inside Fiber: in-depth overview](https://indepth.dev/posts/1008/inside-fiber-in-depth-overview-of-the-new-reconciliation-algorithm-in-react)
- [useEffect 완벽 가이드 (Dan Abramov)](https://overreacted.io/a-complete-guide-to-useeffect/)

---

## 다음 단계

[01-virtual-dom.md](./01-virtual-dom.md)에서 Virtual DOM의 개념과 동작 원리를 알아봅니다.
