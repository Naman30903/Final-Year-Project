# Architecture Overview

## Clean Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                        HTTP Handlers                         │
│                     (internal/handler/)                      │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  UserHandler                                          │  │
│  │  - Receives HTTP requests                            │  │
│  │  - Validates input                                   │  │
│  │  - Calls service layer                               │  │
│  │  - Returns HTTP responses                            │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                        Service Layer                         │
│                     (internal/service/)                      │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  UserService                                          │  │
│  │  - Business logic                                    │  │
│  │  - Domain validation                                 │  │
│  │  - Orchestrates repository calls                     │  │
│  │  - Transaction management                            │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      Repository Layer                        │
│                   (internal/repository/)                     │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  UserRepository (Interface)                           │  │
│  │  - Defines data access contract                      │  │
│  │  - CRUD operations                                   │  │
│  └──────────────────────────────────────────────────────┘  │
│                              ↓                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Implementations:                                     │  │
│  │  - MemoryUserRepository (in-memory)                  │  │
│  │  - PostgresUserRepository (future)                   │  │
│  │  - MongoUserRepository (future)                      │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                        Domain Layer                          │
│                     (internal/domain/)                       │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  User Entity                                          │  │
│  │  - Pure business logic                               │  │
│  │  - No external dependencies                          │  │
│  │  - Validation rules                                  │  │
│  │  - Business invariants                               │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Request Flow

```
HTTP Request
     ↓
┌────────────────┐
│   Handler      │  1. Parses HTTP request
│  (user_handler)│  2. Extracts parameters
└────────────────┘  3. Validates input format
     ↓
┌────────────────┐
│   Service      │  4. Applies business rules
│ (user_service) │  5. Validates domain logic
└────────────────┘  6. Coordinates operations
     ↓
┌────────────────┐
│  Repository    │  7. Data access
│ (user_repo)    │  8. CRUD operations
└────────────────┘  9. Persistence
     ↓
┌────────────────┐
│   Domain       │  10. Entity validation
│   (User)       │  11. Business invariants
└────────────────┘  12. Domain rules
     ↓
HTTP Response
```

## Dependency Flow

```
main.go
  ├─→ Creates Repository (memory/UserRepository)
  ├─→ Injects into Service (UserService)
  ├─→ Injects into Handler (UserHandler)
  └─→ Registers routes

Dependency Rule: Inner layers don't depend on outer layers
✓ Domain ← Repository ← Service ← Handler
✗ Domain → Repository (NOT ALLOWED)
```

## Component Diagram

```
┌──────────────────────────────────────────────────────────┐
│                         cmd/api                          │
│                        main.go                           │
│                                                          │
│  • Initializes components                               │
│  • Wires dependencies                                   │
│  • Starts HTTP server                                   │
│  • Handles graceful shutdown                            │
└──────────────────────────────────────────────────────────┘
                           │
          ┌────────────────┼────────────────┐
          ↓                ↓                ↓
┌──────────────┐  ┌──────────────┐  ┌─────────────┐
│   Handler    │  │   Service    │  │ Repository  │
│              │  │              │  │             │
│ HTTP Layer   │→ │ Business     │→ │ Data        │
│              │  │ Logic        │  │ Access      │
└──────────────┘  └──────────────┘  └─────────────┘
                                             ↓
                                    ┌─────────────┐
                                    │   Domain    │
                                    │             │
                                    │  Entities   │
                                    │  & Rules    │
                                    └─────────────┘
```

## Package Dependencies

```
internal/
├── domain/          (No dependencies)
│   └── user.go
│
├── repository/      (Depends on: domain)
│   ├── user_repository.go
│   └── memory/
│       └── user_repository.go
│
├── service/         (Depends on: domain, repository)
│   └── user_service.go
│
└── handler/         (Depends on: service)
    └── user_handler.go
```

## Data Flow Example

### Creating a User

```
1. HTTP POST /users
   Body: {"email": "user@example.com", "name": "John"}
   │
2. ┌──────────────────────────────────────────────┐
   │ UserHandler.CreateUser()                     │
   │ - Decode JSON body                           │
   │ - Create User struct                         │
   └──────────────────────────────────────────────┘
   │
3. ┌──────────────────────────────────────────────┐
   │ UserService.CreateUser()                     │
   │ - Call user.Validate()                       │
   │ - Check business rules                       │
   └──────────────────────────────────────────────┘
   │
4. ┌──────────────────────────────────────────────┐
   │ User.Validate()                              │
   │ - Check email not empty                      │
   │ - Check name not empty                       │
   └──────────────────────────────────────────────┘
   │
5. ┌──────────────────────────────────────────────┐
   │ UserRepository.Create()                      │
   │ - Check user doesn't exist                   │
   │ - Set timestamps                             │
   │ - Store in database                          │
   └──────────────────────────────────────────────┘
   │
6. HTTP 201 Created
   Body: {"id": "1", "email": "...", "name": "..."}
```

## Advantages of This Architecture

### 1. Testability
```
Each layer can be tested independently:
- Domain: Pure business logic tests
- Repository: Data access tests (can use mock DB)
- Service: Business logic tests (can mock repository)
- Handler: HTTP tests (can mock service)
```

### 2. Maintainability
```
Clear separation of concerns:
- Easy to find code
- Easy to understand flow
- Easy to modify specific layer
```

### 3. Flexibility
```
Easy to swap implementations:
- Memory → PostgreSQL → MongoDB
- Just change repository implementation
- No changes needed in service/handler layers
```

### 4. Scalability
```
Can scale independently:
- Add caching at repository layer
- Add message queue at service layer
- Add load balancer at handler layer
```

## Key Design Patterns

### 1. Repository Pattern
```go
// Interface defines contract
type UserRepository interface {
    Create(ctx context.Context, user *domain.User) error
    GetByID(ctx context.Context, id string) (*domain.User, error)
}

// Multiple implementations possible
type MemoryUserRepository struct { ... }
type PostgresUserRepository struct { ... }
```

### 2. Dependency Injection
```go
// Service depends on interface, not concrete type
type UserService struct {
    repo repository.UserRepository  // Interface, not *MemoryUserRepository
}

// Easy to test with mocks
func TestUserService() {
    mockRepo := &MockUserRepository{}
    service := NewUserService(mockRepo)
    // test service...
}
```

### 3. Clean Architecture
```
• Business logic isolated in domain
• Dependencies point inward
• External concerns (HTTP, DB) at edges
• Core is framework-independent
```

## Extension Points

### Adding New Features

1. **New Entity**: Add to `internal/domain/`
2. **New Repository**: Add interface + implementation
3. **New Service**: Add business logic
4. **New Handler**: Add HTTP endpoints
5. **Wire in main.go**: Connect all components

### Adding New Storage

1. Create new package: `internal/repository/postgres/`
2. Implement interface: `PostgresUserRepository`
3. Update main.go: Use new implementation
4. No other code changes needed!

### Adding New Transport

1. Create new package: `internal/grpc/`
2. Reuse existing service layer
3. Add gRPC handlers
4. Service layer unchanged!

---

This architecture ensures your code is:
- ✅ Testable
- ✅ Maintainable
- ✅ Flexible
- ✅ Scalable
- ✅ Clean
- ✅ Production-ready
