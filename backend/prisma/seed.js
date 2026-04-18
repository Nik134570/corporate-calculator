const { PrismaClient } = require('@prisma/client')
const bcrypt = require('bcryptjs')
const prisma = new PrismaClient()

async function findOrCreate(model, where, data) {
  const existing = await model.findFirst({ where })
  if (!existing) await model.create({ data })
}

async function main() {
  await prisma.user.upsert({ where: { email: 'admin@test.com' }, update: {}, create: { email: 'admin@test.com', passwordHash: await bcrypt.hash('admin123', 12), fullName: 'Администратор', role: 'ADMIN' } })
  await prisma.user.upsert({ where: { email: 'manager@test.com' }, update: {}, create: { email: 'manager@test.com', passwordHash: await bcrypt.hash('manager123', 12), fullName: 'Руководитель', role: 'MANAGER' } })
  await prisma.user.upsert({ where: { email: 'worker@test.com' }, update: {}, create: { email: 'worker@test.com', passwordHash: await bcrypt.hash('worker123', 12), fullName: 'Рабочий', role: 'WORKER' } })

  // Материалы (findFirst чтобы не создавать дубли)
  for (const name of ['Стекло', 'Зеркало', 'Триплекс', 'Закалённое']) {
    await findOrCreate(prisma.material, { name }, { name })
  }
  const materials = await prisma.material.findMany({ where: { isActive: true } })
  const mat = (name) => materials.find(m => m.name === name)

  // Обработки
  for (const [name, pricePerMeter] of [['Шлифовка', 150], ['Фацет', 300], ['Полировка торца', 100]]) {
    await findOrCreate(prisma.processingTemplate, { name }, { name, pricePerMeter })
  }

  // Штучные работы
  for (const [name, unitPrice] of [['Отверстие', 150], ['Вырез', 300], ['Уголок', 80]]) {
    await findOrCreate(prisma.pieceWorkTemplate, { name }, { name, unitPrice })
  }

  // Услуги
  for (const [name, defaultPrice] of [['Доставка', 1500], ['Подъём', 500], ['Расходники', 200], ['Замер', 800], ['Монтаж', 2000]]) {
    await findOrCreate(prisma.serviceTemplate, { name }, { name, defaultPrice })
  }

  // Наименования изделий (ProductTemplate)
  const steklo = mat('Стекло')
  const zerkalo = mat('Зеркало')
  const triplex = mat('Триплекс')
  const zakalnoe = mat('Закалённое')

  if (steklo && zerkalo && triplex && zakalnoe) {
    const proc = await prisma.processingTemplate.findMany({ where: { isActive: true } })
    const pw = await prisma.pieceWorkTemplate.findMany({ where: { isActive: true } })
    const allProcIds = proc.map(p => ({ processingId: p.id }))
    const allPwIds = pw.map(p => ({ pieceWorkId: p.id }))

    const templates = [
      { materialId: steklo.id, thickness: '4мм', unitPrice: 800 },
      { materialId: steklo.id, thickness: '6мм', unitPrice: 1200 },
      { materialId: steklo.id, thickness: 'Матовое 4мм', unitPrice: 950 },
      { materialId: steklo.id, thickness: 'Бронза 4мм', unitPrice: 1050 },
      { materialId: zerkalo.id, thickness: '4мм', unitPrice: 1100 },
      { materialId: zerkalo.id, thickness: '6мм', unitPrice: 1500 },
      { materialId: triplex.id, thickness: '6.4мм', unitPrice: 2500 },
      { materialId: zakalnoe.id, thickness: '6мм', unitPrice: 2200, allowTempered: true },
    ]

    for (const t of templates) {
      // Используем findFirst (без unique index на materialId+thickness для старых БД)
      const existing = await prisma.productTemplate.findFirst({
        where: { materialId: t.materialId, thickness: t.thickness }
      })
      if (!existing) {
        await prisma.productTemplate.create({ data: {
          ...t,
          allowTempered: t.allowTempered ?? false,
          allowedProcessings: { create: allProcIds },
          allowedPieceWorks: { create: allPwIds },
        }})
      }
    }
  }

  await prisma.appSettings.upsert({
    where: { id: '00000000-0000-0000-0000-000000000001' },
    update: {},
    create: { id: '00000000-0000-0000-0000-000000000001', temperedPrice: 100 }
  })
  console.log('Seed completed')
}

main().catch(console.error).finally(() => prisma.$disconnect())
