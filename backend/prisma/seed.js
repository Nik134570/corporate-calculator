const { PrismaClient } = require('@prisma/client')
const bcrypt = require('bcryptjs')
const prisma = new PrismaClient()

async function upsertByName(model, name, extra = {}) {
  const existing = await model.findFirst({ where: { name } })
  if (!existing) return model.create({ data: { name, ...extra } })
  if (Object.keys(extra).length > 0) {
    return model.update({ where: { id: existing.id }, data: extra })
  }
  return existing
}

async function main() {
  await prisma.user.upsert({ where: { email: 'admin@test.com' }, update: {}, create: { email: 'admin@test.com', passwordHash: await bcrypt.hash('admin123', 12), fullName: 'Администратор', role: 'ADMIN' } })
  await prisma.user.upsert({ where: { email: 'manager@test.com' }, update: {}, create: { email: 'manager@test.com', passwordHash: await bcrypt.hash('manager123', 12), fullName: 'Руководитель', role: 'MANAGER' } })
  await prisma.user.upsert({ where: { email: 'worker@test.com' }, update: {}, create: { email: 'worker@test.com', passwordHash: await bcrypt.hash('worker123', 12), fullName: 'Рабочий', role: 'WORKER' } })

  // Материалы (только название — уникальное по name)
  for (const name of ['Стекло', 'Зеркало', 'Триплекс', 'Закалённое']) {
    await prisma.material.upsert({ where: { name }, update: {}, create: { name } })
  }
  const materials = await prisma.material.findMany()
  const mat = (name) => materials.find(m => m.name === name)

  // Обработки (уникальные по name)
  for (const [name, pricePerMeter] of [['Шлифовка', 150], ['Фацет', 300], ['Полировка торца', 100]]) {
    await prisma.processingTemplate.upsert({ where: { name }, update: { pricePerMeter }, create: { name, pricePerMeter } })
  }

  // Штучные работы (уникальные по name)
  for (const [name, unitPrice] of [['Отверстие', 150], ['Вырез', 300], ['Уголок', 80]]) {
    await prisma.pieceWorkTemplate.upsert({ where: { name }, update: { unitPrice }, create: { name, unitPrice } })
  }

  // Услуги
  for (const [name, defaultPrice] of [['Доставка', 1500], ['Подъём', 500], ['Расходники', 200], ['Замер', 800], ['Монтаж', 2000]]) {
    const existing = await prisma.serviceTemplate.findFirst({ where: { name } })
    if (!existing) await prisma.serviceTemplate.create({ data: { name, defaultPrice } })
  }

  // Наименования изделий
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
      const existing = await prisma.productTemplate.findUnique({ where: { materialId_thickness: { materialId: t.materialId, thickness: t.thickness } } })
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
