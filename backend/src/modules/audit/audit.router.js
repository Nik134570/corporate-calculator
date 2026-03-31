const { Router } = require('express')
const authenticate = require('../../middleware/auth.middleware')
const requireRole = require('../../middleware/role.middleware')
const prisma = require('../../prisma')

const router = Router()
router.use(authenticate)
router.use(requireRole('ADMIN', 'MANAGER'))

router.get('/', async (req, res, next) => {
  try {
    const logs = await prisma.auditLog.findMany({
      orderBy: { createdAt: 'desc' },
      take: 200,
    })
    res.json({ success: true, data: logs })
  } catch (err) { next(err) }
})

module.exports = router