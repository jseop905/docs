# BFF (Backend For Frontend) 패턴

**프론트엔드 전용 백엔드**를 두는 아키텍처 패턴입니다. 여러 마이크로서비스의 데이터를 프론트엔드에 맞게 집계하고 변환합니다.

---

## 문제 상황

마이크로서비스 아키텍처에서 프론트엔드가 직접 여러 서비스를 호출하면 다음과 같은 문제가 발생합니다:

```
[프론트엔드에서 "상품 상세 페이지"를 그리려면]

1. 상품 서비스 호출 → 상품 정보
2. 재고 서비스 호출 → 재고 현황
3. 리뷰 서비스 호출 → 리뷰 목록
4. 추천 서비스 호출 → 관련 상품
5. 프로모션 서비스 호출 → 할인 정보

총 5번의 네트워크 요청!
```

### 문제점

1. **과도한 네트워크 요청**: 모바일에서 특히 치명적
2. **응답 형식 불일치**: 각 서비스마다 다른 데이터 구조
3. **오버페칭**: 필요하지 않은 데이터까지 받아옴
4. **프론트엔드 복잡성**: 데이터 조합 로직이 클라이언트에 존재
5. **백엔드 종속성**: 서비스 변경 시 프론트엔드 수정 필요

---

## BFF 해결책

프론트엔드와 마이크로서비스 사이에 **중간 계층(BFF)**을 둡니다:

```
┌─────────────────────────────────────────────────────────────┐
│                     Frontend Applications                    │
├─────────────┬─────────────┬─────────────┬─────────────────┤
│   Web App   │ Mobile App  │  Admin App  │   Partner App   │
└──────┬──────┴──────┬──────┴──────┬──────┴────────┬────────┘
       │             │             │               │
       ▼             ▼             ▼               ▼
┌──────────────┬──────────────┬──────────────┬──────────────┐
│   BFF Web    │  BFF Mobile  │  BFF Admin   │ BFF Partner  │
│              │              │              │              │
│ - 풀 데이터   │ - 최소 데이터 │ - 관리 API   │ - 제한된 API │
│ - 복잡한 UI  │ - 배터리 최적화│ - 대시보드   │ - 파트너 전용 │
└──────┬───────┴──────┬───────┴──────┬───────┴──────┬───────┘
       │              │              │              │
       └──────────────┴──────────────┴──────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Microservices Layer                      │
├─────────────┬─────────────┬─────────────┬─────────────────┤
│   Product   │   Review    │  Inventory  │   Promotion     │
│   Service   │   Service   │   Service   │   Service       │
└─────────────┴─────────────┴─────────────┴─────────────────┘
```

---

## BFF가 하는 일

### 1. 데이터 집계 (Aggregation)

여러 서비스의 데이터를 **한 번의 요청**으로 모아서 제공합니다.

```tsx
// BFF에서 처리
async function getProductDetail(productId: string) {
  // 병렬로 여러 서비스 호출
  const [product, inventory, reviews, recommendations, promotions] =
    await Promise.all([
      productService.getProduct(productId),
      inventoryService.getStock(productId),
      reviewService.getReviews(productId),
      recommendationService.getSimilar(productId),
      promotionService.getActivePromotions(productId),
    ])

  // 프론트엔드에 맞게 조합
  return {
    ...product,
    stock: inventory,
    reviews,
    recommendations,
    promotions,
  }
}
```

### 2. 데이터 변환 (Transformation)

백엔드 응답을 **프론트엔드에 맞게 변환**합니다.

```tsx
// 백엔드 응답 (복잡한 구조)
const backendResponse = {
  product_id: "123",
  product_name: "상품명",
  product_price_krw: 10000,
  product_images: [
    { image_url: "...", image_type: "main" },
    { image_url: "...", image_type: "sub" },
  ],
  inventory_status: { qty: 5, status_code: "AVAILABLE" },
}

// BFF에서 변환
const frontendResponse = {
  id: "123",
  name: "상품명",
  price: 10000,
  images: ["main.jpg", "sub.jpg"],
  stock: {
    quantity: 5,
    available: true,
    lowStock: false,
  },
}
```

### 3. 플랫폼 최적화

각 플랫폼에 맞는 **최적화된 응답**을 제공합니다.

```tsx
// Web BFF - 풀 데이터
{
  product: { /* 상세 정보 */ },
  reviews: { items: [...], total: 100 },  // 전체 리뷰
  recommendations: [...],  // 10개
  relatedContent: [...]    // 관련 컨텐츠
}

// Mobile BFF - 최소 데이터
{
  product: { /* 핵심 정보만 */ },
  reviews: { summary: 4.5, count: 100 },  // 요약만
  recommendations: [...],  // 4개만
  // relatedContent 없음
}
```

---

## Next.js에서 BFF 구현

Next.js의 **API Routes**가 자연스럽게 BFF 역할을 합니다.

### 기본 구조

```
app/
├── api/                           # BFF Layer
│   ├── products/
│   │   ├── route.ts               # GET /api/products
│   │   └── [id]/
│   │       ├── route.ts           # GET /api/products/:id
│   │       └── reviews/
│   │           └── route.ts       # GET /api/products/:id/reviews
│   ├── cart/
│   │   └── route.ts
│   └── checkout/
│       └── route.ts
└── ...
```

### 상품 상세 API

```tsx
// app/api/products/[id]/route.ts
import { NextResponse } from 'next/server'

// 마이크로서비스 클라이언트들
import { productService } from '@/lib/services/product'
import { inventoryService } from '@/lib/services/inventory'
import { reviewService } from '@/lib/services/review'
import { recommendationService } from '@/lib/services/recommendation'
import { promotionService } from '@/lib/services/promotion'

interface Props {
  params: { id: string }
}

export async function GET(request: Request, { params }: Props) {
  const productId = params.id

  try {
    // 1. 병렬로 모든 서비스 호출
    const [product, inventory, reviews, recommendations, promotions] =
      await Promise.all([
        productService.getProduct(productId),
        inventoryService.getStock(productId),
        reviewService.getReviews(productId, { limit: 5 }),
        recommendationService.getSimilar(productId, { limit: 8 }),
        promotionService.getActivePromotions(productId),
      ])

    // 2. 상품이 없으면 404
    if (!product) {
      return NextResponse.json(
        { error: 'Product not found' },
        { status: 404 }
      )
    }

    // 3. 할인가 계산
    const activePromotion = promotions.find((p) => p.type === 'DISCOUNT')
    const discountedPrice = activePromotion
      ? product.price * (1 - activePromotion.discountRate)
      : null

    // 4. 프론트엔드에 맞게 응답 구성
    return NextResponse.json({
      id: product.id,
      name: product.name,
      description: product.description,
      price: product.price,
      discountedPrice,
      images: product.images.map((img) => img.url),

      // 재고 정보
      stock: {
        available: inventory.quantity > 0,
        quantity: inventory.quantity,
        lowStock: inventory.quantity > 0 && inventory.quantity < 10,
      },

      // 리뷰 요약
      reviews: {
        average: reviews.averageRating,
        count: reviews.totalCount,
        recent: reviews.items.map((r) => ({
          id: r.id,
          rating: r.rating,
          content: r.content,
          author: r.user.name,
          createdAt: r.createdAt,
        })),
      },

      // 추천 상품 (필요한 필드만)
      recommendations: recommendations.map((item) => ({
        id: item.id,
        name: item.name,
        price: item.price,
        thumbnail: item.images[0]?.url,
      })),

      // 활성 프로모션
      promotions: promotions.map((p) => ({
        type: p.type,
        label: p.label,
        endDate: p.endDate,
      })),
    })
  } catch (error) {
    console.error('Error fetching product detail:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
```

### 프론트엔드에서 사용

```tsx
// app/products/[id]/page.tsx
import { ProductDetail } from '@/features/products'

interface Props {
  params: { id: string }
}

async function getProductDetail(id: string) {
  const res = await fetch(`${process.env.NEXT_PUBLIC_URL}/api/products/${id}`, {
    next: { revalidate: 60 }, // 1분 캐싱
  })

  if (!res.ok) {
    throw new Error('Failed to fetch product')
  }

  return res.json()
}

export default async function ProductPage({ params }: Props) {
  // 한 번의 API 호출로 모든 데이터!
  const product = await getProductDetail(params.id)

  return <ProductDetail product={product} />
}
```

---

## 서비스 레이어 구성

```
lib/
└── services/
    ├── product.ts        # 상품 서비스 클라이언트
    ├── inventory.ts      # 재고 서비스 클라이언트
    ├── review.ts         # 리뷰 서비스 클라이언트
    ├── recommendation.ts # 추천 서비스 클라이언트
    ├── promotion.ts      # 프로모션 서비스 클라이언트
    └── index.ts
```

```tsx
// lib/services/product.ts
const PRODUCT_SERVICE_URL = process.env.PRODUCT_SERVICE_URL

interface Product {
  id: string
  name: string
  description: string
  price: number
  categoryId: string
  images: { url: string; type: string }[]
}

export const productService = {
  async getProduct(id: string): Promise<Product | null> {
    try {
      const response = await fetch(`${PRODUCT_SERVICE_URL}/products/${id}`, {
        headers: {
          'X-Service-Key': process.env.INTERNAL_SERVICE_KEY!,
        },
      })

      if (!response.ok) {
        if (response.status === 404) return null
        throw new Error(`Product service error: ${response.status}`)
      }

      return response.json()
    } catch (error) {
      console.error('Product service error:', error)
      throw error
    }
  },

  async getProducts(params: {
    categoryId?: string
    page?: number
    limit?: number
  }): Promise<{ items: Product[]; total: number }> {
    const searchParams = new URLSearchParams()
    if (params.categoryId) searchParams.set('categoryId', params.categoryId)
    if (params.page) searchParams.set('page', String(params.page))
    if (params.limit) searchParams.set('limit', String(params.limit))

    const response = await fetch(
      `${PRODUCT_SERVICE_URL}/products?${searchParams}`,
      {
        headers: {
          'X-Service-Key': process.env.INTERNAL_SERVICE_KEY!,
        },
      }
    )

    if (!response.ok) {
      throw new Error(`Product service error: ${response.status}`)
    }

    return response.json()
  },
}
```

```tsx
// lib/services/inventory.ts
const INVENTORY_SERVICE_URL = process.env.INVENTORY_SERVICE_URL

interface Inventory {
  productId: string
  quantity: number
  status: 'AVAILABLE' | 'LOW_STOCK' | 'OUT_OF_STOCK'
  lastUpdated: string
}

export const inventoryService = {
  async getStock(productId: string): Promise<Inventory> {
    const response = await fetch(
      `${INVENTORY_SERVICE_URL}/stock/${productId}`,
      {
        headers: {
          'X-Service-Key': process.env.INTERNAL_SERVICE_KEY!,
        },
        // 재고는 자주 변하므로 캐싱 최소화
        next: { revalidate: 10 },
      }
    )

    if (!response.ok) {
      // 재고 정보 없으면 기본값 반환
      return {
        productId,
        quantity: 0,
        status: 'OUT_OF_STOCK',
        lastUpdated: new Date().toISOString(),
      }
    }

    return response.json()
  },

  async checkMultiple(productIds: string[]): Promise<Map<string, Inventory>> {
    const response = await fetch(`${INVENTORY_SERVICE_URL}/stock/batch`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Service-Key': process.env.INTERNAL_SERVICE_KEY!,
      },
      body: JSON.stringify({ productIds }),
    })

    const data = await response.json()
    return new Map(data.map((item: Inventory) => [item.productId, item]))
  },
}
```

---

## 에러 처리

```tsx
// app/api/products/[id]/route.ts
import { NextResponse } from 'next/server'

export async function GET(request: Request, { params }: Props) {
  const productId = params.id

  try {
    // 필수 데이터와 선택 데이터 분리
    const productPromise = productService.getProduct(productId)

    // 필수 데이터 먼저 확인
    const product = await productPromise

    if (!product) {
      return NextResponse.json(
        { error: 'Product not found' },
        { status: 404 }
      )
    }

    // 선택적 데이터는 실패해도 계속 진행
    const [inventory, reviews, recommendations] = await Promise.allSettled([
      inventoryService.getStock(productId),
      reviewService.getReviews(productId),
      recommendationService.getSimilar(productId),
    ])

    return NextResponse.json({
      ...product,

      // 재고 정보 (실패 시 기본값)
      stock:
        inventory.status === 'fulfilled'
          ? {
              available: inventory.value.quantity > 0,
              quantity: inventory.value.quantity,
            }
          : { available: false, quantity: 0 },

      // 리뷰 (실패 시 빈 배열)
      reviews:
        reviews.status === 'fulfilled'
          ? reviews.value
          : { average: 0, count: 0, recent: [] },

      // 추천 상품 (실패 시 빈 배열)
      recommendations:
        recommendations.status === 'fulfilled'
          ? recommendations.value
          : [],
    })
  } catch (error) {
    console.error('BFF Error:', error)

    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
```

---

## 캐싱 전략

```tsx
// app/api/products/[id]/route.ts
import { NextResponse } from 'next/server'

export async function GET(request: Request, { params }: Props) {
  const productId = params.id

  // 캐시 헤더 설정
  const headers = new Headers()

  try {
    const data = await getProductDetail(productId)

    // 상품 정보는 1분간 캐싱
    headers.set('Cache-Control', 'public, s-maxage=60, stale-while-revalidate=300')

    return NextResponse.json(data, { headers })
  } catch (error) {
    // 에러 응답은 캐싱하지 않음
    headers.set('Cache-Control', 'no-store')

    return NextResponse.json(
      { error: 'Failed to fetch product' },
      { status: 500, headers }
    )
  }
}
```

### 데이터별 캐싱

```tsx
// 정적 데이터 (긴 캐싱)
const categories = await fetch(categoryServiceUrl, {
  next: { revalidate: 3600 }, // 1시간
})

// 준정적 데이터 (중간 캐싱)
const product = await fetch(productServiceUrl, {
  next: { revalidate: 60 }, // 1분
})

// 동적 데이터 (캐싱 없음)
const inventory = await fetch(inventoryServiceUrl, {
  cache: 'no-store',
})
```

---

## 인증 처리

```tsx
// app/api/orders/route.ts
import { NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'

export async function GET(request: Request) {
  // 1. 세션 확인
  const session = await getServerSession(authOptions)

  if (!session) {
    return NextResponse.json(
      { error: 'Unauthorized' },
      { status: 401 }
    )
  }

  // 2. 내부 서비스 호출 시 사용자 정보 전달
  const orders = await orderService.getUserOrders(session.user.id, {
    headers: {
      'X-User-Id': session.user.id,
      'X-User-Role': session.user.role,
      'X-Service-Key': process.env.INTERNAL_SERVICE_KEY!,
    },
  })

  return NextResponse.json(orders)
}
```

---

## 플랫폼별 BFF

```tsx
// app/api/v1/products/[id]/route.ts (Web)
export async function GET(request: Request, { params }: Props) {
  const data = await getProductDetail(params.id)

  return NextResponse.json({
    ...data,
    reviews: data.reviews,           // 전체 리뷰
    recommendations: data.recommendations.slice(0, 10),  // 10개
    relatedArticles: await getRelatedArticles(params.id), // 관련 글
  })
}

// app/api/mobile/v1/products/[id]/route.ts (Mobile)
export async function GET(request: Request, { params }: Props) {
  const data = await getProductDetail(params.id)

  return NextResponse.json({
    id: data.id,
    name: data.name,
    price: data.price,
    mainImage: data.images[0],        // 이미지 1개만
    stock: data.stock.available,      // 재고 여부만
    rating: data.reviews.average,     // 평점만
    recommendations: data.recommendations.slice(0, 4),  // 4개만
    // relatedArticles 없음
  })
}
```

---

## 장단점

### 장점

- **프론트엔드 최적화**: 필요한 데이터만 필요한 형태로
- **네트워크 효율**: 여러 요청을 하나로 통합
- **유연성**: 백엔드 변경 시 BFF만 수정
- **플랫폼 특화**: 각 플랫폼에 맞는 API 제공
- **보안**: 내부 서비스 구조 숨김

### 단점

- **추가 레이어**: 관리해야 할 코드 증가
- **지연 시간**: 추가 홉(hop)으로 인한 지연
- **중복 가능성**: 여러 BFF 간 코드 중복
- **복잡성**: 마이크로서비스 + BFF 조합의 복잡도

---

## 언제 사용할까?

### 적합한 경우

- 마이크로서비스 아키텍처 사용 시
- 여러 플랫폼(Web, Mobile, TV 등) 지원 시
- 백엔드 API가 프론트엔드 요구사항과 맞지 않을 때
- 레거시 API를 새로운 형태로 제공해야 할 때

### 부적합한 경우

- 단일 백엔드 서비스
- 작은 규모의 프로젝트
- 백엔드가 이미 프론트엔드 친화적인 API 제공

---

## Next.js에서의 대안

### Server Components

Next.js 13+에서는 Server Components가 BFF 역할을 일부 대체할 수 있습니다:

```tsx
// app/products/[id]/page.tsx
// Server Component에서 직접 데이터 조합

async function ProductPage({ params }: Props) {
  // 서버에서 직접 여러 서비스 호출
  const [product, reviews, recommendations] = await Promise.all([
    productService.getProduct(params.id),
    reviewService.getReviews(params.id),
    recommendationService.getSimilar(params.id),
  ])

  return <ProductDetail product={product} reviews={reviews} />
}
```

이 방식은:
- 별도 API Route 없이 데이터 조합 가능
- 서버에서 렌더링되므로 클라이언트 요청 감소
- 단, 클라이언트에서 재사용할 API가 필요하면 여전히 BFF 필요
