const { Router } = require('express')
const authenticate = require('../../middleware/auth.middleware')
const requireRole = require('../../middleware/role.middleware')
const prisma = require('../../prisma')

const router = Router()
router.use(authenticate)

router.get('/', async (req, res, next) => {
  try {
    let settings = await prisma.appSettings.findFirst()
    if (!settings) {
      settings = await prisma.appSettings.create({ data: { temperedPrice: 100 } })
    }
    res.json({ success: true, data: settings })
  } catch (err) { next(err) }
})

router.patch('/', requireRole('ADMIN', 'MANAGER'), async (req, res, next) => {
  try {
    let settings = await prisma.appSettings.findFirst()
    if (!settings) {
      settings = await prisma.appSettings.create({ data: req.body })
    } else {
      settings = await prisma.appSettings.update({ where: { id: settings.id }, data: req.body })
    }
    res.json({ success: true, data: settings })
  } catch (err) { next(err) }
})

module.exports = router