# Contributing Guide

## Code Style

### Go Standards
- Follow [Effective Go](https://golang.org/doc/effective_go.html) guidelines
- Use `gofmt` for formatting
- Use meaningful variable and function names
- Add comments for exported functions and types
- Keep functions small and focused

### Package Organization
```
internal/
├── domain/       # Pure business entities (no external dependencies)
├── repository/   # Data access interfaces and implementations
├── service/      # Business logic (uses repository)
└── handler/      # HTTP handlers (uses service)
```

### Naming Conventions
- Interfaces: `<Entity>Repository`, `<Entity>Service`
- Implementations: Descriptive names like `MemoryUserRepository`
- Tests: `Test<FunctionName>` or `Test<Type>_<Method>`
- Files: `snake_case.go` for files, `PascalCase` for types

## Adding New Features

### Example: Adding a Product Entity

#### Step 1: Create Domain Entity
**File:** `internal/domain/product.go`
```go
package domain

import (
    "errors"
    "time"
)

type Product struct {
    ID          string
    Name        string
    Description string
    Price       float64
    Stock       int
    CreatedAt   time.Time
    UpdatedAt   time.Time
}

func (p *Product) Validate() error {
    if p.Name == "" {
        return errors.New("product name is required")
    }
    if p.Price < 0 {
        return errors.New("price cannot be negative")
    }
    if p.Stock < 0 {
        return errors.New("stock cannot be negative")
    }
    return nil
}
```

#### Step 2: Create Repository Interface
**File:** `internal/repository/product_repository.go`
```go
package repository

import (
    "context"
    "github.com/yourusername/projectname/internal/domain"
)

type ProductRepository interface {
    Create(ctx context.Context, product *domain.Product) error
    GetByID(ctx context.Context, id string) (*domain.Product, error)
    Update(ctx context.Context, product *domain.Product) error
    Delete(ctx context.Context, id string) error
    List(ctx context.Context, limit, offset int) ([]*domain.Product, error)
}
```

#### Step 3: Implement Repository
**File:** `internal/repository/memory/product_repository.go`
```go
package memory

import (
    "context"
    "errors"
    "sync"
    "time"

    "github.com/yourusername/projectname/internal/domain"
)

type ProductRepository struct {
    mu       sync.RWMutex
    products map[string]*domain.Product
}

func NewProductRepository() *ProductRepository {
    return &ProductRepository{
        products: make(map[string]*domain.Product),
    }
}

func (r *ProductRepository) Create(ctx context.Context, product *domain.Product) error {
    r.mu.Lock()
    defer r.mu.Unlock()

    if _, exists := r.products[product.ID]; exists {
        return errors.New("product already exists")
    }

    product.CreatedAt = time.Now()
    product.UpdatedAt = time.Now()
    r.products[product.ID] = product
    return nil
}

func (r *ProductRepository) GetByID(ctx context.Context, id string) (*domain.Product, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()

    product, exists := r.products[id]
    if !exists {
        return nil, errors.New("product not found")
    }
    return product, nil
}

// ... implement other methods
```

#### Step 4: Create Service
**File:** `internal/service/product_service.go`
```go
package service

import (
    "context"
    "github.com/yourusername/projectname/internal/domain"
    "github.com/yourusername/projectname/internal/repository"
)

type ProductService struct {
    repo repository.ProductRepository
}

func NewProductService(repo repository.ProductRepository) *ProductService {
    return &ProductService{repo: repo}
}

func (s *ProductService) CreateProduct(ctx context.Context, product *domain.Product) error {
    if err := product.Validate(); err != nil {
        return err
    }
    return s.repo.Create(ctx, product)
}

func (s *ProductService) GetProduct(ctx context.Context, id string) (*domain.Product, error) {
    return s.repo.GetByID(ctx, id)
}

// ... implement other methods
```

#### Step 5: Create HTTP Handler
**File:** `internal/handler/product_handler.go`
```go
package handler

import (
    "encoding/json"
    "net/http"

    "github.com/yourusername/projectname/internal/domain"
    "github.com/yourusername/projectname/internal/service"
)

type ProductHandler struct {
    service *service.ProductService
}

func NewProductHandler(service *service.ProductService) *ProductHandler {
    return &ProductHandler{service: service}
}

func (h *ProductHandler) CreateProduct(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodPost {
        http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
        return
    }

    var product domain.Product
    if err := json.NewDecoder(r.Body).Decode(&product); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }

    if err := h.service.CreateProduct(r.Context(), &product); err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    w.WriteHeader(http.StatusCreated)
    json.NewEncoder(w).Encode(product)
}

func (h *ProductHandler) GetProduct(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodGet {
        http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
        return
    }

    // Extract ID from URL (you'll need a router for this)
    id := r.URL.Query().Get("id")
    
    product, err := h.service.GetProduct(r.Context(), id)
    if err != nil {
        http.Error(w, err.Error(), http.StatusNotFound)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(product)
}
```

#### Step 6: Wire Everything in Main
**File:** `cmd/api/main.go` (add to existing code)
```go
import (
    // ... existing imports
    "github.com/yourusername/projectname/internal/repository/memory"
    "github.com/yourusername/projectname/internal/service"
    "github.com/yourusername/projectname/internal/handler"
)

func main() {
    // ... existing code

    // Initialize Product components
    productRepo := memory.NewProductRepository()
    productService := service.NewProductService(productRepo)
    productHandler := handler.NewProductHandler(productService)

    // Add routes
    mux := http.NewServeMux()
    mux.HandleFunc("/health", healthCheckHandler)
    mux.HandleFunc("/products", productHandler.CreateProduct)
    mux.HandleFunc("/products/get", productHandler.GetProduct)

    // ... rest of the code
}
```

#### Step 7: Add Tests
**File:** `internal/domain/product_test.go`
```go
package domain

import "testing"

func TestProduct_Validate(t *testing.T) {
    tests := []struct {
        name    string
        product Product
        wantErr bool
    }{
        {
            name: "valid product",
            product: Product{
                Name:  "Test Product",
                Price: 99.99,
                Stock: 10,
            },
            wantErr: false,
        },
        {
            name: "invalid - negative price",
            product: Product{
                Name:  "Test Product",
                Price: -10,
                Stock: 10,
            },
            wantErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := tt.product.Validate()
            if (err != nil) != tt.wantErr {
                t.Errorf("Validate() error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
```

## Testing Guidelines

### Unit Tests
- Test each function independently
- Use table-driven tests
- Mock external dependencies
- Aim for >80% coverage

### Integration Tests
- Place in `tests/` directory
- Test complete workflows
- Use test database/fixtures

### Example Test
```go
func TestUserService_CreateUser(t *testing.T) {
    // Arrange
    repo := memory.NewUserRepository()
    service := NewUserService(repo)
    ctx := context.Background()
    
    user := &domain.User{
        ID:    "1",
        Email: "test@example.com",
        Name:  "Test User",
    }

    // Act
    err := service.CreateUser(ctx, user)

    // Assert
    if err != nil {
        t.Errorf("CreateUser() error = %v", err)
    }
}
```

## Pull Request Process

1. **Create a branch**: `git checkout -b feature/your-feature`
2. **Make changes**: Follow the code style guidelines
3. **Write tests**: Ensure coverage for new code
4. **Run tests**: `make test`
5. **Format code**: `go fmt ./...`
6. **Commit**: Use descriptive commit messages
7. **Push**: `git push origin feature/your-feature`
8. **Create PR**: Submit pull request with description

## Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Build process or auxiliary tool changes

**Example:**
```
feat(user): add email validation

Add email validation to user domain entity.
Includes regex pattern matching and format checks.

Closes #123
```

## Best Practices

### Error Handling
```go
// ✅ Good
func doSomething() error {
    if err := validate(); err != nil {
        return fmt.Errorf("validation failed: %w", err)
    }
    return nil
}

// ❌ Bad
func doSomething() error {
    if err := validate(); err != nil {
        return err // loses context
    }
    return nil
}
```

### Context Usage
```go
// ✅ Good
func (s *Service) GetUser(ctx context.Context, id string) (*User, error) {
    // Check context cancellation
    select {
    case <-ctx.Done():
        return nil, ctx.Err()
    default:
    }
    
    return s.repo.GetByID(ctx, id)
}
```

### Dependency Injection
```go
// ✅ Good - Interface-based
type UserService struct {
    repo repository.UserRepository
}

// ❌ Bad - Concrete implementation
type UserService struct {
    repo *memory.UserRepository
}
```

### Testing
```go
// ✅ Good - Table-driven
func TestValidate(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        wantErr bool
    }{
        {"valid", "test", false},
        {"empty", "", true},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := Validate(tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("got %v, want error: %v", err, tt.wantErr)
            }
        })
    }
}
```

## Getting Help

- Check existing code examples
- Read Go documentation: `go doc <package>`
- Review test files for usage patterns
- Ask questions in issues or discussions
