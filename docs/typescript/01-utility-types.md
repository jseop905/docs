# 유틸리티 타입 (Utility Types)

TypeScript가 기본 제공하는 **타입 변환 도구**들입니다. 기존 타입을 기반으로 새로운 타입을 만들 때 사용합니다.

---

## 자주 쓰는 유틸리티 타입

| 유틸리티 | 설명 | 사용 빈도 |
|----------|------|----------|
| `Partial<T>` | 모든 속성을 선택적으로 | ⭐⭐⭐ |
| `Required<T>` | 모든 속성을 필수로 | ⭐⭐ |
| `Pick<T, K>` | 특정 속성만 선택 | ⭐⭐⭐ |
| `Omit<T, K>` | 특정 속성만 제외 | ⭐⭐⭐ |
| `Readonly<T>` | 모든 속성을 읽기 전용으로 | ⭐⭐ |
| `Record<K, V>` | 키-값 타입 정의 | ⭐⭐⭐ |
| `ReturnType<T>` | 함수 반환 타입 추출 | ⭐⭐ |
| `Parameters<T>` | 함수 파라미터 타입 추출 | ⭐⭐ |
| `NonNullable<T>` | null, undefined 제외 | ⭐⭐ |
| `Awaited<T>` | Promise 내부 타입 추출 | ⭐⭐ |

---

## Partial<T>

모든 속성을 **선택적(optional)**으로 만듭니다.

### 기본 사용

```tsx
interface User {
  id: string
  name: string
  email: string
  age: number
}

type PartialUser = Partial<User>
// 결과:
// {
//   id?: string
//   name?: string
//   email?: string
//   age?: number
// }
```

### 실전 예시: 업데이트 함수

```tsx
interface User {
  id: string
  name: string
  email: string
  age: number
}

// 부분 업데이트 - 일부 필드만 업데이트
function updateUser(id: string, updates: Partial<User>): User {
  const user = getUserById(id)
  return { ...user, ...updates }
}

// 사용
updateUser('123', { name: 'New Name' })  // name만 업데이트
updateUser('123', { email: 'new@email.com', age: 30 })  // 여러 필드
```

### 실전 예시: 기본값 병합

```tsx
interface Config {
  apiUrl: string
  timeout: number
  retries: number
  debug: boolean
}

const defaultConfig: Config = {
  apiUrl: 'https://api.example.com',
  timeout: 5000,
  retries: 3,
  debug: false,
}

function createConfig(overrides: Partial<Config>): Config {
  return { ...defaultConfig, ...overrides }
}

// 사용
const config = createConfig({ timeout: 10000, debug: true })
```

---

## Required<T>

모든 속성을 **필수**로 만듭니다. `Partial`의 반대입니다.

### 기본 사용

```tsx
interface Props {
  name?: string
  age?: number
  email?: string
}

type RequiredProps = Required<Props>
// 결과:
// {
//   name: string
//   age: number
//   email: string
// }
```

### 실전 예시: 옵션 검증

```tsx
interface CreateUserOptions {
  name?: string
  email?: string
  password?: string
}

// 모든 옵션이 제공되었는지 확인 후 처리
function createUser(options: CreateUserOptions): User {
  // 검증
  if (!options.name || !options.email || !options.password) {
    throw new Error('All fields are required')
  }

  // 여기서 options는 여전히 optional 타입...
  // Required로 타입 변환
  const validatedOptions = options as Required<CreateUserOptions>

  return {
    id: generateId(),
    ...validatedOptions,
  }
}
```

---

## Pick<T, K>

특정 속성만 **선택**하여 새 타입을 만듭니다.

### 기본 사용

```tsx
interface User {
  id: string
  name: string
  email: string
  password: string
  createdAt: Date
  updatedAt: Date
}

// 화면에 표시할 정보만 선택
type UserDisplay = Pick<User, 'id' | 'name' | 'email'>
// 결과:
// {
//   id: string
//   name: string
//   email: string
// }
```

### 실전 예시: API 응답 타입

```tsx
interface Product {
  id: string
  name: string
  description: string
  price: number
  stock: number
  category: string
  createdAt: Date
  updatedAt: Date
}

// 목록에서는 일부 정보만 필요
type ProductListItem = Pick<Product, 'id' | 'name' | 'price' | 'category'>

// 카드에 표시할 정보
type ProductCard = Pick<Product, 'id' | 'name' | 'price' | 'stock'>

function ProductList({ products }: { products: ProductListItem[] }) {
  return (
    <ul>
      {products.map(product => (
        <li key={product.id}>
          {product.name} - {product.price}원
        </li>
      ))}
    </ul>
  )
}
```

### 실전 예시: 폼 데이터

```tsx
interface User {
  id: string
  name: string
  email: string
  password: string
  role: 'admin' | 'user'
  createdAt: Date
}

// 회원가입 폼에 필요한 필드만
type SignUpForm = Pick<User, 'name' | 'email' | 'password'>

// 프로필 수정에 필요한 필드만
type ProfileForm = Pick<User, 'name' | 'email'>
```

---

## Omit<T, K>

특정 속성을 **제외**하고 새 타입을 만듭니다. `Pick`의 반대입니다.

### 기본 사용

```tsx
interface User {
  id: string
  name: string
  email: string
  password: string
  createdAt: Date
}

// password 제외
type SafeUser = Omit<User, 'password'>
// 결과:
// {
//   id: string
//   name: string
//   email: string
//   createdAt: Date
// }

// 여러 속성 제외
type UserInput = Omit<User, 'id' | 'createdAt'>
// 결과:
// {
//   name: string
//   email: string
//   password: string
// }
```

### 실전 예시: 생성 vs 조회 타입

```tsx
interface Post {
  id: string
  title: string
  content: string
  authorId: string
  createdAt: Date
  updatedAt: Date
}

// 생성 시에는 id, 날짜 불필요
type CreatePostInput = Omit<Post, 'id' | 'createdAt' | 'updatedAt'>

// API 함수
async function createPost(input: CreatePostInput): Promise<Post> {
  const response = await fetch('/api/posts', {
    method: 'POST',
    body: JSON.stringify(input),
  })
  return response.json()
}

// 사용
createPost({
  title: '제목',
  content: '내용',
  authorId: 'user123',
})
```

### 실전 예시: 컴포넌트 Props 확장

```tsx
// HTML button 속성에서 type 제외 후 커스텀 type 추가
interface ButtonProps extends Omit<
  React.ButtonHTMLAttributes<HTMLButtonElement>,
  'type'
> {
  variant: 'primary' | 'secondary'
  type?: 'button' | 'submit'  // 제한된 type만 허용
}

function Button({ variant, type = 'button', ...props }: ButtonProps) {
  return <button type={type} className={variant} {...props} />
}
```

---

## Pick vs Omit 선택 기준

```tsx
interface User {
  id: string        // 1
  name: string      // 2
  email: string     // 3
  password: string  // 4
  phone: string     // 5
  address: string   // 6
  createdAt: Date   // 7
  updatedAt: Date   // 8
}

// 2개만 필요 → Pick
type UserName = Pick<User, 'id' | 'name'>

// 2개만 제외 → Omit
type SafeUser = Omit<User, 'password' | 'phone'>

// 기준: 더 적은 것을 나열하는 쪽 선택
```

---

## Readonly<T>

모든 속성을 **읽기 전용**으로 만듭니다.

### 기본 사용

```tsx
interface User {
  id: string
  name: string
}

type ReadonlyUser = Readonly<User>
// 결과:
// {
//   readonly id: string
//   readonly name: string
// }

const user: ReadonlyUser = { id: '1', name: 'John' }
// user.name = 'Jane'  // Error! 읽기 전용
```

### 실전 예시: 설정 객체

```tsx
interface AppConfig {
  apiUrl: string
  version: string
  features: string[]
}

// 설정은 변경되면 안 됨
const config: Readonly<AppConfig> = {
  apiUrl: 'https://api.example.com',
  version: '1.0.0',
  features: ['auth', 'dashboard'],
}

// config.apiUrl = 'other'  // Error!

// 주의: 얕은(shallow) readonly
config.features.push('new')  // 이건 됨! (배열 내부는 보호 안됨)
```

### DeepReadonly 만들기

```tsx
type DeepReadonly<T> = {
  readonly [K in keyof T]: T[K] extends object
    ? DeepReadonly<T[K]>
    : T[K]
}

const config: DeepReadonly<AppConfig> = {
  apiUrl: 'https://api.example.com',
  version: '1.0.0',
  features: ['auth', 'dashboard'],
}

// config.features.push('new')  // Error! 깊은 레벨도 보호
```

---

## Record<K, V>

**키-값** 쌍의 타입을 정의합니다.

### 기본 사용

```tsx
// 문자열 키, 숫자 값
type StringNumberMap = Record<string, number>

const scores: StringNumberMap = {
  math: 90,
  english: 85,
  science: 92,
}
```

### 실전 예시: 상태 매핑

```tsx
type Status = 'pending' | 'approved' | 'rejected'

// 각 상태별 라벨
const statusLabels: Record<Status, string> = {
  pending: '대기 중',
  approved: '승인됨',
  rejected: '거절됨',
}

// 각 상태별 색상
const statusColors: Record<Status, string> = {
  pending: 'yellow',
  approved: 'green',
  rejected: 'red',
}

function StatusBadge({ status }: { status: Status }) {
  return (
    <span style={{ color: statusColors[status] }}>
      {statusLabels[status]}
    </span>
  )
}
```

### 실전 예시: ID로 인덱싱된 객체

```tsx
interface User {
  id: string
  name: string
  email: string
}

// userId를 키로 하는 객체
type UsersById = Record<string, User>

const users: UsersById = {
  'user-1': { id: 'user-1', name: 'John', email: 'john@example.com' },
  'user-2': { id: 'user-2', name: 'Jane', email: 'jane@example.com' },
}

// 빠른 조회
const user = users['user-1']
```

### 실전 예시: 폼 에러

```tsx
type FormFields = 'name' | 'email' | 'password'

// 각 필드별 에러 메시지 (있을 수도 없을 수도)
type FormErrors = Partial<Record<FormFields, string>>

const errors: FormErrors = {
  email: '유효하지 않은 이메일입니다',
  password: '8자 이상 입력하세요',
  // name은 에러 없음
}
```

---

## ReturnType<T>

함수의 **반환 타입**을 추출합니다.

### 기본 사용

```tsx
function getUser() {
  return {
    id: '1',
    name: 'John',
    email: 'john@example.com',
  }
}

type User = ReturnType<typeof getUser>
// 결과:
// {
//   id: string
//   name: string
//   email: string
// }
```

### 실전 예시: API 응답 타입

```tsx
// API 함수가 먼저 정의되어 있을 때
async function fetchUsers() {
  const response = await fetch('/api/users')
  const data = await response.json()
  return data as {
    users: { id: string; name: string }[]
    total: number
  }
}

// 반환 타입 추출 (Promise 벗기기)
type FetchUsersResult = Awaited<ReturnType<typeof fetchUsers>>
// 결과:
// {
//   users: { id: string; name: string }[]
//   total: number
// }
```

### 실전 예시: 훅 반환 타입

```tsx
function useAuth() {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  const login = async (email: string, password: string) => { /* ... */ }
  const logout = () => { /* ... */ }

  return { user, loading, login, logout }
}

// 훅의 반환 타입
type AuthContext = ReturnType<typeof useAuth>

// Context에서 사용
const AuthContext = createContext<AuthContext | null>(null)
```

---

## Parameters<T>

함수의 **파라미터 타입**을 튜플로 추출합니다.

### 기본 사용

```tsx
function greet(name: string, age: number): string {
  return `Hello, ${name}. You are ${age} years old.`
}

type GreetParams = Parameters<typeof greet>
// 결과: [string, number]

type FirstParam = Parameters<typeof greet>[0]  // string
type SecondParam = Parameters<typeof greet>[1]  // number
```

### 실전 예시: 래퍼 함수

```tsx
function originalFetch(url: string, options?: RequestInit): Promise<Response> {
  return fetch(url, options)
}

// 같은 파라미터를 받는 래퍼 함수
function fetchWithAuth(
  ...args: Parameters<typeof originalFetch>
): Promise<Response> {
  const [url, options = {}] = args
  return originalFetch(url, {
    ...options,
    headers: {
      ...options.headers,
      Authorization: `Bearer ${getToken()}`,
    },
  })
}
```

---

## NonNullable<T>

`null`과 `undefined`를 **제외**합니다.

### 기본 사용

```tsx
type MaybeString = string | null | undefined

type DefiniteString = NonNullable<MaybeString>
// 결과: string
```

### 실전 예시: 필터링 후 타입

```tsx
const items: (string | null)[] = ['a', null, 'b', null, 'c']

// filter로 null 제거
const filtered = items.filter((item): item is string => item !== null)
// filtered의 타입: string[]

// 또는 NonNullable 활용
const filtered2 = items.filter((item): item is NonNullable<typeof item> =>
  item !== null
)
```

---

## Awaited<T>

`Promise` 내부의 타입을 추출합니다. 중첩된 Promise도 처리합니다.

### 기본 사용

```tsx
type PromiseString = Promise<string>
type Result = Awaited<PromiseString>  // string

// 중첩 Promise
type NestedPromise = Promise<Promise<number>>
type Result2 = Awaited<NestedPromise>  // number
```

### 실전 예시: async 함수 반환 타입

```tsx
async function fetchUser(id: string) {
  const response = await fetch(`/api/users/${id}`)
  return response.json() as Promise<User>
}

// ReturnType만 쓰면 Promise<User>
type WithPromise = ReturnType<typeof fetchUser>  // Promise<User>

// Awaited로 Promise 벗기기
type WithoutPromise = Awaited<ReturnType<typeof fetchUser>>  // User
```

---

## 유틸리티 타입 조합

### 실전 예시: CRUD 타입 시스템

```tsx
interface Entity {
  id: string
  createdAt: Date
  updatedAt: Date
}

interface User extends Entity {
  name: string
  email: string
  password: string
  role: 'admin' | 'user'
}

// 생성 입력 (시스템 필드 제외)
type CreateUserInput = Omit<User, keyof Entity>

// 수정 입력 (부분 업데이트, id 필요)
type UpdateUserInput = Partial<Omit<User, keyof Entity>> & Pick<User, 'id'>

// 조회 응답 (비밀번호 제외)
type UserResponse = Omit<User, 'password'>

// 목록 조회 응답 (간략 정보만)
type UserListItem = Pick<User, 'id' | 'name' | 'email' | 'role'>
```

### 실전 예시: API 타입 시스템

```tsx
// 기본 응답 구조
interface ApiResponse<T> {
  data: T
  message: string
  timestamp: Date
}

// 페이지네이션 응답
interface PaginatedResponse<T> extends ApiResponse<T[]> {
  pagination: {
    page: number
    limit: number
    total: number
    totalPages: number
  }
}

// 사용
type UserResponse = ApiResponse<User>
type UserListResponse = PaginatedResponse<UserListItem>
```

---

## 요약 치트시트

```tsx
// 모든 속성을 선택적으로
Partial<User>

// 모든 속성을 필수로
Required<User>

// 특정 속성만 선택
Pick<User, 'id' | 'name'>

// 특정 속성 제외
Omit<User, 'password'>

// 읽기 전용으로
Readonly<User>

// 키-값 매핑
Record<'a' | 'b', number>

// 함수 반환 타입
ReturnType<typeof fn>

// 함수 파라미터 타입
Parameters<typeof fn>

// null, undefined 제외
NonNullable<string | null>

// Promise 내부 타입
Awaited<Promise<User>>
```
