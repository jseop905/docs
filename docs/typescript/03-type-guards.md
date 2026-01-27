# 타입 가드 (Type Guards)

런타임에서 **타입을 좁히는(narrowing)** 방법입니다. 조건문을 통해 TypeScript가 더 구체적인 타입을 알 수 있게 합니다.

---

## 왜 타입 가드가 필요한가?

```tsx
function processValue(value: string | number) {
  // value는 string 또는 number
  // value.toUpperCase()  // Error! number에는 없음
  // value.toFixed()      // Error! string에는 없음

  // 타입 가드로 좁히기
  if (typeof value === 'string') {
    // 여기서 value는 string
    return value.toUpperCase()
  } else {
    // 여기서 value는 number
    return value.toFixed(2)
  }
}
```

---

## 내장 타입 가드

### typeof

원시 타입을 구분합니다.

```tsx
function format(value: string | number | boolean): string {
  if (typeof value === 'string') {
    return value.toUpperCase()
  }
  if (typeof value === 'number') {
    return value.toLocaleString()
  }
  if (typeof value === 'boolean') {
    return value ? 'Yes' : 'No'
  }

  // 모든 케이스 처리됨 - value는 never
  const _exhaustive: never = value
  return _exhaustive
}
```

**typeof가 구분할 수 있는 타입:**
- `'string'`
- `'number'`
- `'boolean'`
- `'symbol'`
- `'bigint'`
- `'undefined'`
- `'object'` (null 포함!)
- `'function'`

### instanceof

클래스 인스턴스를 구분합니다.

```tsx
class Dog {
  bark() { return 'Woof!' }
}

class Cat {
  meow() { return 'Meow!' }
}

function makeSound(animal: Dog | Cat): string {
  if (animal instanceof Dog) {
    return animal.bark()  // Dog로 좁혀짐
  }
  return animal.meow()    // Cat으로 좁혀짐
}
```

```tsx
// DOM 요소 구분
function handleElement(element: HTMLElement) {
  if (element instanceof HTMLInputElement) {
    console.log(element.value)  // value 속성 접근 가능
  }
  if (element instanceof HTMLButtonElement) {
    console.log(element.disabled)
  }
  if (element instanceof HTMLAnchorElement) {
    console.log(element.href)
  }
}
```

### in 연산자

객체에 특정 속성이 있는지 확인합니다.

```tsx
interface Bird {
  fly: () => void
  layEggs: () => void
}

interface Fish {
  swim: () => void
  layEggs: () => void
}

function move(animal: Bird | Fish) {
  if ('fly' in animal) {
    animal.fly()  // Bird로 좁혀짐
  } else {
    animal.swim() // Fish로 좁혀짐
  }
}
```

### 동등 비교 (Equality)

```tsx
type Status = 'loading' | 'success' | 'error'

function handleStatus(status: Status) {
  if (status === 'loading') {
    // status: 'loading'
    return <Spinner />
  }
  if (status === 'success') {
    // status: 'success'
    return <SuccessMessage />
  }
  // status: 'error'
  return <ErrorMessage />
}
```

### Truthiness 체크

```tsx
function processValue(value: string | null | undefined) {
  if (value) {
    // value: string (null, undefined, '' 제외)
    return value.toUpperCase()
  }
  return 'No value'
}

// 주의: 0, '' 는 falsy
function processNumber(value: number | null) {
  if (value) {
    // 0도 여기서 제외됨!
  }

  // 더 정확한 방법
  if (value !== null) {
    // value: number (0 포함)
  }
}
```

---

## 커스텀 타입 가드

### is 키워드

```tsx
// 타입 가드 함수 정의
function isString(value: unknown): value is string {
  return typeof value === 'string'
}

function isNumber(value: unknown): value is number {
  return typeof value === 'number'
}

// 사용
function process(value: unknown) {
  if (isString(value)) {
    // value: string
    console.log(value.toUpperCase())
  }
  if (isNumber(value)) {
    // value: number
    console.log(value.toFixed(2))
  }
}
```

### 객체 타입 가드

```tsx
interface User {
  id: string
  name: string
  email: string
}

interface Admin extends User {
  role: 'admin'
  permissions: string[]
}

// User 타입 가드
function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'name' in value &&
    'email' in value &&
    typeof (value as User).id === 'string' &&
    typeof (value as User).name === 'string' &&
    typeof (value as User).email === 'string'
  )
}

// Admin 타입 가드
function isAdmin(value: unknown): value is Admin {
  return (
    isUser(value) &&
    'role' in value &&
    (value as Admin).role === 'admin' &&
    'permissions' in value &&
    Array.isArray((value as Admin).permissions)
  )
}

// 사용
async function fetchUser(id: string): Promise<User | null> {
  const response = await fetch(`/api/users/${id}`)
  const data = await response.json()

  if (isUser(data)) {
    return data  // User 타입으로 안전하게 반환
  }
  return null
}
```

### 배열 타입 가드

```tsx
// 배열인지 확인
function isArray<T>(value: unknown): value is T[] {
  return Array.isArray(value)
}

// 특정 타입의 배열인지 확인
function isStringArray(value: unknown): value is string[] {
  return Array.isArray(value) && value.every(item => typeof item === 'string')
}

function isUserArray(value: unknown): value is User[] {
  return Array.isArray(value) && value.every(isUser)
}

// 사용
const data: unknown = await fetchData()

if (isUserArray(data)) {
  // data: User[]
  data.forEach(user => console.log(user.name))
}
```

### 유니온 타입 구분

```tsx
interface SuccessResponse {
  status: 'success'
  data: any
}

interface ErrorResponse {
  status: 'error'
  error: string
}

type ApiResponse = SuccessResponse | ErrorResponse

// 타입 가드
function isSuccess(response: ApiResponse): response is SuccessResponse {
  return response.status === 'success'
}

function isError(response: ApiResponse): response is ErrorResponse {
  return response.status === 'error'
}

// 사용
async function handleResponse(response: ApiResponse) {
  if (isSuccess(response)) {
    // response: SuccessResponse
    console.log(response.data)
  } else {
    // response: ErrorResponse
    console.error(response.error)
  }
}
```

---

## Discriminated Union (구별된 유니온)

공통 속성으로 타입을 구분하는 패턴입니다.

### 기본 패턴

```tsx
// 공통 속성: type
interface Circle {
  type: 'circle'
  radius: number
}

interface Rectangle {
  type: 'rectangle'
  width: number
  height: number
}

interface Triangle {
  type: 'triangle'
  base: number
  height: number
}

type Shape = Circle | Rectangle | Triangle

function getArea(shape: Shape): number {
  switch (shape.type) {
    case 'circle':
      // shape: Circle
      return Math.PI * shape.radius ** 2
    case 'rectangle':
      // shape: Rectangle
      return shape.width * shape.height
    case 'triangle':
      // shape: Triangle
      return (shape.base * shape.height) / 2
  }
}
```

### 실전 예시: Redux 액션

```tsx
interface LoadingAction {
  type: 'LOADING'
}

interface SuccessAction {
  type: 'SUCCESS'
  payload: User[]
}

interface ErrorAction {
  type: 'ERROR'
  error: string
}

type UserAction = LoadingAction | SuccessAction | ErrorAction

function userReducer(state: UserState, action: UserAction): UserState {
  switch (action.type) {
    case 'LOADING':
      return { ...state, loading: true }
    case 'SUCCESS':
      // action.payload 접근 가능
      return { ...state, loading: false, users: action.payload }
    case 'ERROR':
      // action.error 접근 가능
      return { ...state, loading: false, error: action.error }
  }
}
```

### 실전 예시: API 응답

```tsx
type ApiResult<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error }

function renderResult<T>(
  result: ApiResult<T>,
  render: (data: T) => React.ReactNode
): React.ReactNode {
  switch (result.status) {
    case 'idle':
      return null
    case 'loading':
      return <Spinner />
    case 'success':
      return render(result.data)  // data 접근 가능
    case 'error':
      return <ErrorMessage error={result.error} />  // error 접근 가능
  }
}
```

### 실전 예시: 폼 필드

```tsx
interface TextField {
  type: 'text'
  value: string
  maxLength?: number
}

interface NumberField {
  type: 'number'
  value: number
  min?: number
  max?: number
}

interface SelectField {
  type: 'select'
  value: string
  options: { label: string; value: string }[]
}

interface CheckboxField {
  type: 'checkbox'
  value: boolean
}

type FormField = TextField | NumberField | SelectField | CheckboxField

function renderField(field: FormField): React.ReactNode {
  switch (field.type) {
    case 'text':
      return <input type="text" value={field.value} maxLength={field.maxLength} />
    case 'number':
      return <input type="number" value={field.value} min={field.min} max={field.max} />
    case 'select':
      return (
        <select value={field.value}>
          {field.options.map(opt => (
            <option key={opt.value} value={opt.value}>{opt.label}</option>
          ))}
        </select>
      )
    case 'checkbox':
      return <input type="checkbox" checked={field.value} />
  }
}
```

---

## asserts 키워드

함수가 성공적으로 반환하면 타입이 좁혀진다고 **단언**합니다.

### 기본 사용

```tsx
function assertIsString(value: unknown): asserts value is string {
  if (typeof value !== 'string') {
    throw new Error('Value must be a string')
  }
}

function processValue(value: unknown) {
  assertIsString(value)
  // 이 줄 이후로 value는 string
  console.log(value.toUpperCase())
}
```

### assertNonNull

```tsx
function assertNonNull<T>(
  value: T | null | undefined,
  message?: string
): asserts value is T {
  if (value === null || value === undefined) {
    throw new Error(message ?? 'Value is null or undefined')
  }
}

// 사용
function getUser(id: string): User | null {
  return users.find(u => u.id === id) ?? null
}

const user = getUser('123')
// user: User | null

assertNonNull(user, 'User not found')
// user: User (이후로 null 아님 보장)
console.log(user.name)
```

### 조건 단언

```tsx
function assert(condition: boolean, message?: string): asserts condition {
  if (!condition) {
    throw new Error(message ?? 'Assertion failed')
  }
}

// 사용
function divide(a: number, b: number): number {
  assert(b !== 0, 'Division by zero')
  return a / b
}
```

---

## 타입 가드 유틸리티

### isDefined

```tsx
function isDefined<T>(value: T | undefined | null): value is T {
  return value !== undefined && value !== null
}

// 배열 필터링에 유용
const items: (string | null)[] = ['a', null, 'b', null, 'c']
const filtered = items.filter(isDefined)
// filtered: string[]
```

### hasProperty

```tsx
function hasProperty<K extends string>(
  obj: unknown,
  key: K
): obj is Record<K, unknown> {
  return typeof obj === 'object' && obj !== null && key in obj
}

// 사용
const data: unknown = { name: 'John', age: 30 }

if (hasProperty(data, 'name')) {
  // data: Record<'name', unknown>
  console.log(data.name)
}
```

### isOneOf

```tsx
function isOneOf<T extends readonly unknown[]>(
  value: unknown,
  options: T
): value is T[number] {
  return options.includes(value as T[number])
}

const statuses = ['pending', 'approved', 'rejected'] as const

const status: unknown = 'approved'
if (isOneOf(status, statuses)) {
  // status: 'pending' | 'approved' | 'rejected'
}
```

---

## 실전 패턴

### API 응답 검증

```tsx
interface ApiUser {
  id: string
  name: string
  email: string
}

function isApiUser(data: unknown): data is ApiUser {
  if (typeof data !== 'object' || data === null) return false

  const obj = data as Record<string, unknown>

  return (
    typeof obj.id === 'string' &&
    typeof obj.name === 'string' &&
    typeof obj.email === 'string'
  )
}

async function fetchUser(id: string): Promise<ApiUser> {
  const response = await fetch(`/api/users/${id}`)
  const data: unknown = await response.json()

  if (!isApiUser(data)) {
    throw new Error('Invalid API response')
  }

  return data  // ApiUser 타입으로 안전하게 반환
}
```

### Zod와 함께 사용

```tsx
import { z } from 'zod'

// Zod 스키마
const UserSchema = z.object({
  id: z.string(),
  name: z.string(),
  email: z.string().email(),
})

type User = z.infer<typeof UserSchema>

// 타입 가드 생성
function isUser(data: unknown): data is User {
  return UserSchema.safeParse(data).success
}

// 또는 parse로 검증 + 변환
async function fetchUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`)
  const data = await response.json()

  return UserSchema.parse(data)  // 유효하지 않으면 에러
}
```

---

## Exhaustive Check (완전성 검사)

모든 케이스를 처리했는지 컴파일 타임에 확인합니다.

```tsx
type Status = 'pending' | 'approved' | 'rejected'

function handleStatus(status: Status): string {
  switch (status) {
    case 'pending':
      return 'Waiting...'
    case 'approved':
      return 'Approved!'
    case 'rejected':
      return 'Rejected'
    default:
      // status가 never가 아니면 컴파일 에러
      const _exhaustiveCheck: never = status
      return _exhaustiveCheck
  }
}

// 나중에 Status에 'cancelled'가 추가되면?
// type Status = 'pending' | 'approved' | 'rejected' | 'cancelled'
// → default에서 컴파일 에러 발생! 처리 누락 방지
```

### assertNever 유틸리티

```tsx
function assertNever(value: never): never {
  throw new Error(`Unexpected value: ${value}`)
}

function handleStatus(status: Status): string {
  switch (status) {
    case 'pending':
      return 'Waiting...'
    case 'approved':
      return 'Approved!'
    case 'rejected':
      return 'Rejected'
    default:
      return assertNever(status)
  }
}
```

---

## 요약

```tsx
// 내장 타입 가드
typeof value === 'string'
value instanceof Date
'property' in object
value === 'specific'

// 커스텀 타입 가드 (is)
function isUser(value: unknown): value is User

// 단언 타입 가드 (asserts)
function assertIsUser(value: unknown): asserts value is User

// 구별된 유니온
type Result = { type: 'success'; data: T } | { type: 'error'; error: E }

// 완전성 검사
const _exhaustive: never = value
```
