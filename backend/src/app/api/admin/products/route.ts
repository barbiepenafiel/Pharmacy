import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET() {
  try {
    const prescriptions = await prisma.prescription.findMany({
      include: { user: true },
    })
    return NextResponse.json(prescriptions)
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch products' }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { userId, doctorName, medication, dosage, instructions } = body

    const prescription = await prisma.prescription.create({
      data: {
        userId,
        doctorName,
        medication,
        dosage,
        instructions,
      },
    })
    return NextResponse.json(prescription, { status: 201 })
  } catch (error) {
    return NextResponse.json({ error: 'Failed to create product' }, { status: 500 })
  }
}