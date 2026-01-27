# Next.js API Routes

Next.js에서 **백엔드 API 엔드포인트**를 만드는 방법입니다. 별도의 백엔드 서버 없이 API를 구현할 수 있습니다.

---

## Pages Router vs App Router

Next.js 버전에 따라 API 작성 방식이 다릅니다:

| 특징 | Pages Router | App Router |
|------|-------------|------------|
| 위치 | `pages/api/` | `app/api/` |
| 파일명 | `*.ts` | `route.ts` |
| 핸들러 | 단일 함수 | HTTP 메서드별 함수 |
| Request | `NextApiRequest` | Web `Request` |
| Response | `NextApiResponse` | `NextResponse` |

---

## Pages Router 방식

### 기본 구조

```
pages/
└── api/
    ├── users/
    │   ├── index.ts        # /api/users
    │   └── [id].ts         # /api/users/:id
    ├── posts/
    │   └── index.ts        # /api/posts
    └── auth/
        └── login.ts        # /api/auth/login
```

### 기본 핸들러

```tsx
// pages/api/users/index.ts
import type { NextApiRequest, NextApiResponse } from 'next'

interface User {
  id: string
  name: string
  email: string
}

type ResponseData = {
  users?: User[]
  user?: User
  error?: string
}

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse<ResponseData>
) {
  // HTTP 메서드에 따라 분기
  switch (req.method) {
    case 'GET':
      return handleGet(req, res)
    case 'POST':
      return handlePost(req, res)
    default:
      res.setHeader('Allow', ['GET', 'POST'])
      return res.status(405).json({ error: `Method ${req.method} Not Allowed` })
  }
}

async function handleGet(
  req: NextApiRequest,
  res: NextApiResponse<ResponseData>
) {
  try {
    const users = await db.user.findMany()
    return res.status(200).json({ users })
  } catch (error) {
    return res.status(500).json({ error: 'Failed to fetch users' })
  }
}

async function handlePost(
  req: NextApiRequest,
  res: NextApiResponse<ResponseData>
) {
  try {
    const { name, email } = req.body

    // 유효성 검사
    if (!name || !email) {
      return res.status(400).json({ error: 'Name and email are required' })
    }

    const user = await db.user.create({
      data: { name, email },
    })

    return res.status(201).json({ user })
  } catch (error) {
    return res.status(500).json({ error: 'Failed to create user' })
  }
}
```

### 동적 라우트

```tsx
// pages/api/users/[id].ts
import type { NextApiRequest, NextApiResponse } from 'next'

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  const { id } = req.query  // URL 파라미터

  switch (req.method) {
    case 'GET':
      const user = await db.user.findUnique({ where: { id: String(id) } })
      if (!user) {
        return res.status(404).json({ error: 'User not found' })
      }
      return res.status(200).json(user)

    case 'PUT':
      const updated = await db.user.update({
        where: { id: String(id) },
        data: req.body,
      })
      return res.status(200).json(updated)

    case 'DELETE':
      await db.user.delete({ where: { id: String(id) } })
      return res.status(204).end()

    default:
      res.setHeader('Allow', ['GET', 'PUT', 'DELETE'])
      return res.status(405).end()
  }
}
```

### Query Parameters

```tsx
// pages/api/products/index.ts
// GET /api/products?category=shoes&page=1&limit=10

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  const {
    category,
    page = '1',
    limit = '10',
    sortBy = 'createdAt',
    sortOrder = 'desc',
  } = req.query

  const products = await db.product.findMany({
    where: category ? { category: String(category) } : undefined,
    skip: (Number(page) - 1) * Number(limit),
    take: Number(limit),
    orderBy: { [String(sortBy)]: sortOrder },
  })

  const total = await db.product.count({
    where: category ? { category: String(category) } : undefined,
  })

  return res.status(200).json({
    products,
    pagination: {
      page: Number(page),
      limit: Number(limit),
      total,
      totalPages: Math.ceil(total / Number(limit)),
    },
  })
}
```

---

## App Router 방식 (Route Handlers)

### 기본 구조

```
app/
└── api/
    ├── users/
    │   ├── route.ts           # /api/users (GET, POST)
    │   └── [id]/
    │       └── route.ts       # /api/users/:id (GET, PUT, DELETE)
    ├── posts/
    │   └── route.ts
    └── auth/
        ├── login/
        │   └── route.ts       # /api/auth/login
        └── register/
            └── route.ts       # /api/auth/register
```

### 기본 핸들러

```tsx
// app/api/users/route.ts
import { NextResponse } from 'next/server'

// GET /api/users
export async function GET(request: Request) {
  try {
    const users = await db.user.findMany()
    return NextResponse.json(users)
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to fetch users' },
      { status: 500 }
    )
  }
}

// POST /api/users
export async function POST(request: Request) {
  try {
    const body = await request.json()
    const { name, email } = body

    // 유효성 검사
    if (!name || !email) {
      return NextResponse.json(
        { error: 'Name and email are required' },
        { status: 400 }
      )
    }

    const user = await db.user.create({
      data: { name, email },
    })

    return NextResponse.json(user, { status: 201 })
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to create user' },
      { status: 500 }
    )
  }
}
```

### 동적 라우트

```tsx
// app/api/users/[id]/route.ts
import { NextResponse } from 'next/server'

interface Props {
  params: { id: string }
}

// GET /api/users/:id
export async function GET(request: Request, { params }: Props) {
  const user = await db.user.findUnique({
    where: { id: params.id },
  })

  if (!user) {
    return NextResponse.json(
      { error: 'User not found' },
      { status: 404 }
    )
  }

  return NextResponse.json(user)
}

// PUT /api/users/:id
export async function PUT(request: Request, { params }: Props) {
  try {
    const body = await request.json()

    const user = await db.user.update({
      where: { id: params.id },
      data: body,
    })

    return NextResponse.json(user)
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to update user' },
      { status: 500 }
    )
  }
}

// DELETE /api/users/:id
export async function DELETE(request: Request, { params }: Props) {
  try {
    await db.user.delete({
      where: { id: params.id },
    })

    return new NextResponse(null, { status: 204 })
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to delete user' },
      { status: 500 }
    )
  }
}
```

### Query Parameters (App Router)

```tsx
// app/api/products/route.ts
import { NextResponse } from 'next/server'

// GET /api/products?category=shoes&page=1&limit=10
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url)

  const category = searchParams.get('category')
  const page = Number(searchParams.get('page')) || 1
  const limit = Number(searchParams.get('limit')) || 10
  const sortBy = searchParams.get('sortBy') || 'createdAt'
  const sortOrder = searchParams.get('sortOrder') || 'desc'

  const products = await db.product.findMany({
    where: category ? { category } : undefined,
    skip: (page - 1) * limit,
    take: limit,
    orderBy: { [sortBy]: sortOrder },
  })

  const total = await db.product.count({
    where: category ? { category } : undefined,
  })

  return NextResponse.json({
    products,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    },
  })
}
```

---

## 공통 패턴

### 미들웨어 패턴

```tsx
// lib/api-middleware.ts
import { NextResponse } from 'next/server'

type Handler = (request: Request, context: any) => Promise<Response>

// 에러 처리 미들웨어
export function withErrorHandling(handler: Handler): Handler {
  return async (request, context) => {
    try {
      return await handler(request, context)
    } catch (error) {
      console.error('API Error:', error)

      if (error instanceof ValidationError) {
        return NextResponse.json(
          { error: error.message },
          { status: 400 }
        )
      }

      if (error instanceof NotFoundError) {
        return NextResponse.json(
          { error: error.message },
          { status: 404 }
        )
      }

      return NextResponse.json(
        { error: 'Internal server error' },
        { status: 500 }
      )
    }
  }
}

// 인증 미들웨어
export function withAuth(handler: Handler): Handler {
  return async (request, context) => {
    const session = await getServerSession()

    if (!session) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      )
    }

    // context에 사용자 정보 추가
    context.user = session.user

    return handler(request, context)
  }
}

// 조합해서 사용
export function withMiddleware(...middlewares: ((h: Handler) => Handler)[]) {
  return (handler: Handler): Handler => {
    return middlewares.reduceRight((h, middleware) => middleware(h), handler)
  }
}
```

```tsx
// app/api/protected/route.ts
import { withMiddleware, withAuth, withErrorHandling } from '@/lib/api-middleware'

async function handler(request: Request, context: { user: User }) {
  // context.user 사용 가능
  return NextResponse.json({ message: `Hello, ${context.user.name}` })
}

export const GET = withMiddleware(withErrorHandling, withAuth)(handler)
```

### 유효성 검사 (Zod 사용)

```tsx
// app/api/users/route.ts
import { NextResponse } from 'next/server'
import { z } from 'zod'

const createUserSchema = z.object({
  name: z.string().min(2, '이름은 2자 이상이어야 합니다'),
  email: z.string().email('올바른 이메일 형식이 아닙니다'),
  password: z.string().min(8, '비밀번호는 8자 이상이어야 합니다'),
})

export async function POST(request: Request) {
  try {
    const body = await request.json()

    // Zod로 유효성 검사
    const result = createUserSchema.safeParse(body)

    if (!result.success) {
      return NextResponse.json(
        {
          error: 'Validation failed',
          details: result.error.flatten().fieldErrors,
        },
        { status: 400 }
      )
    }

    const { name, email, password } = result.data

    // 비밀번호 해싱
    const hashedPassword = await bcrypt.hash(password, 10)

    const user = await db.user.create({
      data: {
        name,
        email,
        password: hashedPassword,
      },
      select: {
        id: true,
        name: true,
        email: true,
        createdAt: true,
      },
    })

    return NextResponse.json(user, { status: 201 })
  } catch (error) {
    if (error.code === 'P2002') {
      return NextResponse.json(
        { error: '이미 등록된 이메일입니다' },
        { status: 409 }
      )
    }

    return NextResponse.json(
      { error: 'Failed to create user' },
      { status: 500 }
    )
  }
}
```

### 인증 (NextAuth.js)

```tsx
// app/api/profile/route.ts
import { NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'

export async function GET() {
  const session = await getServerSession(authOptions)

  if (!session) {
    return NextResponse.json(
      { error: 'Unauthorized' },
      { status: 401 }
    )
  }

  const user = await db.user.findUnique({
    where: { id: session.user.id },
    select: {
      id: true,
      name: true,
      email: true,
      avatar: true,
      createdAt: true,
    },
  })

  return NextResponse.json(user)
}

export async function PUT(request: Request) {
  const session = await getServerSession(authOptions)

  if (!session) {
    return NextResponse.json(
      { error: 'Unauthorized' },
      { status: 401 }
    )
  }

  const body = await request.json()

  const user = await db.user.update({
    where: { id: session.user.id },
    data: {
      name: body.name,
      avatar: body.avatar,
    },
  })

  return NextResponse.json(user)
}
```

### 파일 업로드

```tsx
// app/api/upload/route.ts
import { NextResponse } from 'next/server'
import { writeFile } from 'fs/promises'
import path from 'path'

export async function POST(request: Request) {
  try {
    const formData = await request.formData()
    const file = formData.get('file') as File

    if (!file) {
      return NextResponse.json(
        { error: 'No file provided' },
        { status: 400 }
      )
    }

    // 파일 유효성 검사
    const allowedTypes = ['image/jpeg', 'image/png', 'image/webp']
    if (!allowedTypes.includes(file.type)) {
      return NextResponse.json(
        { error: 'Invalid file type' },
        { status: 400 }
      )
    }

    const maxSize = 5 * 1024 * 1024 // 5MB
    if (file.size > maxSize) {
      return NextResponse.json(
        { error: 'File too large' },
        { status: 400 }
      )
    }

    // 파일 저장
    const bytes = await file.arrayBuffer()
    const buffer = Buffer.from(bytes)

    const filename = `${Date.now()}-${file.name}`
    const filepath = path.join(process.cwd(), 'public/uploads', filename)

    await writeFile(filepath, buffer)

    return NextResponse.json({
      url: `/uploads/${filename}`,
    })
  } catch (error) {
    return NextResponse.json(
      { error: 'Upload failed' },
      { status: 500 }
    )
  }
}
```

### CORS 설정

```tsx
// app/api/public/route.ts
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const data = { message: 'Public API' }

  return NextResponse.json(data, {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  })
}

// OPTIONS 요청 처리 (CORS preflight)
export async function OPTIONS(request: Request) {
  return new NextResponse(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  })
}
```

### 스트리밍 응답

```tsx
// app/api/stream/route.ts
export async function GET() {
  const encoder = new TextEncoder()

  const stream = new ReadableStream({
    async start(controller) {
      for (let i = 0; i < 10; i++) {
        const message = `data: Message ${i}\n\n`
        controller.enqueue(encoder.encode(message))
        await new Promise((resolve) => setTimeout(resolve, 1000))
      }
      controller.close()
    },
  })

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      Connection: 'keep-alive',
    },
  })
}
```

---

## 캐싱

### App Router 캐싱

```tsx
// app/api/products/route.ts
import { NextResponse } from 'next/server'

export async function GET() {
  const products = await db.product.findMany()

  return NextResponse.json(products, {
    headers: {
      // 브라우저 캐시: 60초
      // CDN 캐시: 60초
      // stale-while-revalidate: 300초
      'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=300',
    },
  })
}
```

### Route Segment Config

```tsx
// app/api/products/route.ts

// 동적 렌더링 강제 (캐싱 없음)
export const dynamic = 'force-dynamic'

// 또는 정적 렌더링
export const dynamic = 'force-static'

// 재검증 간격
export const revalidate = 60 // 60초

export async function GET() {
  // ...
}
```

---

## 에러 처리 패턴

```tsx
// lib/errors.ts
export class ApiError extends Error {
  constructor(
    message: string,
    public statusCode: number,
    public code?: string
  ) {
    super(message)
    this.name = 'ApiError'
  }
}

export class ValidationError extends ApiError {
  constructor(message: string) {
    super(message, 400, 'VALIDATION_ERROR')
  }
}

export class UnauthorizedError extends ApiError {
  constructor(message = 'Unauthorized') {
    super(message, 401, 'UNAUTHORIZED')
  }
}

export class NotFoundError extends ApiError {
  constructor(resource: string) {
    super(`${resource} not found`, 404, 'NOT_FOUND')
  }
}

export class ConflictError extends ApiError {
  constructor(message: string) {
    super(message, 409, 'CONFLICT')
  }
}
```

```tsx
// app/api/users/[id]/route.ts
import { NextResponse } from 'next/server'
import { NotFoundError, ValidationError } from '@/lib/errors'

export async function GET(request: Request, { params }: Props) {
  try {
    const user = await db.user.findUnique({
      where: { id: params.id },
    })

    if (!user) {
      throw new NotFoundError('User')
    }

    return NextResponse.json(user)
  } catch (error) {
    if (error instanceof ApiError) {
      return NextResponse.json(
        { error: error.message, code: error.code },
        { status: error.statusCode }
      )
    }

    console.error('Unexpected error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
```

---

## 테스트

```tsx
// __tests__/api/users.test.ts
import { GET, POST } from '@/app/api/users/route'
import { NextRequest } from 'next/server'

describe('/api/users', () => {
  describe('GET', () => {
    it('returns users list', async () => {
      const request = new NextRequest('http://localhost/api/users')
      const response = await GET(request)

      expect(response.status).toBe(200)

      const data = await response.json()
      expect(Array.isArray(data)).toBe(true)
    })
  })

  describe('POST', () => {
    it('creates a new user', async () => {
      const request = new NextRequest('http://localhost/api/users', {
        method: 'POST',
        body: JSON.stringify({
          name: 'Test User',
          email: 'test@example.com',
        }),
      })

      const response = await POST(request)

      expect(response.status).toBe(201)

      const data = await response.json()
      expect(data.name).toBe('Test User')
      expect(data.email).toBe('test@example.com')
    })

    it('returns 400 for invalid data', async () => {
      const request = new NextRequest('http://localhost/api/users', {
        method: 'POST',
        body: JSON.stringify({ name: 'Test' }), // email 누락
      })

      const response = await POST(request)

      expect(response.status).toBe(400)
    })
  })
})
```

---

## 장단점

### 장점

- 별도 백엔드 서버 불필요
- 같은 프로젝트에서 프론트엔드와 API 관리
- Vercel 등에서 자동 서버리스 배포
- TypeScript 타입 공유 용이

### 단점

- 복잡한 백엔드 로직에는 한계
- 긴 실행 시간 작업에 제한 (서버리스 타임아웃)
- 웹소켓 등 지속 연결 어려움
- 스케일링이 필요하면 별도 백엔드 고려
