# Virtual DOM과 재조정 (Reconciliation)

React의 핵심 개념인 Virtual DOM과 재조정 알고리즘을 이해합니다.

---

## Virtual DOM이란?

### 실제 DOM의 문제

```javascript
// DOM 조작은 비용이 큼
const element = document.getElementById('app')
element.innerHTML = '<div>New Content</div>'  // 리플로우, 리페인트 발생

// 여러 번 조작하면 더 비쌈
element.style.width = '100px'   // 리플로우
element.style.height = '100px'  // 리플로우
element.style.color = 'red'     // 리페인트
```

**DOM 조작이 비싼 이유:**
1. 브라우저가 레이아웃을 다시 계산 (리플로우)
2. 화면을 다시 그림 (리페인트)
3. JavaScript ↔ DOM 통신 오버헤드

### Virtual DOM의 해결책

```
[JavaScript 객체]     [비교/계산]      [최소 DOM 업데이트]
     (빠름)              (빠름)              (최소화)
       ↓                   ↓                    ↓
  Virtual DOM  →  Diffing Algorithm  →  Real DOM Patch
```

Virtual DOM은 **실제 DOM의 가벼운 복사본**입니다:

```javascript
// Virtual DOM은 이런 형태의 JavaScript 객체
const vdom = {
  type: 'div',
  props: {
    className: 'container',
    children: [
      {
        type: 'h1',
        props: {
          children: 'Hello'
        }
      },
      {
        type: 'p',
        props: {
          children: 'World'
        }
      }
    ]
  }
}
```

---

## React Element

### JSX와 React Element

```tsx
// JSX
const element = <div className="box">Hello</div>

// 변환 결과 (React.createElement)
const element = React.createElement(
  'div',
  { className: 'box' },
  'Hello'
)

// 실제 생성되는 객체 (React Element)
const element = {
  $$typeof: Symbol.for('react.element'),
  type: 'div',
  props: {
    className: 'box',
    children: 'Hello'
  },
  key: null,
  ref: null,
}
```

### 컴포넌트의 Element

```tsx
function Welcome({ name }) {
  return <h1>Hello, {name}</h1>
}

// 사용
const element = <Welcome name="World" />

// 생성되는 Element
const element = {
  type: Welcome,  // 함수 참조
  props: {
    name: 'World'
  }
}

// React가 Welcome을 호출하면
const result = {
  type: 'h1',
  props: {
    children: 'Hello, World'
  }
}
```

---

## 재조정 (Reconciliation)

### 재조정이란?

상태가 변경되면:
1. 새로운 Virtual DOM 트리 생성
2. 이전 트리와 비교 (Diffing)
3. 변경된 부분만 실제 DOM에 반영

```tsx
// 상태 변경 전
<div>
  <h1>Count: 0</h1>
  <button>+1</button>
</div>

// 상태 변경 후
<div>
  <h1>Count: 1</h1>    {/* 이 텍스트만 변경 */}
  <button>+1</button>
</div>

// 실제 DOM 업데이트
// h1의 텍스트 노드만 "Count: 0" → "Count: 1"로 변경
```

### Diffing 알고리즘

완전한 트리 비교는 O(n³) 복잡도입니다. React는 두 가지 가정으로 O(n)으로 줄입니다:

**가정 1: 다른 타입은 다른 트리**

```tsx
// 타입이 다르면 전체 서브트리 교체
// Before
<div>
  <Counter />
</div>

// After
<span>
  <Counter />
</span>

// div → span: Counter 언마운트 후 새로 마운트
```

**가정 2: key로 동일 요소 식별**

```tsx
// key가 없으면 순서로 비교
// Before
<ul>
  <li>A</li>
  <li>B</li>
</ul>

// After (앞에 추가)
<ul>
  <li>Z</li>  {/* 새로 추가 */}
  <li>A</li>
  <li>B</li>
</ul>

// React는 이렇게 이해함:
// 1. 첫 번째 li: "A" → "Z" (변경)
// 2. 두 번째 li: "B" → "A" (변경)
// 3. 세 번째 li: 없음 → "B" (추가)
// → 3개 모두 변경됨 (비효율!)
```

```tsx
// key가 있으면 정확히 추적
// Before
<ul>
  <li key="a">A</li>
  <li key="b">B</li>
</ul>

// After
<ul>
  <li key="z">Z</li>  {/* 새로 추가 */}
  <li key="a">A</li>  {/* 이동만 */}
  <li key="b">B</li>  {/* 이동만 */}
</ul>

// React는 이렇게 이해함:
// 1. key="z": 새로 추가
// 2. key="a": 그대로 (위치만 변경)
// 3. key="b": 그대로 (위치만 변경)
// → 1개만 추가 (효율!)
```

---

## Key의 중요성

### 왜 key가 필요한가?

```tsx
// Bad: index를 key로 사용
{items.map((item, index) => (
  <Item key={index} data={item} />
))}

// 문제 상황: 첫 번째 항목 삭제
// Before: [A(key=0), B(key=1), C(key=2)]
// After:  [B(key=0), C(key=1)]
//
// React가 보기에:
// - key=0: A → B (업데이트)
// - key=1: B → C (업데이트)
// - key=2: 삭제
//
// 실제로 원하는 것:
// - key=0(A): 삭제
// - key=1(B), key=2(C): 그대로
```

### 올바른 key 사용

```tsx
// Good: 고유한 식별자 사용
{items.map(item => (
  <Item key={item.id} data={item} />
))}

// Good: 고유한 조합 사용 (id가 없을 때)
{items.map(item => (
  <Item key={`${item.name}-${item.date}`} data={item} />
))}
```

### key 관련 흔한 실수

```tsx
// Bad: 랜덤 key (매 렌더마다 새로운 key)
{items.map(item => (
  <Item key={Math.random()} data={item} />  // 매번 재생성!
))}

// Bad: 불안정한 key
{items.map(item => (
  <Item key={Date.now()} data={item} />  // 동일한 key 중복!
))}

// Bad: 객체를 key로 (문자열로 변환됨)
{items.map(item => (
  <Item key={item} data={item} />  // [object Object]
))}
```

---

## 재조정 예시

### 같은 타입의 DOM 요소

```tsx
// Before
<div className="before" title="old" />

// After
<div className="after" title="old" />

// React 동작:
// 1. 같은 div 유지
// 2. className만 변경: "before" → "after"
// 3. title은 그대로
```

### 같은 타입의 컴포넌트

```tsx
// Before
<Counter count={1} />

// After
<Counter count={2} />

// React 동작:
// 1. 같은 Counter 인스턴스 유지 (상태 보존)
// 2. props만 업데이트
// 3. 리렌더링 트리거
```

### 다른 타입의 요소

```tsx
// Before
<div>
  <Counter />
</div>

// After
<section>
  <Counter />
</section>

// React 동작:
// 1. div 언마운트 (Counter도 언마운트, 상태 손실)
// 2. section 마운트 (Counter도 새로 마운트)
```

### 자식 리스트

```tsx
// Before
<ul>
  <li>first</li>
  <li>second</li>
</ul>

// After (끝에 추가)
<ul>
  <li>first</li>
  <li>second</li>
  <li>third</li>
</ul>

// React 동작 (key 없이도 효율적):
// 1. first: 그대로
// 2. second: 그대로
// 3. third: 추가
```

```tsx
// After (앞에 추가)
<ul>
  <li>third</li>
  <li>first</li>
  <li>second</li>
</ul>

// key 없으면:
// 1. first → third (변경)
// 2. second → first (변경)
// 3. (없음) → second (추가)
// → 모든 li 업데이트

// key 있으면:
// 1. third: 추가
// 2. first, second: 이동만
// → 1개만 추가
```

---

## 실전 최적화

### 컴포넌트 위치 유지

```tsx
// Bad: 조건부로 다른 위치
function App({ isAdmin }) {
  return (
    <div>
      {isAdmin && <AdminPanel />}
      <UserProfile />  {/* isAdmin 변경 시 재마운트 */}
    </div>
  )
}

// Good: 위치 고정
function App({ isAdmin }) {
  return (
    <div>
      {isAdmin ? <AdminPanel /> : null}
      <UserProfile />  {/* 항상 두 번째 위치 */}
    </div>
  )
}

// Better: key로 명시적 구분
function App({ isAdmin }) {
  return (
    <div>
      {isAdmin && <AdminPanel />}
      <UserProfile key="profile" />  {/* key로 식별 */}
    </div>
  )
}
```

### 상태 리셋에 key 활용

```tsx
// key를 변경하면 컴포넌트가 재마운트됨
function App() {
  const [userId, setUserId] = useState(1)

  return (
    // userId 변경 시 Profile 완전 리셋
    <Profile key={userId} userId={userId} />
  )
}

// 폼 초기화에 유용
function EditForm({ recordId }) {
  // recordId 변경 시 폼 상태 초기화
  return <Form key={recordId} initialData={...} />
}
```

### 불필요한 래퍼 제거

```tsx
// Bad: 불필요한 중첩
function List({ items }) {
  return (
    <div>
      <div>
        {items.map(item => (
          <div key={item.id}>
            <Item data={item} />
          </div>
        ))}
      </div>
    </div>
  )
}

// Good: Fragment 사용
function List({ items }) {
  return (
    <>
      {items.map(item => (
        <Item key={item.id} data={item} />
      ))}
    </>
  )
}
```

---

## 요약

### Virtual DOM

```
JavaScript 객체로 UI 표현
    ↓
상태 변경 시 새 Virtual DOM 생성
    ↓
이전과 비교 (Diffing)
    ↓
최소한의 DOM 업데이트
```

### 재조정 규칙

1. **타입이 다르면**: 전체 서브트리 교체
2. **타입이 같으면**: 속성만 업데이트
3. **리스트는 key로**: 요소 식별 및 추적

### Key 사용법

```tsx
// Good
<Item key={item.id} />           // 고유 ID
<Item key={`${a}-${b}`} />       // 고유 조합

// Bad
<Item key={index} />             // 순서 변경 시 문제
<Item key={Math.random()} />     // 매번 재생성
```

### 최적화 팁

```tsx
// 위치 유지
{condition ? <A /> : null}
<B />  // 항상 같은 위치

// 상태 리셋
<Component key={resetKey} />

// 불필요한 래퍼 제거
<>{children}</>
```

---

## 다음 단계

[02-fiber-architecture.md](./02-fiber-architecture.md)에서 React의 Fiber 아키텍처를 알아봅니다.
