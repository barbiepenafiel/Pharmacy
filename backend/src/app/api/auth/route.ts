import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function POST(request: NextRequest) {
  try {
    const contentType = request.headers.get('content-type')
    if (!contentType || !contentType.includes('application/json')) {
      return NextResponse.json(
        { success: false, message: 'Content-Type must be application/json' },
        { status: 400 }
      )
    }

    const body = await request.json()
    const { action, email, password, fullName } = body

    if (!action) {
      return NextResponse.json(
        { success: false, message: 'Action is required' },
        { status: 400 }
      )
    }

    if (action === 'login') {
      if (!email || !password) {
        return NextResponse.json({
          success: false,
          message: 'Email and password are required',
        })
      }

      // Find user by email
      const user = await prisma.user.findUnique({
        where: { email },
      })

      if (!user) {
        return NextResponse.json({
          success: false,
          message: 'Invalid email or password',
        })
      }

      // For now, simple password check (in production, use bcrypt)
      if (user.password !== password) {
        return NextResponse.json({
          success: false,
          message: 'Invalid email or password',
        })
      }

      return NextResponse.json({
        success: true,
        message: 'Login successful',
        token: 'dummy-token-' + user.id,
        user: {
          id: user.id,
          email: user.email,
          fullName: user.name,
          isAdmin: user.role === 'admin',
        },
      })
    }

    if (action === 'register') {
      if (!fullName || !email || !password) {
        return NextResponse.json({
          success: false,
          message: 'All fields are required',
        })
      }

      // Check if user already exists
      const existingUser = await prisma.user.findUnique({
        where: { email },
      })

      if (existingUser) {
        return NextResponse.json({
          success: false,
          message: 'User with this email already exists',
        })
      }

      // Create new user
      const user = await prisma.user.create({
        data: {
          name: fullName,
          email,
          password,
          role: 'customer',
        },
      })

      return NextResponse.json({
        success: true,
        message: 'Registration successful. Please login.',
        user: {
          id: user.id,
          email: user.email,
          fullName: user.name,
          isAdmin: false,
        },
      })
    }

    return NextResponse.json({
      success: false,
      message: 'Invalid action',
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