import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const prescription = await prisma.prescription.findUnique({
      where: { id: params.id },
      include: { user: true, orders: true },
    })
    if (!prescription) {
      return NextResponse.json({ error: 'Prescription not found' }, { status: 404 })
    }
    return NextResponse.json(prescription)
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch prescription' }, { status: 500 })
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const body = await request.json()
    const { doctorName, medication, dosage, instructions, status } = body

    const prescription = await prisma.prescription.update({
      where: { id: params.id },
      data: {
        doctorName,
        medication,
        dosage,
        instructions,
        status,
      },
    })
    return NextResponse.json(prescription)
  } catch (error) {
    return NextResponse.json({ error: 'Failed to update prescription' }, { status: 500 })
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    await prisma.prescription.delete({
      where: { id: params.id },
    })
    return NextResponse.json({ message: 'Prescription deleted' })
  } catch (error) {
    return NextResponse.json({ error: 'Failed to delete prescription' }, { status: 500 })
  }
}