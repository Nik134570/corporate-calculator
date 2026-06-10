const { Router } = require('express')
const authenticate = require('../../middleware/auth.middleware')
const prisma = require('../../prisma')

const router = Router()
router.use(authenticate)

router.get('/', async (req, res, next) => {
  try {
    const notifications = await prisma.notification.findMany({
      where: { userId: req.user.userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    })
    const unreadCount = notifications.filter(n => !n.isRead).length
    res.json({ success: true, data: notifications, unreadCount })
  } catch (err) { next(err) }
})

router.patch('/read-all', async (req, res, next) => {
  try {
    await prisma.notification.updateMany({
      where: { userId: req.user.userId, isRead: false },
      data: { isRead: true },
    })
    res.json({ success: true })
  } catch (err) { next(err) }
})

router.patch('/:id/read', async (req, res, next) => {
  try {
    await prisma.notification.update({
      where: { id: req.params.id },
      data: { isRead: true },
    })
    res.json({ success: true })
  } catch (err) { next(err) }
})

module.exports = router
