require('dotenv').config()
const app = require('./src/app')
const logger = require('./src/config/logger')
const prisma = require('./src/prisma')
const bcrypt = require('bcryptjs')

const PORT = process.env.PORT || 3000

async function seedIfEmpty() {
  const count = await prisma.user.count()
  if (count > 0) return

  logger.info('Database is empty — running initial seed...')

  const matNames = ['Стекло', 'Зеркало', 'Триплекс', 'Закалённое']
  for (const name of matNames) {
    await prisma.material.upsert({ where: { id: name }, update: {}, create: { id: name, name } }).catch(async () => {
      const existing = await prisma.material.findFirst({ where: { name } })
      if (!existing) await prisma.material.create({ data: { name } })
    })
  }

  await prisma.processingTemplate.createMany({ skipDuplicates: true, data: [
    { name: 'Шлифовка', pricePerMeter: 150 },
    { name: 'Фацет', pricePerMeter: 300 },
    { name: 'Полировка торца', pricePerMeter: 100 },
  ]})

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

  const materials = await prisma.material.findMany()
  const mat = (name) => materials.find(m => m.name === name)
  const steklo = mat('Стекло'), zerkalo = mat('Зеркало'), triplex = mat('Триплекс'), zakalnoe = mat('Закалённое')

  if (steklo && zerkalo && triplex && zakalnoe) {
    const proc = await prisma.processingTemplate.findMany()
    const pw = await prisma.pieceWorkTemplate.findMany()
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
          allowedProcessings: { create: proc.map(p => ({ processingId: p.id })) },
          allowedPieceWorks: { create: pw.map(p => ({ pieceWorkId: p.id })) },
        }})
      }
    }
  }

  await prisma.appSettings.upsert({ where: { id: '00000000-0000-0000-0000-000000000001' }, update: {}, create: { id: '00000000-0000-0000-0000-000000000001', temperedPrice: 100 } })

  await prisma.user.createMany({ data: [
    { email: 'admin@test.com', passwordHash: await bcrypt.hash('admin123', 12), fullName: 'Администратор', role: 'ADMIN' },
    { email: 'manager@test.com', passwordHash: await bcrypt.hash('manager123', 12), fullName: 'Руководитель', role: 'MANAGER' },
    { email: 'worker@test.com', passwordHash: await bcrypt.hash('worker123', 12), fullName: 'Рабочий', role: 'WORKER' },
  ]})

  logger.info('Initial seed completed')
}

seedIfEmpty()
  .catch(err => logger.error('Seed error:', err))
  .finally(() => {
    app.listen(PORT, () => {
      logger.info(`Server running on port ${PORT}`)
    })
  })