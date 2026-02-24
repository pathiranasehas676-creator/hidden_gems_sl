import os
import requests
import logging

logger = logging.getLogger(__name__)

OPENWEATHER_API_KEY = os.getenv("OPENWEATHER_API_KEY", "")

def get_weather_advisory(city: str) -> str:
    """
    Fetches real-time weather and returns a string advisory for the LLM.
    Falls back to 'Perfect weather' if API fails/missing.
    """
    if not OPENWEATHER_API_KEY:
        return "Weather data unavailable. Assume typical tropical conditions."

    try:
        url = f"https://api.openweathermap.org/data/2.5/weather?q={city},LK&appid={OPENWEATHER_API_KEY}&units=metric"
        response = requests.get(url, timeout=3)
        if response.status_code == 200:
            data = response.json()
            temp = data['main']['temp']
            condition = data['weather'][0]['description']
            main = data['weather'][0]['main']
            
            advisory = f"Current weather in {city}: {temp}°C, {condition}."
            if main in ["Rain", "Drizzle", "Thunderstorm"]:
                advisory += " ALERT: It is currently raining. Strictly prioritize indoor alternatives or transit-heavy plans."
            elif temp > 33:
                advisory += " ALERT: Extreme heat detected. Suggest shaded activities and evening exploration."
            return advisory
    except Exception as e:
        logger.warning(f"Weather API error for {city}: {e}")
    
    return "Weather data unavailable. Assume seasonal defaults."
