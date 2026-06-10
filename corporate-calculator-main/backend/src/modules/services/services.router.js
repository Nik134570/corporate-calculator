const { Router } = require('express')
const authenticate = require('../../middleware/auth.middleware')
const requireRole = require('../../middleware/role.middleware')
const prisma = require('../../prisma')

const router = Router()
router.use(authenticate)

router.get('/', async (req, res, next) => {
  try {
    const services = await prisma.additionalService.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' },
    })
    res.json({ success: true, data: services })
  } catch (err) { next(err) }
})

router.post('/', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const service = await prisma.additionalService.create({ data: req.body })
    res.status(201).json({ success: true, data: service })
  } catch (err) { next(err) }
})

router.patch('/:id', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    const service = await prisma.additionalService.update({
      where: { id: req.params.id },
      data: req.body,
    })
    res.json({ success: true, data: service })
  } catch (err) { next(err) }
})

router.delete('/:id', requireRole('ADMIN'), async (req, res, next) => {
  try {
    await prisma.additionalService.update({
      where: { id: req.params.id },
      data: { isActive: false },
    })
    res.json({ success: true })
  } catch (err) { next(err) }
})

module.exports = router
