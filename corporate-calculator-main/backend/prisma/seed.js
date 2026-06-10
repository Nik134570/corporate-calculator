const { PrismaClient } = require('@prisma/client')
const bcrypt = require('bcryptjs')
const prisma = new PrismaClient()

async function findOrCreate(model, where, data) {
  const existing = await model.findFirst({ where })
  if (!existing) await model.create({ data })
}

async function main() {
  const admin  = await prisma.user.upsert({ where: { email: 'admin@test.com' },   update: {}, create: { email: 'admin@test.com',   passwordHash: await bcrypt.hash('admin123',   12), fullName: 'Администратор', role: 'ADMIN'   } })
  const manager = await prisma.user.upsert({ where: { email: 'manager@test.com' }, update: {}, create: { email: 'manager@test.com', passwordHash: await bcrypt.hash('manager123', 12), fullName: 'Руководитель', role: 'MANAGER' } })
  const worker  = await prisma.user.upsert({ where: { email: 'worker@test.com' },  update: {}, create: { email: 'worker@test.com',  passwordHash: await bcrypt.hash('worker123',  12), fullName: 'Рабочий',       role: 'WORKER'  } })

  for (const name of ['Стекло', 'Зеркало', 'Триплекс', 'Закалённое']) {
    await findOrCreate(prisma.material, { name }, { name })
  }
  const materials = await prisma.material.findMany({ where: { isActive: true } })
  const mat = (name) => materials.find(m => m.name === name)

  for (const [name, pricePerMeter] of [['Шлифовка', 150], ['Фацет', 300], ['Полировка торца', 100]]) {
    await findOrCreate(prisma.processingTemplate, { name }, { name, pricePerMeter })
  }

  for (const [name, unitPrice] of [['Отверстие', 150], ['Вырез', 300], ['Уголок', 80]]) {
    await findOrCreate(prisma.pieceWorkTemplate, { name }, { name, unitPrice })
  }

  for (const [name, defaultPrice] of [['Доставка', 1500], ['Подъём', 500], ['Расходники', 200], ['Замер', 800], ['Монтаж', 2000]]) {
    await findOrCreate(prisma.serviceTemplate, { name }, { name, defaultPrice })
  }

  const steklo   = mat('Стекло')
  const zerkalo  = mat('Зеркало')
  const triplex  = mat('Триплекс')
  const zakalnoe = mat('Закалённое')

  if (steklo && zerkalo && triplex && zakalnoe) {
    const proc = await prisma.processingTemplate.findMany({ where: { isActive: true } })
    const pw   = await prisma.pieceWorkTemplate.findMany({ where: { isActive: true } })
    const allProcIds = proc.map(p => ({ processingId: p.id }))
    const allPwIds   = pw.map(p  => ({ pieceWorkId:  p.id }))

    const templates = [
      { materialId: steklo.id,   thickness: '4мм',        unitPrice: 800  },
      { materialId: steklo.id,   thickness: '6мм',        unitPrice: 1200 },
      { materialId: steklo.id,   thickness: 'Матовое 4мм',unitPrice: 950  },
      { materialId: steklo.id,   thickness: 'Бронза 4мм', unitPrice: 1050 },
      { materialId: zerkalo.id,  thickness: '4мм',        unitPrice: 1100 },
      { materialId: zerkalo.id,  thickness: '6мм',        unitPrice: 1500 },
      { materialId: triplex.id,  thickness: '6.4мм',      unitPrice: 2500 },
      { materialId: zakalnoe.id, thickness: '6мм',        unitPrice: 2200, allowTempered: true },
    ]

    for (const t of templates) {
      const existing = await prisma.productTemplate.findFirst({
        where: { materialId: t.materialId, thickness: t.thickness }
      })
      if (!existing) {
        await prisma.productTemplate.create({ data: {
          ...t,
          allowTempered: t.allowTempered ?? false,
          allowedProcessings: { create: allProcIds },
          allowedPieceWorks:  { create: allPwIds  },
        }})
      }
    }
  }

  await prisma.appSettings.upsert({
    where:  { id: '00000000-0000-0000-0000-000000000001' },
    update: {},
    create: { id: '00000000-0000-0000-0000-000000000001', temperedPrice: 100 },
  })

  const existingCount = await prisma.calculation.count({ where: { createdById: worker.id } })
  if (existingCount < 40) {
    const mat1 = await prisma.material.findFirst({ where: { name: 'Стекло' } })

    const clients = [
      { name: 'ООО «Горизонт»',     phone: '+7 900 111-11-01', address: 'ул. Ленина, 1' },
      { name: 'ИП Смирнов А.В.',    phone: '+7 900 111-11-02', address: 'пр. Мира, 15' },
      { name: 'Салон «Интерьер»',   phone: '+7 900 111-11-03', address: 'ул. Садовая, 7' },
      { name: 'ЖК «Северный»',      phone: '+7 900 111-11-04', address: 'ул. Северная, 22' },
      { name: 'Торговый центр ЮГ',  phone: '+7 900 111-11-05', address: 'ул. Южная, 3' },
      { name: 'Кафе «Уют»',         phone: '+7 900 111-11-06', address: 'ул. Центральная, 8' },
      { name: 'Офис «Альфа»',       phone: '+7 900 111-11-07', address: 'бул. Победы, 12' },
      { name: 'Гостиница «Маяк»',   phone: '+7 900 111-11-08', address: 'ул. Приморская, 5' },
    ]

    const statuses = ['DRAFT', 'DRAFT', 'DRAFT', 'PENDING', 'APPROVED', 'REJECTED']

    for (let i = existingCount; i < 40; i++) {
      const client  = clients[i % clients.length]
      const status  = statuses[i % statuses.length]
      const w       = 400 + (i % 10) * 50
      const h       = 600 + (i % 8) * 40
      const area    = (w / 1000) * (h / 1000)
      const price   = mat1 ? 800 : 1000
      const total   = area * price * (1 + (i % 3) * 0.1)

      await prisma.calculation.create({
        data: {
          title:         `Заказ №${String(i + 1).padStart(3, '0')}`,
          clientName:    client.name,
          clientPhone:   client.phone,
          clientAddress: client.address,
          comment:       i % 4 === 0 ? 'Срочный заказ' : null,
          status,
          isDraft:       status === 'DRAFT' && i % 3 === 0,
          totalPrice:    Math.round((total + (i % 5 === 0 ? 1500 : 0)) * 100) / 100,
          delivery:      i % 5 === 0 ? 1500 : 0,
          createdById:   worker.id,
          products: {
            create: [{
              name:              `Изделие ${i + 1}`,
              width:             w,
              height:            h,
              quantity:          1 + (i % 3),
              isTempered:        i % 7 === 0,
              pricePerSqm:       price,
              originalPricePerSqm: price,
              area,
              totalPrice:        area * price,
            }],
          },
        },
      })
    }
    console.log(`Создано ${40 - existingCount} расчётов`)
  }

  console.log('Seed completed')
}

main().catch(console.error).finally(() => prisma.$disconnect())
