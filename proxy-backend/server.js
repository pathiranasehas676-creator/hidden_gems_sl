require('dotenv').config();
const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const { GoogleGenAI } = require('@google/genai');
const axios = require('axios'); // We need axios for making proxy requests

const app = express();
const port = process.env.PORT || 3000;

// Initialize Google Gen AI
const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY
});

// Middleware
app.use(helmet()); // Add Security Headers
app.use(cors());
app.use(express.json());

// Security: Verify App Authorization Token
const requireAuth = (req, res, next) => {
  const authHeader = req.headers.authorization;
  const expectedToken = process.env.APP_SECRET || 'tripme-secure-token-123';

  if (!authHeader || !authHeader.startsWith('Bearer ') || authHeader.split(' ')[1] !== expectedToken) {
    return res.status(401).json({ error: 'Unauthorized. Invalid or missing Bearer token.' });
  }
  next();
};

// Rate Limiting to prevent abuse (e.g. 100 requests per 15 minutes per IP)
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: { error: 'Too many requests, please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/', requireAuth, limiter);

// ==========================================
// Proxy: Google Maps Places API (Text Search)
// ==========================================
app.get('/api/maps/places/search', async (req, res) => {
  try {
    const { query } = req.query;
    if (!query) return res.status(400).json({ error: 'Query parameter is required' });

    const apiKey = process.env.GOOGLE_MAPS_API_KEY;
    if (!apiKey) return res.status(500).json({ error: 'Google Maps API Key not configured on server' });

    const url = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${encodeURIComponent(query)}&key=${apiKey}`;

    const response = await axios.get(url);
    res.json(response.data);
  } catch (error) {
    console.error('Maps API Error:', error.response ? error.response.data : error.message);
    res.status(500).json({ error: 'Failed to fetch from Google Maps API' });
  }
});

// ==========================================
// Proxy: Google Maps Directions API
// ==========================================
app.get('/api/maps/directions', async (req, res) => {
  try {
    const { origin, destination, mode } = req.query;
    if (!origin || !destination) return res.status(400).json({ error: 'Origin and destination are required' });

    const apiKey = process.env.GOOGLE_MAPS_API_KEY;
    if (!apiKey) return res.status(500).json({ error: 'Google Maps API Key not configured on server' });

    const pMode = mode || 'driving';
    const url = `https://maps.googleapis.com/maps/api/directions/json?origin=${encodeURIComponent(origin)}&destination=${encodeURIComponent(destination)}&mode=${pMode}&key=${apiKey}`;

    const response = await axios.get(url);
    res.json(response.data);
  } catch (error) {
    console.error('Maps API Error:', error.response ? error.response.data : error.message);
    res.status(500).json({ error: 'Failed to fetch from Google Maps API' });
  }
});


// ==========================================
// AI Recommendations
// ==========================================
app.post('/api/ai/recommendations', async (req, res) => {
  try {
    const { nearbyPlaces, vibeText } = req.body;

    if (!nearbyPlaces || !Array.isArray(nearbyPlaces) || nearbyPlaces.length === 0) {
      return res.status(400).json({ error: 'Valid nearbyPlaces array is required.' });
    }

    const placeDetails = nearbyPlaces.map(p => `- [${p.id}] ${p.name} (${p.category}, ${Number(p.distanceKm).toFixed(1)}km away)`).join("\n");
    const userVibe = vibeText || "Any";

    const prompt = `Here are some places near the user:\n${placeDetails}\n\nThe user's vibe or search query is "${userVibe}".\nRank exactly the top 3 places that best match this query and provide a short, enticing 1-sentence reason why they should visit.\nReturn ONLY valid JSON in this exact format, with no markdown formatting or other text:\n[\n  {"id": "place_id", "reason": "reason here"}\n]`;

    const response = await ai.models.generateContent({
      model: 'gemini-1.5-flash',
      contents: prompt,
    });

    let textResult = response.text || "[]";
    textResult = textResult.replace(/```json/g, '').replace(/```/g, '').trim();

    const jsonResult = JSON.parse(textResult);
    res.json(jsonResult);

  } catch (error) {
    console.error('AI Processing Error:', error);
    res.status(500).json({ error: 'Failed to process AI recommendations.' });
  }
});

// Start Server
app.listen(port, () => {
  console.log(`TripMe API Proxy listening at http://localhost:${port}`);
});
