import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function PUT(
  request: NextRequest,
  { params }: { params: { userId: string } }
) {
  try {
    const body = await request.json()
    const { email, name, role } = body

    const user = await prisma.user.update({
      where: { id: params.userId },
      data: {
        email,
        name,
        role,
      },
    })
    return NextResponse.json(user)
  } catch (error) {
    return NextResponse.json({ error: 'Failed to update user' }, { status: 500 })
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: { userId: string } }
) {
  try {
    await prisma.user.delete({
      where: { id: params.userId },
    })
    return NextResponse.json({ message: 'User deleted' })
  } catch (error) {
    return NextResponse.json({ error: 'Failed to delete user' }, { status: 500 })
  }
}