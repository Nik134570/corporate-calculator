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
    const item = await prisma.serviceTemplate.create({ data: { name, defaultPrice } })
    res.status(201).json({ success: true, data: item })
  } catch (err) { next(err) }
})

router.patch('/services/:id', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const { name, defaultPrice } = req.body
    const data = {}
    if (name !== undefined) data.name = name
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

// --- Шаблоны обработки ---
router.get('/processings', async (req, res, next) => {
  try {
    const items = await prisma.processingTemplate.findMany({ where: { isActive: true }, orderBy: { name: 'asc' } })
    res.json({ success: true, data: items })
  } catch (err) { next(err) }
})

router.post('/processings', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const { name, pricePerMeter } = req.body
    const item = await prisma.processingTemplate.create({ data: { name, pricePerMeter } })
    res.status(201).json({ success: true, data: item })
  } catch (err) { next(err) }
})

router.patch('/processings/:id', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const { name, pricePerMeter } = req.body
    const data = {}
    if (name !== undefined) data.name = name
    if (pricePerMeter !== undefined) data.pricePerMeter = pricePerMeter
    const item = await prisma.processingTemplate.update({ where: { id: req.params.id }, data })
    res.json({ success: true, data: item })
  } catch (err) { next(err) }
})

router.delete('/processings/:id', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    await prisma.processingTemplate.update({ where: { id: req.params.id }, data: { isActive: false } })
    res.json({ success: true })
  } catch (err) { next(err) }
})

// --- Шаблоны штучных работ ---
router.get('/piece-works', async (req, res, next) => {
  try {
    const items = await prisma.pieceWorkTemplate.findMany({ where: { isActive: true }, orderBy: { name: 'asc' } })
    res.json({ success: true, data: items })
  } catch (err) { next(err) }
})

router.post('/piece-works', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const { name, unitPrice } = req.body
    const item = await prisma.pieceWorkTemplate.create({ data: { name, unitPrice } })
    res.status(201).json({ success: true, data: item })
  } catch (err) { next(err) }
})

router.patch('/piece-works/:id', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const { name, unitPrice } = req.body
    const data = {}
    if (name !== undefined) data.name = name
    if (unitPrice !== undefined) data.unitPrice = unitPrice
    const item = await prisma.pieceWorkTemplate.update({ where: { id: req.params.id }, data })
    res.json({ success: true, data: item })
  } catch (err) { next(err) }
})

router.delete('/piece-works/:id', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    await prisma.pieceWorkTemplate.update({ where: { id: req.params.id }, data: { isActive: false } })
    res.json({ success: true })
  } catch (err) { next(err) }
})

module.exports = router