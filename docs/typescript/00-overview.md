# TypeScript 심화 가이드

실무에서 자주 사용하는 TypeScript 패턴과 고급 기능을 정리한 문서입니다.

---

## 문서 구조

```
typescript/
├── 00-overview.md              # 현재 문서
├── 01-utility-types.md         # 유틸리티 타입
├── 02-generics.md              # 제네릭
├── 03-type-guards.md           # 타입 가드
├── 04-conditional-types.md     # 조건부 타입
├── 05-mapped-types.md          # 맵드 타입
├── 06-template-literal.md      # 템플릿 리터럴 타입
├── 07-react-patterns.md        # React 타입 패턴
└── 08-common-mistakes.md       # 흔한 실수
```

---

## 왜 TypeScript 심화가 필요한가?

### 기본 타입만으로는 부족한 상황들

```tsx
// 1. API 응답 타입을 일부만 사용하고 싶을 때
interface User {
  id: string
  name: string
  email: string
  password: string  // 이건 프론트엔드에서 필요 없음
  createdAt: string
  updatedAt: string
}

// Pick, Omit 없이는?
interface UserDisplay {
  id: string
  name: string
  email: string
}
// → 중복 코드, 동기화 문제

// 2. 함수가 여러 타입을 받아야 할 때
function first(arr: number[]): number  // 숫자 배열
function first(arr: string[]): string  // 문자 배열
function first(arr: any[]): any        // 복잡해짐...

// → 제네릭으로 해결

// 3. 타입에 따라 다른 동작이 필요할 때
function processValue(value: string | number) {
  // value.toUpperCase()  // Error! number에는 없음
  // → 타입 가드로 해결
}
```

---

## 학습 순서

### 1단계: 필수 (당장 쓸 수 있는 것)

1. **[유틸리티 타입](./01-utility-types.md)** - `Pick`, `Omit`, `Partial` 등
2. **[제네릭](./02-generics.md)** - 재사용 가능한 타입
3. **[타입 가드](./03-type-guards.md)** - 타입 좁히기

### 2단계: 중급 (더 정교한 타입)

4. **[조건부 타입](./04-conditional-types.md)** - `extends`, `infer`
5. **[맵드 타입](./05-mapped-types.md)** - 타입 변환

### 3단계: 고급 (라이브러리 수준)

6. **[템플릿 리터럴 타입](./06-template-literal.md)** - 문자열 타입 조작

### 실전 적용

7. **[React 패턴](./07-react-patterns.md)** - 컴포넌트, 훅 타입
8. **[흔한 실수](./08-common-mistakes.md)** - 안티패턴과 해결책

---

## 핵심 개념 미리보기

### 타입 vs 인터페이스

```tsx
// 대부분의 경우 둘 다 가능
type UserType = {
  name: string
  age: number
}

interface UserInterface {
  name: string
  age: number
}

// 차이점
// 1. 확장 방식
type Extended = UserType & { email: string }
interface ExtendedInterface extends UserInterface {
  email: string
}

// 2. interface는 선언 병합 가능
interface User {
  name: string
}
interface User {
  age: number
}
// → User는 { name: string; age: number }

// 3. type만 가능한 것
type StringOrNumber = string | number  // 유니온
type Tuple = [string, number]          // 튜플
type Primitive = string                // 별칭

// 권장: 객체는 interface, 나머지는 type
```

### 타입 단언 (Type Assertion)

```tsx
// as 키워드
const input = document.getElementById('name') as HTMLInputElement
input.value = 'Hello'

// 주의: 타입 단언은 타입 검사를 우회함
const user = {} as User  // 위험! 실제로는 빈 객체

// 더 안전한 방법: 타입 가드 사용
const input = document.getElementById('name')
if (input instanceof HTMLInputElement) {
  input.value = 'Hello'  // 안전!
}
```

### as const

```tsx
// 일반 객체 - 넓은 타입
const config = {
  endpoint: '/api',
  timeout: 5000,
}
// 타입: { endpoint: string; timeout: number }

// as const - 좁은 타입 (리터럴)
const config = {
  endpoint: '/api',
  timeout: 5000,
} as const
// 타입: { readonly endpoint: '/api'; readonly timeout: 5000 }

// 배열에도 유용
const colors = ['red', 'green', 'blue'] as const
// 타입: readonly ['red', 'green', 'blue']

type Color = (typeof colors)[number]  // 'red' | 'green' | 'blue'
```

### satisfies (TypeScript 4.9+)

```tsx
// as const와 함께 사용하면 강력함
type Colors = Record<string, [number, number, number]>

// as 사용 - 타입 정보 손실
const colors = {
  red: [255, 0, 0],
  green: [0, 255, 0],
} as Colors
colors.red  // [number, number, number] - 구체적 값 손실

// satisfies 사용 - 타입 검사 + 구체적 타입 유지
const colors = {
  red: [255, 0, 0],
  green: [0, 255, 0],
} satisfies Colors
colors.red  // [255, 0, 0] - 구체적 값 유지!
colors.blue // Error! - 타입 검사도 됨
```

### never 타입

```tsx
// never: 절대 발생하지 않는 타입

// 1. 함수가 절대 반환하지 않음
function throwError(message: string): never {
  throw new Error(message)
}

function infiniteLoop(): never {
  while (true) {}
}

// 2. Exhaustive check (모든 케이스 처리 확인)
type Shape = 'circle' | 'square' | 'triangle'

function getArea(shape: Shape): number {
  switch (shape) {
    case 'circle':
      return Math.PI * 10 * 10
    case 'square':
      return 10 * 10
    case 'triangle':
      return (10 * 10) / 2
    default:
      // shape이 never가 아니면 컴파일 에러
      const _exhaustiveCheck: never = shape
      return _exhaustiveCheck
  }
}

// 나중에 'rectangle'이 추가되면?
// → default에서 컴파일 에러 발생! 처리 누락 방지
```

### unknown vs any

```tsx
// any: 타입 검사 포기 (위험)
let valueAny: any = 'hello'
valueAny.foo.bar  // 런타임 에러, 컴파일은 통과

// unknown: 타입 검사 필수 (안전)
let valueUnknown: unknown = 'hello'
// valueUnknown.foo  // Error! 타입 확인 필요

// 사용하려면 타입 좁히기 필요
if (typeof valueUnknown === 'string') {
  valueUnknown.toUpperCase()  // OK
}

// API 응답 등 외부 데이터에 unknown 권장
async function fetchData(): Promise<unknown> {
  const res = await fetch('/api/data')
  return res.json()
}

const data = await fetchData()
// data.foo  // Error! 타입 검증 필요
```

---

## tsconfig 권장 설정

```json
{
  "compilerOptions": {
    // 엄격 모드 (필수!)
    "strict": true,

    // 추가 엄격 옵션
    "noUncheckedIndexedAccess": true,  // 배열/객체 접근 시 undefined 고려
    "exactOptionalPropertyTypes": true, // optional과 undefined 구분

    // 유용한 옵션
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,

    // 모듈
    "moduleResolution": "bundler",
    "esModuleInterop": true,

    // 경로 별칭
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

### noUncheckedIndexedAccess 예시

```tsx
// noUncheckedIndexedAccess: false (기본)
const arr = [1, 2, 3]
const first = arr[0]  // number

// noUncheckedIndexedAccess: true (권장)
const arr = [1, 2, 3]
const first = arr[0]  // number | undefined
// → 실제로 존재하지 않을 수 있음을 인지

// 안전한 사용
const first = arr[0]
if (first !== undefined) {
  console.log(first * 2)  // OK
}

// 또는
const first = arr[0] ?? 0  // 기본값 제공
```

---

## 다음 단계

[유틸리티 타입](./01-utility-types.md)부터 시작하세요. 가장 자주 쓰이고 바로 적용할 수 있습니다.
