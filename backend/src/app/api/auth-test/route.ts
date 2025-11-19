import { NextRequest, NextResponse } from 'next/server'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { email, password } = body

    // Hardcoded admin user for testing
    if (email === 'admin@pharmacy.com' && password === 'admin123') {
      return NextResponse.json({
        success: true,
        message: 'Login successful',
        token: 'test-token-admin',
        user: {
          id: '1',
          email: 'admin@pharmacy.com',
          fullName: 'Admin User',
          isAdmin: true,
        },
      })
    }

    // Regular customer
    if (email === 'user@example.com' && password === 'password123') {
      return NextResponse.json({
        success: true,
        message: 'Login successful',
        token: 'test-token-user',
        user: {
          id: '2',
          email: 'user@example.com',
          fullName: 'Regular User',
          isAdmin: false,
        },
      })
    }

    return NextResponse.json({
      success: false,
      message: 'Invalid email or password',
    })
  } catch (error) {
    console.error('Auth error:', error)
    return NextResponse.json(
      {
        success: false,
        message: `Server error: ${error instanceof Error ? error.message : 'Unknown error'}`,
      },
      { status: 500 }
    )
  }
}