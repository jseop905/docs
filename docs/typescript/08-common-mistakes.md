# 흔한 실수와 해결책

TypeScript에서 자주 발생하는 실수와 올바른 해결 방법입니다.

---

## 타입 단언 남용

### 문제: as를 무분별하게 사용

```tsx
// Bad: 타입 단언으로 에러 무시
const user = {} as User
user.name.toUpperCase()  // 런타임 에러! name은 undefined

// Bad: any로 우회
const data = response as any as User
```

### 해결: 타입 가드와 검증 사용

```tsx
// Good: 타입 가드로 검증
function isUser(data: unknown): data is User {
  return (
    typeof data === 'object' &&
    data !== null &&
    'name' in data &&
    typeof (data as User).name === 'string'
  )
}

const data: unknown = await fetchUser()
if (isUser(data)) {
  data.name.toUpperCase()  // 안전!
}

// Good: Zod 등 런타임 검증 라이브러리 사용
import { z } from 'zod'

const UserSchema = z.object({
  name: z.string(),
  email: z.string().email(),
})

const user = UserSchema.parse(data)  // 검증 실패시 에러
```

---

## any 타입 사용

### 문제: any로 타입 체크 우회

```tsx
// Bad: any는 타입 안전성을 완전히 무시
function processData(data: any) {
  return data.foo.bar.baz  // 어떤 에러도 잡지 못함
}

// Bad: any가 전파됨
const result = processData(input)  // result도 any
```

### 해결: unknown과 타입 가드 사용

```tsx
// Good: unknown으로 시작하고 타입 좁히기
function processData(data: unknown) {
  if (typeof data === 'object' && data !== null && 'foo' in data) {
    // 안전하게 접근
  }
}

// Good: 제네릭 사용
function processData<T>(data: T): T {
  return data
}

// Good: 최소한 Record<string, unknown> 사용
function processObject(data: Record<string, unknown>) {
  // 객체인 것은 보장됨
}
```

### any가 필요한 경우

```tsx
// 서드파티 라이브러리 타입이 없을 때
declare module 'untyped-library' {
  const lib: any
  export default lib
}

// 타입 정의가 너무 복잡할 때 (임시로)
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function complexFunction(arg: any): void {
  // TODO: 나중에 타입 추가
}
```

---

## 객체 타입 실수

### 문제: object vs Object vs {}

```tsx
// Bad: 모든 것 허용
let a: {}           // null, undefined 제외 모든 것
let b: Object       // 위와 동일
let c: object       // 원시 타입 제외

a = 'string'        // OK (의도한 게 아닐 수 있음)
a = 123             // OK
a = { foo: 'bar' }  // OK
```

### 해결: 구체적인 타입 사용

```tsx
// Good: 구체적인 타입
interface User {
  name: string
  age: number
}

let user: User = { name: 'John', age: 30 }

// Good: 인덱스 시그니처
let obj: Record<string, unknown> = {}

// Good: 빈 객체가 필요한 경우
type EmptyObject = Record<string, never>
const empty: EmptyObject = {}
```

---

## 배열 타입 실수

### 문제: 빈 배열의 타입 추론

```tsx
// Bad: never[] 추론
const items = []  // never[]
items.push('a')   // Error!

// Bad: 타입이 너무 넓음
const mixed = [1, 'a', true]  // (string | number | boolean)[]
```

### 해결: 명시적 타입 선언

```tsx
// Good: 타입 명시
const items: string[] = []
items.push('a')  // OK

// Good: 튜플이 필요한 경우
const tuple: [number, string, boolean] = [1, 'a', true]

// Good: as const로 리터럴 타입 유지
const statuses = ['pending', 'active', 'done'] as const
// readonly ['pending', 'active', 'done']

type Status = typeof statuses[number]
// 'pending' | 'active' | 'done'
```

---

## 함수 반환 타입 실수

### 문제: 암시적 any 반환

```tsx
// Bad: 반환 타입 없으면 추론에 의존
function getData() {
  // 복잡한 로직...
  if (condition) return { data: result }
  return null  // 의도치 않은 타입 확장
}

// Bad: async 함수의 암시적 Promise<any>
async function fetchUser(id: string) {
  const res = await fetch(`/api/users/${id}`)
  return res.json()  // Promise<any>
}
```

### 해결: 명시적 반환 타입

```tsx
// Good: 반환 타입 명시
interface ApiResponse<T> {
  data: T
}

function getData(): ApiResponse<User> | null {
  if (condition) return { data: result }
  return null
}

// Good: async 함수 반환 타입
async function fetchUser(id: string): Promise<User> {
  const res = await fetch(`/api/users/${id}`)
  const data: unknown = await res.json()

  if (!isUser(data)) {
    throw new Error('Invalid response')
  }

  return data
}
```

---

## 유니온 타입 실수

### 문제: 타입 좁히기 없이 사용

```tsx
// Bad: 유니온 타입 멤버의 속성에 바로 접근
function process(value: string | number) {
  return value.toUpperCase()  // Error! number에는 없음
}

// Bad: null 체크 누락
function greet(name: string | null) {
  return `Hello, ${name.toUpperCase()}`  // Error!
}
```

### 해결: 타입 가드로 좁히기

```tsx
// Good: typeof로 좁히기
function process(value: string | number) {
  if (typeof value === 'string') {
    return value.toUpperCase()
  }
  return value.toFixed(2)
}

// Good: null 체크
function greet(name: string | null) {
  if (name === null) {
    return 'Hello, Guest'
  }
  return `Hello, ${name.toUpperCase()}`
}

// Good: 옵셔널 체이닝 (결과가 undefined일 수 있음)
function greet(name: string | null) {
  return `Hello, ${name?.toUpperCase() ?? 'Guest'}`
}
```

---

## 제네릭 실수

### 문제: 불필요한 제네릭

```tsx
// Bad: 제네릭이 의미 없음
function identity<T>(value: T): T {
  return value
}

const result = identity<string>('hello')  // 그냥 'hello' 써도 됨

// Bad: 제네릭을 any처럼 사용
function process<T>(data: T) {
  return data.toString()  // T에 toString이 있는지 모름
}
```

### 해결: 제약 조건 사용

```tsx
// Good: 제약 조건 추가
function process<T extends { toString(): string }>(data: T) {
  return data.toString()
}

// Good: 유용한 제네릭
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key]
}

// Good: 기본값 제공
function createState<T = string>(initial: T) {
  let state = initial
  return {
    get: () => state,
    set: (value: T) => { state = value },
  }
}
```

### 문제: 제네릭 타입 매개변수 명명

```tsx
// Bad: 의미 없는 이름
function merge<A, B, C>(a: A, b: B, c: C) { ... }
```

```tsx
// Good: 의미 있는 이름
function merge<TSource, TTarget, TResult>(
  source: TSource,
  target: TTarget
): TResult { ... }

// 일반적인 컨벤션
// T - Type
// K - Key
// V - Value
// E - Element
// P - Props
// R - Return
```

---

## 인터페이스 vs 타입 혼란

### 문제: 무분별한 사용

```tsx
// 일관성 없는 사용
interface User { name: string }
type Post = { title: string }
interface Comment { text: string }
type Reply = { content: string }
```

### 해결: 일관된 규칙 적용

```tsx
// 권장: interface - 객체 형태 정의
interface User {
  id: string
  name: string
}

// 권장: type - 유니온, 인터섹션, 유틸리티
type Status = 'active' | 'inactive'
type UserWithPosts = User & { posts: Post[] }
type PartialUser = Partial<User>

// interface만의 기능: 선언 병합
interface User {
  email: string  // 기존 User에 추가됨
}

// type만의 기능: 원시 타입 별칭
type ID = string
type Callback = () => void
```

---

## 옵셔널 프로퍼티 실수

### 문제: undefined 체크 누락

```tsx
interface Config {
  timeout?: number
  retries?: number
}

// Bad: 옵셔널 값 바로 사용
function init(config: Config) {
  const delay = config.timeout * 1000  // Error! undefined일 수 있음
}
```

### 해결: 기본값 제공

```tsx
// Good: 기본값 사용
function init(config: Config) {
  const timeout = config.timeout ?? 5000
  const retries = config.retries ?? 3

  const delay = timeout * 1000  // OK
}

// Good: 구조 분해와 기본값
function init({ timeout = 5000, retries = 3 }: Config) {
  const delay = timeout * 1000  // OK
}

// Good: Required로 필수 변환
type RequiredConfig = Required<Config>
```

---

## Enum 실수

### 문제: 숫자 enum의 위험성

```tsx
// Bad: 숫자 enum은 역방향 매핑됨
enum Status {
  Pending,   // 0
  Active,    // 1
  Done,      // 2
}

const status: Status = 999  // 에러 없음! (위험)

// Bad: 문자열 비교 혼란
if (status === 'Pending') { }  // Error
if (status === Status.Pending) { }  // OK (0과 비교)
```

### 해결: const enum 또는 유니온 타입

```tsx
// Good: const enum (컴파일 시 인라인)
const enum Status {
  Pending = 'PENDING',
  Active = 'ACTIVE',
  Done = 'DONE',
}

// Good: 유니온 타입 (권장)
type Status = 'pending' | 'active' | 'done'

const status: Status = 'pending'
if (status === 'pending') { }  // 직관적

// Good: as const 객체
const Status = {
  Pending: 'pending',
  Active: 'active',
  Done: 'done',
} as const

type StatusType = typeof Status[keyof typeof Status]
// 'pending' | 'active' | 'done'
```

---

## 비동기 코드 실수

### 문제: Promise 타입 혼란

```tsx
// Bad: Promise<T>와 T 혼동
async function getUser(): User {  // Error! async는 Promise 반환
  return { name: 'John' }
}

// Bad: await 누락
async function process() {
  const user = fetchUser()  // Promise<User>, not User
  console.log(user.name)    // Error!
}
```

### 해결: 올바른 타입 사용

```tsx
// Good: Promise<T> 반환 타입
async function getUser(): Promise<User> {
  return { name: 'John' }
}

// Good: await 사용
async function process() {
  const user = await fetchUser()  // User
  console.log(user.name)          // OK
}

// Good: Awaited로 Promise 언래핑
type UserPromise = Promise<User>
type ResolvedUser = Awaited<UserPromise>  // User
```

---

## React 관련 실수

### 문제: 이벤트 타입

```tsx
// Bad: any 이벤트
const handleClick = (e: any) => {
  console.log(e.target.value)
}

// Bad: 잘못된 이벤트 타입
const handleChange = (e: React.MouseEvent) => {
  // input의 onChange는 ChangeEvent
}
```

### 해결: 올바른 이벤트 타입

```tsx
// Good: 정확한 이벤트 타입
const handleClick = (e: React.MouseEvent<HTMLButtonElement>) => {
  console.log(e.currentTarget.disabled)
}

const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
  console.log(e.target.value)
}

const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
  e.preventDefault()
}

const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
  if (e.key === 'Enter') { }
}
```

### 문제: children 타입

```tsx
// Bad: 너무 제한적
interface Props {
  children: JSX.Element  // 단일 요소만 허용
}

// Bad: 너무 광범위
interface Props {
  children: any
}
```

### 해결: ReactNode 사용

```tsx
// Good: 일반적인 children
interface Props {
  children: React.ReactNode
}

// Good: 필수 children
interface Props {
  children: React.ReactNode  // undefined 가능
}

// 필수로 만들려면
interface Props {
  children: Exclude<React.ReactNode, null | undefined>
}

// Good: 특정 형태만 허용
interface Props {
  children: React.ReactElement<ChildProps>
}
```

---

## 타입 좁히기 실수

### 문제: 배열 메서드와 타입 좁히기

```tsx
// Bad: filter 후에도 타입 좁혀지지 않음
const items: (string | null)[] = ['a', null, 'b']
const filtered = items.filter(item => item !== null)
// filtered: (string | null)[]  여전히 null 포함!

// Bad: find 결과 체크 누락
const found = items.find(item => item === 'a')
console.log(found.toUpperCase())  // Error! undefined일 수 있음
```

### 해결: 타입 가드 함수 사용

```tsx
// Good: 타입 가드로 filter
function isNotNull<T>(value: T | null): value is T {
  return value !== null
}

const filtered = items.filter(isNotNull)
// filtered: string[]

// Good: find 결과 체크
const found = items.find(item => item === 'a')
if (found) {
  console.log(found.toUpperCase())
}

// 또는 Non-null assertion (확실할 때만)
const found = items.find(item => item === 'a')!
```

---

## 인덱스 시그니처 실수

### 문제: 존재하지 않는 키 접근

```tsx
// Bad: undefined 가능성 무시
const dict: { [key: string]: number } = { a: 1, b: 2 }
const value = dict['nonexistent']  // number (실제로는 undefined)
console.log(value.toFixed())       // 런타임 에러!
```

### 해결: noUncheckedIndexedAccess 사용

```tsx
// tsconfig.json
{
  "compilerOptions": {
    "noUncheckedIndexedAccess": true
  }
}

// 이제 타입이 number | undefined
const value = dict['nonexistent']  // number | undefined

if (value !== undefined) {
  console.log(value.toFixed())     // OK
}

// 또는 Map 사용
const dict = new Map<string, number>([
  ['a', 1],
  ['b', 2],
])

const value = dict.get('a')  // number | undefined (명시적)
```

---

## 모듈 import 실수

### 문제: 타입과 값 혼동

```tsx
// Bad: 타입만 import 해야 하는데 값으로 import
import { User } from './types'  // 번들에 포함될 수 있음

// 런타임에 사용하려 함
const user = new User()  // Error! 타입은 런타임에 없음
```

### 해결: type import 사용

```tsx
// Good: 타입 전용 import
import type { User } from './types'

// Good: 인라인 type import
import { type User, createUser } from './module'

// Good: 타입과 값 구분
// types.ts
export interface User {
  name: string
}

// factory.ts
import type { User } from './types'

export function createUser(name: string): User {
  return { name }
}
```

---

## 요약 체크리스트

```tsx
// 1. any 대신 unknown 사용
function process(data: unknown) { }

// 2. 타입 단언 대신 타입 가드
if (isUser(data)) { }

// 3. 명시적 반환 타입
function getData(): User | null { }

// 4. null/undefined 체크
value?.property ?? defaultValue

// 5. 제네릭 제약 조건
function fn<T extends HasId>(item: T) { }

// 6. 유니온 대신 const enum 또는 리터럴 유니온
type Status = 'active' | 'inactive'

// 7. 옵셔널 프로퍼티 기본값
const { timeout = 5000 } = config

// 8. 올바른 이벤트 타입
(e: React.ChangeEvent<HTMLInputElement>) => { }

// 9. 타입 가드로 배열 필터
array.filter(isNotNull)

// 10. type import 사용
import type { User } from './types'
```

---

## 권장 tsconfig 설정

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noImplicitOverride": true,
    "exactOptionalPropertyTypes": true
  }
}
```

각 옵션의 의미:
- `strict`: 모든 엄격 검사 활성화
- `noUncheckedIndexedAccess`: 인덱스 접근 시 undefined 포함
- `noImplicitReturns`: 모든 경로에서 반환 필요
- `noFallthroughCasesInSwitch`: switch case fall-through 방지
- `noImplicitOverride`: override 키워드 강제
- `exactOptionalPropertyTypes`: 옵셔널과 undefined 구분
