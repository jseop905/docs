# Server Actions (Next.js 14+)

Next.js 14에서 안정화된 **서버에서 실행되는 함수**입니다. API Route 없이 폼 제출, 데이터 변경 등을 처리할 수 있습니다.

---

## 핵심 개념

Server Actions는 `'use server'` 지시어로 선언된 **비동기 함수**입니다. 클라이언트에서 호출하면 서버에서 실행됩니다.

```tsx
// 파일 최상단에 'use server' 선언
'use server'

export async function createUser(formData: FormData) {
  const name = formData.get('name') as string
  const email = formData.get('email') as string

  // 서버에서 실행됨 - DB 접근 가능!
  await db.user.create({
    data: { name, email }
  })
}
```

---

## 기본 사용법

### 폼에서 직접 사용

```tsx
// app/actions.ts
'use server'

import { revalidatePath } from 'next/cache'

export async function createPost(formData: FormData) {
  const title = formData.get('title') as string
  const content = formData.get('content') as string

  await db.post.create({
    data: { title, content }
  })

  // 캐시 무효화 - 목록 페이지 갱신
  revalidatePath('/posts')
}
```

```tsx
// app/posts/new/page.tsx
import { createPost } from '@/app/actions'

export default function NewPostPage() {
  return (
    <form action={createPost}>
      <input name="title" placeholder="제목" required />
      <textarea name="content" placeholder="내용" required />
      <button type="submit">작성</button>
    </form>
  )
}
```

### Client Component에서 사용

```tsx
// app/actions.ts
'use server'

export async function deletePost(postId: string) {
  await db.post.delete({
    where: { id: postId }
  })

  revalidatePath('/posts')
}
```

```tsx
// app/components/DeleteButton.tsx
'use client'

import { deletePost } from '@/app/actions'

interface DeleteButtonProps {
  postId: string
}

export function DeleteButton({ postId }: DeleteButtonProps) {
  const handleDelete = async () => {
    if (confirm('정말 삭제하시겠습니까?')) {
      await deletePost(postId)
    }
  }

  return (
    <button onClick={handleDelete}>
      삭제
    </button>
  )
}
```

---

## 폼 상태 관리

### useFormState

폼 제출 결과를 받아 처리합니다.

```tsx
// app/actions.ts
'use server'

interface FormState {
  error?: string
  success?: boolean
  message?: string
}

export async function createUser(
  prevState: FormState,
  formData: FormData
): Promise<FormState> {
  const name = formData.get('name') as string
  const email = formData.get('email') as string

  // 유효성 검사
  if (!name || name.length < 2) {
    return { error: '이름은 2자 이상이어야 합니다' }
  }

  if (!email || !email.includes('@')) {
    return { error: '올바른 이메일 형식이 아닙니다' }
  }

  try {
    // 중복 확인
    const existing = await db.user.findUnique({ where: { email } })
    if (existing) {
      return { error: '이미 등록된 이메일입니다' }
    }

    // 사용자 생성
    await db.user.create({
      data: { name, email }
    })

    revalidatePath('/users')

    return {
      success: true,
      message: '사용자가 생성되었습니다'
    }
  } catch (error) {
    return { error: '사용자 생성에 실패했습니다' }
  }
}
```

```tsx
// app/users/new/page.tsx
'use client'

import { useFormState } from 'react-dom'
import { createUser } from '@/app/actions'

const initialState = {
  error: undefined,
  success: undefined,
  message: undefined,
}

export default function NewUserPage() {
  const [state, formAction] = useFormState(createUser, initialState)

  return (
    <form action={formAction}>
      <div>
        <label htmlFor="name">이름</label>
        <input id="name" name="name" required />
      </div>

      <div>
        <label htmlFor="email">이메일</label>
        <input id="email" name="email" type="email" required />
      </div>

      {state.error && (
        <p className="error">{state.error}</p>
      )}

      {state.success && (
        <p className="success">{state.message}</p>
      )}

      <SubmitButton />
    </form>
  )
}
```

### useFormStatus

폼 제출 상태(pending)를 확인합니다.

```tsx
// app/components/SubmitButton.tsx
'use client'

import { useFormStatus } from 'react-dom'

export function SubmitButton() {
  const { pending } = useFormStatus()

  return (
    <button type="submit" disabled={pending}>
      {pending ? '처리 중...' : '제출'}
    </button>
  )
}
```

```tsx
// 더 복잡한 예시
'use client'

import { useFormStatus } from 'react-dom'

export function FormFields() {
  const { pending, data, method, action } = useFormStatus()

  return (
    <>
      <input
        name="email"
        type="email"
        disabled={pending}
        placeholder="이메일"
      />
      <input
        name="password"
        type="password"
        disabled={pending}
        placeholder="비밀번호"
      />

      {pending && <p>로그인 중...</p>}
    </>
  )
}
```

---

## 유효성 검사 (Zod 사용)

```tsx
// app/actions.ts
'use server'

import { z } from 'zod'

const createUserSchema = z.object({
  name: z.string().min(2, '이름은 2자 이상이어야 합니다'),
  email: z.string().email('올바른 이메일 형식이 아닙니다'),
  password: z.string().min(8, '비밀번호는 8자 이상이어야 합니다'),
})

interface FormState {
  errors?: {
    name?: string[]
    email?: string[]
    password?: string[]
  }
  message?: string
  success?: boolean
}

export async function createUser(
  prevState: FormState,
  formData: FormData
): Promise<FormState> {
  // Zod로 유효성 검사
  const validatedFields = createUserSchema.safeParse({
    name: formData.get('name'),
    email: formData.get('email'),
    password: formData.get('password'),
  })

  // 유효성 검사 실패
  if (!validatedFields.success) {
    return {
      errors: validatedFields.error.flatten().fieldErrors,
      message: '입력값을 확인해주세요',
    }
  }

  const { name, email, password } = validatedFields.data

  try {
    // 비밀번호 해싱
    const hashedPassword = await bcrypt.hash(password, 10)

    await db.user.create({
      data: {
        name,
        email,
        password: hashedPassword,
      },
    })

    revalidatePath('/users')

    return { success: true, message: '가입이 완료되었습니다' }
  } catch (error) {
    return { message: '가입에 실패했습니다' }
  }
}
```

```tsx
// app/register/page.tsx
'use client'

import { useFormState } from 'react-dom'
import { createUser } from '@/app/actions'

export default function RegisterPage() {
  const [state, formAction] = useFormState(createUser, {})

  return (
    <form action={formAction}>
      <div>
        <label htmlFor="name">이름</label>
        <input id="name" name="name" />
        {state.errors?.name && (
          <p className="error">{state.errors.name[0]}</p>
        )}
      </div>

      <div>
        <label htmlFor="email">이메일</label>
        <input id="email" name="email" type="email" />
        {state.errors?.email && (
          <p className="error">{state.errors.email[0]}</p>
        )}
      </div>

      <div>
        <label htmlFor="password">비밀번호</label>
        <input id="password" name="password" type="password" />
        {state.errors?.password && (
          <p className="error">{state.errors.password[0]}</p>
        )}
      </div>

      {state.message && !state.success && (
        <p className="error">{state.message}</p>
      )}

      {state.success && (
        <p className="success">{state.message}</p>
      )}

      <SubmitButton />
    </form>
  )
}
```

---

## 인증 처리

```tsx
// app/actions/auth.ts
'use server'

import { cookies } from 'next/headers'
import { redirect } from 'next/navigation'
import { z } from 'zod'

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
})

interface LoginState {
  error?: string
}

export async function login(
  prevState: LoginState,
  formData: FormData
): Promise<LoginState> {
  const validatedFields = loginSchema.safeParse({
    email: formData.get('email'),
    password: formData.get('password'),
  })

  if (!validatedFields.success) {
    return { error: '이메일과 비밀번호를 입력해주세요' }
  }

  const { email, password } = validatedFields.data

  // 사용자 조회
  const user = await db.user.findUnique({ where: { email } })

  if (!user) {
    return { error: '이메일 또는 비밀번호가 올바르지 않습니다' }
  }

  // 비밀번호 확인
  const passwordMatch = await bcrypt.compare(password, user.password)

  if (!passwordMatch) {
    return { error: '이메일 또는 비밀번호가 올바르지 않습니다' }
  }

  // 세션 생성
  const session = await createSession(user.id)

  // 쿠키 설정
  cookies().set('session', session.token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: 60 * 60 * 24 * 7, // 7일
  })

  // 리다이렉트
  redirect('/dashboard')
}

export async function logout() {
  cookies().delete('session')
  redirect('/login')
}
```

```tsx
// app/login/page.tsx
'use client'

import { useFormState } from 'react-dom'
import { login } from '@/app/actions/auth'

export default function LoginPage() {
  const [state, formAction] = useFormState(login, {})

  return (
    <form action={formAction}>
      <input name="email" type="email" placeholder="이메일" required />
      <input name="password" type="password" placeholder="비밀번호" required />

      {state.error && <p className="error">{state.error}</p>}

      <SubmitButton />
    </form>
  )
}
```

---

## 낙관적 업데이트 (useOptimistic)

서버 응답을 기다리지 않고 **즉시 UI를 업데이트**합니다.

```tsx
// app/actions.ts
'use server'

export async function toggleLike(postId: string, userId: string) {
  const existing = await db.like.findUnique({
    where: {
      postId_userId: { postId, userId }
    }
  })

  if (existing) {
    await db.like.delete({
      where: { id: existing.id }
    })
  } else {
    await db.like.create({
      data: { postId, userId }
    })
  }

  revalidatePath(`/posts/${postId}`)
}
```

```tsx
// app/components/LikeButton.tsx
'use client'

import { useOptimistic, useTransition } from 'react'
import { toggleLike } from '@/app/actions'

interface LikeButtonProps {
  postId: string
  userId: string
  initialLiked: boolean
  initialCount: number
}

export function LikeButton({
  postId,
  userId,
  initialLiked,
  initialCount,
}: LikeButtonProps) {
  const [isPending, startTransition] = useTransition()

  const [optimisticState, setOptimisticState] = useOptimistic(
    { liked: initialLiked, count: initialCount },
    (state, newLiked: boolean) => ({
      liked: newLiked,
      count: newLiked ? state.count + 1 : state.count - 1,
    })
  )

  const handleClick = () => {
    startTransition(async () => {
      // 낙관적으로 UI 먼저 업데이트
      setOptimisticState(!optimisticState.liked)

      // 서버에서 실제 처리
      await toggleLike(postId, userId)
    })
  }

  return (
    <button
      onClick={handleClick}
      disabled={isPending}
      className={optimisticState.liked ? 'liked' : ''}
    >
      {optimisticState.liked ? '❤️' : '🤍'} {optimisticState.count}
    </button>
  )
}
```

---

## 파일 업로드

```tsx
// app/actions.ts
'use server'

import { writeFile } from 'fs/promises'
import path from 'path'

export async function uploadImage(formData: FormData) {
  const file = formData.get('file') as File

  if (!file) {
    return { error: '파일을 선택해주세요' }
  }

  // 파일 유효성 검사
  const allowedTypes = ['image/jpeg', 'image/png', 'image/webp']
  if (!allowedTypes.includes(file.type)) {
    return { error: '이미지 파일만 업로드 가능합니다' }
  }

  const maxSize = 5 * 1024 * 1024 // 5MB
  if (file.size > maxSize) {
    return { error: '파일 크기는 5MB 이하여야 합니다' }
  }

  try {
    const bytes = await file.arrayBuffer()
    const buffer = Buffer.from(bytes)

    // 파일명 생성
    const ext = file.name.split('.').pop()
    const filename = `${Date.now()}-${Math.random().toString(36).slice(2)}.${ext}`

    // 저장
    const filepath = path.join(process.cwd(), 'public/uploads', filename)
    await writeFile(filepath, buffer)

    return {
      success: true,
      url: `/uploads/${filename}`,
    }
  } catch (error) {
    return { error: '업로드에 실패했습니다' }
  }
}
```

```tsx
// app/components/ImageUploader.tsx
'use client'

import { useState } from 'react'
import { uploadImage } from '@/app/actions'

export function ImageUploader() {
  const [preview, setPreview] = useState<string | null>(null)
  const [uploadedUrl, setUploadedUrl] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [uploading, setUploading] = useState(false)

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      const reader = new FileReader()
      reader.onloadend = () => {
        setPreview(reader.result as string)
      }
      reader.readAsDataURL(file)
    }
  }

  const handleSubmit = async (formData: FormData) => {
    setUploading(true)
    setError(null)

    const result = await uploadImage(formData)

    if (result.error) {
      setError(result.error)
    } else if (result.url) {
      setUploadedUrl(result.url)
    }

    setUploading(false)
  }

  return (
    <form action={handleSubmit}>
      <input
        type="file"
        name="file"
        accept="image/*"
        onChange={handleFileChange}
      />

      {preview && (
        <img src={preview} alt="Preview" style={{ maxWidth: 200 }} />
      )}

      {error && <p className="error">{error}</p>}

      {uploadedUrl && (
        <p className="success">
          업로드 완료: <a href={uploadedUrl}>{uploadedUrl}</a>
        </p>
      )}

      <button type="submit" disabled={uploading}>
        {uploading ? '업로드 중...' : '업로드'}
      </button>
    </form>
  )
}
```

---

## 캐시 무효화

### revalidatePath

특정 경로의 캐시를 무효화합니다.

```tsx
'use server'

import { revalidatePath } from 'next/cache'

export async function createPost(formData: FormData) {
  await db.post.create({
    data: { /* ... */ }
  })

  // 특정 페이지 무효화
  revalidatePath('/posts')

  // 동적 경로 무효화
  revalidatePath('/posts/[slug]', 'page')

  // 레이아웃 포함 무효화
  revalidatePath('/posts', 'layout')
}
```

### revalidateTag

태그 기반으로 캐시를 무효화합니다.

```tsx
// 데이터 페칭 시 태그 설정
async function getPosts() {
  const res = await fetch('https://api.example.com/posts', {
    next: { tags: ['posts'] }
  })
  return res.json()
}

// Server Action에서 태그 무효화
'use server'

import { revalidateTag } from 'next/cache'

export async function createPost(formData: FormData) {
  await db.post.create({
    data: { /* ... */ }
  })

  revalidateTag('posts')
}
```

---

## 리다이렉트

```tsx
'use server'

import { redirect } from 'next/navigation'

export async function createPost(formData: FormData) {
  const post = await db.post.create({
    data: {
      title: formData.get('title') as string,
      content: formData.get('content') as string,
    }
  })

  // 생성된 포스트 페이지로 리다이렉트
  redirect(`/posts/${post.id}`)
}
```

**주의:** `redirect()`는 `try/catch` 안에서 호출하면 안 됩니다. Next.js가 내부적으로 에러를 throw하기 때문입니다.

```tsx
// ❌ 잘못된 사용
export async function createPost(formData: FormData) {
  try {
    const post = await db.post.create({ /* ... */ })
    redirect(`/posts/${post.id}`)  // catch에 걸림!
  } catch (error) {
    return { error: 'Failed' }
  }
}

// ✅ 올바른 사용
export async function createPost(formData: FormData) {
  let post

  try {
    post = await db.post.create({ /* ... */ })
  } catch (error) {
    return { error: 'Failed' }
  }

  redirect(`/posts/${post.id}`)  // try 밖에서 호출
}
```

---

## 권한 확인

```tsx
// app/actions.ts
'use server'

import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'

export async function deletePost(postId: string) {
  // 인증 확인
  const session = await getServerSession(authOptions)

  if (!session) {
    throw new Error('로그인이 필요합니다')
  }

  // 게시글 조회
  const post = await db.post.findUnique({
    where: { id: postId }
  })

  if (!post) {
    throw new Error('게시글을 찾을 수 없습니다')
  }

  // 권한 확인
  if (post.authorId !== session.user.id && session.user.role !== 'admin') {
    throw new Error('삭제 권한이 없습니다')
  }

  // 삭제
  await db.post.delete({
    where: { id: postId }
  })

  revalidatePath('/posts')
}
```

---

## bind를 사용한 인자 전달

```tsx
// app/posts/[id]/page.tsx
import { deletePost } from '@/app/actions'

export default async function PostPage({ params }: { params: { id: string } }) {
  const post = await getPost(params.id)

  // bind로 postId를 미리 바인딩
  const deletePostWithId = deletePost.bind(null, params.id)

  return (
    <article>
      <h1>{post.title}</h1>
      <p>{post.content}</p>

      <form action={deletePostWithId}>
        <button type="submit">삭제</button>
      </form>
    </article>
  )
}
```

```tsx
// app/actions.ts
'use server'

export async function deletePost(postId: string) {
  await db.post.delete({
    where: { id: postId }
  })

  revalidatePath('/posts')
  redirect('/posts')
}
```

---

## API Route vs Server Actions

| 특징 | API Route | Server Actions |
|------|-----------|----------------|
| 사용 목적 | REST API, 외부 연동 | 폼 제출, 데이터 변경 |
| 호출 방식 | fetch() | 직접 함수 호출 |
| HTTP 메서드 | GET, POST, PUT, DELETE | POST만 |
| 캐싱 | 가능 | 불가능 |
| 외부 접근 | 가능 | 불가능 (내부용) |
| Progressive Enhancement | 불가능 | 가능 (JS 없이도 동작) |

### 언제 무엇을 사용할까?

**Server Actions 사용:**
- 폼 제출
- 데이터 변경 (CRUD)
- 내부 데이터 처리

**API Route 사용:**
- 외부에서 접근해야 하는 API
- GET 요청 (데이터 조회)
- 웹훅
- 제3자 서비스 연동

---

## 장단점

### 장점

- API Route 없이 서버 로직 실행
- TypeScript 타입 안전성
- Progressive Enhancement (JS 없이도 동작)
- 코드 간소화
- 자동 최적화 (번들에 포함되지 않음)

### 단점

- POST 요청만 지원
- 외부에서 접근 불가
- 복잡한 API에는 부적합
- 디버깅이 어려울 수 있음

---

## 모범 사례

1. **actions 파일 분리**
   ```
   app/
   └── actions/
       ├── auth.ts
       ├── posts.ts
       ├── users.ts
       └── index.ts
   ```

2. **유효성 검사는 항상 서버에서**
   - 클라이언트 검사는 UX용
   - 서버 검사는 보안용

3. **에러 처리 일관성**
   - 일관된 반환 형식 사용
   - 사용자 친화적 에러 메시지

4. **낙관적 업데이트 활용**
   - 좋아요, 북마크 등에 적용
   - 즉각적인 피드백 제공
