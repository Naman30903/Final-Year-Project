#!/bin/bash

# Script to reorganize repository structure
# This moves .git from backend/ to parent directory

echo "🔄 Reorganizing repository structure..."
echo "Current structure: backend/ contains .git"
echo "Target structure: root contains .git, with backend/ and frontend/ subdirectories"
echo ""

# Get current directory
BACKEND_DIR="/Users/namanjain.3009/Documents/Final_year_project/backend"
PARENT_DIR="/Users/namanjain.3009/Documents/Final_year_project"

cd "$BACKEND_DIR" || exit 1

echo "Step 1: Checking git status..."
git status

echo ""
read -p "⚠️  This will move .git directory to parent folder. Continue? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Operation cancelled"
    exit 1
fi

echo ""
echo "Step 2: Moving .git directory to parent..."
mv .git "$PARENT_DIR/"

echo ""
echo "Step 3: Updating git structure..."
cd "$PARENT_DIR" || exit 1

# Add all backend files
git add backend/

echo ""
echo "✅ Repository reorganized successfully!"
echo ""
echo "📂 New structure:"
echo "   Final_year_project/"
echo "   ├── .git/"
echo "   ├── backend/     (all your Go files)"
echo "   └── frontend/    (to be created)"
echo ""
echo "🎯 Next steps:"
echo "   1. Create frontend folder: mkdir frontend"
echo "   2. Check status: git status"
echo "   3. Commit changes: git commit -m 'Reorganize: Move backend to subfolder'"
echo "   4. Push to GitHub: git push origin main"
