import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const address = await prisma.address.findUnique({
      where: { id: params.id },
      include: { user: true },
    })
    if (!address) {
      return NextResponse.json({ error: 'Address not found' }, { status: 404 })
    }
    return NextResponse.json(address)
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch address' }, { status: 500 })
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const body = await request.json()
    const { street, city, state, zip, country, isDefault } = body

    const address = await prisma.address.update({
      where: { id: params.id },
      data: {
        street,
        city,
        state,
        zip,
        country,
        isDefault,
      },
    })
    return NextResponse.json(address)
  } catch (error) {
    return NextResponse.json({ error: 'Failed to update address' }, { status: 500 })
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    await prisma.address.delete({
      where: { id: params.id },
    })
    return NextResponse.json({ message: 'Address deleted' })
  } catch (error) {
    return NextResponse.json({ error: 'Failed to delete address' }, { status: 500 })
  }
}