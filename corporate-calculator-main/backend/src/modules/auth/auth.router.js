const { Router } = require('express')
const bcrypt = require('bcryptjs')
const jwt = require('jsonwebtoken')
const prisma = require('../../prisma')
const ApiError = require('../../utils/ApiError')

const router = Router()

router.post('/register', async (req, res, next) => {
  try {
    const { email, password, fullName } = req.body
    const existing = await prisma.user.findUnique({ where: { email } })
    if (existing) throw new ApiError(400, 'Email already in use')
    const passwordHash = await bcrypt.hash(password, 12)
    const user = await prisma.user.create({
      data: { email, passwordHash, fullName, role: 'WORKER' },
    })
    res.status(201).json({ success: true, data: { id: user.id, email: user.email, fullName: user.fullName, role: user.role } })
  } catch (err) { next(err) }
})

router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body
    const user = await prisma.user.findUnique({ where: { email } })
    if (!user) throw new ApiError(401, 'Invalid credentials')
    const valid = await bcrypt.compare(password, user.passwordHash)
    if (!valid) throw new ApiError(401, 'Invalid credentials')
    const accessToken = jwt.sign(
      { userId: user.id, role: user.role },
      process.env.JWT_ACCESS_SECRET,
      { expiresIn: '15m' }
    )
    const refreshToken = jwt.sign(
      { userId: user.id },
      process.env.JWT_REFRESH_SECRET,
      { expiresIn: '30d' }
    )
    await prisma.refreshToken.create({
      data: {
        userId: user.id,
        tokenHash: refreshToken,
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      },
    })
    res.json({
      success: true,
      data: {
        accessToken,
        refreshToken,
        user: { id: user.id, email: user.email, fullName: user.fullName, role: user.role },
      },
    })
  } catch (err) { next(err) }
})

router.post('/refresh', async (req, res, next) => {
  try {
    const { refreshToken } = req.body
    if (!refreshToken) throw new ApiError(401, 'No refresh token')
    const payload = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET)
    const stored = await prisma.refreshToken.findFirst({
      where: { userId: payload.userId, tokenHash: refreshToken, expiresAt: { gt: new Date() } },
    })
    if (!stored) throw new ApiError(401, 'Invalid refresh token')
    const user = await prisma.user.findUnique({ where: { id: payload.userId } })
    const accessToken = jwt.sign(
      { userId: user.id, role: user.role },
      process.env.JWT_ACCESS_SECRET,
      { expiresIn: '15m' }
    )
    const newRefreshToken = jwt.sign(
      { userId: user.id },
      process.env.JWT_REFRESH_SECRET,
      { expiresIn: '30d' }
    )
    await prisma.refreshToken.delete({ where: { id: stored.id } })
    await prisma.refreshToken.create({
      data: {
        userId: user.id,
        tokenHash: newRefreshToken,
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      },
    })
    res.json({ success: true, data: { accessToken, refreshToken: newRefreshToken } })
  } catch (err) { next(err) }
})

router.post('/logout', async (req, res, next) => {
  try {
    const { refreshToken } = req.body
    if (refreshToken) {
      await prisma.refreshToken.deleteMany({ where: { tokenHash: refreshToken } })
    }
    res.json({ success: true })
  } catch (err) { next(err) }
})

module.exports = router