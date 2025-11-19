package memory

import (
	"context"
	"testing"

	"github.com/yourusername/projectname/internal/domain"
)

func TestUserRepository_Create(t *testing.T) {
	repo := NewUserRepository()
	ctx := context.Background()

	user := &domain.User{
		ID:    "1",
		Email: "test@example.com",
		Name:  "Test User",
	}

	err := repo.Create(ctx, user)
	if err != nil {
		t.Errorf("Create() error = %v", err)
	}

	// Try to create duplicate
	err = repo.Create(ctx, user)
	if err == nil {
		t.Error("Create() should return error for duplicate user")
	}
}

func TestUserRepository_GetByID(t *testing.T) {
	repo := NewUserRepository()
	ctx := context.Background()

	user := &domain.User{
		ID:    "1",
		Email: "test@example.com",
		Name:  "Test User",
	}

	// Create user first
	_ = repo.Create(ctx, user)

	// Get existing user
	retrieved, err := repo.GetByID(ctx, "1")
	if err != nil {
		t.Errorf("GetByID() error = %v", err)
	}
	if retrieved.Email != user.Email {
		t.Errorf("GetByID() got = %v, want %v", retrieved.Email, user.Email)
	}

	// Get non-existing user
	_, err = repo.GetByID(ctx, "999")
	if err == nil {
		t.Error("GetByID() should return error for non-existing user")
	}
}
