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
}

function format(t) {
  return {
    id: t.id,
    materialId: t.materialId,
    materialName: t.material?.name,
    thickness: t.thickness,
    unitPrice: t.unitPrice,
    allowTempered: t.allowTempered,
    isActive: t.isActive,
    allowedProcessingIds: (t.allowedProcessings || []).map(x => x.processingId),
    allowedPieceWorkIds: (t.allowedPieceWorks || []).map(x => x.pieceWorkId),
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
    const { materialId, thickness, unitPrice, allowTempered, processingIds, pieceWorkIds } = req.body
    const item = await prisma.productTemplate.create({
      data: {
        materialId, thickness, unitPrice,
        allowTempered: allowTempered ?? false,
        allowedProcessings: processingIds?.length
          ? { create: processingIds.map(id => ({ processingId: id })) } : undefined,
        allowedPieceWorks: pieceWorkIds?.length
          ? { create: pieceWorkIds.map(id => ({ pieceWorkId: id })) } : undefined,
      },
      include: includeRelations,
    })
    res.status(201).json({ success: true, data: format(item) })
  } catch (err) { next(err) }
})

router.patch('/:id', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const { materialId, thickness, unitPrice, allowTempered, isActive, processingIds, pieceWorkIds } = req.body
    const data = {}
    if (materialId !== undefined) data.materialId = materialId
    if (thickness !== undefined) data.thickness = thickness
    if (unitPrice !== undefined) data.unitPrice = unitPrice
    if (allowTempered !== undefined) data.allowTempered = allowTempered
    if (isActive !== undefined) data.isActive = isActive
    if (processingIds !== undefined) {
      data.allowedProcessings = { deleteMany: {}, create: processingIds.map(id => ({ processingId: id })) }
    }
    if (pieceWorkIds !== undefined) {
      data.allowedPieceWorks = { deleteMany: {}, create: pieceWorkIds.map(id => ({ pieceWorkId: id })) }
    }
    const item = await prisma.productTemplate.update({ where: { id: req.params.id }, data, include: includeRelations })
    res.json({ success: true, data: format(item) })
  } catch (err) { next(err) }
})

router.delete('/:id', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    await prisma.productTemplate.update({ where: { id: req.params.id }, data: { isActive: false } })
    res.json({ success: true })
  } catch (err) { next(err) }
})

module.exports = router
