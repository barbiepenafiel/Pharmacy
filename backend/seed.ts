const { prisma } = require('./src/lib/prisma')

async function main() {
  try {
    // Create admin user if it doesn't exist
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

    console.log('Admin user created/updated:', adminUser)

    // Create a regular user for testing
    const regularUser = await prisma.user.upsert({
      where: { email: 'user@example.com' },
      update: {},
      create: {
        email: 'user@example.com',
        password: 'password123',
        name: 'Regular User',
        role: 'customer',
      },
    })

    console.log('Regular user created/updated:', regularUser)

    // Add sample products
    const products = [
      {
        name: 'Paracetamol 500mg',
        description: 'Pain reliever and fever reducer',
        dosage: '500mg',
        category: 'Pain Relief',
        price: 5.99,
        quantity: 100,
        supplier: 'PharmaCorp',
        imageUrl: 'https://cdn-icons-png.flaticon.com/512/3209/3209873.png',
      },
      {
        name: 'Ibuprofen 200mg',
        description: 'Anti-inflammatory pain reliever',
        dosage: '200mg',
        category: 'Pain Relief',
        price: 7.49,
        quantity: 80,
        supplier: 'MediSupply',
        imageUrl: 'https://cdn-icons-png.flaticon.com/512/3209/3209881.png',
      },
      {
        name: 'Multivitamin Complex',
        description: 'Complete daily vitamin supplement',
        dosage: '1 tablet',
        category: 'Vitamins',
        price: 12.99,
        quantity: 150,
        supplier: 'NutritionPlus',
        imageUrl: 'https://cdn-icons-png.flaticon.com/512/3209/3209882.png',
      },
      {
        name: 'Vitamin C 1000mg',
        description: 'Immune system booster',
        dosage: '1000mg',
        category: 'Vitamins',
        price: 9.99,
        quantity: 120,
        supplier: 'HealthCare+',
        imageUrl: 'https://cdn-icons-png.flaticon.com/512/3209/3209883.png',
      },
      {
        name: 'Omega-3 Fish Oil',
        description: 'Heart health supplement',
        dosage: '1000mg',
        category: 'Supplements',
        price: 14.99,
        quantity: 90,
        supplier: 'PharmaCorp',
        imageUrl: 'https://cdn-icons-png.flaticon.com/512/3209/3209884.png',
      },
      {
        name: 'Cough Syrup',
        description: 'Relief from dry and wet cough',
        dosage: '100ml',
        category: 'Cold & Cough',
        price: 6.49,
        quantity: 110,
        supplier: 'MediSupply',
        imageUrl: 'https://cdn-icons-png.flaticon.com/512/3209/3209885.png',
      },
      {
        name: 'Antacid Tablets',
        description: 'Relief from heartburn and acidity',
        dosage: '500mg',
        category: 'Digestive',
        price: 4.99,
        quantity: 200,
        supplier: 'HealthCare+',
        imageUrl: 'https://cdn-icons-png.flaticon.com/512/3209/3209886.png',
      },
      {
        name: 'Allergy Relief Tablets',
        description: 'Non-drowsy allergy relief',
        dosage: '10mg',
        category: 'Allergy',
        price: 8.99,
        quantity: 75,
        supplier: 'PharmaCorp',
        imageUrl: 'https://cdn-icons-png.flaticon.com/512/3209/3209887.png',
      },
      {
        name: 'Protein Powder',
        description: 'Muscle building and recovery support',
        dosage: '500g',
        category: 'Sports Nutrition',
        price: 24.99,
        quantity: 50,
        supplier: 'FitLife',
        imageUrl: 'https://cdn-icons-png.flaticon.com/512/3209/3209888.png',
      },
      {
        name: 'Blood Pressure Monitor',
        description: 'Digital automatic blood pressure monitor',
        dosage: 'N/A',
        category: 'Medical Devices',
        price: 34.99,
        quantity: 30,
        supplier: 'MedTech',
        imageUrl: 'https://cdn-icons-png.flaticon.com/512/3209/3209889.png',
      },
    ]

    // Delete existing products and create fresh
    await prisma.product.deleteMany({})
    console.log('Cleared existing products')
    
    // Create products
    for (const product of products) {
      await prisma.product.create({
        data: product,
      })
      console.log(`Product "${product.name}" created`)
    }

    console.log('✅ All products seeded successfully!')
  } catch (error) {
    console.error('Error seeding database:', error)
  } finally {
    await prisma.$disconnect()
  }
}

main()