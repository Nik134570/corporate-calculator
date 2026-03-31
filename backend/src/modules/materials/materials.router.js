const { Router } = require('express')
const authenticate = require('../../middleware/auth.middleware')
const requireRole = require('../../middleware/role.middleware')
const prisma = require('../../prisma')

const router = Router()
router.use(authenticate)

router.get('/', async (req, res, next) => {
  try {
    const materials = await prisma.material.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' },
    })
    res.json({ success: true, data: materials })
  } catch (err) { next(err) }
})

router.post('/', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const { name, unitPrice } = req.body
    const material = await prisma.material.create({ data: { name, unitPrice } })
    res.status(201).json({ success: true, data: material })
  } catch (err) { next(err) }
})

router.patch('/:id', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const { name, unitPrice, isActive } = req.body
    const data = {}
    if (name !== undefined) data.name = name
    if (unitPrice !== undefined) data.unitPrice = unitPrice
    if (isActive !== undefined) data.isActive = isActive
    const material = await prisma.material.update({ where: { id: req.params.id }, data })
    res.json({ success: true, data: material })
  } catch (err) { next(err) }
})

router.delete('/:id', requireRole('ADMIN'), async (req, res, next) => {
  try {
    await prisma.material.update({
      where: { id: req.params.id },
      data: { isActive: false },
    })
    res.json({ success: true })
  } catch (err) { next(err) }
})

module.exports = router