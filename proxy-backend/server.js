require('dotenv').config();
const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const { GoogleGenAI } = require('@google/genai');

const app = express();
const port = process.env.PORT || 3000;

// Initialize Google Gen AI
const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY
});

// Middleware
app.use(cors());
app.use(express.json());

// Rate Limiting to prevent abuse (e.g. 50 requests per 15 minutes per IP)
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, 
  max: 50, 
  message: { error: 'Too many requests, please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/', limiter);

// Endpoints
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
