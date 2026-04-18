const { Router } = require('express')
const authenticate = require('../../middleware/auth.middleware')
const requireRole = require('../../middleware/role.middleware')
const prisma = require('../../prisma')

const router = Router()
router.use(authenticate)

const includeRelations = {
  material: true,
  allowedProcessings: { select: { processingId: true } },
  allowedPieceWorks: { select: { pieceWorkId: true } },
  allowedDiscounts: { select: { discountId: true } },
}

function format(t) {
  return {
    id: t.id,
    materialId: t.materialId,
    materialName: t.material?.name,
    thickness: t.thickness,
    unitPrice: t.unitPrice,
    allowTempered: t.allowTempered,
    complexityType: t.complexityType,
    complexityValue: t.complexityValue,
    isActive: t.isActive,
    allowedProcessingIds: (t.allowedProcessings || []).map(x => x.processingId),
    allowedPieceWorkIds: (t.allowedPieceWorks || []).map(x => x.pieceWorkId),
    allowedDiscountIds: (t.allowedDiscounts || []).map(x => x.discountId),
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
  }
}

router.get('/', async (req, res, next) => {
  try {
    const items = await prisma.productTemplate.findMany({
      where: { isActive: true },
      orderBy: [{ material: { name: 'asc' } }, { thickness: 'asc' }],
      include: includeRelations,
    })
    res.json({ success: true, data: items.map(format) })
  } catch (err) { next(err) }
})

router.post('/', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const { materialId, thickness, unitPrice, allowTempered, complexityType, complexityValue, processingIds, pieceWorkIds, discountIds } = req.body
    const item = await prisma.productTemplate.create({
      data: {
        materialId, thickness, unitPrice,
        allowTempered: allowTempered ?? false,
        complexityType: complexityType || 'none',
        complexityValue: complexityValue || 0,
        allowedProcessings: processingIds?.length
          ? { create: processingIds.map(id => ({ processingId: id })) } : undefined,
        allowedPieceWorks: pieceWorkIds?.length
          ? { create: pieceWorkIds.map(id => ({ pieceWorkId: id })) } : undefined,
        allowedDiscounts: discountIds?.length
          ? { create: discountIds.map(id => ({ discountId: id })) } : undefined,
      },
      include: includeRelations,
    })
    res.status(201).json({ success: true, data: format(item) })
  } catch (err) {
    if (err.code === 'P2002') return res.status(409).json({ success: false, message: 'Шаблон изделия с таким материалом и толщиной уже существует' })
    next(err)
  }
})

router.patch('/:id', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const { materialId, thickness, unitPrice, allowTempered, complexityType, complexityValue, isActive, processingIds, pieceWorkIds, discountIds } = req.body
    const data = {}
    if (materialId !== undefined) data.materialId = materialId
    if (thickness !== undefined) data.thickness = thickness
    if (unitPrice !== undefined) data.unitPrice = unitPrice
    if (allowTempered !== undefined) data.allowTempered = allowTempered
    if (complexityType !== undefined) data.complexityType = complexityType
    if (complexityValue !== undefined) data.complexityValue = complexityValue
    if (isActive !== undefined) data.isActive = isActive
    if (processingIds !== undefined) {
      data.allowedProcessings = { deleteMany: {}, create: processingIds.map(id => ({ processingId: id })) }
    }
    if (pieceWorkIds !== undefined) {
      data.allowedPieceWorks = { deleteMany: {}, create: pieceWorkIds.map(id => ({ pieceWorkId: id })) }
    }
    if (discountIds !== undefined) {
      data.allowedDiscounts = { deleteMany: {}, create: discountIds.map(id => ({ discountId: id })) }
    }
    const item = await prisma.productTemplate.update({ where: { id: req.params.id }, data, include: includeRelations })
    res.json({ success: true, data: format(item) })
  } catch (err) {
    if (err.code === 'P2002') return res.status(409).json({ success: false, message: 'Шаблон изделия с таким материалом и толщиной уже существует' })
    next(err)
  }
})

router.delete('/:id', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    await prisma.productTemplate.update({ where: { id: req.params.id }, data: { isActive: false } })
    res.json({ success: true })
  } catch (err) { next(err) }
})

module.exports = router
