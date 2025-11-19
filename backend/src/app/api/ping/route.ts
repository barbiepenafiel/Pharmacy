import { NextResponse } from 'next/server'

export async function GET() {
  try {
    return NextResponse.json({
      status: 'ok',
      message: 'Backend is running',
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV,
    })
  } catch (error) {
    return NextResponse.json(
      { status: 'error', message: 'Backend error' },
      { status: 500 }
    )
  }
}