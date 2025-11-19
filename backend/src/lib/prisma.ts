import { PrismaClient } from '../generated/prisma/client'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

export const prisma = globalForPrisma.prisma ?? new PrismaClient()

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma

// Seed admin user on startup
async function seedAdminUser() {
  try {
    const adminUser = await prisma.user.upsert({
      where: { email: 'admin@pharmacy.com' },
      update: {},
      create: {
        email: 'admin@pharmacy.com',
        password: 'admin123', // In production, hash this
        name: 'Admin User',
        role: 'admin',
      },
    })
    console.log('Admin user ready:', adminUser.email)
  } catch (error) {
    console.error('Error seeding admin user:', error)
  }
}

// Seed sample data
async function seedSampleData() {
  try {
    // Create sample customers
    const customers = [
      { email: 'john@example.com', name: 'John Smith', password: 'pass123' },
      { email: 'jane@example.com', name: 'Jane Doe', password: 'pass123' },
      { email: 'bob@example.com', name: 'Bob Johnson', password: 'pass123' },
      { email: 'alice@example.com', name: 'Alice Brown', password: 'pass123' },
    ]

    const createdCustomers = []
    for (const customer of customers) {
      const user = await prisma.user.upsert({
        where: { email: customer.email },
        update: {},
        create: {
          email: customer.email,
          name: customer.name,
          password: customer.password,
          role: 'customer',
        },
      })
      createdCustomers.push(user)
    }

    // Create sample prescriptions
    const medications = [
      { name: 'Amoxicillin', dosage: '500mg' },
      { name: 'Ibuprofen', dosage: '200mg' },
      { name: 'Metformin', dosage: '1000mg' },
      { name: 'Paracetamol', dosage: '500mg' },
      { name: 'Lisinopril', dosage: '10mg' },
    ]

    for (let i = 0; i < createdCustomers.length; i++) {
      for (let j = 0; j < 3; j++) {
        const medication = medications[j % medications.length]
        await prisma.prescription.create({
          data: {
            userId: createdCustomers[i].id,
            doctorName: 'Dr. Smith',
            medication: medication.name,
            dosage: medication.dosage,
            instructions: 'Take 1 pill twice daily',
            status: j === 0 ? 'completed' : j === 1 ? 'pending' : 'approved',
          },
        })
      }
    }

    // Create sample orders for today
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    const orderStatuses = ['pending', 'shipped', 'delivered', 'cancelled']
    for (let i = 0; i < createdCustomers.length; i++) {
      for (let j = 0; j < 2; j++) {
        const orderDate = new Date(today.getTime() + Math.random() * 24 * 60 * 60 * 1000)
        await prisma.order.create({
          data: {
            userId: createdCustomers[i].id,
            total: Math.floor(Math.random() * 5000) + 1000,
            status: orderStatuses[Math.floor(Math.random() * orderStatuses.length)],
            createdAt: orderDate,
          },
        })
      }
    }

    // Create sample addresses
    for (let i = 0; i < createdCustomers.length; i++) {
      await prisma.address.create({
        data: {
          userId: createdCustomers[i].id,
          street: `${100 + i} Main St`,
          city: 'Manila',
          state: 'NCR',
          zip: '1000',
          country: 'Philippines',
          isDefault: true,
        },
      })
    }

    console.log('Sample data seeded successfully')
  } catch (error) {
    console.error('Error seeding sample data:', error)
  }
}

// Seed inventory data
async function seedInventory() {
  try {
    const inventoryItems = [
      { name: 'Paracetamol', dosage: '500mg', quantity: 120, supplier: 'Pharma Inc.', daysToExpiry: 60, status: 'in_stock' },
      { name: 'Amoxicillin', dosage: '250mg', quantity: 50, supplier: 'MedSupply Co.', daysToExpiry: 240, status: 'in_stock' },
      { name: 'Ibuprofen', dosage: '500mg', quantity: 0, supplier: 'HealthWell', daysToExpiry: 365, status: 'low_stock' },
      { name: 'Loratadine', dosage: '10mg', quantity: 75, supplier: 'HealthWell', daysToExpiry: 7, status: 'expired' },
      { name: 'Metformin', dosage: '1000mg', quantity: 200, supplier: 'GenMeds', daysToExpiry: 150, status: 'in_stock' },
      { name: 'Lisinopril', dosage: '10mg', quantity: 85, supplier: 'CardioPharm', daysToExpiry: 300, status: 'in_stock' },
      { name: 'Atorvastatin', dosage: '20mg', quantity: 40, supplier: 'GenMeds', daysToExpiry: 180, status: 'low_stock' },
      { name: 'Omeprazole', dosage: '20mg', quantity: 150, supplier: 'GastroMeds', daysToExpiry: 120, status: 'in_stock' },
    ]

    for (const item of inventoryItems) {
      const expiryDate = new Date()
      expiryDate.setDate(expiryDate.getDate() + item.daysToExpiry)

      await prisma.inventory.create({
        data: {
          name: item.name,
          dosage: item.dosage,
          quantity: item.quantity,
          supplier: item.supplier,
          expiryDate: expiryDate,
          status: item.status,
        },
      })
    }

    console.log('Inventory seeded successfully')
  } catch (error) {
    console.error('Error seeding inventory:', error)
  }
}

// Seed products
async function seedProducts() {
  try {
    const products = [
      {
        name: 'Paracetamol Tablets',
        description: 'Effective pain and fever relief',
        dosage: '500mg',
        category: 'Pain Relief',
        price: 150.00,
        imageUrl: 'https://images.unsplash.com/photo-1631549387789-4c1017266635?w=400',
        quantity: 120,
        supplier: 'Pharma Inc.',
      },
      {
        name: 'Amoxicillin Capsules',
        description: 'Antibiotic for bacterial infections',
        dosage: '250mg',
        category: 'Antibiotics',
        price: 320.00,
        imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5f400f628?w=400',
        quantity: 80,
        supplier: 'MedSupply Co.',
      },
      {
        name: 'Ibuprofen Tablets',
        description: 'Anti-inflammatory pain reliever',
        dosage: '400mg',
        category: 'Anti-inflammatory',
        price: 200.00,
        imageUrl: 'https://images.unsplash.com/photo-1587854692152-cbe660dbde0f?w=400',
        quantity: 100,
        supplier: 'HealthWell',
      },
      {
        name: 'Metformin Tablets',
        description: 'Diabetes management medication',
        dosage: '500mg',
        category: 'Diabetes',
        price: 280.00,
        imageUrl: 'https://images.unsplash.com/photo-1631549387789-4c1017266635?w=400',
        quantity: 200,
        supplier: 'GenMeds',
      },
      {
        name: 'Loratadine Tablets',
        description: 'Allergy relief antihistamine',
        dosage: '10mg',
        category: 'Allergy',
        price: 180.00,
        imageUrl: 'https://images.unsplash.com/photo-1586082860216-e7e5f0cc1d63?w=400',
        quantity: 150,
        supplier: 'HealthWell',
      },
      {
        name: 'Lisinopril Tablets',
        description: 'Blood pressure control medication',
        dosage: '10mg',
        category: 'Cardiovascular',
        price: 350.00,
        imageUrl: 'https://images.unsplash.com/photo-1631549387789-4c1017266635?w=400',
        quantity: 85,
        supplier: 'CardioPharm',
      },
    ]

    for (const product of products) {
      await prisma.product.create({
        data: product,
      })
    }

    console.log('Products seeded successfully')
  } catch (error) {
    console.error('Error seeding products:', error)
  }
}

// Only seed in development
if (process.env.NODE_ENV !== 'production') {
  ;(async () => {
    await seedAdminUser()
    await seedSampleData()
    await seedInventory()
    await seedProducts()
  })()
}