const { Router } = require('express')
const authenticate = require('../../middleware/auth.middleware')
const requireRole = require('../../middleware/role.middleware')
const prisma = require('../../prisma')

const router = Router()
router.use(authenticate)

// --- Шаблоны услуг ---
router.get('/services', async (req, res, next) => {
  try {
    const items = await prisma.serviceTemplate.findMany({ where: { isActive: true }, orderBy: { name: 'asc' } })
    res.json({ success: true, data: items })
  } catch (err) { next(err) }
})
router.post('/services', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const { name, defaultPrice } = req.body
    const existing = await prisma.serviceTemplate.findFirst({ where: { name: { equals: name, mode: 'insensitive' }, isActive: true } })
    if (existing) return res.status(409).json({ success: false, message: 'Услуга с таким названием уже существует' })
    const item = await prisma.serviceTemplate.create({ data: { name, defaultPrice } })
    res.status(201).json({ success: true, data: item })
  } catch (err) { next(err) }
})
router.patch('/services/:id', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const { name, defaultPrice } = req.body
    const data = {}
    if (name !== undefined) {
      const existing = await prisma.serviceTemplate.findFirst({ where: { name: { equals: name, mode: 'insensitive' }, isActive: true, NOT: { id: req.params.id } } })
      if (existing) return res.status(409).json({ success: false, message: 'Услуга с таким названием уже существует' })
      data.name = name
    }
    if (defaultPrice !== undefined) data.defaultPrice = defaultPrice
    const item = await prisma.serviceTemplate.update({ where: { id: req.params.id }, data })
    res.json({ success: true, data: item })
  } catch (err) { next(err) }
})
router.delete('/services/:id', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    await prisma.serviceTemplate.update({ where: { id: req.params.id }, data: { isActive: false } })
    res.json({ success: true })
  } catch (err) { next(err) }
})

// --- Шаблоны скидок ---
const discInclude = { allowedProductTemplates: { select: { productTemplateId: true } } }
const fmtDisc = i => ({ ...i, productTemplateIds: i.allowedProductTemplates.map(x => x.productTemplateId), allowedProductTemplates: undefined })

router.get('/discounts', async (req, res, next) => {
  try {
    const items = await prisma.discountTemplate.findMany({ where: { isActive: true }, orderBy: [{ type: 'asc' }, { value: 'asc' }], include: discInclude })
    res.json({ success: true, data: items.map(fmtDisc) })
  } catch (err) { next(err) }
})
router.post('/discounts', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const { name, type, value, productTemplateIds } = req.body
    const item = await prisma.discountTemplate.create({
      data: { name, type, value, allowedProductTemplates: productTemplateIds?.length ? { create: productTemplateIds.map(id => ({ productTemplateId: id })) } : undefined },
      include: discInclude,
    })
    res.status(201).json({ success: true, data: fmtDisc(item) })
  } catch (err) { next(err) }
})
router.patch('/discounts/:id', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const { name, type, value, productTemplateIds } = req.body
    const data = {}
    if (name !== undefined) data.name = name
    if (type !== undefined) data.type = type
    if (value !== undefined) data.value = value
    if (productTemplateIds !== undefined) data.allowedProductTemplates = { deleteMany: {}, create: productTemplateIds.map(id => ({ productTemplateId: id })) }
    const item = await prisma.discountTemplate.update({ where: { id: req.params.id }, data, include: discInclude })
    res.json({ success: true, data: fmtDisc(item) })
  } catch (err) { next(err) }
})
router.delete('/discounts/:id', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    await prisma.discountTemplate.update({ where: { id: req.params.id }, data: { isActive: false } })
    res.json({ success: true })
  } catch (err) { next(err) }
})

// --- Шаблоны обработки ---
const procInclude = { allowedProductTemplates: { select: { productTemplateId: true } } }
const fmtProc = i => ({ ...i, productTemplateIds: i.allowedProductTemplates.map(x => x.productTemplateId), allowedProductTemplates: undefined })

router.get('/processings', async (req, res, next) => {
  try {
    const items = await prisma.processingTemplate.findMany({ where: { isActive: true }, orderBy: { name: 'asc' }, include: procInclude })
    res.json({ success: true, data: items.map(fmtProc) })
  } catch (err) { next(err) }
})
router.post('/processings', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const { name, pricePerMeter, productTemplateIds } = req.body
    const existing = await prisma.processingTemplate.findFirst({ where: { name: { equals: name, mode: 'insensitive' }, isActive: true } })
    if (existing) return res.status(409).json({ success: false, message: 'Обработка с таким названием уже существует' })
    const item = await prisma.processingTemplate.create({
      data: { name, pricePerMeter, allowedProductTemplates: productTemplateIds?.length ? { create: productTemplateIds.map(id => ({ productTemplateId: id })) } : undefined },
      include: procInclude,
    })
    res.status(201).json({ success: true, data: fmtProc(item) })
  } catch (err) { next(err) }
})
router.patch('/processings/:id', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const { name, pricePerMeter, productTemplateIds } = req.body
    const data = {}
    if (name !== undefined) {
      const existing = await prisma.processingTemplate.findFirst({ where: { name: { equals: name, mode: 'insensitive' }, isActive: true, NOT: { id: req.params.id } } })
      if (existing) return res.status(409).json({ success: false, message: 'Обработка с таким названием уже существует' })
      data.name = name
    }
    if (pricePerMeter !== undefined) data.pricePerMeter = pricePerMeter
    if (productTemplateIds !== undefined) data.allowedProductTemplates = { deleteMany: {}, create: productTemplateIds.map(id => ({ productTemplateId: id })) }
    const item = await prisma.processingTemplate.update({ where: { id: req.params.id }, data, include: procInclude })
    res.json({ success: true, data: fmtProc(item) })
  } catch (err) { next(err) }
})
router.delete('/processings/:id', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    await prisma.processingTemplate.update({ where: { id: req.params.id }, data: { isActive: false } })
    res.json({ success: true })
  } catch (err) { next(err) }
})

// --- Шаблоны штучных работ ---
const pwInclude = { allowedProductTemplates: { select: { productTemplateId: true } } }
const fmtPw = i => ({ ...i, productTemplateIds: i.allowedProductTemplates.map(x => x.productTemplateId), allowedProductTemplates: undefined })

router.get('/piece-works', async (req, res, next) => {
  try {
    const items = await prisma.pieceWorkTemplate.findMany({ where: { isActive: true }, orderBy: { name: 'asc' }, include: pwInclude })
    res.json({ success: true, data: items.map(fmtPw) })
  } catch (err) { next(err) }
})
router.post('/piece-works', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const { name, unitPrice, productTemplateIds } = req.body
    const existing = await prisma.pieceWorkTemplate.findFirst({ where: { name: { equals: name, mode: 'insensitive' }, isActive: true } })
    if (existing) return res.status(409).json({ success: false, message: 'Штучная работа с таким названием уже существует' })
    const item = await prisma.pieceWorkTemplate.create({
      data: { name, unitPrice, allowedProductTemplates: productTemplateIds?.length ? { create: productTemplateIds.map(id => ({ productTemplateId: id })) } : undefined },
      include: pwInclude,
    })
    res.status(201).json({ success: true, data: fmtPw(item) })
  } catch (err) { next(err) }
})
router.patch('/piece-works/:id', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const { name, unitPrice, productTemplateIds } = req.body
    const data = {}
    if (name !== undefined) {
      const existing = await prisma.pieceWorkTemplate.findFirst({ where: { name: { equals: name, mode: 'insensitive' }, isActive: true, NOT: { id: req.params.id } } })
      if (existing) return res.status(409).json({ success: false, message: 'Штучная работа с таким названием уже существует' })
      data.name = name
    }
    if (unitPrice !== undefined) data.unitPrice = unitPrice
    if (productTemplateIds !== undefined) data.allowedProductTemplates = { deleteMany: {}, create: productTemplateIds.map(id => ({ productTemplateId: id })) }
    const item = await prisma.pieceWorkTemplate.update({ where: { id: req.params.id }, data, include: pwInclude })
    res.json({ success: true, data: fmtPw(item) })
  } catch (err) { next(err) }
})
router.delete('/piece-works/:id', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    await prisma.pieceWorkTemplate.update({ where: { id: req.params.id }, data: { isActive: false } })
    res.json({ success: true })
  } catch (err) { next(err) }
})

module.exports = router
