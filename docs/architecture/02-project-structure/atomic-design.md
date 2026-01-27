# Atomic Design

UI 컴포넌트를 **화학의 원자 개념**처럼 단계별로 조합하는 방법론입니다. Brad Frost가 제안했으며, 디자인 시스템 구축에 널리 사용됩니다.

---

## 핵심 개념

UI를 5단계로 나누어 작은 단위부터 큰 단위로 조합합니다:

```
원자(Atoms) → 분자(Molecules) → 유기체(Organisms) → 템플릿(Templates) → 페이지(Pages)
```

```
components/
├── atoms/          # 가장 작은 단위
├── molecules/      # 원자의 조합
├── organisms/      # 분자의 조합
├── templates/      # 페이지 레이아웃
└── pages/          # 실제 콘텐츠
```

---

## 1. Atoms (원자)

더 이상 쪼갤 수 없는 **가장 기본적인 UI 요소**입니다. 단독으로는 큰 의미가 없지만, 모든 UI의 기초가 됩니다.

### 예시

- Button, Input, Label
- Icon, Image, Avatar
- Text, Heading, Link
- Badge, Tag, Spinner

### 코드 예시

```tsx
// components/atoms/Button/Button.tsx
import { ButtonHTMLAttributes, forwardRef } from 'react'
import styles from './Button.module.css'

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger'
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl'
  isLoading?: boolean
  leftIcon?: React.ReactNode
  rightIcon?: React.ReactNode
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      children,
      variant = 'primary',
      size = 'md',
      isLoading = false,
      leftIcon,
      rightIcon,
      className,
      disabled,
      ...props
    },
    ref
  ) => {
    return (
      <button
        ref={ref}
        className={`${styles.button} ${styles[variant]} ${styles[size]} ${className || ''}`}
        disabled={disabled || isLoading}
        {...props}
      >
        {isLoading && <span className={styles.spinner} />}
        {!isLoading && leftIcon && <span className={styles.leftIcon}>{leftIcon}</span>}
        {children}
        {!isLoading && rightIcon && <span className={styles.rightIcon}>{rightIcon}</span>}
      </button>
    )
  }
)

Button.displayName = 'Button'
```

```tsx
// components/atoms/Input/Input.tsx
import { InputHTMLAttributes, forwardRef } from 'react'
import styles from './Input.module.css'

export interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  error?: boolean
  leftElement?: React.ReactNode
  rightElement?: React.ReactNode
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ error, leftElement, rightElement, className, ...props }, ref) => {
    return (
      <div className={`${styles.inputWrapper} ${error ? styles.error : ''}`}>
        {leftElement && <span className={styles.leftElement}>{leftElement}</span>}
        <input
          ref={ref}
          className={`${styles.input} ${className || ''}`}
          {...props}
        />
        {rightElement && <span className={styles.rightElement}>{rightElement}</span>}
      </div>
    )
  }
)

Input.displayName = 'Input'
```

```tsx
// components/atoms/Label/Label.tsx
import { LabelHTMLAttributes } from 'react'
import styles from './Label.module.css'

export interface LabelProps extends LabelHTMLAttributes<HTMLLabelElement> {
  required?: boolean
}

export function Label({ children, required, className, ...props }: LabelProps) {
  return (
    <label className={`${styles.label} ${className || ''}`} {...props}>
      {children}
      {required && <span className={styles.required}>*</span>}
    </label>
  )
}
```

```tsx
// components/atoms/Text/Text.tsx
import { HTMLAttributes } from 'react'
import styles from './Text.module.css'

type TextVariant = 'body1' | 'body2' | 'caption' | 'overline'
type TextColor = 'primary' | 'secondary' | 'muted' | 'error' | 'success'

export interface TextProps extends HTMLAttributes<HTMLParagraphElement> {
  variant?: TextVariant
  color?: TextColor
  as?: 'p' | 'span' | 'div'
}

export function Text({
  children,
  variant = 'body1',
  color = 'primary',
  as: Component = 'p',
  className,
  ...props
}: TextProps) {
  return (
    <Component
      className={`${styles.text} ${styles[variant]} ${styles[color]} ${className || ''}`}
      {...props}
    >
      {children}
    </Component>
  )
}
```

```tsx
// components/atoms/Avatar/Avatar.tsx
import Image from 'next/image'
import styles from './Avatar.module.css'

export interface AvatarProps {
  src?: string
  alt: string
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl'
  fallback?: string
}

const sizeMap = {
  xs: 24,
  sm: 32,
  md: 40,
  lg: 48,
  xl: 64,
}

export function Avatar({ src, alt, size = 'md', fallback }: AvatarProps) {
  const pixelSize = sizeMap[size]

  if (!src) {
    const initial = fallback || alt.charAt(0).toUpperCase()
    return (
      <div
        className={`${styles.avatar} ${styles.fallback} ${styles[size]}`}
        aria-label={alt}
      >
        {initial}
      </div>
    )
  }

  return (
    <Image
      src={src}
      alt={alt}
      width={pixelSize}
      height={pixelSize}
      className={`${styles.avatar} ${styles[size]}`}
    />
  )
}
```

```tsx
// components/atoms/index.ts
export { Button } from './Button/Button'
export type { ButtonProps } from './Button/Button'

export { Input } from './Input/Input'
export type { InputProps } from './Input/Input'

export { Label } from './Label/Label'
export type { LabelProps } from './Label/Label'

export { Text } from './Text/Text'
export type { TextProps } from './Text/Text'

export { Avatar } from './Avatar/Avatar'
export type { AvatarProps } from './Avatar/Avatar'

export { Icon } from './Icon/Icon'
export { Badge } from './Badge/Badge'
export { Spinner } from './Spinner/Spinner'
```

---

## 2. Molecules (분자)

원자들을 조합한 **간단한 UI 그룹**입니다. 하나의 기능을 수행하는 단위입니다.

### 예시

- FormField (Label + Input + ErrorMessage)
- SearchInput (Input + Button)
- NavItem (Icon + Text)
- UserInfo (Avatar + Name + Email)

### 코드 예시

```tsx
// components/molecules/FormField/FormField.tsx
import { Input, InputProps, Label, Text } from '@/components/atoms'
import styles from './FormField.module.css'

export interface FormFieldProps extends InputProps {
  label: string
  name: string
  error?: string
  helperText?: string
  required?: boolean
}

export function FormField({
  label,
  name,
  error,
  helperText,
  required,
  ...inputProps
}: FormFieldProps) {
  return (
    <div className={styles.formField}>
      <Label htmlFor={name} required={required}>
        {label}
      </Label>

      <Input
        id={name}
        name={name}
        error={!!error}
        aria-describedby={error ? `${name}-error` : undefined}
        {...inputProps}
      />

      {error && (
        <Text
          id={`${name}-error`}
          variant="caption"
          color="error"
          role="alert"
        >
          {error}
        </Text>
      )}

      {!error && helperText && (
        <Text variant="caption" color="muted">
          {helperText}
        </Text>
      )}
    </div>
  )
}
```

```tsx
// components/molecules/SearchInput/SearchInput.tsx
'use client'

import { useState, FormEvent } from 'react'
import { Input, Button, Icon } from '@/components/atoms'
import styles from './SearchInput.module.css'

export interface SearchInputProps {
  placeholder?: string
  onSearch: (query: string) => void
  isLoading?: boolean
}

export function SearchInput({
  placeholder = '검색어를 입력하세요',
  onSearch,
  isLoading = false,
}: SearchInputProps) {
  const [value, setValue] = useState('')

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault()
    if (value.trim()) {
      onSearch(value.trim())
    }
  }

  return (
    <form className={styles.searchInput} onSubmit={handleSubmit}>
      <Input
        type="search"
        value={value}
        onChange={(e) => setValue(e.target.value)}
        placeholder={placeholder}
        leftElement={<Icon name="search" />}
      />
      <Button type="submit" isLoading={isLoading}>
        검색
      </Button>
    </form>
  )
}
```

```tsx
// components/molecules/UserInfo/UserInfo.tsx
import { Avatar, Text } from '@/components/atoms'
import styles from './UserInfo.module.css'

export interface UserInfoProps {
  name: string
  email?: string
  avatar?: string
  size?: 'sm' | 'md' | 'lg'
}

export function UserInfo({ name, email, avatar, size = 'md' }: UserInfoProps) {
  return (
    <div className={`${styles.userInfo} ${styles[size]}`}>
      <Avatar src={avatar} alt={name} size={size} />
      <div className={styles.details}>
        <Text variant={size === 'lg' ? 'body1' : 'body2'}>{name}</Text>
        {email && (
          <Text variant="caption" color="muted">
            {email}
          </Text>
        )}
      </div>
    </div>
  )
}
```

```tsx
// components/molecules/PriceTag/PriceTag.tsx
import { Text } from '@/components/atoms'
import styles from './PriceTag.module.css'

export interface PriceTagProps {
  price: number
  originalPrice?: number
  currency?: string
}

function formatPrice(price: number, currency: string): string {
  return new Intl.NumberFormat('ko-KR', {
    style: 'currency',
    currency,
  }).format(price)
}

export function PriceTag({
  price,
  originalPrice,
  currency = 'KRW',
}: PriceTagProps) {
  const hasDiscount = originalPrice && originalPrice > price
  const discountRate = hasDiscount
    ? Math.round((1 - price / originalPrice) * 100)
    : 0

  return (
    <div className={styles.priceTag}>
      {hasDiscount && (
        <>
          <Text
            as="span"
            variant="caption"
            color="muted"
            className={styles.originalPrice}
          >
            {formatPrice(originalPrice, currency)}
          </Text>
          <span className={styles.discountBadge}>-{discountRate}%</span>
        </>
      )}
      <Text as="span" variant="body1" className={styles.currentPrice}>
        {formatPrice(price, currency)}
      </Text>
    </div>
  )
}
```

```tsx
// components/molecules/Rating/Rating.tsx
import { Icon, Text } from '@/components/atoms'
import styles from './Rating.module.css'

export interface RatingProps {
  value: number
  max?: number
  reviewCount?: number
  showValue?: boolean
}

export function Rating({
  value,
  max = 5,
  reviewCount,
  showValue = true,
}: RatingProps) {
  const fullStars = Math.floor(value)
  const hasHalfStar = value % 1 >= 0.5
  const emptyStars = max - fullStars - (hasHalfStar ? 1 : 0)

  return (
    <div className={styles.rating}>
      <div className={styles.stars}>
        {[...Array(fullStars)].map((_, i) => (
          <Icon key={`full-${i}`} name="star-filled" className={styles.filled} />
        ))}
        {hasHalfStar && <Icon name="star-half" className={styles.filled} />}
        {[...Array(emptyStars)].map((_, i) => (
          <Icon key={`empty-${i}`} name="star" className={styles.empty} />
        ))}
      </div>

      {showValue && (
        <Text as="span" variant="caption" color="muted">
          {value.toFixed(1)}
        </Text>
      )}

      {reviewCount !== undefined && (
        <Text as="span" variant="caption" color="muted">
          ({reviewCount.toLocaleString()})
        </Text>
      )}
    </div>
  )
}
```

```tsx
// components/molecules/index.ts
export { FormField } from './FormField/FormField'
export type { FormFieldProps } from './FormField/FormField'

export { SearchInput } from './SearchInput/SearchInput'
export type { SearchInputProps } from './SearchInput/SearchInput'

export { UserInfo } from './UserInfo/UserInfo'
export type { UserInfoProps } from './UserInfo/UserInfo'

export { PriceTag } from './PriceTag/PriceTag'
export type { PriceTagProps } from './PriceTag/PriceTag'

export { Rating } from './Rating/Rating'
export type { RatingProps } from './Rating/Rating'
```

---

## 3. Organisms (유기체)

분자들을 조합한 **복잡한 UI 섹션**입니다. 독립적으로 의미를 가지며, 페이지의 특정 영역을 담당합니다.

### 예시

- Header, Footer, Sidebar
- ProductCard, UserCard
- LoginForm, CommentSection
- NavigationMenu, HeroSection

### 코드 예시

```tsx
// components/organisms/Header/Header.tsx
'use client'

import Link from 'next/link'
import { Button, Icon, Avatar } from '@/components/atoms'
import { SearchInput, UserInfo } from '@/components/molecules'
import { useAuth } from '@/hooks/useAuth'
import styles from './Header.module.css'

export function Header() {
  const { user, isAuthenticated } = useAuth()

  return (
    <header className={styles.header}>
      <div className={styles.container}>
        {/* Logo */}
        <Link href="/" className={styles.logo}>
          <Icon name="logo" size="lg" />
          <span>MyShop</span>
        </Link>

        {/* Navigation */}
        <nav className={styles.nav}>
          <Link href="/products">상품</Link>
          <Link href="/categories">카테고리</Link>
          <Link href="/deals">특가</Link>
        </nav>

        {/* Search */}
        <SearchInput
          onSearch={(query) => console.log('Search:', query)}
          placeholder="상품 검색"
        />

        {/* Actions */}
        <div className={styles.actions}>
          <Link href="/cart">
            <Button variant="ghost" aria-label="장바구니">
              <Icon name="cart" />
            </Button>
          </Link>

          {isAuthenticated ? (
            <UserInfo
              name={user!.name}
              avatar={user!.avatar}
              size="sm"
            />
          ) : (
            <Link href="/login">
              <Button variant="outline">로그인</Button>
            </Link>
          )}
        </div>
      </div>
    </header>
  )
}
```

```tsx
// components/organisms/ProductCard/ProductCard.tsx
import Image from 'next/image'
import Link from 'next/link'
import { Button, Badge, Icon } from '@/components/atoms'
import { PriceTag, Rating } from '@/components/molecules'
import styles from './ProductCard.module.css'

export interface Product {
  id: string
  name: string
  price: number
  originalPrice?: number
  image: string
  rating: number
  reviewCount: number
  isNew?: boolean
  isSoldOut?: boolean
}

export interface ProductCardProps {
  product: Product
  onAddToCart?: (product: Product) => void
  onToggleWishlist?: (product: Product) => void
  isWishlisted?: boolean
}

export function ProductCard({
  product,
  onAddToCart,
  onToggleWishlist,
  isWishlisted = false,
}: ProductCardProps) {
  return (
    <article className={styles.productCard}>
      {/* Image */}
      <div className={styles.imageWrapper}>
        <Link href={`/products/${product.id}`}>
          <Image
            src={product.image}
            alt={product.name}
            fill
            className={styles.image}
          />
        </Link>

        {/* Badges */}
        <div className={styles.badges}>
          {product.isNew && <Badge variant="primary">NEW</Badge>}
          {product.isSoldOut && <Badge variant="secondary">품절</Badge>}
        </div>

        {/* Wishlist Button */}
        {onToggleWishlist && (
          <button
            className={styles.wishlistBtn}
            onClick={() => onToggleWishlist(product)}
            aria-label={isWishlisted ? '위시리스트에서 제거' : '위시리스트에 추가'}
          >
            <Icon
              name={isWishlisted ? 'heart-filled' : 'heart'}
              className={isWishlisted ? styles.wishlisted : ''}
            />
          </button>
        )}
      </div>

      {/* Content */}
      <div className={styles.content}>
        <Link href={`/products/${product.id}`}>
          <h3 className={styles.name}>{product.name}</h3>
        </Link>

        <Rating value={product.rating} reviewCount={product.reviewCount} />

        <PriceTag price={product.price} originalPrice={product.originalPrice} />

        {/* Actions */}
        {onAddToCart && (
          <Button
            onClick={() => onAddToCart(product)}
            disabled={product.isSoldOut}
            className={styles.addToCartBtn}
          >
            {product.isSoldOut ? '품절' : '장바구니 담기'}
          </Button>
        )}
      </div>
    </article>
  )
}
```

```tsx
// components/organisms/LoginForm/LoginForm.tsx
'use client'

import { useState, FormEvent } from 'react'
import Link from 'next/link'
import { Button, Text } from '@/components/atoms'
import { FormField } from '@/components/molecules'
import styles from './LoginForm.module.css'

export interface LoginFormProps {
  onSubmit: (email: string, password: string) => Promise<void>
  isLoading?: boolean
  error?: string
}

export function LoginForm({ onSubmit, isLoading = false, error }: LoginFormProps) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})

  const validate = (): boolean => {
    const newErrors: Record<string, string> = {}

    if (!email) {
      newErrors.email = '이메일을 입력하세요'
    } else if (!/\S+@\S+\.\S+/.test(email)) {
      newErrors.email = '올바른 이메일 형식이 아닙니다'
    }

    if (!password) {
      newErrors.password = '비밀번호를 입력하세요'
    } else if (password.length < 8) {
      newErrors.password = '비밀번호는 8자 이상이어야 합니다'
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    if (validate()) {
      await onSubmit(email, password)
    }
  }

  return (
    <form className={styles.loginForm} onSubmit={handleSubmit}>
      <h2 className={styles.title}>로그인</h2>

      {error && (
        <Text color="error" className={styles.errorAlert}>
          {error}
        </Text>
      )}

      <FormField
        label="이메일"
        name="email"
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        error={errors.email}
        required
        autoComplete="email"
      />

      <FormField
        label="비밀번호"
        name="password"
        type="password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        error={errors.password}
        required
        autoComplete="current-password"
      />

      <Button
        type="submit"
        isLoading={isLoading}
        className={styles.submitBtn}
      >
        로그인
      </Button>

      <div className={styles.links}>
        <Link href="/forgot-password">비밀번호 찾기</Link>
        <Link href="/register">회원가입</Link>
      </div>
    </form>
  )
}
```

```tsx
// components/organisms/Footer/Footer.tsx
import Link from 'next/link'
import { Icon, Text } from '@/components/atoms'
import styles from './Footer.module.css'

export function Footer() {
  return (
    <footer className={styles.footer}>
      <div className={styles.container}>
        {/* Links */}
        <div className={styles.linksSection}>
          <div className={styles.linkGroup}>
            <h4>고객센터</h4>
            <Link href="/faq">자주 묻는 질문</Link>
            <Link href="/contact">문의하기</Link>
            <Link href="/shipping">배송 안내</Link>
          </div>

          <div className={styles.linkGroup}>
            <h4>회사 정보</h4>
            <Link href="/about">회사 소개</Link>
            <Link href="/careers">채용</Link>
            <Link href="/press">보도자료</Link>
          </div>

          <div className={styles.linkGroup}>
            <h4>정책</h4>
            <Link href="/terms">이용약관</Link>
            <Link href="/privacy">개인정보처리방침</Link>
            <Link href="/refund">환불 정책</Link>
          </div>
        </div>

        {/* Social */}
        <div className={styles.socialSection}>
          <a href="https://instagram.com" aria-label="Instagram">
            <Icon name="instagram" />
          </a>
          <a href="https://facebook.com" aria-label="Facebook">
            <Icon name="facebook" />
          </a>
          <a href="https://twitter.com" aria-label="Twitter">
            <Icon name="twitter" />
          </a>
        </div>

        {/* Copyright */}
        <Text variant="caption" color="muted" className={styles.copyright}>
          © 2024 MyShop. All rights reserved.
        </Text>
      </div>
    </footer>
  )
}
```

```tsx
// components/organisms/index.ts
export { Header } from './Header/Header'
export { Footer } from './Footer/Footer'
export { ProductCard } from './ProductCard/ProductCard'
export type { ProductCardProps, Product } from './ProductCard/ProductCard'
export { LoginForm } from './LoginForm/LoginForm'
export type { LoginFormProps } from './LoginForm/LoginForm'
```

---

## 4. Templates (템플릿)

페이지의 **레이아웃 구조**를 정의합니다. 실제 콘텐츠 대신 Placeholder를 사용하며, 콘텐츠의 위치와 배치를 결정합니다.

### 예시

- MainTemplate (Header + Main + Footer)
- DashboardTemplate (Sidebar + Content)
- AuthTemplate (Centered form)
- ProductListTemplate (Filters + Grid + Pagination)

### 코드 예시

```tsx
// components/templates/MainTemplate/MainTemplate.tsx
import styles from './MainTemplate.module.css'

export interface MainTemplateProps {
  header: React.ReactNode
  children: React.ReactNode
  footer: React.ReactNode
  sidebar?: React.ReactNode
}

export function MainTemplate({
  header,
  children,
  footer,
  sidebar,
}: MainTemplateProps) {
  return (
    <div className={styles.mainTemplate}>
      <div className={styles.header}>{header}</div>

      <div className={styles.body}>
        {sidebar && <aside className={styles.sidebar}>{sidebar}</aside>}
        <main className={styles.main}>{children}</main>
      </div>

      <div className={styles.footer}>{footer}</div>
    </div>
  )
}
```

```tsx
// components/templates/AuthTemplate/AuthTemplate.tsx
import styles from './AuthTemplate.module.css'

export interface AuthTemplateProps {
  children: React.ReactNode
  title?: string
  subtitle?: string
}

export function AuthTemplate({ children, title, subtitle }: AuthTemplateProps) {
  return (
    <div className={styles.authTemplate}>
      <div className={styles.container}>
        {(title || subtitle) && (
          <div className={styles.header}>
            {title && <h1 className={styles.title}>{title}</h1>}
            {subtitle && <p className={styles.subtitle}>{subtitle}</p>}
          </div>
        )}

        <div className={styles.content}>{children}</div>
      </div>
    </div>
  )
}
```

```tsx
// components/templates/ProductListTemplate/ProductListTemplate.tsx
import styles from './ProductListTemplate.module.css'

export interface ProductListTemplateProps {
  filters: React.ReactNode
  products: React.ReactNode
  pagination: React.ReactNode
  sortControls?: React.ReactNode
  resultCount?: React.ReactNode
}

export function ProductListTemplate({
  filters,
  products,
  pagination,
  sortControls,
  resultCount,
}: ProductListTemplateProps) {
  return (
    <div className={styles.productListTemplate}>
      <aside className={styles.filtersSection}>{filters}</aside>

      <div className={styles.productsSection}>
        <div className={styles.toolbar}>
          {resultCount && <div className={styles.resultCount}>{resultCount}</div>}
          {sortControls && <div className={styles.sortControls}>{sortControls}</div>}
        </div>

        <div className={styles.productGrid}>{products}</div>

        <div className={styles.pagination}>{pagination}</div>
      </div>
    </div>
  )
}
```

```tsx
// components/templates/DashboardTemplate/DashboardTemplate.tsx
import styles from './DashboardTemplate.module.css'

export interface DashboardTemplateProps {
  sidebar: React.ReactNode
  header: React.ReactNode
  children: React.ReactNode
}

export function DashboardTemplate({
  sidebar,
  header,
  children,
}: DashboardTemplateProps) {
  return (
    <div className={styles.dashboardTemplate}>
      <aside className={styles.sidebar}>{sidebar}</aside>

      <div className={styles.mainArea}>
        <header className={styles.header}>{header}</header>
        <main className={styles.content}>{children}</main>
      </div>
    </div>
  )
}
```

```tsx
// components/templates/index.ts
export { MainTemplate } from './MainTemplate/MainTemplate'
export type { MainTemplateProps } from './MainTemplate/MainTemplate'

export { AuthTemplate } from './AuthTemplate/AuthTemplate'
export type { AuthTemplateProps } from './AuthTemplate/AuthTemplate'

export { ProductListTemplate } from './ProductListTemplate/ProductListTemplate'
export type { ProductListTemplateProps } from './ProductListTemplate/ProductListTemplate'

export { DashboardTemplate } from './DashboardTemplate/DashboardTemplate'
export type { DashboardTemplateProps } from './DashboardTemplate/DashboardTemplate'
```

---

## 5. Pages (페이지)

템플릿에 **실제 데이터와 컴포넌트**를 넣어 완성된 페이지를 만듭니다.

### 코드 예시

```tsx
// components/pages/HomePage/HomePage.tsx
import { MainTemplate } from '@/components/templates'
import { Header, Footer, ProductCard, HeroBanner } from '@/components/organisms'
import { Product } from '@/components/organisms/ProductCard/ProductCard'
import styles from './HomePage.module.css'

export interface HomePageProps {
  featuredProducts: Product[]
  newProducts: Product[]
}

export function HomePage({ featuredProducts, newProducts }: HomePageProps) {
  const handleAddToCart = (product: Product) => {
    console.log('Add to cart:', product.id)
  }

  return (
    <MainTemplate header={<Header />} footer={<Footer />}>
      <HeroBanner />

      <section className={styles.section}>
        <h2>인기 상품</h2>
        <div className={styles.productGrid}>
          {featuredProducts.map((product) => (
            <ProductCard
              key={product.id}
              product={product}
              onAddToCart={handleAddToCart}
            />
          ))}
        </div>
      </section>

      <section className={styles.section}>
        <h2>신상품</h2>
        <div className={styles.productGrid}>
          {newProducts.map((product) => (
            <ProductCard
              key={product.id}
              product={product}
              onAddToCart={handleAddToCart}
            />
          ))}
        </div>
      </section>
    </MainTemplate>
  )
}
```

```tsx
// components/pages/LoginPage/LoginPage.tsx
'use client'

import { useRouter } from 'next/navigation'
import { useState } from 'react'
import { AuthTemplate } from '@/components/templates'
import { LoginForm } from '@/components/organisms'
import { authApi } from '@/api/auth'

export function LoginPage() {
  const router = useRouter()
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string>()

  const handleLogin = async (email: string, password: string) => {
    setIsLoading(true)
    setError(undefined)

    try {
      await authApi.login({ email, password })
      router.push('/dashboard')
    } catch (err) {
      setError('이메일 또는 비밀번호가 올바르지 않습니다')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <AuthTemplate
      title="로그인"
      subtitle="계정에 로그인하세요"
    >
      <LoginForm
        onSubmit={handleLogin}
        isLoading={isLoading}
        error={error}
      />
    </AuthTemplate>
  )
}
```

```tsx
// components/pages/ProductListPage/ProductListPage.tsx
import { MainTemplate, ProductListTemplate } from '@/components/templates'
import { Header, Footer, ProductCard } from '@/components/organisms'
import { FilterPanel, SortSelect, Pagination } from '@/components/organisms'
import { Text } from '@/components/atoms'
import { Product } from '@/components/organisms/ProductCard/ProductCard'

export interface ProductListPageProps {
  products: Product[]
  totalCount: number
  currentPage: number
  totalPages: number
  filters: {
    categories: string[]
    priceRange: { min: number; max: number }
  }
}

export function ProductListPage({
  products,
  totalCount,
  currentPage,
  totalPages,
  filters,
}: ProductListPageProps) {
  return (
    <MainTemplate header={<Header />} footer={<Footer />}>
      <ProductListTemplate
        filters={<FilterPanel filters={filters} />}
        resultCount={<Text>{totalCount.toLocaleString()}개의 상품</Text>}
        sortControls={<SortSelect />}
        products={
          <>
            {products.map((product) => (
              <ProductCard key={product.id} product={product} />
            ))}
          </>
        }
        pagination={
          <Pagination
            currentPage={currentPage}
            totalPages={totalPages}
          />
        }
      />
    </MainTemplate>
  )
}
```

---

## 폴더 구조 요약

```
components/
├── atoms/
│   ├── Button/
│   │   ├── Button.tsx
│   │   ├── Button.module.css
│   │   └── Button.test.tsx
│   ├── Input/
│   ├── Label/
│   ├── Text/
│   ├── Avatar/
│   ├── Icon/
│   ├── Badge/
│   ├── Spinner/
│   └── index.ts
│
├── molecules/
│   ├── FormField/
│   ├── SearchInput/
│   ├── UserInfo/
│   ├── PriceTag/
│   ├── Rating/
│   └── index.ts
│
├── organisms/
│   ├── Header/
│   ├── Footer/
│   ├── ProductCard/
│   ├── LoginForm/
│   ├── FilterPanel/
│   └── index.ts
│
├── templates/
│   ├── MainTemplate/
│   ├── AuthTemplate/
│   ├── ProductListTemplate/
│   ├── DashboardTemplate/
│   └── index.ts
│
└── pages/
    ├── HomePage/
    ├── LoginPage/
    ├── ProductListPage/
    └── index.ts
```

---

## 분류 기준

| 단계 | 질문 | 예시 |
|------|------|------|
| **Atom** | 더 쪼갤 수 있나? | Button, Input → No |
| **Molecule** | 한 가지 기능만 하나? | FormField(Label+Input+Error) → Yes |
| **Organism** | 독립적으로 의미가 있나? | Header, ProductCard → Yes |
| **Template** | 콘텐츠 없이 레이아웃만? | MainTemplate → Yes |
| **Page** | 실제 데이터가 들어있나? | HomePage → Yes |

---

## 장단점

### 장점

- UI 컴포넌트 재사용성 극대화
- 디자인 시스템 구축에 최적화
- 디자이너와 협업 시 공통 언어 제공
- 일관된 UI 유지 가능
- 컴포넌트 테스트 용이

### 단점

- 분류 기준이 주관적일 수 있음 (이게 분자야? 유기체야?)
- 비즈니스 로직과 UI가 분리되어 있어 전체 흐름 파악이 어려울 수 있음
- 작은 변경에도 여러 레이어를 수정해야 할 수 있음
- 초기 설정 비용이 높음

---

## 언제 사용할까?

- **디자인 시스템**을 구축할 때
- **재사용 가능한 UI 라이브러리**를 만들 때
- 여러 프로젝트에서 **컴포넌트를 공유**할 때
- **디자이너와 긴밀히 협업**하는 팀

비즈니스 로직이 복잡한 경우 [FSD](./fsd.md)와 조합해서 사용할 수 있습니다:
- Atomic Design으로 UI 컴포넌트 관리
- FSD로 비즈니스 로직 관리

---

## 참고 자료

- [Atomic Design by Brad Frost](https://bradfrost.com/blog/post/atomic-web-design/)
- [Atomic Design Book](https://atomicdesign.bradfrost.com/)
