#!/bin/bash
# Deployment Verification Script
# Run this script to verify the application is ready for deployment

echo "================================"
echo "Deployment Verification Script"
echo "================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0

# Helper functions
pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((PASS_COUNT++))
}

fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((FAIL_COUNT++))
}

warn() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
}

echo "1. Checking Node.js and npm..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    pass "Node.js installed: $NODE_VERSION"
else
    fail "Node.js not found"
fi

if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm -v)
    pass "npm installed: $NPM_VERSION"
else
    fail "npm not found"
fi

echo ""
echo "2. Checking dependencies..."
if npm list > /dev/null 2>&1; then
    pass "All npm dependencies installed"
else
    fail "Missing npm dependencies - run 'npm install'"
fi

echo ""
echo "3. Running linting checks..."
if npm run lint > /dev/null 2>&1; then
    pass "ESLint passed - code style is good"
else
    warn "ESLint warnings/errors found - review them"
fi

echo ""
echo "4. Running test suite..."
echo "   (This may take a minute...)"
if npm test > /dev/null 2>&1; then
    TESTS=$(npm test 2>&1 | grep -o "[0-9]* passing" | grep -o "[0-9]*")
    pass "All tests passed: $TESTS tests"
else
    fail "Some tests failed - fix them before deploying"
fi

echo ""
echo "5. Checking code coverage..."
COVERAGE=$(npm test 2>&1 | grep "% Stmts" | awk '{print $2}')
if [[ ! -z "$COVERAGE" ]]; then
    if (( ${COVERAGE%\%} >= 80 )); then
        pass "Code coverage acceptable: $COVERAGE"
    else
        warn "Code coverage below target: $COVERAGE (target: 80%)"
    fi
fi

echo ""
echo "6. Verifying key files exist..."
FILES=("public/index.html" "api/controller.js" "api/routes.js" "server.js" "package.json")
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        pass "File exists: $file"
    else
        fail "File missing: $file"
    fi
done

echo ""
echo "7. Checking for power feature..."
if grep -q "power" api/controller.js 2>/dev/null; then
    pass "Power operation found in controller"
else
    fail "Power operation not found in controller"
fi

if grep -q "\\^" public/index.html 2>/dev/null; then
    pass "Power button found in UI"
else
    fail "Power button not found in UI"
fi

echo ""
echo "8. Git status check..."
if git diff --quiet; then
    pass "Working directory clean - all changes committed"
else
    warn "Uncommitted changes found - commit before deploying"
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "   Current branch: $BRANCH"

echo ""
echo "================================"
echo "Deployment Readiness Report"
echo "================================"
echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
echo -e "${RED}Failed: $FAIL_COUNT${NC}"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ Application is ready for deployment!${NC}"
    exit 0
else
    echo -e "${RED}✗ Application is NOT ready for deployment.${NC}"
    echo "Please fix the failed checks above."
    exit 1
fi
