import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

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
    return NextResponse.json({ error: 'Failed to update product' }, { status: 500 })
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
    return NextResponse.json({ message: 'Product deleted' })
  } catch (error) {
    return NextResponse.json({ error: 'Failed to delete product' }, { status: 500 })
  }
}