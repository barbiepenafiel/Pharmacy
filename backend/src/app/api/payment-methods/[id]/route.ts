import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const paymentMethod = await prisma.paymentMethod.findUnique({
      where: { id: params.id },
      include: { user: true },
    })
    if (!paymentMethod) {
      return NextResponse.json({ error: 'Payment method not found' }, { status: 404 })
    }
    return NextResponse.json(paymentMethod)
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch payment method' }, { status: 500 })
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const body = await request.json()
    const { type, details } = body

    const paymentMethod = await prisma.paymentMethod.update({
      where: { id: params.id },
      data: {
        type,
        details,
      },
    })
    return NextResponse.json(paymentMethod)
  } catch (error) {
    return NextResponse.json({ error: 'Failed to update payment method' }, { status: 500 })
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    await prisma.paymentMethod.delete({
      where: { id: params.id },
    })
    return NextResponse.json({ message: 'Payment method deleted' })
  } catch (error) {
    return NextResponse.json({ error: 'Failed to delete payment method' }, { status: 500 })
  }
}