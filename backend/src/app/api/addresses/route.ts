import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const userId = searchParams.get('userId')

    const addresses = await prisma.address.findMany({
      where: userId ? { userId } : {},
      include: { user: true },
    })
    return NextResponse.json(addresses)
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch addresses' }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { userId, street, city, state, zip, country, isDefault } = body

    const address = await prisma.address.create({
      data: {
        userId,
        street,
        city,
        state,
        zip,
        country,
        isDefault: isDefault || false,
      },
    })
    return NextResponse.json(address, { status: 201 })
  } catch (error) {
    return NextResponse.json({ error: 'Failed to create address' }, { status: 500 })
  }
}