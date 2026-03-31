const { Router } = require('express')
const authenticate = require('../../middleware/auth.middleware')
const requireRole = require('../../middleware/role.middleware')
const prisma = require('../../prisma')
const ApiError = require('../../utils/ApiError')
const logAudit = async (userId, userFullName, action, entityId, entityTitle, details) => {
  await prisma.auditLog.create({
    data: { userId, userFullName, action, entityId, entityTitle, details }
  }).catch(() => {}) // не ломаем основной запрос если аудит упал
}

const router = Router()
router.use(authenticate)

const includeAll = {
  createdBy: { select: { id: true, fullName: true, email: true } },
  products: {
    include: { processings: true, pieceWorks: true, material: true },
    orderBy: { sortOrder: 'asc' },
  },
  reviewRequest: {
    include: {
      requestedBy: { select: { id: true, fullName: true, email: true } },
      reviewedBy: { select: { id: true, fullName: true, email: true } },
    },
  },
}

router.get('/', async (req, res, next) => {
  try {
    const where = req.user.role === 'WORKER' ? { createdById: req.user.userId } : {}
    const calculations = await prisma.calculation.findMany({
      where,
      include: includeAll,
      orderBy: { createdAt: 'desc' },
    })
    res.json({ success: true, data: calculations })
  } catch (err) { next(err) }
})

router.get('/reviews/pending', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const reviews = await prisma.reviewRequest.findMany({
      where: { status: 'PENDING' },
      include: {
        requestedBy: { select: { id: true, fullName: true } },
        calculation: { include: includeAll },
      },
      orderBy: { createdAt: 'desc' },
    })
    res.json({ success: true, data: reviews })
  } catch (err) { next(err) }
})

router.get('/:id', async (req, res, next) => {
  try {
    const calculation = await prisma.calculation.findUnique({
      where: { id: req.params.id },
      include: includeAll,
    })
    if (!calculation) throw new ApiError(404, 'Not found')
    if (calculation.createdById !== req.user.userId && req.user.role === 'WORKER') throw new ApiError(403, 'Forbidden')
    res.json({ success: true, data: calculation })
  } catch (err) { next(err) }
})

const buildData = (body) => {
  const {
    title, clientName, clientPhone, clientAddress, comment,
    delivery = 0, lifting = 0, consumables = 0, measurement = 0, installation = 0,
    discountType = 'none', discountValue = 0,
    complexityType = 'none', complexityValue = 0,
    hasPriceChanges = false,
    products = [],
  } = body

  const productsTotal = products.reduce((sum, p) => sum + Number(p.totalPrice) * Number(p.quantity || 1), 0)
  const servicesTotal = Number(delivery) + Number(lifting) + Number(consumables) + Number(measurement) + Number(installation)
  let subtotal = productsTotal + servicesTotal

  let complexityAmount = 0
  if (complexityType === 'percent') complexityAmount = subtotal * Number(complexityValue) / 100
  else if (complexityType === 'fixed') complexityAmount = Number(complexityValue)
  subtotal += complexityAmount

  let discountAmount = 0
  if (discountType === 'percent') discountAmount = subtotal * Number(discountValue) / 100
  else if (discountType === 'fixed') discountAmount = Number(discountValue)
  const totalPrice = Math.max(0, subtotal - discountAmount)

  const status = hasPriceChanges ? 'PENDING' : 'DRAFT'

  const isDraft = !clientName || products.length === 0 ||
    products.every(p => !p.width || !p.height)

  return {
    title, clientName, clientPhone, clientAddress, comment,
    delivery, lifting, consumables, measurement, installation,
    discountType, discountValue, complexityType, complexityValue,
    hasPriceChanges, status, totalPrice, isDraft,
  }
}

const buildProducts = (products) => products.map((p, idx) => ({
  materialId: p.materialId || null,
  name: p.name,
  width: p.width,
  height: p.height,
  quantity: p.quantity || 1,
  isTempered: p.isTempered || false,
  pricePerSqm: p.pricePerSqm,
  originalPricePerSqm: p.originalPricePerSqm || null,
  area: p.area,
  totalPrice: p.totalPrice,
  sortOrder: idx,
  processings: {
    create: (p.processings || []).map(proc => ({
      name: proc.name,
      pricePerMeter: proc.pricePerMeter,
      originalPricePerMeter: proc.originalPricePerMeter || null,
      totalPrice: proc.totalPrice,
    })),
  },
  pieceWorks: {
    create: (p.pieceWorks || []).map(pw => ({
      name: pw.name,
      quantity: pw.quantity,
      unitPrice: pw.unitPrice,
      originalUnitPrice: pw.originalUnitPrice || null,
      totalPrice: pw.totalPrice,
    })),
  },
}))

router.post('/', async (req, res, next) => {
  try {
    const data = buildData(req.body)
    const calculation = await prisma.calculation.create({
      data: {
        ...data,
        createdById: req.user.userId,
        products: { create: buildProducts(req.body.products || []) },
      },
      include: includeAll,
    })
    
    await logAudit(
  req.user.userId,
  req.user.fullName || 'Пользователь',
  'CALCULATION_CREATED',
  calculation.id,
  calculation.title,
  null
)

    res.status(201).json({ success: true, data: calculation })
  } catch (err) { next(err) }
})

router.put('/:id', async (req, res, next) => {
  try {
    const existing = await prisma.calculation.findUnique({ where: { id: req.params.id } })
    if (!existing) throw new ApiError(404, 'Not found')
    if (existing.createdById !== req.user.userId && req.user.role === 'WORKER') throw new ApiError(403, 'Forbidden')

    await prisma.calculationProduct.deleteMany({ where: { calculationId: req.params.id } })

    const data = buildData(req.body)
    const calculation = await prisma.calculation.update({
      where: { id: req.params.id },
      data: {
        ...data,
        products: { create: buildProducts(req.body.products || []) },
      },
      include: includeAll,
    })
    res.json({ success: true, data: calculation })
  } catch (err) { next(err) }
})

// Отправить на модерацию
router.post('/:id/submit-review', async (req, res, next) => {
  try {
    const calculation = await prisma.calculation.findUnique({ where: { id: req.params.id } })
    if (!calculation) throw new ApiError(404, 'Not found')
    if (calculation.createdById !== req.user.userId) throw new ApiError(403, 'Forbidden')

    const { comment } = req.body

    await prisma.reviewRequest.upsert({
      where: { calculationId: req.params.id },
      update: { comment, status: 'PENDING', adminComment: null },
      create: { calculationId: req.params.id, requestedById: req.user.userId, comment },
    })

    await prisma.calculation.update({
      where: { id: req.params.id },
      data: { status: 'IN_REVIEW' },
    })

    await logAudit(
  req.user.userId,
  req.user.fullName || 'Пользователь',
  'REVIEW_SUBMITTED',
  req.params.id,
  calculation.title,
  comment || null
)

    res.json({ success: true })
  } catch (err) { next(err) }
})

// Одобрить
router.post('/:id/approve', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const { comment } = req.body
    const existing = await prisma.calculation.findUnique({ where: { id: req.params.id } })
    if (!existing) throw new ApiError(404, 'Not found')
    await prisma.reviewRequest.update({
      where: { calculationId: req.params.id },
      data: { status: 'APPROVED', adminComment: comment, reviewedById: req.user.userId },
    })
    await prisma.calculation.update({
      where: { id: req.params.id },
      data: { status: 'APPROVED', hasPriceChanges: false },
    })
    await logAudit(
      req.user.userId,
      req.user.fullName || 'Администратор',
      'CALCULATION_APPROVED',
      req.params.id,
      existing.title,
      comment || null
    )
    res.json({ success: true })
  } catch (err) { next(err) }
})

// Отклонить
router.post('/:id/reject', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const { comment } = req.body
    const existing = await prisma.calculation.findUnique({ where: { id: req.params.id } })
    if (!existing) throw new ApiError(404, 'Not found')
    await prisma.reviewRequest.update({
      where: { calculationId: req.params.id },
      data: { status: 'REJECTED', adminComment: comment, reviewedById: req.user.userId },
    })
    await prisma.calculation.update({
      where: { id: req.params.id },
      data: { status: 'REJECTED' },
    })
    await logAudit(
      req.user.userId,
      req.user.fullName || 'Администратор',
      'CALCULATION_REJECTED',
      req.params.id,
      existing.title,
      comment || null
    )
    res.json({ success: true })
  } catch (err) { next(err) }
})

router.delete('/:id', async (req, res, next) => {
  try {
    const calculation = await prisma.calculation.findUnique({ where: { id: req.params.id } })
    if (!calculation) throw new ApiError(404, 'Not found')
    if (calculation.createdById !== req.user.userId && req.user.role === 'WORKER') throw new ApiError(403, 'Forbidden')
    await prisma.calculation.delete({ where: { id: req.params.id } })
    res.json({ success: true })
  } catch (err) { next(err) }
})

module.exports = router