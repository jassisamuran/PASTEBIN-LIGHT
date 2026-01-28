import { NextResponse } from 'next/server';

export function middleware(request) {
  // For API routes, ensure JSON content-type
  if (request.nextUrl.pathname.startsWith('/api/')) {
    const response = NextResponse.next();
    response.headers.set('Content-Type', 'application/json');
    return response;
  }
  
  return NextResponse.next();
}

export const config = {
  matcher: '/api/:path*',
};
