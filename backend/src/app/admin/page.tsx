'use client'

import { useState, useEffect } from 'react'

type User = {
  id: string
  email: string
  name: string
  role: string
  createdAt: string
}

type Address = {
  id: string
  street: string
  city: string
  state: string
  zip: string
  country: string
  isDefault: boolean
  user: { name: string }
}

type PaymentMethod = {
  id: string
  type: string
  details: string
  user: { name: string }
}

type Prescription = {
  id: string
  doctorName: string
  medication: string
  dosage: string
  status: string
  user: { name: string }
}

type Order = {
  id: string
  total: number
  status: string
  user: { name: string }
  prescription?: { medication: string }
}

export default function AdminDashboard() {
  const [activeTab, setActiveTab] = useState('users')
  const [users, setUsers] = useState<User[]>([])
  const [addresses, setAddresses] = useState<Address[]>([])
  const [paymentMethods, setPaymentMethods] = useState<PaymentMethod[]>([])
  const [prescriptions, setPrescriptions] = useState<Prescription[]>([])
  const [orders, setOrders] = useState<Order[]>([])

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    try {
      const [usersRes, addressesRes, paymentsRes, prescriptionsRes, ordersRes] = await Promise.all([
        fetch('/api/users'),
        fetch('/api/addresses'),
        fetch('/api/payment-methods'),
        fetch('/api/prescriptions'),
        fetch('/api/orders'),
      ])
      setUsers(await usersRes.json())
      setAddresses(await addressesRes.json())
      setPaymentMethods(await paymentsRes.json())
      setPrescriptions(await prescriptionsRes.json())
      setOrders(await ordersRes.json())
    } catch (error) {
      console.error('Failed to fetch data', error)
    }
  }

  const deleteItem = async (endpoint: string, id: string) => {
    if (confirm('Are you sure?')) {
      await fetch(`/api/${endpoint}/${id}`, { method: 'DELETE' })
      fetchData()
    }
  }

  return (
    <div className="min-h-screen bg-gray-100">
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
          <h1 className="text-3xl font-bold text-gray-900">Pharmacy Admin Dashboard</h1>
        </div>
      </header>
      <nav className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex space-x-8">
            {['users', 'addresses', 'payment-methods', 'prescriptions', 'orders'].map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`py-4 px-1 border-b-2 font-medium text-sm ${
                  activeTab === tab
                    ? 'border-indigo-500 text-indigo-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                {tab.replace('-', ' ').toUpperCase()}
              </button>
            ))}
          </div>
        </div>
      </nav>
      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        {activeTab === 'users' && <UsersTable users={users} onDelete={(id) => deleteItem('users', id)} onRefresh={fetchData} />}
        {activeTab === 'addresses' && <AddressesTable addresses={addresses} onDelete={(id) => deleteItem('addresses', id)} onRefresh={fetchData} />}
        {activeTab === 'payment-methods' && <PaymentMethodsTable paymentMethods={paymentMethods} onDelete={(id) => deleteItem('payment-methods', id)} onRefresh={fetchData} />}
        {activeTab === 'prescriptions' && <PrescriptionsTable prescriptions={prescriptions} onDelete={(id) => deleteItem('prescriptions', id)} onRefresh={fetchData} />}
        {activeTab === 'orders' && <OrdersTable orders={orders} onDelete={(id) => deleteItem('orders', id)} onRefresh={fetchData} />}
      </main>
    </div>
  )
}

function UsersTable({ users, onDelete, onRefresh }: { users: User[], onDelete: (id: string) => void, onRefresh: () => void }) {
  return (
    <div className="px-4 py-6 sm:px-0">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-2xl font-bold">Users</h2>
        <button className="bg-indigo-600 text-white px-4 py-2 rounded">Add User</button>
      </div>
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-50">
          <tr>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Role</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {users.map((user) => (
            <tr key={user.id}>
              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{user.name}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{user.email}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{user.role}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                <button className="text-indigo-600 hover:text-indigo-900 mr-2">Edit</button>
                <button onClick={() => onDelete(user.id)} className="text-red-600 hover:text-red-900">Delete</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

// Similar components for other tables
function AddressesTable({ addresses, onDelete, onRefresh }: { addresses: Address[], onDelete: (id: string) => void, onRefresh: () => void }) {
  return (
    <div className="px-4 py-6 sm:px-0">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-2xl font-bold">Addresses</h2>
        <button className="bg-indigo-600 text-white px-4 py-2 rounded">Add Address</button>
      </div>
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-50">
          <tr>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Address</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Default</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {addresses.map((address) => (
            <tr key={address.id}>
              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{address.user.name}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{`${address.street}, ${address.city}, ${address.state} ${address.zip}`}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{address.isDefault ? 'Yes' : 'No'}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                <button className="text-indigo-600 hover:text-indigo-900 mr-2">Edit</button>
                <button onClick={() => onDelete(address.id)} className="text-red-600 hover:text-red-900">Delete</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

function PaymentMethodsTable({ paymentMethods, onDelete, onRefresh }: { paymentMethods: PaymentMethod[], onDelete: (id: string) => void, onRefresh: () => void }) {
  return (
    <div className="px-4 py-6 sm:px-0">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-2xl font-bold">Payment Methods</h2>
        <button className="bg-indigo-600 text-white px-4 py-2 rounded">Add Payment Method</button>
      </div>
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-50">
          <tr>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Details</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {paymentMethods.map((pm) => (
            <tr key={pm.id}>
              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{pm.user.name}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{pm.type}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{pm.details}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                <button className="text-indigo-600 hover:text-indigo-900 mr-2">Edit</button>
                <button onClick={() => onDelete(pm.id)} className="text-red-600 hover:text-red-900">Delete</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

function PrescriptionsTable({ prescriptions, onDelete, onRefresh }: { prescriptions: Prescription[], onDelete: (id: string) => void, onRefresh: () => void }) {
  return (
    <div className="px-4 py-6 sm:px-0">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-2xl font-bold">Prescriptions</h2>
        <button className="bg-indigo-600 text-white px-4 py-2 rounded">Add Prescription</button>
      </div>
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-50">
          <tr>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Doctor</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Medication</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {prescriptions.map((p) => (
            <tr key={p.id}>
              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{p.user.name}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{p.doctorName}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{p.medication}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{p.status}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                <button className="text-indigo-600 hover:text-indigo-900 mr-2">Edit</button>
                <button onClick={() => onDelete(p.id)} className="text-red-600 hover:text-red-900">Delete</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

function OrdersTable({ orders, onDelete, onRefresh }: { orders: Order[], onDelete: (id: string) => void, onRefresh: () => void }) {
  return (
    <div className="px-4 py-6 sm:px-0">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-2xl font-bold">Orders</h2>
        <button className="bg-indigo-600 text-white px-4 py-2 rounded">Add Order</button>
      </div>
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-50">
          <tr>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Prescription</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Total</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {orders.map((o) => (
            <tr key={o.id}>
              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{o.user.name}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{o.prescription?.medication || 'N/A'}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${o.total}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{o.status}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                <button className="text-indigo-600 hover:text-indigo-900 mr-2">Edit</button>
                <button onClick={() => onDelete(o.id)} className="text-red-600 hover:text-red-900">Delete</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}