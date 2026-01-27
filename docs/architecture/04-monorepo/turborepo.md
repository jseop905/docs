# Turborepo

Vercel에서 만든 **고성능 모노레포 빌드 시스템**입니다. 캐싱과 병렬 실행으로 빌드 속도를 크게 향상시킵니다.

---

## 모노레포란?

여러 프로젝트를 **하나의 저장소**에서 관리하는 방식입니다.

```
# 멀티레포 (기존 방식)
company-website/     ← 별도 저장소
admin-dashboard/     ← 별도 저장소
mobile-app/          ← 별도 저장소
shared-components/   ← 별도 저장소

# 모노레포
my-company/          ← 하나의 저장소
├── apps/
│   ├── website/
│   ├── admin/
│   └── mobile/
└── packages/
    └── shared-components/
```

### 모노레포의 장점

- 코드 공유가 쉬움
- 일관된 설정 관리
- 원자적 커밋 (여러 프로젝트 동시 변경)
- 의존성 관리 단순화

### 모노레포의 단점

- 저장소가 커짐
- 빌드 시간 증가 (Turborepo로 해결!)
- 권한 관리 복잡

---

## Turborepo 시작하기

### 새 프로젝트 생성

```bash
# 새 Turborepo 프로젝트 생성
npx create-turbo@latest my-turborepo

# 또는 pnpm 사용
pnpm dlx create-turbo@latest my-turborepo
```

### 기존 프로젝트에 추가

```bash
# Turborepo 설치
npm install turbo --save-dev

# turbo.json 생성
npx turbo init
```

---

## 폴더 구조

```
my-turborepo/
├── apps/                         # 애플리케이션들
│   ├── web/                      # 메인 웹앱 (Next.js)
│   │   ├── app/
│   │   ├── package.json
│   │   ├── next.config.js
│   │   └── tsconfig.json
│   │
│   ├── admin/                    # 어드민 대시보드
│   │   ├── app/
│   │   ├── package.json
│   │   └── ...
│   │
│   └── docs/                     # 문서 사이트
│       ├── pages/
│       ├── package.json
│       └── ...
│
├── packages/                     # 공유 패키지들
│   ├── ui/                       # UI 컴포넌트 라이브러리
│   │   ├── src/
│   │   │   ├── Button.tsx
│   │   │   ├── Input.tsx
│   │   │   └── index.ts
│   │   ├── package.json
│   │   └── tsconfig.json
│   │
│   ├── utils/                    # 유틸리티 함수
│   │   ├── src/
│   │   │   ├── formatDate.ts
│   │   │   └── index.ts
│   │   └── package.json
│   │
│   ├── config-eslint/            # 공유 ESLint 설정
│   │   ├── index.js
│   │   └── package.json
│   │
│   └── config-typescript/        # 공유 TypeScript 설정
│       ├── base.json
│       ├── nextjs.json
│       ├── react-library.json
│       └── package.json
│
├── turbo.json                    # Turborepo 설정
├── package.json                  # 루트 package.json
├── pnpm-workspace.yaml           # pnpm 워크스페이스 설정
└── .gitignore
```

---

## 핵심 설정 파일

### pnpm-workspace.yaml

워크스페이스에 포함할 폴더를 지정합니다.

```yaml
# pnpm-workspace.yaml
packages:
  - "apps/*"
  - "packages/*"
```

### 루트 package.json

```json
{
  "name": "my-turborepo",
  "private": true,
  "scripts": {
    "build": "turbo build",
    "dev": "turbo dev",
    "lint": "turbo lint",
    "test": "turbo test",
    "clean": "turbo clean"
  },
  "devDependencies": {
    "turbo": "^2.0.0"
  },
  "packageManager": "pnpm@8.0.0"
}
```

### turbo.json

Turborepo의 핵심 설정 파일입니다.

```json
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["**/.env.*local"],
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "!.next/cache/**", "dist/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "lint": {},
    "test": {
      "dependsOn": ["build"]
    },
    "clean": {
      "cache": false
    }
  }
}
```

---

## Pipeline 설정 상세

### dependsOn

태스크 실행 순서를 지정합니다.

```json
{
  "pipeline": {
    "build": {
      // ^build: 의존하는 패키지들의 build가 먼저 실행
      // 예: web이 ui에 의존하면, ui의 build가 먼저 실행
      "dependsOn": ["^build"]
    },
    "test": {
      // build가 먼저 실행된 후 test 실행
      "dependsOn": ["build"]
    },
    "deploy": {
      // build와 test가 먼저 실행
      "dependsOn": ["build", "test"]
    }
  }
}
```

### outputs

캐싱할 빌드 결과물을 지정합니다.

```json
{
  "pipeline": {
    "build": {
      "outputs": [
        ".next/**",           // Next.js 빌드 결과
        "!.next/cache/**",    // 캐시 제외
        "dist/**",            // 라이브러리 빌드 결과
        "build/**"            // CRA 빌드 결과
      ]
    }
  }
}
```

### cache

캐싱 여부를 설정합니다.

```json
{
  "pipeline": {
    "dev": {
      "cache": false,      // 개발 서버는 캐싱 안 함
      "persistent": true   // 계속 실행되는 태스크
    },
    "lint": {
      "cache": true        // 기본값, 결과 캐싱
    }
  }
}
```

### inputs

캐시 무효화 기준이 되는 파일을 지정합니다.

```json
{
  "pipeline": {
    "test": {
      "inputs": [
        "src/**/*.tsx",
        "src/**/*.ts",
        "test/**/*.ts"
      ]
    },
    "lint": {
      "inputs": [
        "src/**/*.tsx",
        "src/**/*.ts",
        ".eslintrc.js"
      ]
    }
  }
}
```

---

## 공유 패키지 만들기

### UI 패키지

```json
// packages/ui/package.json
{
  "name": "@repo/ui",
  "version": "0.0.0",
  "private": true,
  "exports": {
    ".": "./src/index.ts",
    "./button": "./src/Button.tsx",
    "./input": "./src/Input.tsx"
  },
  "scripts": {
    "lint": "eslint src/",
    "build": "tsc",
    "dev": "tsc --watch"
  },
  "devDependencies": {
    "@repo/config-eslint": "workspace:*",
    "@repo/config-typescript": "workspace:*",
    "typescript": "^5.0.0"
  },
  "peerDependencies": {
    "react": "^18.0.0",
    "react-dom": "^18.0.0"
  }
}
```

```tsx
// packages/ui/src/Button.tsx
import { ButtonHTMLAttributes, forwardRef } from 'react'

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline'
  size?: 'sm' | 'md' | 'lg'
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ children, variant = 'primary', size = 'md', className, ...props }, ref) => {
    const baseStyles = 'inline-flex items-center justify-center rounded font-medium'

    const variants = {
      primary: 'bg-blue-600 text-white hover:bg-blue-700',
      secondary: 'bg-gray-200 text-gray-900 hover:bg-gray-300',
      outline: 'border border-gray-300 hover:bg-gray-50',
    }

    const sizes = {
      sm: 'px-3 py-1.5 text-sm',
      md: 'px-4 py-2 text-base',
      lg: 'px-6 py-3 text-lg',
    }

    return (
      <button
        ref={ref}
        className={`${baseStyles} ${variants[variant]} ${sizes[size]} ${className || ''}`}
        {...props}
      >
        {children}
      </button>
    )
  }
)

Button.displayName = 'Button'
```

```tsx
// packages/ui/src/index.ts
export { Button } from './Button'
export type { ButtonProps } from './Button'

export { Input } from './Input'
export type { InputProps } from './Input'

export { Modal } from './Modal'
export type { ModalProps } from './Modal'
```

```json
// packages/ui/tsconfig.json
{
  "extends": "@repo/config-typescript/react-library.json",
  "compilerOptions": {
    "outDir": "dist"
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist"]
}
```

### Utils 패키지

```json
// packages/utils/package.json
{
  "name": "@repo/utils",
  "version": "0.0.0",
  "private": true,
  "exports": {
    ".": "./src/index.ts"
  },
  "scripts": {
    "lint": "eslint src/",
    "build": "tsc",
    "test": "jest"
  },
  "devDependencies": {
    "@repo/config-typescript": "workspace:*",
    "typescript": "^5.0.0"
  }
}
```

```tsx
// packages/utils/src/formatDate.ts
export function formatDate(date: Date | string, format = 'YYYY-MM-DD'): string {
  const d = typeof date === 'string' ? new Date(date) : date

  const year = d.getFullYear()
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')

  return format
    .replace('YYYY', String(year))
    .replace('MM', month)
    .replace('DD', day)
}

export function formatRelativeTime(date: Date | string): string {
  const d = typeof date === 'string' ? new Date(date) : date
  const now = new Date()
  const diff = now.getTime() - d.getTime()

  const seconds = Math.floor(diff / 1000)
  const minutes = Math.floor(seconds / 60)
  const hours = Math.floor(minutes / 60)
  const days = Math.floor(hours / 24)

  if (days > 0) return `${days}일 전`
  if (hours > 0) return `${hours}시간 전`
  if (minutes > 0) return `${minutes}분 전`
  return '방금 전'
}
```

```tsx
// packages/utils/src/formatPrice.ts
export function formatPrice(
  price: number,
  options: {
    currency?: string
    locale?: string
  } = {}
): string {
  const { currency = 'KRW', locale = 'ko-KR' } = options

  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency,
  }).format(price)
}
```

```tsx
// packages/utils/src/index.ts
export { formatDate, formatRelativeTime } from './formatDate'
export { formatPrice } from './formatPrice'
export { cn } from './cn'
```

### 공유 설정 패키지

```js
// packages/config-eslint/index.js
module.exports = {
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:react/recommended',
    'plugin:react-hooks/recommended',
    'prettier',
  ],
  parser: '@typescript-eslint/parser',
  plugins: ['@typescript-eslint', 'react'],
  rules: {
    'react/react-in-jsx-scope': 'off',
    '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
  },
  settings: {
    react: {
      version: 'detect',
    },
  },
}
```

```json
// packages/config-typescript/base.json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  }
}
```

```json
// packages/config-typescript/nextjs.json
{
  "extends": "./base.json",
  "compilerOptions": {
    "lib": ["DOM", "DOM.Iterable", "ES2020"],
    "jsx": "preserve",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowJs": true,
    "noEmit": true,
    "incremental": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "plugins": [
      {
        "name": "next"
      }
    ]
  }
}
```

```json
// packages/config-typescript/react-library.json
{
  "extends": "./base.json",
  "compilerOptions": {
    "lib": ["DOM", "DOM.Iterable", "ES2020"],
    "jsx": "react-jsx",
    "declaration": true,
    "declarationMap": true
  }
}
```

---

## 앱에서 패키지 사용

### package.json 설정

```json
// apps/web/package.json
{
  "name": "web",
  "version": "0.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "@repo/ui": "workspace:*",
    "@repo/utils": "workspace:*",
    "next": "^14.0.0",
    "react": "^18.0.0",
    "react-dom": "^18.0.0"
  },
  "devDependencies": {
    "@repo/config-eslint": "workspace:*",
    "@repo/config-typescript": "workspace:*",
    "typescript": "^5.0.0"
  }
}
```

### 컴포넌트에서 사용

```tsx
// apps/web/app/page.tsx
import { Button, Input } from '@repo/ui'
import { formatDate, formatPrice } from '@repo/utils'

export default function HomePage() {
  const today = formatDate(new Date())
  const price = formatPrice(10000)

  return (
    <main>
      <h1>오늘: {today}</h1>
      <p>가격: {price}</p>

      <div>
        <Input placeholder="이름을 입력하세요" />
        <Button variant="primary">
          제출
        </Button>
      </div>
    </main>
  )
}
```

### Next.js 설정

```js
// apps/web/next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  transpilePackages: ['@repo/ui', '@repo/utils'],
}

module.exports = nextConfig
```

---

## 주요 명령어

### 기본 명령어

```bash
# 모든 앱 빌드
pnpm build

# 모든 앱 개발 서버 시작
pnpm dev

# 모든 앱 린트
pnpm lint

# 모든 앱 테스트
pnpm test

# 캐시 삭제
pnpm clean
```

### 필터링

```bash
# 특정 앱만 빌드
pnpm build --filter web

# 특정 앱만 개발 서버
pnpm dev --filter admin

# 여러 앱 지정
pnpm build --filter web --filter admin

# 패턴 매칭
pnpm build --filter "@repo/*"

# 의존성 포함
pnpm build --filter web...
```

### 캐시 관리

```bash
# 로컬 캐시 삭제
turbo clean

# 캐시 상태 확인
turbo run build --dry-run
```

---

## Remote Caching

팀원들과 빌드 캐시를 공유하여 CI/CD 속도를 크게 향상시킵니다.

### Vercel Remote Cache

```bash
# Vercel에 로그인
npx turbo login

# Remote cache 연결
npx turbo link
```

### 환경 변수 설정

```bash
# CI/CD에서 사용
TURBO_TOKEN=your_token
TURBO_TEAM=your_team
```

### turbo.json 설정

```json
{
  "$schema": "https://turbo.build/schema.json",
  "remoteCache": {
    "signature": true
  },
  "pipeline": {
    // ...
  }
}
```

---

## 환경 변수 관리

### 전역 환경 변수

```json
// turbo.json
{
  "globalEnv": ["NODE_ENV", "CI"],
  "globalDependencies": [".env"],
  "pipeline": {
    // ...
  }
}
```

### 앱별 환경 변수

```json
// turbo.json
{
  "pipeline": {
    "build": {
      "env": ["DATABASE_URL", "API_KEY"],
      "dependsOn": ["^build"]
    }
  }
}
```

### .env 파일 구조

```
my-turborepo/
├── .env                    # 전역 (모든 앱)
├── .env.local              # 전역 로컬 (gitignore)
├── apps/
│   ├── web/
│   │   ├── .env            # web 앱 전용
│   │   └── .env.local
│   └── admin/
│       ├── .env            # admin 앱 전용
│       └── .env.local
```

---

## 모범 사례

### 1. 패키지 네이밍 컨벤션

```
@repo/ui          # UI 컴포넌트
@repo/utils       # 유틸리티
@repo/config-*    # 설정 패키지
@repo/types       # 공유 타입
@repo/api-client  # API 클라이언트
```

### 2. 의존성 관리

```json
// 루트 package.json - 공통 개발 의존성
{
  "devDependencies": {
    "turbo": "^2.0.0",
    "prettier": "^3.0.0"
  }
}

// 패키지별 - 해당 패키지에서만 사용하는 의존성
// packages/ui/package.json
{
  "peerDependencies": {
    "react": "^18.0.0"  // peer로 지정
  }
}
```

### 3. 버전 관리

```bash
# Changesets 사용
pnpm add -D @changesets/cli
pnpm changeset init

# 변경 사항 기록
pnpm changeset

# 버전 업데이트
pnpm changeset version

# 배포
pnpm changeset publish
```

---

## 실전 예시: 전자상거래 모노레포

```
ecommerce-monorepo/
├── apps/
│   ├── web/                  # 고객용 웹사이트
│   ├── admin/                # 관리자 대시보드
│   ├── mobile/               # React Native 앱
│   └── api/                  # Express/NestJS API 서버
│
├── packages/
│   ├── ui/                   # 공유 UI 컴포넌트
│   ├── api-client/           # API 클라이언트 (React Query 훅)
│   ├── types/                # 공유 TypeScript 타입
│   ├── utils/                # 유틸리티 함수
│   ├── validators/           # Zod 스키마
│   ├── config-eslint/
│   └── config-typescript/
│
├── turbo.json
├── package.json
└── pnpm-workspace.yaml
```

---

## 장단점

### 장점

- **빌드 캐싱**: 변경된 부분만 다시 빌드
- **병렬 실행**: 독립적인 태스크 동시 실행
- **Remote Caching**: 팀 전체 빌드 캐시 공유
- **의존성 그래프**: 자동으로 빌드 순서 결정
- **점진적 채택**: 기존 프로젝트에 쉽게 추가

### 단점

- **초기 설정 복잡성**: 처음 구성하는 데 시간 필요
- **학습 곡선**: 팀 전체가 모노레포 개념 이해 필요
- **저장소 크기**: 프로젝트가 많아지면 커짐
- **CI/CD 복잡성**: 적절한 설정 필요

---

## 참고 자료

- [Turborepo 공식 문서](https://turbo.build/repo/docs)
- [Turborepo Examples](https://github.com/vercel/turbo/tree/main/examples)
- [Vercel Monorepo Guide](https://vercel.com/docs/monorepos)
