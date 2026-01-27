# 조건부 타입 (Conditional Types)

**조건에 따라 다른 타입**을 선택하는 기능입니다. 삼항 연산자처럼 동작합니다.

---

## 기본 문법

```tsx
T extends U ? X : Y
```

- `T`가 `U`에 할당 가능하면 → `X` 타입
- 그렇지 않으면 → `Y` 타입

---

## 기본 예시

### 간단한 조건부 타입

```tsx
type IsString<T> = T extends string ? true : false

type A = IsString<string>   // true
type B = IsString<number>   // false
type C = IsString<'hello'>  // true (리터럴도 string에 할당 가능)
```

### null 체크

```tsx
type IsNull<T> = T extends null ? true : false

type A = IsNull<null>      // true
type B = IsNull<string>    // false
type C = IsNull<undefined> // false
```

### 배열 체크

```tsx
type IsArray<T> = T extends any[] ? true : false

type A = IsArray<string[]>   // true
type B = IsArray<number>     // false
type C = IsArray<[1, 2, 3]>  // true (튜플도 배열)
```

---

## 타입 추출 (infer)

조건부 타입에서 **타입을 추출**할 때 사용합니다.

### 기본 사용

```tsx
// 배열 요소 타입 추출
type ElementType<T> = T extends (infer U)[] ? U : never

type A = ElementType<string[]>   // string
type B = ElementType<number[]>   // number
type C = ElementType<string>     // never (배열 아님)
```

### Promise 내부 타입 추출

```tsx
type UnwrapPromise<T> = T extends Promise<infer U> ? U : T

type A = UnwrapPromise<Promise<string>>  // string
type B = UnwrapPromise<Promise<number>>  // number
type C = UnwrapPromise<string>           // string (Promise 아니면 그대로)

// 중첩 Promise도 처리
type DeepUnwrap<T> = T extends Promise<infer U> ? DeepUnwrap<U> : T

type D = DeepUnwrap<Promise<Promise<string>>>  // string
```

### 함수 반환 타입 추출

```tsx
type GetReturnType<T> = T extends (...args: any[]) => infer R ? R : never

type A = GetReturnType<() => string>        // string
type B = GetReturnType<(x: number) => void> // void
type C = GetReturnType<string>              // never

// TypeScript 내장: ReturnType<T>와 동일
```

### 함수 파라미터 타입 추출

```tsx
type GetParameters<T> = T extends (...args: infer P) => any ? P : never

type A = GetParameters<(a: string, b: number) => void>  // [string, number]
type B = GetParameters<() => void>                       // []

// 첫 번째 파라미터만
type FirstParam<T> = T extends (first: infer F, ...rest: any[]) => any
  ? F
  : never

type C = FirstParam<(a: string, b: number) => void>  // string
```

---

## 분배 조건부 타입 (Distributive)

유니온 타입에 조건부 타입을 적용하면 **각 멤버에 분배**됩니다.

### 기본 동작

```tsx
type ToArray<T> = T extends any ? T[] : never

// 유니온에 적용하면 분배됨
type A = ToArray<string | number>
// = ToArray<string> | ToArray<number>
// = string[] | number[]

// 분배 없이 하려면 대괄호로 감싸기
type ToArrayNonDist<T> = [T] extends [any] ? T[] : never

type B = ToArrayNonDist<string | number>
// = (string | number)[]
```

### Exclude 구현 원리

```tsx
// TypeScript 내장 Exclude 구현
type MyExclude<T, U> = T extends U ? never : T

type A = MyExclude<'a' | 'b' | 'c', 'a'>
// 분배:
// = ('a' extends 'a' ? never : 'a') | ('b' extends 'a' ? never : 'b') | ('c' extends 'a' ? never : 'c')
// = never | 'b' | 'c'
// = 'b' | 'c'
```

### Extract 구현 원리

```tsx
// TypeScript 내장 Extract 구현
type MyExtract<T, U> = T extends U ? T : never

type A = MyExtract<'a' | 'b' | 'c', 'a' | 'b'>
// = 'a' | 'b'
```

---

## 실전 패턴

### NonNullable 구현

```tsx
type MyNonNullable<T> = T extends null | undefined ? never : T

type A = MyNonNullable<string | null | undefined>
// = string
```

### 함수만 추출

```tsx
type FunctionKeys<T> = {
  [K in keyof T]: T[K] extends (...args: any[]) => any ? K : never
}[keyof T]

interface User {
  id: string
  name: string
  getName: () => string
  setName: (name: string) => void
}

type UserFunctions = FunctionKeys<User>
// = 'getName' | 'setName'
```

### 특정 타입의 키만 추출

```tsx
type KeysOfType<T, V> = {
  [K in keyof T]: T[K] extends V ? K : never
}[keyof T]

interface User {
  id: string
  name: string
  age: number
  active: boolean
}

type StringKeys = KeysOfType<User, string>   // 'id' | 'name'
type NumberKeys = KeysOfType<User, number>   // 'age'
type BooleanKeys = KeysOfType<User, boolean> // 'active'
```

### 옵셔널 키만 추출

```tsx
type OptionalKeys<T> = {
  [K in keyof T]-?: undefined extends T[K] ? K : never
}[keyof T]

interface Config {
  required: string
  optional?: number
  alsoOptional?: boolean
}

type Optional = OptionalKeys<Config>
// = 'optional' | 'alsoOptional'
```

### 조건부 반환 타입

```tsx
type ApiResponse<T, E = Error> = {
  success: true
  data: T
} | {
  success: false
  error: E
}

// 성공 응답에서 데이터 추출
type ExtractData<T> = T extends { success: true; data: infer D } ? D : never

type UserResponse = ApiResponse<User>
type UserData = ExtractData<UserResponse>  // User
```

---

## 고급 패턴

### 재귀 조건부 타입

```tsx
// 깊은 Partial
type DeepPartial<T> = T extends object
  ? { [K in keyof T]?: DeepPartial<T[K]> }
  : T

interface NestedConfig {
  server: {
    host: string
    port: number
    ssl: {
      enabled: boolean
      cert: string
    }
  }
}

type PartialConfig = DeepPartial<NestedConfig>
// 모든 중첩 속성이 선택적으로 변환됨
```

### 깊은 Readonly

```tsx
type DeepReadonly<T> = T extends (infer U)[]
  ? DeepReadonlyArray<U>
  : T extends object
    ? DeepReadonlyObject<T>
    : T

interface DeepReadonlyArray<T> extends ReadonlyArray<DeepReadonly<T>> {}

type DeepReadonlyObject<T> = {
  readonly [K in keyof T]: DeepReadonly<T[K]>
}
```

### 경로 기반 타입 추출

```tsx
// 객체에서 경로로 타입 추출 (간단 버전)
type Get<T, K> = K extends keyof T
  ? T[K]
  : K extends `${infer Key}.${infer Rest}`
    ? Key extends keyof T
      ? Get<T[Key], Rest>
      : never
    : never

interface Config {
  server: {
    host: string
    port: number
  }
  database: {
    url: string
  }
}

type ServerHost = Get<Config, 'server.host'>  // string
type DbUrl = Get<Config, 'database.url'>      // string
```

---

## 유틸리티 타입 만들기

### Awaited 직접 구현

```tsx
type MyAwaited<T> = T extends null | undefined
  ? T
  : T extends object & { then(onfulfilled: infer F): any }
    ? F extends (value: infer V) => any
      ? MyAwaited<V>
      : never
    : T

type A = MyAwaited<Promise<string>>           // string
type B = MyAwaited<Promise<Promise<number>>>  // number
```

### Flatten (배열 평탄화)

```tsx
type Flatten<T> = T extends (infer U)[]
  ? Flatten<U>
  : T

type A = Flatten<string[][]>   // string
type B = Flatten<number[][][]> // number
type C = Flatten<string>       // string
```

### UnionToIntersection

```tsx
// 유니온을 인터섹션으로 변환 (고급)
type UnionToIntersection<U> = (
  U extends any ? (k: U) => void : never
) extends (k: infer I) => void
  ? I
  : never

type A = UnionToIntersection<{ a: string } | { b: number }>
// = { a: string } & { b: number }
```

---

## 내장 조건부 타입

TypeScript가 제공하는 조건부 유틸리티 타입들:

```tsx
// Exclude: T에서 U에 할당 가능한 타입 제외
type A = Exclude<'a' | 'b' | 'c', 'a'>  // 'b' | 'c'

// Extract: T에서 U에 할당 가능한 타입만 추출
type B = Extract<'a' | 'b' | 'c', 'a' | 'b'>  // 'a' | 'b'

// NonNullable: null과 undefined 제외
type C = NonNullable<string | null>  // string

// ReturnType: 함수 반환 타입
type D = ReturnType<() => string>  // string

// Parameters: 함수 파라미터 타입
type E = Parameters<(a: string) => void>  // [string]

// Awaited: Promise 내부 타입
type F = Awaited<Promise<string>>  // string

// InstanceType: 클래스 인스턴스 타입
type G = InstanceType<typeof Date>  // Date
```

---

## 요약

```tsx
// 기본 조건부 타입
type Check<T> = T extends string ? 'string' : 'other'

// infer로 타입 추출
type ElementOf<T> = T extends (infer U)[] ? U : never

// 분배 조건부 타입
type ToArray<T> = T extends any ? T[] : never  // 유니온에 분배됨

// 분배 방지
type ToArrayNonDist<T> = [T] extends [any] ? T[] : never

// 재귀 조건부 타입
type DeepPartial<T> = T extends object
  ? { [K in keyof T]?: DeepPartial<T[K]> }
  : T
```
