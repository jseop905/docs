# 제네릭 (Generics)

**타입을 파라미터처럼** 받아서 재사용 가능한 타입/함수를 만드는 기능입니다.

---

## 왜 제네릭이 필요한가?

### 문제 상황

```tsx
// 배열의 첫 번째 요소를 반환하는 함수
function firstNumber(arr: number[]): number {
  return arr[0]
}

function firstString(arr: string[]): string {
  return arr[0]
}

function firstUser(arr: User[]): User {
  return arr[0]
}

// 타입마다 함수를 만들어야 함 → 중복!
```

### any로 해결? (나쁜 방법)

```tsx
function first(arr: any[]): any {
  return arr[0]
}

const num = first([1, 2, 3])     // any - 타입 정보 손실!
const str = first(['a', 'b'])    // any - 타입 정보 손실!
```

### 제네릭으로 해결 (좋은 방법)

```tsx
function first<T>(arr: T[]): T {
  return arr[0]
}

const num = first([1, 2, 3])     // number - 타입 유지!
const str = first(['a', 'b'])    // string - 타입 유지!
const user = first([user1])      // User - 타입 유지!
```

---

## 기본 문법

### 함수에서 제네릭

```tsx
// 기본 형태
function identity<T>(value: T): T {
  return value
}

// 사용 (타입 추론)
identity(42)        // T = number
identity('hello')   // T = string

// 명시적 타입 지정
identity<number>(42)
identity<string>('hello')
```

### 화살표 함수에서 제네릭

```tsx
// 일반적인 형태
const identity = <T>(value: T): T => value

// TSX 파일에서는 <T,>로 작성 (JSX와 구분)
const identity = <T,>(value: T): T => value
```

### 여러 타입 파라미터

```tsx
function pair<T, U>(first: T, second: U): [T, U] {
  return [first, second]
}

const result = pair('hello', 42)  // [string, number]
```

---

## 제네릭 제약 (Constraints)

### extends로 제약 추가

```tsx
// T는 아무 타입이나 가능 → 문제 발생 가능
function getLength<T>(value: T): number {
  return value.length  // Error! T에 length가 있는지 모름
}

// length 속성이 있는 타입만 허용
function getLength<T extends { length: number }>(value: T): number {
  return value.length  // OK!
}

getLength('hello')      // OK - string은 length 있음
getLength([1, 2, 3])    // OK - array도 length 있음
getLength({ length: 5 }) // OK
getLength(123)          // Error! number는 length 없음
```

### 실전 예시: 객체 키 접근

```tsx
// K는 T의 키 중 하나여야 함
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key]
}

const user = { name: 'John', age: 30 }

getProperty(user, 'name')  // string
getProperty(user, 'age')   // number
getProperty(user, 'email') // Error! 'email'은 user의 키가 아님
```

### 실전 예시: ID가 있는 객체

```tsx
interface HasId {
  id: string | number
}

function findById<T extends HasId>(items: T[], id: T['id']): T | undefined {
  return items.find(item => item.id === id)
}

interface User {
  id: string
  name: string
}

interface Product {
  id: number
  name: string
  price: number
}

const users: User[] = [{ id: 'u1', name: 'John' }]
const products: Product[] = [{ id: 1, name: 'Phone', price: 999 }]

findById(users, 'u1')     // User | undefined
findById(products, 1)     // Product | undefined
```

---

## 제네릭 인터페이스

### 기본 형태

```tsx
interface Container<T> {
  value: T
  getValue: () => T
  setValue: (value: T) => void
}

const numberContainer: Container<number> = {
  value: 42,
  getValue: () => 42,
  setValue: (v) => { /* ... */ },
}
```

### 실전 예시: API 응답 타입

```tsx
interface ApiResponse<T> {
  data: T
  status: number
  message: string
}

interface User {
  id: string
  name: string
}

interface Product {
  id: string
  name: string
  price: number
}

// 사용
type UserResponse = ApiResponse<User>
type ProductResponse = ApiResponse<Product>
type ProductListResponse = ApiResponse<Product[]>

// 함수에서 활용
async function fetchApi<T>(url: string): Promise<ApiResponse<T>> {
  const response = await fetch(url)
  return response.json()
}

const userResponse = await fetchApi<User>('/api/users/1')
// userResponse.data는 User 타입
```

### 실전 예시: 페이지네이션 응답

```tsx
interface PaginatedResponse<T> {
  items: T[]
  pagination: {
    page: number
    limit: number
    total: number
    totalPages: number
  }
}

async function fetchPaginated<T>(
  url: string,
  page: number,
  limit: number
): Promise<PaginatedResponse<T>> {
  const response = await fetch(`${url}?page=${page}&limit=${limit}`)
  return response.json()
}

// 사용
const users = await fetchPaginated<User>('/api/users', 1, 10)
users.items  // User[]
users.pagination.total  // number
```

---

## 제네릭 타입 별칭

```tsx
// 함수 타입
type Mapper<T, U> = (item: T) => U

const toString: Mapper<number, string> = (n) => String(n)
const toNumber: Mapper<string, number> = (s) => Number(s)

// 조건부 null 허용
type Nullable<T> = T | null

type NullableUser = Nullable<User>  // User | null

// 배열 또는 단일 값
type MaybeArray<T> = T | T[]

function ensureArray<T>(value: MaybeArray<T>): T[] {
  return Array.isArray(value) ? value : [value]
}
```

---

## 제네릭 클래스

```tsx
class Stack<T> {
  private items: T[] = []

  push(item: T): void {
    this.items.push(item)
  }

  pop(): T | undefined {
    return this.items.pop()
  }

  peek(): T | undefined {
    return this.items[this.items.length - 1]
  }

  isEmpty(): boolean {
    return this.items.length === 0
  }
}

const numberStack = new Stack<number>()
numberStack.push(1)
numberStack.push(2)
numberStack.pop()  // number | undefined

const stringStack = new Stack<string>()
stringStack.push('a')
```

---

## 제네릭 기본값

```tsx
// 기본값 지정
interface Container<T = string> {
  value: T
}

const c1: Container = { value: 'hello' }  // T = string
const c2: Container<number> = { value: 42 }  // T = number

// 함수에서
function createArray<T = string>(length: number, value: T): T[] {
  return Array(length).fill(value)
}

createArray(3, 'x')     // string[] - T 추론됨
createArray<number>(3, 0)  // number[] - 명시적
```

---

## 실전 패턴

### 1. 팩토리 함수

```tsx
function createState<T>(initial: T) {
  let state = initial

  return {
    get: () => state,
    set: (value: T) => { state = value },
    reset: () => { state = initial },
  }
}

const counter = createState(0)
counter.get()   // number
counter.set(5)  // OK
counter.set('5') // Error! string은 안됨

const user = createState<User | null>(null)
user.get()  // User | null
user.set({ id: '1', name: 'John' })
```

### 2. 이벤트 에미터

```tsx
type EventMap = {
  login: { userId: string }
  logout: undefined
  message: { text: string; from: string }
}

class EventEmitter<T extends Record<string, any>> {
  private listeners: {
    [K in keyof T]?: ((data: T[K]) => void)[]
  } = {}

  on<K extends keyof T>(event: K, callback: (data: T[K]) => void): void {
    if (!this.listeners[event]) {
      this.listeners[event] = []
    }
    this.listeners[event]!.push(callback)
  }

  emit<K extends keyof T>(event: K, data: T[K]): void {
    this.listeners[event]?.forEach(cb => cb(data))
  }
}

const emitter = new EventEmitter<EventMap>()

emitter.on('login', (data) => {
  console.log(data.userId)  // 타입 안전!
})

emitter.emit('login', { userId: '123' })  // OK
emitter.emit('login', { text: 'hi' })     // Error!
```

### 3. 빌더 패턴

```tsx
class QueryBuilder<T> {
  private query: Partial<T> = {}

  where<K extends keyof T>(key: K, value: T[K]): this {
    this.query[key] = value
    return this
  }

  build(): Partial<T> {
    return { ...this.query }
  }
}

interface UserQuery {
  name: string
  age: number
  role: 'admin' | 'user'
}

const query = new QueryBuilder<UserQuery>()
  .where('name', 'John')
  .where('role', 'admin')
  .build()
// { name: 'John', role: 'admin' }
```

### 4. React 컴포넌트 Props

```tsx
// 제네릭 리스트 컴포넌트
interface ListProps<T> {
  items: T[]
  renderItem: (item: T, index: number) => React.ReactNode
  keyExtractor: (item: T) => string
}

function List<T>({ items, renderItem, keyExtractor }: ListProps<T>) {
  return (
    <ul>
      {items.map((item, index) => (
        <li key={keyExtractor(item)}>
          {renderItem(item, index)}
        </li>
      ))}
    </ul>
  )
}

// 사용
<List
  items={users}
  renderItem={(user) => <span>{user.name}</span>}
  keyExtractor={(user) => user.id}
/>
```

### 5. 폼 훅

```tsx
function useForm<T extends Record<string, any>>(initialValues: T) {
  const [values, setValues] = useState<T>(initialValues)
  const [errors, setErrors] = useState<Partial<Record<keyof T, string>>>({})

  const setValue = <K extends keyof T>(key: K, value: T[K]) => {
    setValues(prev => ({ ...prev, [key]: value }))
  }

  const setError = <K extends keyof T>(key: K, error: string) => {
    setErrors(prev => ({ ...prev, [key]: error }))
  }

  const reset = () => {
    setValues(initialValues)
    setErrors({})
  }

  return { values, errors, setValue, setError, reset }
}

// 사용
const form = useForm({
  name: '',
  email: '',
  age: 0,
})

form.setValue('name', 'John')     // OK
form.setValue('name', 123)        // Error! string이어야 함
form.setValue('invalid', 'test')  // Error! 존재하지 않는 키
```

---

## 제네릭 추론 팁

### infer 키워드 (고급)

```tsx
// 배열 요소 타입 추출
type ArrayElement<T> = T extends (infer U)[] ? U : never

type StringArray = string[]
type Element = ArrayElement<StringArray>  // string

// Promise 내부 타입 추출
type UnwrapPromise<T> = T extends Promise<infer U> ? U : T

type P = Promise<number>
type Result = UnwrapPromise<P>  // number

// 함수 첫 번째 인자 타입 추출
type FirstArg<T> = T extends (first: infer F, ...args: any[]) => any
  ? F
  : never

type Fn = (name: string, age: number) => void
type First = FirstArg<Fn>  // string
```

### 제네릭 가드

```tsx
// 타입 가드와 제네릭 조합
function isOfType<T>(
  value: unknown,
  check: (value: unknown) => value is T
): value is T {
  return check(value)
}

// 사용
function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'name' in value
  )
}

const data: unknown = await fetchData()
if (isOfType(data, isUser)) {
  console.log(data.name)  // User로 좁혀짐
}
```

---

## 요약

```tsx
// 기본 제네릭
function fn<T>(value: T): T

// 여러 타입 파라미터
function fn<T, U>(a: T, b: U): [T, U]

// 제약 조건
function fn<T extends { id: string }>(item: T): string

// 키 제약
function fn<T, K extends keyof T>(obj: T, key: K): T[K]

// 기본값
function fn<T = string>(value: T): T

// 인터페이스/타입
interface Container<T> { value: T }
type Nullable<T> = T | null

// 클래스
class Stack<T> { /* ... */ }
```
