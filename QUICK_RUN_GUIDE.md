# 🎯 QUICK COMMAND REFERENCE

## 🚀 RUN COMPLETE SYSTEM IN 3 STEPS

### Step 1: Backend Already Running ✓
```bash
# Terminal 1 - Already in background
# Port: 3000
# Status: Ready
```

### Step 2: Seed Database
```bash
# Terminal 2:
cd C:\src\Pharmacy\backend
node prisma/seed.js
```

### Step 3: Launch Flutter App
```bash
# Terminal 3:
cd C:\src\Pharmacy
flutter run -d emulator-5554
```

---

## 📱 IN THE FLUTTER APP

**Login Screen:**
- Email: `admin@pharmacy.com`
- Password: `Admin@123456`
- Press: **Login**

**After Login:**
- Dashboard displays
- See real data from database
- Admin features available

---

## 🔍 VERIFY SYSTEM

### Check Backend
```bash
curl http://localhost:3000
```

### Test Admin Login
```powershell
$body = @{action='login';email='admin@pharmacy.com';password='Admin@123456'} | ConvertTo-Json
Invoke-WebRequest -Uri http://localhost:3000/api/auth -Method POST -Body $body -ContentType application/json -UseBasicParsing
```

### Check Database
```bash
cd C:\src\Pharmacy\backend
npx prisma studio
# Opens admin interface to view database
```

---

## 🛑 STOP SERVICES

### Kill All Node Processes
```bash
taskkill /F /IM node.exe
```

### Stop Flutter App
```
Press 'q' in Flutter terminal
```

---

## 📊 SYSTEM STATUS

| Component | Status | Port |
|-----------|--------|------|
| Backend | ✅ Running | 3000 |
| Database | ✅ Seeded | - |
| Admin User | ✅ Created | - |
| Flutter | ✅ Ready | Emulator |

---

## 🎓 ADMIN CREDENTIALS

```
Email:    admin@pharmacy.com
Password: Admin@123456
```

⚠️ Change in production!

---

## 📁 KEY FILES

```
C:\src\Pharmacy\backend\
├── npm run dev ..................... Start backend
├── node prisma/seed.js ............ Seed database
├── lib/auth.js .................... Auth logic (now uses Prisma!)
├── pages/api/auth.js .............. Login endpoint
├── pages/api/admin/ ............... Admin endpoints
├── prisma/schema.prisma ........... Database schema
└── jsconfig.json .................. Path aliases ✓

C:\src\Pharmacy\
├── flutter run -d emulator-5554 ... Launch app
└── lib/main.dart .................. App entry point
```

---

## 🎯 EXPECTED FLOW

```
App Launch
   ↓
Login Screen
   ↓ (admin@pharmacy.com / Admin@123456)
Backend Authenticates
   ↓
Database Query (Prisma)
   ↓
JWT Token Generated
   ↓
Token Sent to Flutter
   ↓
Dashboard Loads
   ↓
Real Data Displayed ✓
```

---

## ✅ CHECKLIST

- [ ] Backend running (Terminal 1)
- [ ] Database seeded (Terminal 2)
- [ ] Flutter app launched (Terminal 3)
- [ ] Login screen visible
- [ ] Admin credentials entered
- [ ] Dashboard displayed
- [ ] Real data showing

---

## 🎉 YOU'RE ALL SET!

Just run the 3 commands and enjoy your fully functional pharmacy app!

---

**Backend Credentials**
- User: admin@pharmacy.com
- Pass: Admin@123456

**Server**
- URL: http://localhost:3000
- Status: Ready

**Database**
- Records: 28 total
- Status: Seeded

**App**
- Platform: Android Emulator
- Status: Ready to launch
