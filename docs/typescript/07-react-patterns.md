# React 타입 패턴

React에서 자주 사용하는 TypeScript 패턴들을 정리합니다.

---

## 컴포넌트 Props

### 기본 Props 타입

```tsx
// interface 사용 (권장)
interface ButtonProps {
  children: React.ReactNode
  onClick?: () => void
  disabled?: boolean
}

function Button({ children, onClick, disabled }: ButtonProps) {
  return (
    <button onClick={onClick} disabled={disabled}>
      {children}
    </button>
  )
}

// type 사용
type ButtonProps = {
  children: React.ReactNode
  onClick?: () => void
}
```

### HTML 요소 확장

```tsx
// button 요소의 모든 속성 상속
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary'
  isLoading?: boolean
}

function Button({
  variant = 'primary',
  isLoading,
  children,
  disabled,
  ...props  // 나머지 button 속성들
}: ButtonProps) {
  return (
    <button
      disabled={disabled || isLoading}
      className={variant}
      {...props}
    >
      {isLoading ? 'Loading...' : children}
    </button>
  )
}

// 사용
<Button type="submit" onClick={handleClick} variant="primary">
  Submit
</Button>
```

### 특정 속성 제외하고 확장

```tsx
// 'size' 속성 제외 (커스텀 size 사용)
interface InputProps extends Omit<
  React.InputHTMLAttributes<HTMLInputElement>,
  'size'
> {
  size?: 'sm' | 'md' | 'lg'
  error?: string
}

function Input({ size = 'md', error, className, ...props }: InputProps) {
  return (
    <div>
      <input className={`input-${size} ${className}`} {...props} />
      {error && <span className="error">{error}</span>}
    </div>
  )
}
```

### ComponentPropsWithoutRef

```tsx
import { ComponentPropsWithoutRef } from 'react'

// 더 간결한 방법
type ButtonProps = ComponentPropsWithoutRef<'button'> & {
  variant?: 'primary' | 'secondary'
}

// 다른 컴포넌트의 props 가져오기
type MyButtonProps = ComponentPropsWithoutRef<typeof Button> & {
  extra?: string
}
```

---

## Children 타입

```tsx
// 가장 일반적 - 모든 렌더링 가능한 것
interface Props {
  children: React.ReactNode
}

// 단일 요소만
interface Props {
  children: React.ReactElement
}

// 특정 컴포넌트만
interface Props {
  children: React.ReactElement<TabProps>
}

// 문자열만
interface Props {
  children: string
}

// 함수 (render props)
interface Props {
  children: (data: Data) => React.ReactNode
}

// 선택적 children
interface Props {
  children?: React.ReactNode
}
```

### ReactNode vs ReactElement

```tsx
// ReactNode: 렌더링 가능한 모든 것
type ReactNode =
  | ReactElement
  | string
  | number
  | boolean
  | null
  | undefined
  | Iterable<ReactNode>

// ReactElement: JSX 요소만
type ReactElement = {
  type: string | ComponentType
  props: object
  key: string | null
}

// 대부분의 경우 ReactNode 사용
interface LayoutProps {
  children: React.ReactNode
}
```

---

## 이벤트 핸들러

### 기본 이벤트 타입

```tsx
// 클릭 이벤트
function handleClick(event: React.MouseEvent<HTMLButtonElement>) {
  console.log(event.currentTarget.name)
}

// 입력 이벤트
function handleChange(event: React.ChangeEvent<HTMLInputElement>) {
  console.log(event.target.value)
}

// 폼 제출
function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
  event.preventDefault()
}

// 키보드 이벤트
function handleKeyDown(event: React.KeyboardEvent<HTMLInputElement>) {
  if (event.key === 'Enter') {
    // ...
  }
}

// 포커스 이벤트
function handleFocus(event: React.FocusEvent<HTMLInputElement>) {
  event.target.select()
}
```

### Props에서 이벤트 핸들러

```tsx
interface FormProps {
  onSubmit: (event: React.FormEvent<HTMLFormElement>) => void
  onChange: (event: React.ChangeEvent<HTMLInputElement>) => void
}

// 또는 React 제공 타입 사용
interface FormProps {
  onSubmit: React.FormEventHandler<HTMLFormElement>
  onChange: React.ChangeEventHandler<HTMLInputElement>
}
```

### 커스텀 이벤트 핸들러

```tsx
interface SelectProps {
  // 값만 전달
  onChange: (value: string) => void

  // 값과 이벤트 둘 다
  onChange: (value: string, event: React.ChangeEvent<HTMLSelectElement>) => void

  // 여러 값
  onSelect: (item: Item, index: number) => void
}

function Select({ onChange }: SelectProps) {
  return (
    <select onChange={(e) => onChange(e.target.value, e)}>
      {/* ... */}
    </select>
  )
}
```

---

## 제네릭 컴포넌트

### 리스트 컴포넌트

```tsx
interface ListProps<T> {
  items: T[]
  renderItem: (item: T, index: number) => React.ReactNode
  keyExtractor: (item: T) => string
  emptyMessage?: string
}

function List<T>({
  items,
  renderItem,
  keyExtractor,
  emptyMessage = 'No items',
}: ListProps<T>) {
  if (items.length === 0) {
    return <p>{emptyMessage}</p>
  }

  return (
    <ul>
      {items.map((item, index) => (
        <li key={keyExtractor(item)}>{renderItem(item, index)}</li>
      ))}
    </ul>
  )
}

// 사용
interface User {
  id: string
  name: string
}

<List<User>
  items={users}
  keyExtractor={(user) => user.id}
  renderItem={(user) => <span>{user.name}</span>}
/>

// 타입 추론도 됨
<List
  items={users}  // User[]로 추론
  keyExtractor={(user) => user.id}  // user는 User로 추론
  renderItem={(user) => <span>{user.name}</span>}
/>
```

### Select 컴포넌트

```tsx
interface SelectOption<T> {
  value: T
  label: string
}

interface SelectProps<T> {
  options: SelectOption<T>[]
  value: T
  onChange: (value: T) => void
  placeholder?: string
}

function Select<T extends string | number>({
  options,
  value,
  onChange,
  placeholder,
}: SelectProps<T>) {
  return (
    <select
      value={value}
      onChange={(e) => onChange(e.target.value as T)}
    >
      {placeholder && (
        <option value="" disabled>
          {placeholder}
        </option>
      )}
      {options.map((option) => (
        <option key={String(option.value)} value={option.value}>
          {option.label}
        </option>
      ))}
    </select>
  )
}

// 사용
type Status = 'pending' | 'approved' | 'rejected'

const options: SelectOption<Status>[] = [
  { value: 'pending', label: '대기' },
  { value: 'approved', label: '승인' },
  { value: 'rejected', label: '거절' },
]

<Select<Status>
  options={options}
  value={status}
  onChange={setStatus}  // (value: Status) => void
/>
```

### 테이블 컴포넌트

```tsx
interface Column<T> {
  key: keyof T
  header: string
  render?: (value: T[keyof T], item: T) => React.ReactNode
}

interface TableProps<T> {
  data: T[]
  columns: Column<T>[]
  onRowClick?: (item: T) => void
}

function Table<T extends { id: string | number }>({
  data,
  columns,
  onRowClick,
}: TableProps<T>) {
  return (
    <table>
      <thead>
        <tr>
          {columns.map((col) => (
            <th key={String(col.key)}>{col.header}</th>
          ))}
        </tr>
      </thead>
      <tbody>
        {data.map((item) => (
          <tr key={item.id} onClick={() => onRowClick?.(item)}>
            {columns.map((col) => (
              <td key={String(col.key)}>
                {col.render
                  ? col.render(item[col.key], item)
                  : String(item[col.key])}
              </td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  )
}
```

---

## forwardRef

```tsx
import { forwardRef } from 'react'

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string
  error?: string
}

const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, ...props }, ref) => {
    return (
      <div>
        {label && <label>{label}</label>}
        <input ref={ref} {...props} />
        {error && <span className="error">{error}</span>}
      </div>
    )
  }
)

Input.displayName = 'Input'

// 사용
function Form() {
  const inputRef = useRef<HTMLInputElement>(null)

  return <Input ref={inputRef} label="Name" />
}
```

### 제네릭 forwardRef

```tsx
// 제네릭 컴포넌트에 forwardRef 사용
interface SelectProps<T> {
  options: T[]
  value: T
  onChange: (value: T) => void
}

// 타입 단언 필요
const Select = forwardRef(function Select<T>(
  props: SelectProps<T>,
  ref: React.ForwardedRef<HTMLSelectElement>
) {
  return <select ref={ref}>{/* ... */}</select>
}) as <T>(
  props: SelectProps<T> & { ref?: React.ForwardedRef<HTMLSelectElement> }
) => React.ReactElement
```

---

## Hooks 타입

### useState

```tsx
// 타입 추론
const [count, setCount] = useState(0)  // number

// 명시적 타입
const [user, setUser] = useState<User | null>(null)

// 복잡한 타입
interface State {
  loading: boolean
  data: User | null
  error: Error | null
}

const [state, setState] = useState<State>({
  loading: true,
  data: null,
  error: null,
})
```

### useRef

```tsx
// DOM 요소
const inputRef = useRef<HTMLInputElement>(null)

// 값 저장 (변경 가능)
const countRef = useRef<number>(0)
countRef.current = 1  // OK

// 값 저장 (초기값 없음)
const valueRef = useRef<string>()
// valueRef.current는 string | undefined
```

### useReducer

```tsx
interface State {
  count: number
  loading: boolean
}

type Action =
  | { type: 'increment' }
  | { type: 'decrement' }
  | { type: 'set'; payload: number }
  | { type: 'setLoading'; payload: boolean }

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'increment':
      return { ...state, count: state.count + 1 }
    case 'decrement':
      return { ...state, count: state.count - 1 }
    case 'set':
      return { ...state, count: action.payload }
    case 'setLoading':
      return { ...state, loading: action.payload }
  }
}

function Counter() {
  const [state, dispatch] = useReducer(reducer, {
    count: 0,
    loading: false,
  })

  dispatch({ type: 'increment' })
  dispatch({ type: 'set', payload: 10 })
}
```

### useContext

```tsx
interface AuthContext {
  user: User | null
  login: (email: string, password: string) => Promise<void>
  logout: () => void
}

const AuthContext = createContext<AuthContext | null>(null)

// 커스텀 훅으로 null 체크
function useAuth(): AuthContext {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider')
  }
  return context
}

// 사용
function Profile() {
  const { user, logout } = useAuth()  // null 체크 완료
  // ...
}
```

### 커스텀 훅 타입

```tsx
// 반환 타입 추론
function useToggle(initial = false) {
  const [value, setValue] = useState(initial)
  const toggle = useCallback(() => setValue((v) => !v), [])
  const setTrue = useCallback(() => setValue(true), [])
  const setFalse = useCallback(() => setValue(false), [])

  return { value, toggle, setTrue, setFalse }
}

// 명시적 반환 타입
interface UseToggleReturn {
  value: boolean
  toggle: () => void
  setTrue: () => void
  setFalse: () => void
}

function useToggle(initial = false): UseToggleReturn {
  // ...
}

// 튜플 반환
function useToggle(initial = false): [boolean, () => void] {
  const [value, setValue] = useState(initial)
  const toggle = useCallback(() => setValue((v) => !v), [])
  return [value, toggle]
}
```

### 제네릭 훅

```tsx
function useLocalStorage<T>(key: string, initialValue: T) {
  const [storedValue, setStoredValue] = useState<T>(() => {
    try {
      const item = window.localStorage.getItem(key)
      return item ? JSON.parse(item) : initialValue
    } catch {
      return initialValue
    }
  })

  const setValue = (value: T | ((val: T) => T)) => {
    try {
      const valueToStore =
        value instanceof Function ? value(storedValue) : value
      setStoredValue(valueToStore)
      window.localStorage.setItem(key, JSON.stringify(valueToStore))
    } catch (error) {
      console.error(error)
    }
  }

  return [storedValue, setValue] as const
}

// 사용
const [user, setUser] = useLocalStorage<User | null>('user', null)
```

---

## Context 패턴

### Provider 패턴

```tsx
interface ThemeContextValue {
  theme: 'light' | 'dark'
  toggleTheme: () => void
}

const ThemeContext = createContext<ThemeContextValue | undefined>(undefined)

interface ThemeProviderProps {
  children: React.ReactNode
  defaultTheme?: 'light' | 'dark'
}

function ThemeProvider({ children, defaultTheme = 'light' }: ThemeProviderProps) {
  const [theme, setTheme] = useState<'light' | 'dark'>(defaultTheme)

  const toggleTheme = useCallback(() => {
    setTheme((t) => (t === 'light' ? 'dark' : 'light'))
  }, [])

  const value = useMemo(() => ({ theme, toggleTheme }), [theme, toggleTheme])

  return (
    <ThemeContext.Provider value={value}>
      {children}
    </ThemeContext.Provider>
  )
}

function useTheme(): ThemeContextValue {
  const context = useContext(ThemeContext)
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider')
  }
  return context
}

export { ThemeProvider, useTheme }
```

---

## 컴포넌트 타입

### FC vs 일반 함수

```tsx
// React.FC 사용 (권장하지 않음)
const Button: React.FC<ButtonProps> = ({ children }) => {
  return <button>{children}</button>
}

// 일반 함수 (권장)
function Button({ children }: ButtonProps) {
  return <button>{children}</button>
}

// 이유:
// 1. FC는 암시적 children 포함 (React 18부터 제거됨)
// 2. 제네릭 컴포넌트에 FC 사용 어려움
// 3. 타입 추론이 더 좋음
```

### 조건부 Props

```tsx
// 상호 배타적 Props
type ButtonProps =
  | {
      variant: 'link'
      href: string
      onClick?: never
    }
  | {
      variant: 'button'
      onClick: () => void
      href?: never
    }

function Button(props: ButtonProps) {
  if (props.variant === 'link') {
    return <a href={props.href}>Link</a>
  }
  return <button onClick={props.onClick}>Button</button>
}

// 사용
<Button variant="link" href="/about" />
<Button variant="button" onClick={() => {}} />
<Button variant="link" onClick={() => {}} />  // Error!
```

### Polymorphic 컴포넌트

```tsx
type AsProp<C extends React.ElementType> = {
  as?: C
}

type PropsWithAs<C extends React.ElementType, Props = {}> = Props &
  AsProp<C> &
  Omit<React.ComponentPropsWithoutRef<C>, keyof Props | 'as'>

interface BoxOwnProps {
  padding?: number
  margin?: number
}

type BoxProps<C extends React.ElementType = 'div'> = PropsWithAs<C, BoxOwnProps>

function Box<C extends React.ElementType = 'div'>({
  as,
  padding,
  margin,
  style,
  ...props
}: BoxProps<C>) {
  const Component = as || 'div'

  return (
    <Component
      style={{ padding, margin, ...style }}
      {...props}
    />
  )
}

// 사용
<Box>Default div</Box>
<Box as="section">Section</Box>
<Box as="a" href="/about">Link</Box>
<Box as={CustomComponent} customProp="value">Custom</Box>
```

---

## 요약

```tsx
// Props 확장
interface Props extends React.ButtonHTMLAttributes<HTMLButtonElement> {}

// Children
children: React.ReactNode

// 이벤트
onClick: (e: React.MouseEvent<HTMLButtonElement>) => void
onChange: React.ChangeEventHandler<HTMLInputElement>

// 제네릭 컴포넌트
function List<T>({ items }: { items: T[] }) {}

// forwardRef
const Input = forwardRef<HTMLInputElement, Props>((props, ref) => {})

// Context
const Context = createContext<Value | undefined>(undefined)

// 훅 반환
return [value, setValue] as const
```
