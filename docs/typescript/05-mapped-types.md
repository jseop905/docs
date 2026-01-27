# 맵드 타입 (Mapped Types)

기존 타입의 **모든 속성을 변환**하여 새로운 타입을 만드는 기능입니다.

---

## 기본 문법

```tsx
type MappedType<T> = {
  [K in keyof T]: T[K]
}
```

- `K in keyof T`: T의 모든 키를 순회
- `T[K]`: 해당 키의 값 타입

---

## 기본 예시

### 모든 속성을 옵셔널로

```tsx
type MyPartial<T> = {
  [K in keyof T]?: T[K]
}

interface User {
  id: string
  name: string
  age: number
}

type PartialUser = MyPartial<User>
// {
//   id?: string
//   name?: string
//   age?: number
// }
```

### 모든 속성을 필수로

```tsx
type MyRequired<T> = {
  [K in keyof T]-?: T[K]  // -?는 선택적 제거
}

interface Config {
  host?: string
  port?: number
}

type RequiredConfig = MyRequired<Config>
// {
//   host: string
//   port: number
// }
```

### 모든 속성을 읽기 전용으로

```tsx
type MyReadonly<T> = {
  readonly [K in keyof T]: T[K]
}

interface User {
  id: string
  name: string
}

type ReadonlyUser = MyReadonly<User>
// {
//   readonly id: string
//   readonly name: string
// }
```

### 읽기 전용 제거

```tsx
type Mutable<T> = {
  -readonly [K in keyof T]: T[K]
}

type MutableUser = Mutable<ReadonlyUser>
// {
//   id: string
//   name: string
// }
```

---

## 키 변환 (Key Remapping)

TypeScript 4.1+에서 `as` 절로 키를 변환할 수 있습니다.

### 키 이름 변경

```tsx
// 모든 키에 접두사 추가
type Prefixed<T, P extends string> = {
  [K in keyof T as `${P}${Capitalize<string & K>}`]: T[K]
}

interface User {
  name: string
  age: number
}

type PrefixedUser = Prefixed<User, 'user'>
// {
//   userName: string
//   userAge: number
// }
```

### Getter 타입 생성

```tsx
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K]
}

interface User {
  name: string
  age: number
}

type UserGetters = Getters<User>
// {
//   getName: () => string
//   getAge: () => number
// }
```

### Setter 타입 생성

```tsx
type Setters<T> = {
  [K in keyof T as `set${Capitalize<string & K>}`]: (value: T[K]) => void
}

type UserSetters = Setters<User>
// {
//   setName: (value: string) => void
//   setAge: (value: number) => void
// }
```

### 특정 키 제외

```tsx
type RemoveKind<T> = {
  [K in keyof T as Exclude<K, 'kind'>]: T[K]
}

interface Circle {
  kind: 'circle'
  radius: number
}

type CircleWithoutKind = RemoveKind<Circle>
// {
//   radius: number
// }
```

### 특정 타입의 키만 선택

```tsx
type OnlyStrings<T> = {
  [K in keyof T as T[K] extends string ? K : never]: T[K]
}

interface Mixed {
  name: string
  age: number
  email: string
  active: boolean
}

type StringsOnly = OnlyStrings<Mixed>
// {
//   name: string
//   email: string
// }
```

---

## 실전 패턴

### 이벤트 핸들러 타입

```tsx
type EventHandlers<T> = {
  [K in keyof T as `on${Capitalize<string & K>}`]: (event: T[K]) => void
}

interface Events {
  click: MouseEvent
  focus: FocusEvent
  change: Event
}

type Handlers = EventHandlers<Events>
// {
//   onClick: (event: MouseEvent) => void
//   onFocus: (event: FocusEvent) => void
//   onChange: (event: Event) => void
// }
```

### Nullable 변환

```tsx
type Nullable<T> = {
  [K in keyof T]: T[K] | null
}

interface User {
  name: string
  age: number
}

type NullableUser = Nullable<User>
// {
//   name: string | null
//   age: number | null
// }
```

### Promise 래핑

```tsx
type Promisify<T> = {
  [K in keyof T]: Promise<T[K]>
}

interface UserService {
  getUser: (id: string) => User
  getUsers: () => User[]
}

type AsyncUserService = Promisify<UserService>
// {
//   getUser: Promise<(id: string) => User>
//   getUsers: Promise<() => User[]>
// }
```

### 메서드만 Promisify

```tsx
type PromisifyMethods<T> = {
  [K in keyof T]: T[K] extends (...args: infer A) => infer R
    ? (...args: A) => Promise<R>
    : T[K]
}

interface UserService {
  name: string
  getUser: (id: string) => User
  saveUser: (user: User) => void
}

type AsyncUserService = PromisifyMethods<UserService>
// {
//   name: string
//   getUser: (id: string) => Promise<User>
//   saveUser: (user: User) => Promise<void>
// }
```

---

## Record 구현

```tsx
type MyRecord<K extends keyof any, V> = {
  [P in K]: V
}

// 사용
type StringMap = MyRecord<string, number>
// { [key: string]: number }

type Status = 'pending' | 'approved' | 'rejected'
type StatusLabels = MyRecord<Status, string>
// {
//   pending: string
//   approved: string
//   rejected: string
// }
```

---

## Pick / Omit 구현

### Pick

```tsx
type MyPick<T, K extends keyof T> = {
  [P in K]: T[P]
}

interface User {
  id: string
  name: string
  email: string
  password: string
}

type UserPreview = MyPick<User, 'id' | 'name'>
// {
//   id: string
//   name: string
// }
```

### Omit

```tsx
type MyOmit<T, K extends keyof any> = {
  [P in Exclude<keyof T, K>]: T[P]
}

// 또는 Pick과 Exclude 조합
type MyOmit2<T, K extends keyof any> = Pick<T, Exclude<keyof T, K>>

type SafeUser = MyOmit<User, 'password'>
// {
//   id: string
//   name: string
//   email: string
// }
```

---

## 깊은 맵드 타입 (Deep Mapped Types)

### DeepPartial

```tsx
type DeepPartial<T> = T extends object
  ? { [K in keyof T]?: DeepPartial<T[K]> }
  : T

interface Config {
  server: {
    host: string
    port: number
    ssl: {
      enabled: boolean
      cert: string
    }
  }
  database: {
    url: string
  }
}

type PartialConfig = DeepPartial<Config>
// server, server.host, server.ssl.enabled 등 모두 선택적
```

### DeepReadonly

```tsx
type DeepReadonly<T> = T extends (infer U)[]
  ? ReadonlyArray<DeepReadonly<U>>
  : T extends object
    ? { readonly [K in keyof T]: DeepReadonly<T[K]> }
    : T
```

### DeepRequired

```tsx
type DeepRequired<T> = T extends object
  ? { [K in keyof T]-?: DeepRequired<T[K]> }
  : T
```

---

## 조건부 맵드 타입

### 특정 타입 필터링

```tsx
// 함수가 아닌 속성만
type NonFunctionProperties<T> = {
  [K in keyof T as T[K] extends Function ? never : K]: T[K]
}

interface User {
  id: string
  name: string
  getName: () => string
  setName: (name: string) => void
}

type UserData = NonFunctionProperties<User>
// {
//   id: string
//   name: string
// }
```

### 함수 속성만

```tsx
type FunctionProperties<T> = {
  [K in keyof T as T[K] extends Function ? K : never]: T[K]
}

type UserMethods = FunctionProperties<User>
// {
//   getName: () => string
//   setName: (name: string) => void
// }
```

### 조건부 값 타입 변환

```tsx
// 문자열은 그대로, 숫자는 문자열로
type StringifyNumbers<T> = {
  [K in keyof T]: T[K] extends number ? string : T[K]
}

interface Product {
  name: string
  price: number
  count: number
}

type StringifiedProduct = StringifyNumbers<Product>
// {
//   name: string
//   price: string
//   count: string
// }
```

---

## 인덱스 시그니처와 맵드 타입

```tsx
// 인덱스 시그니처
type Dictionary<T> = {
  [key: string]: T
}

// 맵드 타입으로 특정 키만
type StrictDictionary<K extends string, V> = {
  [P in K]: V
}

type Fruit = 'apple' | 'banana' | 'orange'
type FruitPrices = StrictDictionary<Fruit, number>
// {
//   apple: number
//   banana: number
//   orange: number
// }
```

---

## 실전 예시: API 타입 시스템

```tsx
// 기본 엔티티
interface Entity {
  id: string
  createdAt: Date
  updatedAt: Date
}

interface User extends Entity {
  name: string
  email: string
  role: 'admin' | 'user'
}

// 생성용 타입 (시스템 필드 제외)
type CreateInput<T extends Entity> = Omit<T, keyof Entity>

// 수정용 타입 (부분 업데이트)
type UpdateInput<T extends Entity> = Partial<Omit<T, keyof Entity>>

// 응답 타입 (날짜를 문자열로)
type ApiResponse<T> = {
  [K in keyof T]: T[K] extends Date ? string : T[K]
}

// 사용
type CreateUserInput = CreateInput<User>
// { name: string; email: string; role: 'admin' | 'user' }

type UpdateUserInput = UpdateInput<User>
// { name?: string; email?: string; role?: 'admin' | 'user' }

type UserResponse = ApiResponse<User>
// { id: string; name: string; email: string; role: 'admin' | 'user'; createdAt: string; updatedAt: string }
```

---

## 실전 예시: 폼 상태 타입

```tsx
interface FormField<T> {
  value: T
  error: string | null
  touched: boolean
  dirty: boolean
}

type FormState<T> = {
  [K in keyof T]: FormField<T[K]>
}

interface LoginForm {
  email: string
  password: string
  rememberMe: boolean
}

type LoginFormState = FormState<LoginForm>
// {
//   email: FormField<string>
//   password: FormField<string>
//   rememberMe: FormField<boolean>
// }

// 초기값 생성 헬퍼
function createFormState<T>(values: T): FormState<T> {
  const state = {} as FormState<T>

  for (const key in values) {
    state[key] = {
      value: values[key],
      error: null,
      touched: false,
      dirty: false,
    }
  }

  return state
}
```

---

## 요약

```tsx
// 기본 맵드 타입
type Mapped<T> = { [K in keyof T]: T[K] }

// 수정자
type Partial<T> = { [K in keyof T]?: T[K] }      // 옵셔널 추가
type Required<T> = { [K in keyof T]-?: T[K] }    // 옵셔널 제거
type Readonly<T> = { readonly [K in keyof T]: T[K] }  // readonly 추가
type Mutable<T> = { -readonly [K in keyof T]: T[K] }  // readonly 제거

// 키 리매핑 (as)
type Getters<T> = { [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K] }

// 키 필터링
type StringKeys<T> = { [K in keyof T as T[K] extends string ? K : never]: T[K] }

// 값 타입 변환
type Nullable<T> = { [K in keyof T]: T[K] | null }
```
