# 템플릿 리터럴 타입 (Template Literal Types)

**문자열 타입을 조합**하여 새로운 문자열 타입을 만드는 기능입니다.

---

## 기본 문법

```tsx
type Greeting = `Hello, ${string}!`

const a: Greeting = 'Hello, World!'   // OK
const b: Greeting = 'Hello, John!'    // OK
const c: Greeting = 'Hi, World!'      // Error!
```

---

## 기본 예시

### 리터럴 조합

```tsx
type Color = 'red' | 'green' | 'blue'
type Size = 'small' | 'medium' | 'large'

// 모든 조합 생성
type ColorSize = `${Color}-${Size}`
// = 'red-small' | 'red-medium' | 'red-large'
//   | 'green-small' | 'green-medium' | 'green-large'
//   | 'blue-small' | 'blue-medium' | 'blue-large'

const valid: ColorSize = 'red-small'    // OK
const invalid: ColorSize = 'red-tiny'   // Error!
```

### 접두사/접미사 추가

```tsx
type EventName = 'click' | 'focus' | 'blur'

// 접두사 추가
type OnEvent = `on${Capitalize<EventName>}`
// = 'onClick' | 'onFocus' | 'onBlur'

// 접미사 추가
type EventHandler = `${EventName}Handler`
// = 'clickHandler' | 'focusHandler' | 'blurHandler'
```

---

## 내장 문자열 타입 유틸리티

TypeScript가 제공하는 문자열 변환 타입들:

```tsx
type Str = 'helloWorld'

type Upper = Uppercase<Str>     // 'HELLOWORLD'
type Lower = Lowercase<Str>     // 'helloworld'
type Cap = Capitalize<Str>      // 'HelloWorld'
type Uncap = Uncapitalize<Str>  // 'helloWorld'
```

### 실전 예시

```tsx
type EventName = 'click' | 'mouseenter' | 'mouseleave'

// React 스타일 이벤트 핸들러 이름
type ReactEventHandler = `on${Capitalize<EventName>}`
// = 'onClick' | 'onMouseenter' | 'onMouseleave'

// DOM 스타일 이벤트 리스너
type DOMEventListener = `${EventName}listener`
// = 'clicklistener' | 'mouseenterlistener' | 'mouseleavelistener'
```

---

## CSS 관련 타입

### CSS 단위

```tsx
type CSSUnit = 'px' | 'em' | 'rem' | '%' | 'vh' | 'vw'
type CSSValue = `${number}${CSSUnit}`

const width: CSSValue = '100px'   // OK
const height: CSSValue = '50vh'   // OK
const invalid: CSSValue = '100'   // Error! 단위 필요
```

### CSS 속성

```tsx
type CSSProperty = 'margin' | 'padding'
type Direction = 'top' | 'right' | 'bottom' | 'left'

type DirectionalProperty = `${CSSProperty}-${Direction}`
// = 'margin-top' | 'margin-right' | ... | 'padding-left'

type CSSStyles = {
  [K in DirectionalProperty]?: CSSValue
}

const styles: CSSStyles = {
  'margin-top': '10px',
  'padding-left': '20px',
}
```

### 색상 타입

```tsx
type HexDigit = '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' | 'a' | 'b' | 'c' | 'd' | 'e' | 'f'

// 3자리 hex (단순화)
type HexColor3 = `#${HexDigit}${HexDigit}${HexDigit}`

// 실제로는 이렇게 하면 조합이 너무 많음
// 실용적인 방법: 런타임 검증 + 타입 단언
type HexColor = `#${string}`

function isHexColor(value: string): value is HexColor {
  return /^#([0-9a-f]{3}|[0-9a-f]{6})$/i.test(value)
}
```

---

## 경로 타입

### API 경로

```tsx
type ApiVersion = 'v1' | 'v2'
type Resource = 'users' | 'posts' | 'comments'

type ApiEndpoint = `/api/${ApiVersion}/${Resource}`
// = '/api/v1/users' | '/api/v1/posts' | ... | '/api/v2/comments'

type ApiEndpointWithId = `/api/${ApiVersion}/${Resource}/${string}`

const endpoint: ApiEndpoint = '/api/v1/users'  // OK
const withId: ApiEndpointWithId = '/api/v2/posts/123'  // OK
```

### 동적 라우트

```tsx
type StaticRoute = '/' | '/about' | '/contact'
type DynamicRoute = `/users/${string}` | `/posts/${string}`

type Route = StaticRoute | DynamicRoute

function navigate(route: Route) {
  // ...
}

navigate('/')                  // OK
navigate('/users/123')         // OK
navigate('/invalid')           // Error!
```

---

## 이벤트 타입

### DOM 이벤트

```tsx
type DOMEventType =
  | 'click'
  | 'dblclick'
  | 'mouseenter'
  | 'mouseleave'
  | 'keydown'
  | 'keyup'

type EventHandler<T extends DOMEventType> = `on${Capitalize<T>}`

type ClickHandler = EventHandler<'click'>      // 'onClick'
type KeyDownHandler = EventHandler<'keydown'>  // 'onKeydown'
```

### 커스텀 이벤트

```tsx
type EntityEvent<E extends string, A extends string> = `${E}:${A}`

type UserEvent = EntityEvent<'user', 'created' | 'updated' | 'deleted'>
// = 'user:created' | 'user:updated' | 'user:deleted'

type PostEvent = EntityEvent<'post', 'published' | 'archived'>
// = 'post:published' | 'post:archived'

type AppEvent = UserEvent | PostEvent

function on(event: AppEvent, handler: () => void) {
  // ...
}

on('user:created', () => {})  // OK
on('post:deleted', () => {})  // Error! post:deleted는 없음
```

---

## 객체 키 패턴

### Getter/Setter 패턴

```tsx
type Getter<T extends string> = `get${Capitalize<T>}`
type Setter<T extends string> = `set${Capitalize<T>}`

type PropertyAccessors<T> = {
  [K in keyof T as Getter<string & K>]: () => T[K]
} & {
  [K in keyof T as Setter<string & K>]: (value: T[K]) => void
}

interface User {
  name: string
  age: number
}

type UserAccessors = PropertyAccessors<User>
// {
//   getName: () => string
//   getAge: () => number
//   setName: (value: string) => void
//   setAge: (value: number) => void
// }
```

### 상태 액션 패턴

```tsx
type StateAction<S extends string> =
  | `set${Capitalize<S>}`
  | `reset${Capitalize<S>}`
  | `toggle${Capitalize<S>}`

type BooleanActions = StateAction<'loading' | 'visible' | 'active'>
// = 'setLoading' | 'resetLoading' | 'toggleLoading'
//   | 'setVisible' | 'resetVisible' | 'toggleVisible'
//   | 'setActive' | 'resetActive' | 'toggleActive'
```

---

## 문자열 추출 (infer)

### 경로 파라미터 추출

```tsx
type ExtractRouteParams<T extends string> =
  T extends `${infer _Start}:${infer Param}/${infer Rest}`
    ? Param | ExtractRouteParams<Rest>
    : T extends `${infer _Start}:${infer Param}`
      ? Param
      : never

type Params1 = ExtractRouteParams<'/users/:userId'>
// = 'userId'

type Params2 = ExtractRouteParams<'/users/:userId/posts/:postId'>
// = 'userId' | 'postId'
```

### 이벤트 이름에서 추출

```tsx
type ExtractEventName<T extends string> =
  T extends `on${infer E}` ? Uncapitalize<E> : never

type Event1 = ExtractEventName<'onClick'>     // 'click'
type Event2 = ExtractEventName<'onMouseEnter'> // 'mouseEnter'
type Event3 = ExtractEventName<'click'>       // never
```

### 점 표기법 경로 파싱

```tsx
type Split<S extends string, D extends string> =
  S extends `${infer T}${D}${infer U}`
    ? [T, ...Split<U, D>]
    : [S]

type Path = Split<'user.profile.name', '.'>
// = ['user', 'profile', 'name']
```

---

## 실전 패턴

### 타입 안전한 라우터

```tsx
type Routes = {
  '/': {}
  '/users': {}
  '/users/:id': { id: string }
  '/posts/:postId/comments/:commentId': { postId: string; commentId: string }
}

type ExtractParams<T extends string> =
  T extends `${infer _}:${infer Param}/${infer Rest}`
    ? { [K in Param | keyof ExtractParams<Rest>]: string }
    : T extends `${infer _}:${infer Param}`
      ? { [K in Param]: string }
      : {}

function navigate<T extends keyof Routes>(
  path: T,
  ...args: keyof ExtractParams<T> extends never
    ? []
    : [params: ExtractParams<T>]
): void {
  // 구현
}

navigate('/')                                    // OK
navigate('/users')                               // OK
navigate('/users/:id', { id: '123' })            // OK
navigate('/users/:id')                           // Error! params 필요
```

### i18n 키 타입

```tsx
type Namespace = 'common' | 'auth' | 'dashboard'

type TranslationKey<N extends Namespace> = `${N}:${string}`

function t<N extends Namespace>(key: TranslationKey<N>): string {
  // 구현
  return ''
}

t('common:greeting')    // OK
t('auth:login.title')   // OK
t('invalid:key')        // Error!
```

### 환경 변수 타입

```tsx
type EnvPrefix = 'NEXT_PUBLIC_' | 'VITE_'

type PublicEnvKey = `${EnvPrefix}${string}`

function getPublicEnv(key: PublicEnvKey): string | undefined {
  return process.env[key]
}

getPublicEnv('NEXT_PUBLIC_API_URL')  // OK
getPublicEnv('VITE_APP_TITLE')       // OK
getPublicEnv('SECRET_KEY')           // Error!
```

---

## 제한사항

### 조합 폭발

유니온 타입이 크면 조합이 폭발적으로 늘어납니다:

```tsx
type Digit = '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9'

// 2자리 숫자: 100개 조합 → OK
type TwoDigits = `${Digit}${Digit}`

// 3자리 숫자: 1000개 조합 → 느려질 수 있음
type ThreeDigits = `${Digit}${Digit}${Digit}`

// 6자리: 100만 개 조합 → 에러!
// type SixDigits = `${Digit}${Digit}${Digit}${Digit}${Digit}${Digit}`
```

### 해결책

```tsx
// 런타임 검증과 타입 가드 조합
type DigitString = `${number}`

function isValidCode(value: string): value is `${number}` {
  return /^\d{6}$/.test(value)
}

const code: unknown = '123456'
if (isValidCode(code)) {
  // code: `${number}`
}
```

---

## 요약

```tsx
// 기본 조합
type Combined = `${A}-${B}`

// 문자열 변환
Uppercase<T>      // 대문자
Lowercase<T>      // 소문자
Capitalize<T>     // 첫 글자 대문자
Uncapitalize<T>   // 첫 글자 소문자

// 키 리매핑과 조합
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K]
}

// infer로 추출
type ExtractParam<T> = T extends `${string}:${infer P}` ? P : never

// 실전 패턴
type ApiPath = `/api/${Version}/${Resource}`
type EventHandler = `on${Capitalize<EventName>}`
type CSSValue = `${number}${Unit}`
```
