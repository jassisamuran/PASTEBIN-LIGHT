# Pastebin Lite

A lightweight pastebin application that allows users to create and share text snippets with optional expiry times and view limits.

## 🚀 Live Demo

https://pastebinlight1.vercel.app

## 📋 Project Description

Pastebin Lite is a modern web application built with Next.js that enables users to:

- Create text pastes and receive shareable URLs
- Set optional time-based expiry (TTL) on pastes
- Set optional view count limits on pastes
- View pastes through clean, responsive web interfaces
- Automatic paste expiration when constraints are triggered

## 🛠️ Technology Stack

- **Framework**: Next.js 14 (App Router)
- **Language**: JavaScript (ES6+)
- **Persistence**: Vercel KV (Redis)
- **Deployment**: Vercel
- **Runtime**: Node.js 18+

## 💾 Persistence Layer

This application uses **Vercel KV** (Redis) for data persistence.

### Why Vercel KV?

1. **Serverless-compatible**: Designed specifically for serverless Next.js applications on Vercel
2. **Low latency**: Built on Upstash Redis with sub-millisecond read/write operations
3. **Native TTL support**: Redis provides built-in automatic key expiration
4. **Atomic operations**: Ensures thread-safe view count increments
5. **Free tier**: Generous free tier suitable for this application
6. **No manual setup**: Seamlessly integrates with Vercel deployment

### Data Structure

Each paste is stored as a Redis key-value pair:

**Key format:** `paste:{id}`

**Value structure:**

```javascript
{
  content: string,        // The paste text content
  createdAt: number,      // Timestamp in milliseconds
  viewCount: number,      // Current number of views
  maxViews?: number       // Optional maximum view count
}
```

## 🏃‍♂️ Running Locally

### Prerequisites

- Node.js 18 or higher
- npm or yarn
- Vercel account (for KV database access)

### Installation Steps

1. **Clone the repository:**

```bash
git clone https://github.com/YOUR_USERNAME/pastebin-lite.git
cd pastebin-lite
```

2. **Install dependencies:**

```bash
npm install
```

3. **Set up Vercel KV database:**

Install Vercel CLI:

```bash
npm install -g vercel
```

Login to Vercel:

```bash
vercel login
```

Link your project:

```bash
vercel link
```

Create a KV database:

- Go to https://vercel.com/dashboard
- Navigate to your project
- Click "Storage" tab
- Click "Create Database" → Select "KV"
- Connect it to your project

Pull environment variables:

```bash
vercel env pull .env.local
```

4. **Add base URL to `.env.local`:**

```bash
echo "NEXT_PUBLIC_BASE_URL=http://localhost:3000" >> .env.local
```

5. **Run the development server:**

```bash
npm run dev
```

6. **Open your browser:**
   Visit http://localhost:3000

## 🚀 Deployment

### Deploy to Vercel

1. **Push code to GitHub:**

```bash
git add .
git commit -m "Initial commit"
git push origin main
```

2. **Deploy via Vercel:**

```bash
vercel --prod
```

Or use the Vercel Dashboard:

- Go to https://vercel.com/new
- Import your GitHub repository
- Vercel auto-detects Next.js configuration
- Click "Deploy"

3. **Configure environment variables:**

- Create KV database in Vercel Dashboard
- Connect it to your project
- Set `NEXT_PUBLIC_BASE_URL` to your production URL
- Redeploy

## 🔌 API Documentation

### Health Check

```http
GET /api/healthz
```

**Response:**

```json
{
  "ok": true
}
```

### Create Paste

```http
POST /api/pastes
Content-Type: application/json
```

**Request Body:**

```json
{
  "content": "Your paste content here",
  "ttl_seconds": 60, // Optional: expires after 60 seconds
  "max_views": 5 // Optional: expires after 5 views
}
```

**Response (201):**

```json
{
  "id": "abc123xy",
  "url": "https://your-app.vercel.app/p/abc123xy"
}
```

**Error Response (400):**

```json
{
  "error": "Content is required"
}
```

### Fetch Paste (API)

```http
GET /api/pastes/:id
```

**Response (200):**

```json
{
  "content": "Your paste content here",
  "remaining_views": 4,
  "expires_at": "2026-01-30T12:00:00.000Z"
}
```

**Notes:**

- `remaining_views` is `null` if no view limit is set
- `expires_at` is `null` if no TTL is set
- Each successful API fetch increments the view count

**Error Response (404):**

```json
{
  "error": "Paste not found"
}
```

### View Paste (HTML)

```http
GET /p/:id
```

Returns an HTML page displaying the paste content.

**Note:** Viewing the HTML page does NOT increment the view count. Only API fetches count as views.

## 🎨 Design Decisions

### 1. View Counting Strategy

**Decision:** Only API fetches (`GET /api/pastes/:id`) increment the view count, not HTML page views (`GET /p/:id`).

**Rationale:**

- Follows the specification exactly: "Each successful API fetch counts as a view"
- Prevents double-counting when users view a paste
- Allows users to refresh the page without consuming views
- API remains the source of truth for view counting

### 2. Dual-Layer Expiry System

**Decision:** Implemented both application-level and Redis-level TTL.

**Implementation:**

- Application checks expiry time on every request
- Redis TTL is set to `ttl_seconds + 60` (with 60-second buffer)
- Application enforces exact expiry time
- Redis automatically cleans up expired keys after buffer period

**Rationale:**

- Ensures precise expiry time as specified by user
- Redis TTL provides automatic cleanup to prevent data accumulation
- Buffer prevents edge cases where paste might be accessed during cleanup

### 3. Stateless Architecture

**Decision:** No server-side sessions or global mutable state.

**Rationale:**

- Perfect for serverless deployment on Vercel
- Horizontally scalable without coordination
- Each request is independent
- Survives across serverless function cold starts

### 4. TEST_MODE Support

**Decision:** Implemented deterministic time testing via `x-test-now-ms` header.

**Implementation:**

```javascript
if (process.env.TEST_MODE === "1" && headers.get("x-test-now-ms")) {
  currentTime = parseInt(headers.get("x-test-now-ms"));
}
```

**Rationale:**

- Allows automated testing of TTL functionality
- No need to wait for actual time to pass in tests
- Meets specification requirement exactly

### 5. Atomic Operations

**Decision:** Use Redis atomic operations for view counting.

**Rationale:**

- Prevents race conditions under concurrent access
- Ensures accurate view counts
- No over-counting or under-counting
- Critical for view limit enforcement

### 6. ID Generation

**Decision:** Use `nanoid` library with 8-character IDs.

**Rationale:**

- URL-safe characters only
- 8 characters provides ~207 billion unique combinations
- Collision probability is negligible
- Shorter and cleaner than UUIDs

### 7. Error Handling

**Decision:** Consistent 404 responses for all unavailable paste scenarios.

**Rationale:**

- Follows specification requirement
- Doesn't leak information about whether paste existed
- Consistent user experience
- Matches HTTP semantics (resource not found)

### 8. XSS Protection

**Decision:** Content is safely rendered without script execution.

**Implementation:**

- React automatically escapes content in JSX
- Server-side rendering uses safe string interpolation
- No `dangerouslySetInnerHTML` used

**Rationale:**

- Security-first approach
- Prevents malicious paste content from executing
- Meets specification requirement

## 🧪 Testing

### Run Automated Tests

```bash
# Test local development
./test.sh

# Test production deployment
BASE_URL=https://your-app.vercel.app ./test.sh
```

### Manual Testing Examples

**Create a paste:**

```bash
curl -X POST http://localhost:3000/api/pastes \
  -H "Content-Type: application/json" \
  -d '{"content":"Hello World","ttl_seconds":60,"max_views":5}'
```

**Fetch a paste:**

```bash
curl http://localhost:3000/api/pastes/abc123xy
```

**Test TTL expiry:**

```bash
# Set TEST_MODE=1 in .env.local first
curl http://localhost:3000/api/pastes/abc123xy \
  -H "x-test-now-ms: 9999999999999"
```

## 📁 Project Structure

```
pastebin-lite/
├── app/
│   ├── api/
│   │   ├── healthz/
│   │   │   └── route.js          # Health check endpoint
│   │   └── pastes/
│   │       ├── route.js           # POST: Create paste
│   │       └── [id]/
│   │           └── route.js       # GET: Fetch paste by ID
│   ├── p/
│   │   └── [id]/
│   │       ├── page.js            # View paste HTML page
│   │       └── not-found.js       # 404 error page
│   ├── layout.js                  # Root layout
│   └── page.js                    # Home page with create form
├── lib/
│   └── paste.js                   # Business logic and utilities
├── .env.example                   # Environment variables template
├── .gitignore                     # Git ignore rules
├── middleware.js                  # Next.js middleware for headers
├── next.config.js                 # Next.js configuration
├── package.json                   # Dependencies
├── README.md                      # This file
└── test.sh                        # Automated test suite
```

## 🔐 Environment Variables

| Variable                      | Description                       | Required | Example                       |
| ----------------------------- | --------------------------------- | -------- | ----------------------------- |
| `KV_REST_API_URL`             | Vercel KV API endpoint            | Yes      | `https://xxx.upstash.io`      |
| `KV_REST_API_TOKEN`           | Vercel KV API token               | Yes      | Auto-set by Vercel            |
| `KV_REST_API_READ_ONLY_TOKEN` | Read-only token                   | Yes      | Auto-set by Vercel            |
| `NEXT_PUBLIC_BASE_URL`        | Base URL for paste links          | Yes      | `https://your-app.vercel.app` |
| `TEST_MODE`                   | Enable deterministic time testing | No       | `0` or `1`                    |

## 🐛 Troubleshooting

### Health check returns `{"ok": false}`

**Cause:** Cannot connect to KV database

**Solution:**

1. Verify KV database is created and connected in Vercel
2. Check environment variables are set correctly
3. Redeploy the application

### Pastes not persisting

**Cause:** KV environment variables not configured

**Solution:**

1. Run `vercel env pull .env.local` for local development
2. Ensure KV database is connected in Vercel Dashboard for production
3. Verify all three KV environment variables exist

### URL shows "localhost" in production

**Cause:** `NEXT_PUBLIC_BASE_URL` not set correctly

**Solution:**

1. Set `NEXT_PUBLIC_BASE_URL` to your actual Vercel URL
2. Redeploy the application

## 📄 License

MIT

## 👤 Author

Jaspreet Singh
