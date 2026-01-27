# 실전 패턴 모음

React 개발에서 자주 사용되는 패턴과 모범 사례를 알아봅니다.

---

## 컴포넌트 패턴

### Compound Components

관련된 컴포넌트들을 하나의 API로 묶습니다.

```tsx
// 사용
<Menu>
  <Menu.Button>Options</Menu.Button>
  <Menu.List>
    <Menu.Item onClick={edit}>Edit</Menu.Item>
    <Menu.Item onClick={copy}>Copy</Menu.Item>
    <Menu.Item onClick={remove}>Delete</Menu.Item>
  </Menu.List>
</Menu>
```

```tsx
// 구현
const MenuContext = createContext<{
  isOpen: boolean
  toggle: () => void
} | null>(null)

function Menu({ children }: { children: React.ReactNode }) {
  const [isOpen, setIsOpen] = useState(false)
  const toggle = useCallback(() => setIsOpen(v => !v), [])

  return (
    <MenuContext.Provider value={{ isOpen, toggle }}>
      <div className="menu">{children}</div>
    </MenuContext.Provider>
  )
}

function MenuButton({ children }: { children: React.ReactNode }) {
  const context = useContext(MenuContext)
  if (!context) throw new Error('Menu.Button must be used within Menu')

  return (
    <button onClick={context.toggle}>
      {children}
    </button>
  )
}

function MenuList({ children }: { children: React.ReactNode }) {
  const context = useContext(MenuContext)
  if (!context) throw new Error('Menu.List must be used within Menu')

  if (!context.isOpen) return null

  return <ul className="menu-list">{children}</ul>
}

function MenuItem({
  children,
  onClick,
}: {
  children: React.ReactNode
  onClick: () => void
}) {
  const context = useContext(MenuContext)
  if (!context) throw new Error('Menu.Item must be used within Menu')

  const handleClick = () => {
    onClick()
    context.toggle()
  }

  return <li onClick={handleClick}>{children}</li>
}

// 조합
Menu.Button = MenuButton
Menu.List = MenuList
Menu.Item = MenuItem

export { Menu }
```

### Render Props

컴포넌트 로직을 재사용하면서 렌더링을 위임합니다.

```tsx
// 사용
<Mouse>
  {({ x, y }) => (
    <div>Mouse position: {x}, {y}</div>
  )}
</Mouse>
```

```tsx
// 구현
interface MouseState {
  x: number
  y: number
}

interface MouseProps {
  children: (state: MouseState) => React.ReactNode
}

function Mouse({ children }: MouseProps) {
  const [position, setPosition] = useState({ x: 0, y: 0 })

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      setPosition({ x: e.clientX, y: e.clientY })
    }

    window.addEventListener('mousemove', handleMouseMove)
    return () => window.removeEventListener('mousemove', handleMouseMove)
  }, [])

  return <>{children(position)}</>
}
```

### Higher-Order Components (HOC)

컴포넌트를 받아 새 컴포넌트를 반환합니다.

```tsx
// 사용
const EnhancedComponent = withAuth(MyComponent)
```

```tsx
// 구현
function withAuth<P extends object>(
  WrappedComponent: React.ComponentType<P>
) {
  return function WithAuthComponent(props: P) {
    const { user, loading } = useAuth()

    if (loading) return <Spinner />
    if (!user) return <Navigate to="/login" />

    return <WrappedComponent {...props} />
  }
}

// 로깅 HOC
function withLogging<P extends object>(
  WrappedComponent: React.ComponentType<P>,
  componentName: string
) {
  return function WithLoggingComponent(props: P) {
    useEffect(() => {
      console.log(`${componentName} mounted`)
      return () => console.log(`${componentName} unmounted`)
    }, [])

    return <WrappedComponent {...props} />
  }
}
```

### Controlled vs Uncontrolled

```tsx
// Controlled: 상태를 부모가 관리
function ControlledInput({
  value,
  onChange,
}: {
  value: string
  onChange: (value: string) => void
}) {
  return (
    <input
      value={value}
      onChange={e => onChange(e.target.value)}
    />
  )
}

// 사용
function Parent() {
  const [value, setValue] = useState('')
  return <ControlledInput value={value} onChange={setValue} />
}
```

```tsx
// Uncontrolled: 상태를 컴포넌트 내부에서 관리
function UncontrolledInput({
  defaultValue,
  onBlur,
}: {
  defaultValue?: string
  onBlur?: (value: string) => void
}) {
  const inputRef = useRef<HTMLInputElement>(null)

  return (
    <input
      ref={inputRef}
      defaultValue={defaultValue}
      onBlur={() => onBlur?.(inputRef.current?.value ?? '')}
    />
  )
}

// 사용
function Parent() {
  const handleBlur = (value: string) => {
    console.log('Final value:', value)
  }
  return <UncontrolledInput defaultValue="hello" onBlur={handleBlur} />
}
```

```tsx
// 둘 다 지원 (Flexible)
interface InputProps {
  value?: string
  defaultValue?: string
  onChange?: (value: string) => void
}

function FlexibleInput({ value, defaultValue, onChange }: InputProps) {
  const [internalValue, setInternalValue] = useState(defaultValue ?? '')

  const isControlled = value !== undefined
  const currentValue = isControlled ? value : internalValue

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value

    if (!isControlled) {
      setInternalValue(newValue)
    }

    onChange?.(newValue)
  }

  return <input value={currentValue} onChange={handleChange} />
}
```

---

## 상태 관리 패턴

### Reducer + Context

```tsx
// types
type State = {
  items: Item[]
  loading: boolean
  error: string | null
}

type Action =
  | { type: 'FETCH_START' }
  | { type: 'FETCH_SUCCESS'; payload: Item[] }
  | { type: 'FETCH_ERROR'; payload: string }
  | { type: 'ADD_ITEM'; payload: Item }
  | { type: 'REMOVE_ITEM'; payload: string }

// reducer
function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'FETCH_START':
      return { ...state, loading: true, error: null }
    case 'FETCH_SUCCESS':
      return { ...state, loading: false, items: action.payload }
    case 'FETCH_ERROR':
      return { ...state, loading: false, error: action.payload }
    case 'ADD_ITEM':
      return { ...state, items: [...state.items, action.payload] }
    case 'REMOVE_ITEM':
      return { ...state, items: state.items.filter(i => i.id !== action.payload) }
    default:
      return state
  }
}

// context
const StateContext = createContext<State | null>(null)
const DispatchContext = createContext<React.Dispatch<Action> | null>(null)

// provider
function ItemsProvider({ children }: { children: React.ReactNode }) {
  const [state, dispatch] = useReducer(reducer, {
    items: [],
    loading: false,
    error: null,
  })

  return (
    <StateContext.Provider value={state}>
      <DispatchContext.Provider value={dispatch}>
        {children}
      </DispatchContext.Provider>
    </StateContext.Provider>
  )
}

// hooks
function useItemsState() {
  const context = useContext(StateContext)
  if (!context) throw new Error('useItemsState must be used within ItemsProvider')
  return context
}

function useItemsDispatch() {
  const context = useContext(DispatchContext)
  if (!context) throw new Error('useItemsDispatch must be used within ItemsProvider')
  return context
}

// 사용
function ItemList() {
  const { items, loading } = useItemsState()
  const dispatch = useItemsDispatch()

  if (loading) return <Spinner />

  return (
    <ul>
      {items.map(item => (
        <li key={item.id}>
          {item.name}
          <button onClick={() => dispatch({ type: 'REMOVE_ITEM', payload: item.id })}>
            Remove
          </button>
        </li>
      ))}
    </ul>
  )
}
```

### 상태 머신

```tsx
type LoadingState =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: Data }
  | { status: 'error'; error: Error }

type LoadingAction =
  | { type: 'FETCH' }
  | { type: 'SUCCESS'; data: Data }
  | { type: 'ERROR'; error: Error }
  | { type: 'RESET' }

function loadingReducer(state: LoadingState, action: LoadingAction): LoadingState {
  switch (state.status) {
    case 'idle':
      if (action.type === 'FETCH') return { status: 'loading' }
      return state

    case 'loading':
      if (action.type === 'SUCCESS') return { status: 'success', data: action.data }
      if (action.type === 'ERROR') return { status: 'error', error: action.error }
      return state

    case 'success':
      if (action.type === 'FETCH') return { status: 'loading' }
      if (action.type === 'RESET') return { status: 'idle' }
      return state

    case 'error':
      if (action.type === 'FETCH') return { status: 'loading' }
      if (action.type === 'RESET') return { status: 'idle' }
      return state

    default:
      return state
  }
}

// 사용
function DataFetcher() {
  const [state, dispatch] = useReducer(loadingReducer, { status: 'idle' })

  const fetchData = async () => {
    dispatch({ type: 'FETCH' })
    try {
      const data = await fetch('/api/data').then(r => r.json())
      dispatch({ type: 'SUCCESS', data })
    } catch (error) {
      dispatch({ type: 'ERROR', error: error as Error })
    }
  }

  switch (state.status) {
    case 'idle':
      return <button onClick={fetchData}>Load Data</button>
    case 'loading':
      return <Spinner />
    case 'success':
      return <DataDisplay data={state.data} />
    case 'error':
      return <ErrorMessage error={state.error} onRetry={fetchData} />
  }
}
```

---

## 데이터 페칭 패턴

### 에러 바운더리

```tsx
interface ErrorBoundaryProps {
  fallback: React.ReactNode | ((error: Error, reset: () => void) => React.ReactNode)
  children: React.ReactNode
}

interface ErrorBoundaryState {
  hasError: boolean
  error: Error | null
}

class ErrorBoundary extends React.Component<ErrorBoundaryProps, ErrorBoundaryState> {
  state: ErrorBoundaryState = { hasError: false, error: null }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Error caught:', error, errorInfo)
  }

  reset = () => {
    this.setState({ hasError: false, error: null })
  }

  render() {
    if (this.state.hasError && this.state.error) {
      if (typeof this.props.fallback === 'function') {
        return this.props.fallback(this.state.error, this.reset)
      }
      return this.props.fallback
    }

    return this.props.children
  }
}

// 사용
<ErrorBoundary
  fallback={(error, reset) => (
    <div>
      <p>Something went wrong: {error.message}</p>
      <button onClick={reset}>Try again</button>
    </div>
  )}
>
  <App />
</ErrorBoundary>
```

### Suspense + 에러 바운더리

```tsx
function AsyncBoundary({
  children,
  loadingFallback,
  errorFallback,
}: {
  children: React.ReactNode
  loadingFallback: React.ReactNode
  errorFallback: React.ReactNode | ((error: Error, reset: () => void) => React.ReactNode)
}) {
  return (
    <ErrorBoundary fallback={errorFallback}>
      <Suspense fallback={loadingFallback}>
        {children}
      </Suspense>
    </ErrorBoundary>
  )
}

// 사용
<AsyncBoundary
  loadingFallback={<Spinner />}
  errorFallback={(error, reset) => <ErrorMessage error={error} onRetry={reset} />}
>
  <UserProfile userId={userId} />
</AsyncBoundary>
```

### 낙관적 업데이트

```tsx
function useOptimisticUpdate<T, U>(
  currentData: T,
  updateFn: (data: T, variables: U) => T,
  mutationFn: (variables: U) => Promise<T>
) {
  const [optimisticData, setOptimisticData] = useState(currentData)
  const [isPending, setIsPending] = useState(false)
  const [error, setError] = useState<Error | null>(null)

  useEffect(() => {
    setOptimisticData(currentData)
  }, [currentData])

  const mutate = async (variables: U) => {
    setIsPending(true)
    setError(null)

    // 낙관적 업데이트
    const previousData = optimisticData
    setOptimisticData(updateFn(optimisticData, variables))

    try {
      const result = await mutationFn(variables)
      setOptimisticData(result)
    } catch (e) {
      // 롤백
      setOptimisticData(previousData)
      setError(e as Error)
    } finally {
      setIsPending(false)
    }
  }

  return { data: optimisticData, isPending, error, mutate }
}

// 사용
function TodoList() {
  const [todos, setTodos] = useState<Todo[]>([])

  const { data, isPending, mutate } = useOptimisticUpdate(
    todos,
    (todos, newTodo: Todo) => [...todos, newTodo],
    async (newTodo) => {
      const result = await fetch('/api/todos', {
        method: 'POST',
        body: JSON.stringify(newTodo),
      }).then(r => r.json())

      setTodos(prev => [...prev, result])
      return result
    }
  )

  const addTodo = () => {
    mutate({ id: Date.now().toString(), text: 'New Todo', done: false })
  }

  return (
    <div>
      <ul>
        {data.map(todo => (
          <li key={todo.id} style={{ opacity: isPending ? 0.5 : 1 }}>
            {todo.text}
          </li>
        ))}
      </ul>
      <button onClick={addTodo}>Add Todo</button>
    </div>
  )
}
```

---

## 폼 패턴

### 필드 레벨 검증

```tsx
interface FieldProps {
  name: string
  validate?: (value: string) => string | undefined
  children: (field: {
    value: string
    error: string | undefined
    touched: boolean
    onChange: (value: string) => void
    onBlur: () => void
  }) => React.ReactNode
}

function Field({ name, validate, children }: FieldProps) {
  const [value, setValue] = useState('')
  const [touched, setTouched] = useState(false)
  const [error, setError] = useState<string | undefined>()

  const handleChange = (newValue: string) => {
    setValue(newValue)
    if (validate) {
      setError(validate(newValue))
    }
  }

  const handleBlur = () => {
    setTouched(true)
    if (validate) {
      setError(validate(value))
    }
  }

  return (
    <>
      {children({
        value,
        error: touched ? error : undefined,
        touched,
        onChange: handleChange,
        onBlur: handleBlur,
      })}
    </>
  )
}

// 사용
<Field
  name="email"
  validate={(value) => {
    if (!value) return 'Required'
    if (!value.includes('@')) return 'Invalid email'
  }}
>
  {({ value, error, onChange, onBlur }) => (
    <div>
      <input
        value={value}
        onChange={e => onChange(e.target.value)}
        onBlur={onBlur}
      />
      {error && <span className="error">{error}</span>}
    </div>
  )}
</Field>
```

### 멀티스텝 폼

```tsx
interface Step {
  id: string
  component: React.ComponentType<StepProps>
  validate?: (data: FormData) => boolean
}

interface StepProps {
  data: FormData
  updateData: (updates: Partial<FormData>) => void
}

function MultiStepForm({ steps }: { steps: Step[] }) {
  const [currentStep, setCurrentStep] = useState(0)
  const [data, setData] = useState<FormData>({})

  const updateData = (updates: Partial<FormData>) => {
    setData(prev => ({ ...prev, ...updates }))
  }

  const goNext = () => {
    const step = steps[currentStep]
    if (step.validate && !step.validate(data)) {
      return
    }
    setCurrentStep(prev => Math.min(prev + 1, steps.length - 1))
  }

  const goBack = () => {
    setCurrentStep(prev => Math.max(prev - 1, 0))
  }

  const CurrentStepComponent = steps[currentStep].component
  const isFirstStep = currentStep === 0
  const isLastStep = currentStep === steps.length - 1

  return (
    <div>
      <div className="progress">
        Step {currentStep + 1} of {steps.length}
      </div>

      <CurrentStepComponent data={data} updateData={updateData} />

      <div className="buttons">
        {!isFirstStep && <button onClick={goBack}>Back</button>}
        {!isLastStep ? (
          <button onClick={goNext}>Next</button>
        ) : (
          <button onClick={() => handleSubmit(data)}>Submit</button>
        )}
      </div>
    </div>
  )
}

// 사용
const steps: Step[] = [
  { id: 'personal', component: PersonalInfoStep },
  { id: 'address', component: AddressStep },
  { id: 'review', component: ReviewStep },
]

<MultiStepForm steps={steps} />
```

---

## 레이아웃 패턴

### Slot 패턴

```tsx
interface LayoutProps {
  header?: React.ReactNode
  sidebar?: React.ReactNode
  footer?: React.ReactNode
  children: React.ReactNode
}

function Layout({ header, sidebar, footer, children }: LayoutProps) {
  return (
    <div className="layout">
      {header && <header className="header">{header}</header>}
      <div className="main">
        {sidebar && <aside className="sidebar">{sidebar}</aside>}
        <main className="content">{children}</main>
      </div>
      {footer && <footer className="footer">{footer}</footer>}
    </div>
  )
}

// 사용
<Layout
  header={<Navigation />}
  sidebar={<Sidebar />}
  footer={<Footer />}
>
  <MainContent />
</Layout>
```

### Portal

```tsx
function Modal({ isOpen, onClose, children }: {
  isOpen: boolean
  onClose: () => void
  children: React.ReactNode
}) {
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden'
    }
    return () => {
      document.body.style.overflow = ''
    }
  }, [isOpen])

  if (!isOpen) return null

  return createPortal(
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={e => e.stopPropagation()}>
        {children}
      </div>
    </div>,
    document.body
  )
}

// 사용
function App() {
  const [isOpen, setIsOpen] = useState(false)

  return (
    <div>
      <button onClick={() => setIsOpen(true)}>Open Modal</button>
      <Modal isOpen={isOpen} onClose={() => setIsOpen(false)}>
        <h2>Modal Content</h2>
        <button onClick={() => setIsOpen(false)}>Close</button>
      </Modal>
    </div>
  )
}
```

---

## 접근성 패턴

### Focus Trap

```tsx
function useFocusTrap(isActive: boolean) {
  const containerRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!isActive || !containerRef.current) return

    const container = containerRef.current
    const focusableElements = container.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    )
    const firstElement = focusableElements[0] as HTMLElement
    const lastElement = focusableElements[focusableElements.length - 1] as HTMLElement

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key !== 'Tab') return

      if (e.shiftKey) {
        if (document.activeElement === firstElement) {
          e.preventDefault()
          lastElement.focus()
        }
      } else {
        if (document.activeElement === lastElement) {
          e.preventDefault()
          firstElement.focus()
        }
      }
    }

    container.addEventListener('keydown', handleKeyDown)
    firstElement?.focus()

    return () => container.removeEventListener('keydown', handleKeyDown)
  }, [isActive])

  return containerRef
}

// 사용
function Dialog({ isOpen, children }) {
  const containerRef = useFocusTrap(isOpen)

  if (!isOpen) return null

  return (
    <div ref={containerRef} role="dialog" aria-modal="true">
      {children}
    </div>
  )
}
```

### 라이브 리전

```tsx
function useAnnounce() {
  const announce = useCallback((message: string, priority: 'polite' | 'assertive' = 'polite') => {
    const region = document.createElement('div')
    region.setAttribute('aria-live', priority)
    region.setAttribute('aria-atomic', 'true')
    region.setAttribute('class', 'sr-only')
    document.body.appendChild(region)

    setTimeout(() => {
      region.textContent = message
    }, 100)

    setTimeout(() => {
      document.body.removeChild(region)
    }, 1000)
  }, [])

  return announce
}

// 사용
function SubmitButton() {
  const announce = useAnnounce()

  const handleSubmit = async () => {
    try {
      await submitForm()
      announce('Form submitted successfully')
    } catch {
      announce('Form submission failed', 'assertive')
    }
  }

  return <button onClick={handleSubmit}>Submit</button>
}
```

---

## 테스트 친화적 패턴

### 의존성 주입

```tsx
// 직접 import 대신 props나 context로 주입
interface UserServiceProps {
  userService: {
    getUser: (id: string) => Promise<User>
    updateUser: (user: User) => Promise<User>
  }
}

function UserProfile({ userService }: UserServiceProps) {
  const [user, setUser] = useState<User | null>(null)

  useEffect(() => {
    userService.getUser('1').then(setUser)
  }, [userService])

  return user ? <Profile user={user} /> : <Spinner />
}

// 프로덕션
<UserProfile userService={realUserService} />

// 테스트
<UserProfile userService={mockUserService} />
```

### 데이터 테스트 속성

```tsx
function LoginForm() {
  return (
    <form data-testid="login-form">
      <input
        data-testid="email-input"
        type="email"
        placeholder="Email"
      />
      <input
        data-testid="password-input"
        type="password"
        placeholder="Password"
      />
      <button data-testid="submit-button" type="submit">
        Login
      </button>
    </form>
  )
}

// 테스트
test('submits login form', async () => {
  render(<LoginForm />)

  await userEvent.type(screen.getByTestId('email-input'), 'test@example.com')
  await userEvent.type(screen.getByTestId('password-input'), 'password')
  await userEvent.click(screen.getByTestId('submit-button'))

  // assertions...
})
```

---

## 요약

### 컴포넌트 패턴

| 패턴 | 용도 |
|------|------|
| Compound Components | 관련 컴포넌트 그룹화 |
| Render Props | 렌더링 로직 위임 |
| HOC | 횡단 관심사 추가 |
| Controlled/Uncontrolled | 상태 관리 방식 |

### 상태 관리 패턴

| 패턴 | 용도 |
|------|------|
| Reducer + Context | 전역 상태 관리 |
| 상태 머신 | 복잡한 상태 전이 |
| 낙관적 업데이트 | 즉각적인 UI 반응 |

### 레이아웃 패턴

| 패턴 | 용도 |
|------|------|
| Slot | 유연한 레이아웃 구성 |
| Portal | DOM 계층 이탈 |
| Focus Trap | 모달 접근성 |

### 사용 지침

```
1. 단순하게 시작: 필요할 때만 패턴 도입
2. 일관성 유지: 프로젝트 내 동일 문제에 동일 패턴
3. 문서화: 팀원들이 이해할 수 있도록
4. 테스트: 패턴이 올바르게 동작하는지 확인
```
