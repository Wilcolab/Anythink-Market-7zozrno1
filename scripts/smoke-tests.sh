#!/bin/bash
# Smoke Tests for Calculator Application
# Run after deployment to verify basic functionality

echo "================================"
echo "Calculator Smoke Tests"
echo "================================"
echo ""

# Configuration
API_URL="${1:-http://localhost:3000}"
PASS=0
FAIL=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

test_api() {
    local operation=$1
    local operand1=$2
    local operand2=$3
    local expected=$4
    local description=$5
    
    echo -n "Testing $description... "
    
    response=$(curl -s "$API_URL/arithmetic?operation=$operation&operand1=$operand1&operand2=$operand2")
    result=$(echo $response | grep -o '"result":[^}]*' | cut -d: -f2)
    
    if [ "$result" == "$expected" ]; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo "  Expected: $expected, Got: $result"
        ((FAIL++))
    fi
}

echo "API Endpoint Tests:"
echo "==================="

# Power Operation Tests
echo ""
echo "Power Operation Tests:"
test_api "power" "2" "3" "8" "2^3 = 8"
test_api "power" "5" "0" "1" "5^0 = 1 (zero exponent)"
test_api "power" "2" "-2" "0.25" "2^-2 = 0.25 (negative exponent)"
test_api "power" "4" "0.5" "2" "4^0.5 = 2 (square root)"
test_api "power" "10" "2" "100" "10^2 = 100"

# Regression Tests (verify existing operations still work)
echo ""
echo "Regression Tests (Existing Operations):"
test_api "add" "5" "3" "8" "5 + 3 = 8"
test_api "subtract" "10" "3" "7" "10 - 3 = 7"
test_api "multiply" "4" "5" "20" "4 × 5 = 20"
test_api "divide" "20" "4" "5" "20 ÷ 4 = 5"

# Error Handling Tests
echo ""
echo "Error Handling Tests:"
echo -n "Testing missing operation... "
response=$(curl -s "$API_URL/arithmetic?operand1=5&operand2=3")
if echo $response | grep -q "error"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASS++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAIL++))
fi

echo -n "Testing invalid operation... "
response=$(curl -s "$API_URL/arithmetic?operation=invalid&operand1=5&operand2=3")
if echo $response | grep -q "Invalid operation"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASS++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAIL++))
fi

# Performance Tests
echo ""
echo "Performance Tests:"
echo -n "Testing API response time... "
start=$(date +%s%N | cut -b1-13)
curl -s "$API_URL/arithmetic?operation=power&operand1=2&operand2=3" > /dev/null
end=$(date +%s%N | cut -b1-13)
response_time=$((end - start))

if [ $response_time -lt 1000 ]; then
    echo -e "${GREEN}✓ PASS${NC} (${response_time}ms)"
    ((PASS++))
else
    echo -e "${RED}✗ FAIL${NC} (${response_time}ms - too slow)"
    ((FAIL++))
fi

# UI Tests
echo ""
echo "UI Tests:"
echo -n "Testing UI loads... "
response=$(curl -s "$API_URL/")
if echo $response | grep -q "calculator"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASS++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAIL++))
fi

echo -n "Testing power button exists in UI... "
response=$(curl -s "$API_URL/")
if echo $response | grep -q "\\^"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASS++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAIL++))
fi

# Summary
echo ""
echo "================================"
echo "Test Results"
echo "================================"
echo -e "${GREEN}Passed: $PASS${NC}"
echo -e "${RED}Failed: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ All smoke tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed.${NC}"
    exit 1
fi
