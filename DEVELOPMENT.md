# FoodLoop Development Guide

## Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ for testing
- Git for version control

### First Time Setup
```bash
# Clone and navigate to project
cd /Users/litsungju/Documents/FoodLoop

# Open project in Xcode
open FoodLoop.xcodeproj
```

## Daily Development Workflow

### 1. Before Starting Work
```bash
# Check current status
git status

# Pull latest changes (when working with team)
git pull origin main

# Create feature branch for new work
git checkout -b feature/your-feature-name
```

### 2. During Development
```bash
# Check what files changed
git status

# See specific changes
git diff

# Stage files for commit
git add .

# Or stage specific files
git add FoodLoop/HomeView.swift
```

### 3. Making Commits
Use meaningful commit messages with these prefixes:
- `feat:` - New features
- `fix:` - Bug fixes
- `refactor:` - Code improvements without new features
- `docs:` - Documentation changes
- `style:` - Code formatting, no logic changes
- `test:` - Adding or updating tests

```bash
# Good commit example
git commit -m "feat: Add food expiry date filter in ExploreView

- Allow users to filter by expiry date ranges
- Add date picker UI component
- Update FoodRepository to support date filtering"

# Quick commit for small changes
git commit -m "fix: Correct typo in HomeView welcome message"
```

### 4. Updating Changelog
Before each commit, update `CHANGELOG.md`:
```markdown
## [Unreleased]

### Added
- Food expiry date filter in ExploreView

### Fixed
- Typo in HomeView welcome message
```

## Git Best Practices

### Useful Git Commands
```bash
# See commit history
git log --oneline -10

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Discard all changes (careful!)
git restore .

# Check differences between versions
git diff HEAD~1 HEAD
```

### Branch Management
```bash
# Switch to main branch
git checkout main

# Create and switch to new branch
git checkout -b feature/new-feature

# Delete branch after merging
git branch -d feature/old-feature
```

## iOS Development Workflow

### Building and Testing
```bash
# Build project from command line
xcodebuild -project FoodLoop.xcodeproj -scheme FoodLoop build

# Run tests
xcodebuild test -project FoodLoop.xcodeproj -scheme FoodLoop -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Code Organization
- Keep related functionality in the same file
- Use meaningful variable and function names
- Add comments for complex logic only
- Follow existing code style in the project

## Troubleshooting

### Common Issues
1. **Build Fails**: Clean build folder in Xcode (⇧⌘K)
2. **Git Conflicts**: Use `git status` to see conflicted files
3. **Simulator Issues**: Reset simulator (Device > Erase All Content and Settings)

### Getting Help
- Check `CLAUDE.md` for project-specific guidance
- Use Xcode's built-in documentation (Option+Click on code)
- iOS documentation: https://developer.apple.com/documentation/

## Version Management

### Semantic Versioning
- **1.0.0**: Major release (breaking changes)
- **0.1.0**: Minor release (new features)
- **0.0.1**: Patch release (bug fixes)

### Release Process
1. Update version in Xcode project settings
2. Update `CHANGELOG.md` with release date
3. Create git tag: `git tag v1.0.0`
4. Commit and push changes