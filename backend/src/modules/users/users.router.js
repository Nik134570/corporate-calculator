const { Router } = require('express')
const bcrypt = require('bcryptjs')
const crypto = require('crypto')
const authenticate = require('../../middleware/auth.middleware')
const requireRole = require('../../middleware/role.middleware')
const prisma = require('../../prisma')

const router = Router()
router.use(authenticate)
router.use(requireRole('ADMIN', 'MANAGER'))

router.get('/', async (req, res, next) => {
  try {
    const users = await prisma.user.findMany({
      select: {
        id: true, email: true, fullName: true,
        role: true, isActive: true, createdAt: true,
      },
      orderBy: { createdAt: 'desc' },
    })
    res.json({ success: true, data: users })
  } catch (err) { next(err) }
})

router.post('/', async (req, res, next) => {
  try {
    const { email, fullName, role = 'WORKER' } = req.body

    const existing = await prisma.user.findUnique({ where: { email } })
    if (existing) {
      return res.status(400).json({ success: false, message: 'Email уже используется' })
    }

    const password = crypto.randomBytes(10).toString('hex')

    const passwordHash = await bcrypt.hash(password, 12)

    const user = await prisma.user.create({
      data: { email, fullName, role, passwordHash },
      select: { id: true, email: true, fullName: true, role: true, isActive: true, createdAt: true },
    })

    res.status(201).json({ success: true, data: { ...user, password } })
  } catch (err) { next(err) }
})

router.patch('/:id', async (req, res, next) => {
  try {
    const { role, isActive } = req.body
    const user = await prisma.user.update({
      where: { id: req.params.id },
      data: { ...(role && { role }), ...(isActive !== undefined && { isActive }) },
      select: { id: true, email: true, fullName: true, role: true, isActive: true },
    })
    res.json({ success: true, data: user })
  } catch (err) { next(err) }
})

module.exports = router