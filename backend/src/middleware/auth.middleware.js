const jwt = require('jsonwebtoken')
const prisma = require('../prisma')

module.exports = async (req, res, next) => {
  const authHeader = req.headers.authorization
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, message: 'Unauthorized' })
  }
  const token = authHeader.split(' ')[1]
  try {
    const payload = jwt.verify(token, process.env.JWT_ACCESS_SECRET)
    const user = await prisma.user.findUnique({
      where: { id: payload.userId },
      select: { fullName: true, isActive: true }
    })
    if (!user || !user.isActive) {
      return res.status(401).json({ success: false, message: 'Unauthorized' })
    }
    req.user = { ...payload, fullName: user.fullName }
    next()
  } catch {
    res.status(401).json({ success: false, message: 'Invalid token' })
  }
}