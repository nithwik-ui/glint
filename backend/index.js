import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';
import path from 'path';
import crypto from 'crypto';
import { fileURLToPath } from 'url';
import wallpaperRouter from './routes/wallpapers.js';

// Setup environment variables
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.join(__dirname, '.env') });

const app = express();
const PORT = process.env.PORT || 3000;

// Security Midlleware
app.use(helmet());
app.use(cors()); // Allow requests from all origins (useful for mobile apps and dev browser environment)
app.use(express.json());

// Rate Limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 300, // Limit each IP to 300 requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests from this IP, please try again after 15 minutes.' }
});
app.use('/api/', limiter);

// V2 Request Verification & Abuse Protection Middleware
const SHARED_SECRET = 'glint_shared_hmac_secret_key_2026_luxury_wallpapers';
const APP_TOKEN = 'glint_premium_secure_session_token_2026';

function verifyRequestSignature(req, res, next) {
  const token = req.headers['x-glint-app-token'];
  const timestamp = req.headers['x-glint-timestamp'];
  const nonce = req.headers['x-glint-nonce'];
  const signature = req.headers['x-glint-signature'];

  // 1. Check basic header presence
  if (!token || !timestamp || !nonce || !signature) {
    return res.status(403).json({ error: 'Forbidden: Missing security headers' });
  }

  // 2. Verify app token
  if (token !== APP_TOKEN) {
    return res.status(403).json({ error: 'Forbidden: Invalid Glint App Token' });
  }

  // 3. Prevent replay attacks: check if timestamp is within 5 minutes (300 seconds)
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const diff = Math.abs(currentTimestamp - parseInt(timestamp));
  if (isNaN(diff) || diff > 300) {
    return res.status(403).json({ error: 'Forbidden: Request expired' });
  }

  // 4. Verify HMAC-SHA256 signature
  // We sign using path + timestamp + nonce
  const path = req.originalUrl.split('?')[0];
  const message = `${path}|${timestamp}|${nonce}`;
  
  const expectedSignature = crypto
    .createHmac('sha256', SHARED_SECRET)
    .update(message)
    .digest('hex');

  if (signature !== expectedSignature) {
    return res.status(403).json({ error: 'Forbidden: Signature verification failed' });
  }

  next();
}

// Healthy route
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date() });
});

// App Proxy Endpoints (Secured with Request Signature verification)
app.use('/api/wallpapers', verifyRequestSignature, wallpaperRouter);

// Error Handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal Server Error' });
});

// Start Server
app.listen(PORT, () => {
  console.log(`Glint Server running on port ${PORT}`);
});
