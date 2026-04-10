const { PrismaClient } = require('@prisma/client')
const bcrypt = require('bcryptjs')
const prisma = new PrismaClient()

async function main() {
  await prisma.user.upsert({ where: { email: 'admin@test.com' }, update: {}, create: { email: 'admin@test.com', passwordHash: await bcrypt.hash('admin123', 12), fullName: 'Администратор', role: 'ADMIN' } })
  await prisma.user.upsert({ where: { email: 'manager@test.com' }, update: {}, create: { email: 'manager@test.com', passwordHash: await bcrypt.hash('manager123', 12), fullName: 'Руководитель', role: 'MANAGER' } })
  await prisma.user.upsert({ where: { email: 'worker@test.com' }, update: {}, create: { email: 'worker@test.com', passwordHash: await bcrypt.hash('worker123', 12), fullName: 'Рабочий', role: 'WORKER' } })

  // Базовые материалы
  const matNames = ['Стекло', 'Зеркало', 'Триплекс', 'Закалённое']
  for (const name of matNames) {
    await prisma.material.upsert({ where: { id: name }, update: {}, create: { id: name, name } }).catch(async () => {
      const existing = await prisma.material.findFirst({ where: { name } })
      if (!existing) await prisma.material.create({ data: { name } })
    })
  }
  const materials = await prisma.material.findMany()
  const mat = (name) => materials.find(m => m.name === name)

  // Обработки
  await prisma.processingTemplate.createMany({ skipDuplicates: true, data: [
    { name: 'Шлифовка', pricePerMeter: 150 },
    { name: 'Фацет', pricePerMeter: 300 },
    { name: 'Полировка торца', pricePerMeter: 100 },
  ]})

  // Штучные работы
  await prisma.pieceWorkTemplate.createMany({ skipDuplicates: true, data: [
    { name: 'Отверстие', unitPrice: 150 },
    { name: 'Вырез', unitPrice: 300 },
    { name: 'Уголок', unitPrice: 80 },
  ]})

  await prisma.serviceTemplate.createMany({ skipDuplicates: true, data: [
    { name: 'Доставка', defaultPrice: 1500 },
    { name: 'Подъём', defaultPrice: 500 },
    { name: 'Расходники', defaultPrice: 200 },
    { name: 'Замер', defaultPrice: 800 },
    { name: 'Монтаж', defaultPrice: 2000 },
  ]})

  // Наименования изделий (productTemplates)
  const steklo = mat('Стекло')
  const zerkalo = mat('Зеркало')
  const triplex = mat('Триплекс')
  const zakalnoe = mat('Закалённое')

  if (steklo && zerkalo && triplex && zakalnoe) {
    const proc = await prisma.processingTemplate.findMany()
    const pw = await prisma.pieceWorkTemplate.findMany()
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
      const existing = await prisma.productTemplate.findFirst({ where: { materialId: t.materialId, thickness: t.thickness } })
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

  await prisma.appSettings.upsert({ where: { id: '00000000-0000-0000-0000-000000000001' }, update: {}, create: { id: '00000000-0000-0000-0000-000000000001', temperedPrice: 100 } })
  console.log('Seed completed')
}

main().catch(console.error).finally(() => prisma.$disconnect())
