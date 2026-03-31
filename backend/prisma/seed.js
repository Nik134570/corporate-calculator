const { PrismaClient } = require('@prisma/client')
const bcrypt = require('bcryptjs')
const prisma = new PrismaClient()

async function main() {
  const adminHash = await bcrypt.hash('admin123', 12)
  const workerHash = await bcrypt.hash('worker123', 12)
  const managerHash = await bcrypt.hash('manager123', 12)

  await prisma.user.upsert({
    where: { email: 'admin@test.com' },
    update: {},
    create: { email: 'admin@test.com', passwordHash: adminHash, fullName: 'Администратор', role: 'ADMIN' },
  })
  await prisma.user.upsert({
    where: { email: 'manager@test.com' },
    update: {},
    create: { email: 'manager@test.com', passwordHash: managerHash, fullName: 'Руководитель', role: 'MANAGER' },
  })
  await prisma.user.upsert({
    where: { email: 'worker@test.com' },
    update: {},
    create: { email: 'worker@test.com', passwordHash: workerHash, fullName: 'Рабочий', role: 'WORKER' },
  })

  await prisma.material.createMany({
    skipDuplicates: true,
    data: [
      { name: 'Стекло прозрачное 4мм', unitPrice: 800 },
      { name: 'Стекло прозрачное 6мм', unitPrice: 1200 },
      { name: 'Стекло матовое 4мм', unitPrice: 950 },
      { name: 'Стекло бронза 4мм', unitPrice: 1050 },
      { name: 'Зеркало 4мм', unitPrice: 1100 },
      { name: 'Зеркало 6мм', unitPrice: 1500 },
      { name: 'Триплекс 6.4мм', unitPrice: 2500 },
      { name: 'Закалённое 6мм', unitPrice: 2200 },
    ],
  })

  await prisma.serviceTemplate.createMany({
    skipDuplicates: true,
    data: [
      { name: 'Доставка', defaultPrice: 1500 },
      { name: 'Подъём', defaultPrice: 500 },
      { name: 'Расходники', defaultPrice: 200 },
      { name: 'Замер', defaultPrice: 800 },
      { name: 'Монтаж', defaultPrice: 2000 },
    ],
  })

  await prisma.processingTemplate.createMany({
    skipDuplicates: true,
    data: [
      { name: 'Шлифовка', pricePerMeter: 150 },
      { name: 'Фацет', pricePerMeter: 300 },
      { name: 'Полировка торца', pricePerMeter: 100 },
    ],
  })

  await prisma.pieceWorkTemplate.createMany({
    skipDuplicates: true,
    data: [
      { name: 'Отверстие', unitPrice: 150 },
      { name: 'Вырез', unitPrice: 300 },
      { name: 'Уголок', unitPrice: 80 },
    ],
  })

  await prisma.appSettings.upsert({
    where: { id: '00000000-0000-0000-0000-000000000001' },
    update: {},
    create: { id: '00000000-0000-0000-0000-000000000001', temperedPrice: 100 },
  })

  console.log('Seed completed')
}

main().catch(console.error).finally(() => prisma.$disconnect())