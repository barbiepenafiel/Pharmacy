import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const userId = searchParams.get('userId')

    const prescriptions = await prisma.prescription.findMany({
      where: userId ? { userId } : {},
      include: { user: true, orders: true },
    })
    return NextResponse.json(prescriptions)
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch prescriptions' }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { userId, doctorName, medication, dosage, instructions, status } = body

    const prescription = await prisma.prescription.create({
      data: {
        userId,
        doctorName,
        medication,
        dosage,
        instructions,
        status: status || 'pending',
      },
    })
    return NextResponse.json(prescription, { status: 201 })
  } catch (error) {
    return NextResponse.json({ error: 'Failed to create prescription' }, { status: 500 })
  }
}