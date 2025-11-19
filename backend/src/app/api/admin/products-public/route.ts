import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET() {
  try {
    const prescriptions = await prisma.prescription.findMany({
      include: {
        user: {
          select: { name: true }
        }
      },
    })
    // Return prescriptions as products for the admin dashboard
    return NextResponse.json(prescriptions)
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch products' }, { status: 500 })
  }
}