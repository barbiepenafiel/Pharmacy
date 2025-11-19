import Link from 'next/link'

export default function Home() {
  return (
    <div className="min-h-screen bg-gray-100 flex items-center justify-center">
      <div className="max-w-md mx-auto bg-white rounded-xl shadow-md overflow-hidden">
        <div className="p-8">
          <div className="uppercase tracking-wide text-sm text-indigo-500 font-semibold">Pharmacy Management System</div>
          <h1 className="block mt-1 text-lg leading-tight font-medium text-black">Backend & Admin Dashboard</h1>
          <p className="mt-2 text-gray-500">
            Manage users, orders, prescriptions, payment methods, and addresses.
          </p>
          <div className="mt-4">
            <Link href="/admin" className="bg-indigo-600 text-white px-4 py-2 rounded hover:bg-indigo-700">
              Go to Admin Dashboard
            </Link>
          </div>
        </div>
      </div>
    </div>
  )
}
