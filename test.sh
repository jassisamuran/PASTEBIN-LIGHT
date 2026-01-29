#!/bin/bash

# Pastebin-Lite Automated Test Suite
# Tests all requirements from the assignment specification

# Configuration
BASE_URL="${BASE_URL:-http://localhost:3000}"
PASSED=0
FAILED=0
TOTAL=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
  echo ""
  echo "=========================================="
  echo "$1"
  echo "=========================================="
}

print_test() {
  echo ""
  echo -e "${BLUE}Test $TOTAL:${NC} $1"
}

pass() {
  echo -e "${GREEN}✅ PASS${NC} - $1"
  ((PASSED++))
}

fail() {
  echo -e "${RED}❌ FAIL${NC} - $1"
  echo -e "${RED}   Details: $2${NC}"
  ((FAILED++))
}

test_case() {
  ((TOTAL++))
  print_test "$1"
}

# Start testing
print_header "🧪 PASTEBIN-LITE AUTOMATED TEST SUITE"
echo "Testing against: $BASE_URL"
echo "Start time: $(date)"

# ============================================
# SERVICE CHECKS
# ============================================
print_header "�� SERVICE CHECKS"

# Test 1: Health check returns 200 and valid JSON
test_case "Health check returns HTTP 200 and valid JSON"
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/healthz")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
  if echo "$BODY" | jq -e '.ok' > /dev/null 2>&1; then
    pass "Returns 200 with valid JSON: $BODY"
  else
    fail "Invalid JSON response" "Body: $BODY"
  fi
else
  fail "Expected 200, got $HTTP_CODE" "Body: $BODY"
fi

# Test 2: Health check responds quickly
test_case "Health check responds within reasonable timeout"
START_TIME=$(date +%s%N)
curl -s "$BASE_URL/api/healthz" > /dev/null
END_TIME=$(date +%s%N)
DURATION=$(( ($END_TIME - $START_TIME) / 1000000 )) # Convert to milliseconds

if [ $DURATION -lt 5000 ]; then
  pass "Response time: ${DURATION}ms"
else
  fail "Response too slow: ${DURATION}ms" "Should be < 5000ms"
fi

# Test 3: API returns correct Content-Type
test_case "API responses have correct Content-Type header"
CONTENT_TYPE=$(curl -s -I "$BASE_URL/api/healthz" | grep -i "content-type" | tr -d '\r')

if echo "$CONTENT_TYPE" | grep -q "application/json"; then
  pass "Content-Type: $CONTENT_TYPE"
else
  fail "Wrong Content-Type" "Got: $CONTENT_TYPE"
fi

# ============================================
# PASTE CREATION
# ============================================
print_header "📝 PASTE CREATION"

# Test 4: Create paste returns valid id and url
test_case "Creating a paste returns valid id and url"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/pastes" \
  -H "Content-Type: application/json" \
  -d '{"content":"Test paste content"}')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
  PASTE_ID=$(echo "$BODY" | jq -r '.id')
  PASTE_URL=$(echo "$BODY" | jq -r '.url')
  
  if [ -n "$PASTE_ID" ] && [ "$PASTE_ID" != "null" ]; then
    if [ -n "$PASTE_URL" ] && [ "$PASTE_URL" != "null" ]; then
      pass "Created paste - ID: $PASTE_ID, URL: $PASTE_URL"
    else
      fail "Missing url in response" "Body: $BODY"
    fi
  else
    fail "Missing id in response" "Body: $BODY"
  fi
else
  fail "Expected 200/201, got $HTTP_CODE" "Body: $BODY"
fi

# Test 5: URL points to correct path
test_case "Returned URL points to /p/:id on domain"
if echo "$PASTE_URL" | grep -q "/p/$PASTE_ID"; then
  pass "URL format correct: $PASTE_URL"
else
  fail "URL doesn't match /p/:id format" "Got: $PASTE_URL"
fi

# Test 6: Response is valid JSON with 201 status
test_case "Create paste returns 2xx status"
if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
  pass "Status code: $HTTP_CODE"
else
  fail "Expected 2xx, got $HTTP_CODE"
fi

# ============================================
# PASTE RETRIEVAL
# ============================================
print_header "📖 PASTE RETRIEVAL"

# Test 7: Fetch paste via API returns content
test_case "Fetching paste via API returns original content"
sleep 1 # Give server time to process
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/pastes/$PASTE_ID")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
  CONTENT=$(echo "$BODY" | jq -r '.content')
  if [ "$CONTENT" = "Test paste content" ]; then
    pass "Content matches: $CONTENT"
  else
    fail "Content mismatch" "Expected 'Test paste content', got: $CONTENT"
  fi
else
  fail "Expected 200, got $HTTP_CODE" "Body: $BODY"
fi

# Test 8: API response has correct structure
test_case "API response includes all required fields"
REMAINING_VIEWS=$(echo "$BODY" | jq -r '.remaining_views')
EXPIRES_AT=$(echo "$BODY" | jq -r '.expires_at')

if [ -n "$REMAINING_VIEWS" ]; then
  if [ -n "$EXPIRES_AT" ]; then
    pass "Has content, remaining_views, expires_at"
  else
    fail "Missing expires_at field" "Body: $BODY"
  fi
else
  fail "Missing remaining_views field" "Body: $BODY"
fi

# Test 9: View paste HTML returns content
test_case "Viewing /p/:id returns HTML with content"
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/p/$PASTE_ID")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
  if echo "$BODY" | grep -q "Test paste content"; then
    pass "HTML contains paste content"
  else
    fail "HTML doesn't contain content" "Response length: ${#BODY}"
  fi
else
  fail "Expected 200, got $HTTP_CODE"
fi

# Test 10: HTML doesn't execute scripts (XSS protection)
test_case "HTML renders content safely (XSS protection)"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/pastes" \
  -H "Content-Type: application/json" \
  -d '{"content":"<script>alert(1)</script>"}')
XSS_ID=$(echo "$RESPONSE" | jq -r '.id')
sleep 1

HTML=$(curl -s "$BASE_URL/p/$XSS_ID")
if echo "$HTML" | grep -q "&lt;script&gt;" || ! echo "$HTML" | grep -q "<script>alert"; then
  pass "Script tags are escaped or removed"
else
  fail "Potential XSS vulnerability" "Script tags not escaped"
fi

# ============================================
# VIEW LIMITS
# ============================================
print_header "👁️ VIEW LIMITS"

# Test 11: max_views = 1 (first fetch 200, second 404)
test_case "Paste with max_views=1: first fetch succeeds, second fails"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/pastes" \
  -H "Content-Type: application/json" \
  -d '{"content":"Limited to 1 view","max_views":1}')
LIMITED_ID=$(echo "$RESPONSE" | jq -r '.id')
sleep 1

# First fetch should succeed
STATUS1=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/api/pastes/$LIMITED_ID")
sleep 1

# Second fetch should fail
STATUS2=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/api/pastes/$LIMITED_ID")

if [ "$STATUS1" = "200" ] && [ "$STATUS2" = "404" ]; then
  pass "First: 200, Second: 404"
else
  fail "View limit not enforced" "First: $STATUS1, Second: $STATUS2"
fi

# Test 12: max_views = 2 (two succeed, third fails)
test_case "Paste with max_views=2: two fetches succeed, third fails"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/pastes" \
  -H "Content-Type: application/json" \
  -d '{"content":"Limited to 2 views","max_views":2}')
LIMITED2_ID=$(echo "$RESPONSE" | jq -r '.id')
sleep 1

STATUS1=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/api/pastes/$LIMITED2_ID")
sleep 1
STATUS2=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/api/pastes/$LIMITED2_ID")
sleep 1
STATUS3=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/api/pastes/$LIMITED2_ID")

if [ "$STATUS1" = "200" ] && [ "$STATUS2" = "200" ] && [ "$STATUS3" = "404" ]; then
  pass "First: 200, Second: 200, Third: 404"
else
  fail "View limit not enforced" "Got: $STATUS1, $STATUS2, $STATUS3"
fi

# Test 13: remaining_views decrements correctly
test_case "remaining_views field decrements correctly"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/pastes" \
  -H "Content-Type: application/json" \
  -d '{"content":"Check remaining views","max_views":3}')
CHECK_ID=$(echo "$RESPONSE" | jq -r '.id')
sleep 1

RESPONSE1=$(curl -s "$BASE_URL/api/pastes/$CHECK_ID")
REMAINING1=$(echo "$RESPONSE1" | jq -r '.remaining_views')
sleep 1

RESPONSE2=$(curl -s "$BASE_URL/api/pastes/$CHECK_ID")
REMAINING2=$(echo "$RESPONSE2" | jq -r '.remaining_views')

if [ "$REMAINING1" = "2" ] && [ "$REMAINING2" = "1" ]; then
  pass "Correctly decrements: 2 → 1"
else
  fail "remaining_views not decrementing" "Got: $REMAINING1 → $REMAINING2"
fi

# Test 14: No negative remaining_views
test_case "No negative remaining_views values"
if [ "$REMAINING1" -ge 0 ] && [ "$REMAINING2" -ge 0 ]; then
  pass "All values non-negative"
else
  fail "Negative values detected" "Values: $REMAINING1, $REMAINING2"
fi

# ============================================
# TIME-TO-LIVE (TTL)
# ============================================
print_header "⏰ TIME-TO-LIVE (TTL)"

# Test 15: TTL paste available before expiry
test_case "Paste with TTL is available before expiry"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/pastes" \
  -H "Content-Type: application/json" \
  -d '{"content":"Expires in 3600 seconds","ttl_seconds":3600}')
TTL_ID=$(echo "$RESPONSE" | jq -r '.id')
sleep 1

STATUS=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/api/pastes/$TTL_ID")

if [ "$STATUS" = "200" ]; then
  pass "Available before expiry: $STATUS"
else
  fail "Not available before expiry" "Status: $STATUS"
fi

# Test 16: TTL paste returns 404 after expiry (using x-test-now-ms)
test_case "Paste returns 404 after expiry (using x-test-now-ms header)"
FUTURE_TIME=9999999999999 # Far future timestamp

STATUS=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/api/pastes/$TTL_ID" \
  -H "x-test-now-ms: $FUTURE_TIME")

if [ "$STATUS" = "404" ]; then
  pass "Returns 404 after expiry: $STATUS"
else
  fail "Still available after expiry" "Status: $STATUS (expected 404)"
fi

# Test 17: expires_at field is ISO format
test_case "expires_at field is in ISO 8601 format"
RESPONSE=$(curl -s "$BASE_URL/api/pastes" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"content":"Check expiry format","ttl_seconds":60}')
EXPIRY_ID=$(echo "$RESPONSE" | jq -r '.id')
sleep 1

RESPONSE=$(curl -s "$BASE_URL/api/pastes/$EXPIRY_ID")
EXPIRES_AT=$(echo "$RESPONSE" | jq -r '.expires_at')

if echo "$EXPIRES_AT" | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}'; then
  pass "ISO format: $EXPIRES_AT"
else
  fail "Not ISO format" "Got: $EXPIRES_AT"
fi

# ============================================
# COMBINED CONSTRAINTS
# ============================================
print_header "🔗 COMBINED CONSTRAINTS"

# Test 18: Both TTL and max_views - whichever triggers first
test_case "Paste with both constraints becomes unavailable when first triggers"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/pastes" \
  -H "Content-Type: application/json" \
  -d '{"content":"Both constraints","ttl_seconds":3600,"max_views":1}')
COMBINED_ID=$(echo "$RESPONSE" | jq -r '.id')
sleep 1

# First fetch should succeed
STATUS1=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/api/pastes/$COMBINED_ID")

# Second fetch should fail (view limit hit first)
STATUS2=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/api/pastes/$COMBINED_ID")

if [ "$STATUS1" = "200" ] && [ "$STATUS2" = "404" ]; then
  pass "Constraint triggered correctly"
else
  fail "Combined constraints not working" "Got: $STATUS1, $STATUS2"
fi

# ============================================
# ERROR HANDLING
# ============================================
print_header "⚠️ ERROR HANDLING"

# Test 19: Empty content returns 400
test_case "Empty content returns 400 with JSON error"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/pastes" \
  -H "Content-Type: application/json" \
  -d '{"content":""}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "400" ]; then
  if echo "$BODY" | jq -e '.error' > /dev/null 2>&1; then
    pass "Returns 400 with error message"
  else
    fail "400 but no error in JSON" "Body: $BODY"
  fi
else
  fail "Expected 400, got $HTTP_CODE" "Body: $BODY"
fi

# Test 20: Missing content returns 400
test_case "Missing content field returns 400"
STATUS=$(curl -s -w "%{http_code}" -o /dev/null -X POST "$BASE_URL/api/pastes" \
  -H "Content-Type: application/json" \
  -d '{"ttl_seconds":60}')

if [ "$STATUS" = "400" ]; then
  pass "Returns 400 for missing content"
else
  fail "Expected 400, got $STATUS"
fi

# Test 21: Invalid ttl_seconds (negative) returns 400
test_case "Invalid ttl_seconds returns 400"
STATUS=$(curl -s -w "%{http_code}" -o /dev/null -X POST "$BASE_URL/api/pastes" \
  -H "Content-Type: application/json" \
  -d '{"content":"test","ttl_seconds":-1}')

if [ "$STATUS" = "400" ]; then
  pass "Returns 400 for negative ttl_seconds"
else
  fail "Expected 400, got $STATUS"
fi

# Test 22: Invalid ttl_seconds (zero) returns 400
test_case "ttl_seconds=0 returns 400"
STATUS=$(curl -s -w "%{http_code}" -o /dev/null -X POST "$BASE_URL/api/pastes" \
  -H "Content-Type: application/json" \
  -d '{"content":"test","ttl_seconds":0}')

if [ "$STATUS" = "400" ]; then
  pass "Returns 400 for zero ttl_seconds"
else
  fail "Expected 400, got $STATUS"
fi

# Test 23: Invalid max_views returns 400
test_case "Invalid max_views returns 400"
STATUS=$(curl -s -w "%{http_code}" -o /dev/null -X POST "$BASE_URL/api/pastes" \
  -H "Content-Type: application/json" \
  -d '{"content":"test","max_views":0}')

if [ "$STATUS" = "400" ]; then
  pass "Returns 400 for invalid max_views"
else
  fail "Expected 400, got $STATUS"
fi

# Test 24: Non-existent paste returns 404
test_case "Non-existent paste returns 404"
STATUS=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/api/pastes/nonexistent123")

if [ "$STATUS" = "404" ]; then
  pass "Returns 404 for non-existent paste"
else
  fail "Expected 404, got $STATUS"
fi

# Test 25: 404 responses return JSON
test_case "404 responses include JSON error body"
RESPONSE=$(curl -s "$BASE_URL/api/pastes/nonexistent456")

if echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
  pass "404 includes JSON error"
else
  fail "404 doesn't have JSON error" "Body: $RESPONSE"
fi

# Test 26: HTML view of non-existent paste returns 404
test_case "HTML view of non-existent paste returns 404"
STATUS=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/p/nonexistent789")

if [ "$STATUS" = "404" ]; then
  pass "HTML view returns 404"
else
  fail "Expected 404, got $STATUS"
fi

# ============================================
# PERSISTENCE CHECKS
# ============================================
print_header "💾 PERSISTENCE"

# Test 27: Paste survives across requests
test_case "Paste data persists across multiple requests"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/pastes" \
  -H "Content-Type: application/json" \
  -d '{"content":"Persistence test"}')
PERSIST_ID=$(echo "$RESPONSE" | jq -r '.id')
sleep 2

# Fetch multiple times
CONTENT1=$(curl -s "$BASE_URL/api/pastes/$PERSIST_ID" | jq -r '.content')
sleep 1
CONTENT2=$(curl -s "$BASE_URL/api/pastes/$PERSIST_ID" | jq -r '.content')

if [ "$CONTENT1" = "Persistence test" ] && [ "$CONTENT2" = "Persistence test" ]; then
  pass "Data persists correctly"
else
  fail "Data not persisting" "Got: $CONTENT1, $CONTENT2"
fi

# ============================================
# ROBUSTNESS
# ============================================
print_header "🛡️ ROBUSTNESS"

# Test 28: Concurrent requests don't break view limits
test_case "Paste handles concurrent requests correctly"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/pastes" \
  -H "Content-Type: application/json" \
  -d '{"content":"Concurrent test","max_views":5}')
CONCURRENT_ID=$(echo "$RESPONSE" | jq -r '.id')
sleep 1

# Make 3 concurrent requests
curl -s "$BASE_URL/api/pastes/$CONCURRENT_ID" > /dev/null &
curl -s "$BASE_URL/api/pastes/$CONCURRENT_ID" > /dev/null &
curl -s "$BASE_URL/api/pastes/$CONCURRENT_ID" > /dev/null &
wait
sleep 1

RESPONSE=$(curl -s "$BASE_URL/api/pastes/$CONCURRENT_ID")
REMAINING=$(echo "$RESPONSE" | jq -r '.remaining_views')

if [ "$REMAINING" -ge 0 ] && [ "$REMAINING" -le 5 ]; then
  pass "Remaining views: $REMAINING (within valid range)"
else
  fail "Invalid remaining views after concurrent requests" "Got: $REMAINING"
fi

# ============================================
# FINAL REPORT
# ============================================
print_header "📊 TEST RESULTS"

echo ""
echo "Total Tests:  $TOTAL"
echo -e "${GREEN}Passed:       $PASSED${NC}"
echo -e "${RED}Failed:       $FAILED${NC}"
echo ""

PERCENTAGE=$((PASSED * 100 / TOTAL))
echo "Success Rate: $PERCENTAGE%"
echo ""

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}🎉 ALL TESTS PASSED! 🎉${NC}"
  echo "Your application meets all requirements!"
  exit 0
else
  echo -e "${RED}❌ SOME TESTS FAILED${NC}"
  echo "Please review the failures above and fix them."
  exit 1
fi
