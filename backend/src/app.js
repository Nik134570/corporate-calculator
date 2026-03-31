const express = require('express')
const helmet = require('helmet')
const cors = require('cors')
const rateLimit = require('express-rate-limit')
const errorMiddleware = require('./middleware/error.middleware')
const authRouter = require('./modules/auth/auth.router')
const materialsRouter = require('./modules/materials/materials.router')
const calculationsRouter = require('./modules/calculations/calculations.router')
const usersRouter = require('./modules/users/users.router')
const catalogRouter = require('./modules/catalog/catalog.router')
const settingsRouter = require('./modules/settings/settings.router')
const auditRouter = require('./modules/audit/audit.router')

const app = express()

app.use(helmet())
const allowedOrigin = process.env.ALLOWED_ORIGIN || ''
app.use(cors({
  origin: (origin, callback) => {
    if (!origin) return callback(null, true)
    if (origin.startsWith('http://localhost')) return callback(null, true)
    if (allowedOrigin && origin === allowedOrigin) return callback(null, true)
    if (origin.endsWith('.railway.app')) return callback(null, true)
    callback(new Error('Not allowed by CORS'))
  },
  credentials: true,
}))
app.use(express.json())

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  message: { success: false, message: 'Too many requests' },
})

app.use('/api/v1/auth', authLimiter, authRouter)
app.use('/api/v1/materials', materialsRouter)
app.use('/api/v1/calculations', calculationsRouter)
app.use('/api/v1/users', usersRouter)
app.use('/api/v1/catalog', catalogRouter)
app.use('/api/v1/settings', settingsRouter)

app.use('/api/v1/audit', auditRouter)
app.get('/health', (req, res) => res.json({ status: 'ok' }))
app.use(errorMiddleware)

module.exports = app