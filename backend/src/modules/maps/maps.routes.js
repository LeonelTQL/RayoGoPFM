const { Router } = require('express');
const { z } = require('zod');
const { requireAuth } = require('../../middlewares/auth.middleware');

const router = Router();
const GOOGLE_MAPS_SERVER_KEY = process.env.GOOGLE_MAPS_SERVER_KEY;
const GOOGLE_MAPS_COUNTRY = process.env.GOOGLE_MAPS_COUNTRY || 'ec';
const GOOGLE_MAPS_LANGUAGE = process.env.GOOGLE_MAPS_LANGUAGE || 'es';

function requireMapsKey(res) {
  if (!GOOGLE_MAPS_SERVER_KEY) {
    res.status(500).json({ message: 'GOOGLE_MAPS_SERVER_KEY no está configurada en el backend.' });
    return false;
  }
  return true;
}

function parseNumber(value) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

async function googleGet(url) {
  const response = await fetch(url);
  const json = await response.json();
  if (!response.ok) {
    throw new Error(json.error_message || json.error?.message || 'Error consultando Google Maps.');
  }
  return json;
}

function toLatLngLiteral(value) {
  return {
    latitude: Number(value.lat ?? value.latitude),
    longitude: Number(value.lng ?? value.longitude),
  };
}

router.get('/geocode', requireAuth, async (req, res, next) => {
  try {
    if (!requireMapsKey(res)) return;
    const address = req.query.address?.toString()?.trim();
    if (!address || address.length < 3) {
      return res.status(400).json({ message: 'El parámetro address es obligatorio.' });
    }

    const url = new URL('https://maps.googleapis.com/maps/api/geocode/json');
    url.searchParams.set('address', address);
    url.searchParams.set('language', GOOGLE_MAPS_LANGUAGE);
    url.searchParams.set('components', `country:${GOOGLE_MAPS_COUNTRY}`);
    url.searchParams.set('key', GOOGLE_MAPS_SERVER_KEY);

    const json = await googleGet(url);
    const results = (json.results || []).map((item) => ({
      formattedAddress: item.formatted_address,
      latitude: item.geometry.location.lat,
      longitude: item.geometry.location.lng,
      placeId: item.place_id,
    }));

    return res.json({ results });
  } catch (error) {
    return next(error);
  }
});

router.get('/reverse-geocode', requireAuth, async (req, res, next) => {
  try {
    if (!requireMapsKey(res)) return;
    const lat = parseNumber(req.query.lat);
    const lng = parseNumber(req.query.lng);
    if (lat === null || lng === null || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return res.status(400).json({ message: 'lat y lng son obligatorios y deben ser coordenadas válidas.' });
    }

    const url = new URL('https://maps.googleapis.com/maps/api/geocode/json');
    url.searchParams.set('latlng', `${lat},${lng}`);
    url.searchParams.set('language', GOOGLE_MAPS_LANGUAGE);
    url.searchParams.set('key', GOOGLE_MAPS_SERVER_KEY);

    const json = await googleGet(url);
    const first = (json.results || [])[0];
    if (!first) return res.json({ result: null });

    return res.json({
      result: {
        formattedAddress: first.formatted_address,
        latitude: first.geometry.location.lat,
        longitude: first.geometry.location.lng,
        placeId: first.place_id,
      },
    });
  } catch (error) {
    return next(error);
  }
});

router.get('/places/autocomplete', requireAuth, async (req, res, next) => {
  try {
    if (!requireMapsKey(res)) return;
    const input = req.query.input?.toString()?.trim();
    if (!input || input.length < 2) {
      return res.json({ predictions: [] });
    }

    const url = new URL('https://maps.googleapis.com/maps/api/place/autocomplete/json');
    url.searchParams.set('input', input);
    url.searchParams.set('language', GOOGLE_MAPS_LANGUAGE);
    url.searchParams.set('components', `country:${GOOGLE_MAPS_COUNTRY}`);
    url.searchParams.set('key', GOOGLE_MAPS_SERVER_KEY);

    const json = await googleGet(url);
    const predictions = (json.predictions || []).map((item) => ({
      placeId: item.place_id,
      description: item.description,
      mainText: item.structured_formatting?.main_text || item.description,
      secondaryText: item.structured_formatting?.secondary_text || '',
    }));

    return res.json({ predictions });
  } catch (error) {
    return next(error);
  }
});

router.get('/places/details/:placeId', requireAuth, async (req, res, next) => {
  try {
    if (!requireMapsKey(res)) return;
    const placeId = req.params.placeId;
    if (!placeId) return res.status(400).json({ message: 'placeId es obligatorio.' });

    const url = new URL('https://maps.googleapis.com/maps/api/place/details/json');
    url.searchParams.set('place_id', placeId);
    url.searchParams.set('language', GOOGLE_MAPS_LANGUAGE);
    url.searchParams.set('fields', 'place_id,formatted_address,geometry,name');
    url.searchParams.set('key', GOOGLE_MAPS_SERVER_KEY);

    const json = await googleGet(url);
    if (!json.result) return res.status(404).json({ message: 'Lugar no encontrado.' });

    return res.json({
      place: {
        placeId: json.result.place_id,
        name: json.result.name,
        formattedAddress: json.result.formatted_address,
        latitude: json.result.geometry.location.lat,
        longitude: json.result.geometry.location.lng,
      },
    });
  } catch (error) {
    return next(error);
  }
});


const routeSchema = z.object({
  origin: z.object({ lat: z.number().min(-90).max(90), lng: z.number().min(-180).max(180) }),
  destination: z.object({ lat: z.number().min(-90).max(90), lng: z.number().min(-180).max(180) }),
  travelMode: z.enum(['DRIVE', 'TWO_WHEELER', 'WALK', 'BICYCLE']).default('DRIVE'),
});

function encodePolyline(points) {
  let lastLat = 0;
  let lastLng = 0;
  let result = '';

  function encodeValue(value) {
    let shifted = value < 0 ? ~(value << 1) : value << 1;
    let output = '';
    while (shifted >= 0x20) {
      output += String.fromCharCode((0x20 | (shifted & 0x1f)) + 63);
      shifted >>= 5;
    }
    output += String.fromCharCode(shifted + 63);
    return output;
  }

  for (const point of points) {
    const lat = Math.round(Number(point.lat) * 1e5);
    const lng = Math.round(Number(point.lng) * 1e5);
    result += encodeValue(lat - lastLat);
    result += encodeValue(lng - lastLng);
    lastLat = lat;
    lastLng = lng;
  }

  return result;
}

function haversineDistanceMeters(a, b) {
  const radius = 6371000;
  const toRadians = (degrees) => (degrees * Math.PI) / 180;
  const lat1 = toRadians(Number(a.lat));
  const lat2 = toRadians(Number(b.lat));
  const deltaLat = toRadians(Number(b.lat) - Number(a.lat));
  const deltaLng = toRadians(Number(b.lng) - Number(a.lng));

  const sinLat = Math.sin(deltaLat / 2);
  const sinLng = Math.sin(deltaLng / 2);
  const h = sinLat * sinLat + Math.cos(lat1) * Math.cos(lat2) * sinLng * sinLng;
  return Math.round(radius * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h)));
}

function directFallbackRoute(origin, destination, reason = 'fallback') {
  const distanceMeters = haversineDistanceMeters(origin, destination);
  const durationSeconds = Math.max(60, Math.round(distanceMeters / 7)); // aproximado para demo visual
  return {
    distanceMeters,
    duration: `${durationSeconds}s`,
    encodedPolyline: encodePolyline([origin, destination]),
    provider: 'direct_fallback',
    fallback: true,
    reason,
  };
}

function directionsMode(travelMode) {
  if (travelMode === 'WALK') return 'walking';
  if (travelMode === 'BICYCLE') return 'bicycling';
  return 'driving';
}

async function computeRouteWithDirectionsApi(origin, destination, travelMode) {
  const url = new URL('https://maps.googleapis.com/maps/api/directions/json');
  url.searchParams.set('origin', `${origin.lat},${origin.lng}`);
  url.searchParams.set('destination', `${destination.lat},${destination.lng}`);
  url.searchParams.set('mode', directionsMode(travelMode));
  url.searchParams.set('language', GOOGLE_MAPS_LANGUAGE);
  url.searchParams.set('units', 'metric');
  url.searchParams.set('key', GOOGLE_MAPS_SERVER_KEY);

  const response = await fetch(url);
  const json = await response.json();

  if (json.status !== 'OK') {
    const error = new Error('Directions API no pudo calcular la ruta.');
    error.googleStatus = json.status;
    error.apiMessage = json.error_message || json.status;
    error.googlePayload = json;
    throw error;
  }

  const route = json.routes?.[0];
  const leg = route?.legs?.[0];
  if (!route || !leg || !route.overview_polyline?.points) {
    throw new Error('Directions API no devolvió una ruta válida.');
  }

  return {
    distanceMeters: Number(leg.distance?.value || 0),
    duration: `${Number(leg.duration?.value || 0)}s`,
    encodedPolyline: route.overview_polyline.points,
    provider: 'directions_api',
    fallback: false,
  };
}

async function computeRouteWithRoutesApi(origin, destination, travelMode) {
  const response = await fetch('https://routes.googleapis.com/directions/v2:computeRoutes', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': GOOGLE_MAPS_SERVER_KEY,
      'X-Goog-FieldMask': 'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline',
    },
    body: JSON.stringify({
      origin: { location: { latLng: toLatLngLiteral(origin) } },
      destination: { location: { latLng: toLatLngLiteral(destination) } },
      travelMode,
      routingPreference: travelMode === 'DRIVE' || travelMode === 'TWO_WHEELER' ? 'TRAFFIC_AWARE' : undefined,
      languageCode: GOOGLE_MAPS_LANGUAGE,
      units: 'METRIC',
    }),
  });

  const json = await response.json();
  if (!response.ok) {
    const error = new Error('Routes API no pudo calcular la ruta.');
    error.status = response.status;
    error.apiMessage = json.error?.message;
    error.googlePayload = json;
    throw error;
  }

  const route = json.routes?.[0];
  if (!route) return null;

  return {
    distanceMeters: route.distanceMeters || 0,
    duration: route.duration || null,
    encodedPolyline: route.polyline?.encodedPolyline || null,
    provider: 'routes_api',
    fallback: false,
  };
}

router.post('/route', requireAuth, async (req, res) => {
  if (!requireMapsKey(res)) return;

  const parsed = routeSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ message: 'Datos inválidos para calcular la ruta.', errors: parsed.error.errors });
  }

  const { origin, destination, travelMode } = parsed.data;

  try {
    const route = await computeRouteWithRoutesApi(origin, destination, travelMode);
    if (route) return res.json({ route });
  } catch (error) {
    console.warn('[maps/route] Routes API falló, intentando Directions API:', error.message);
  }

  try {
    const route = await computeRouteWithDirectionsApi(origin, destination, travelMode);
    return res.json({ route });
  } catch (error) {
    console.warn('[maps/route] Directions API falló, usando ruta directa:', error.message);
    return res.json({
      route: directFallbackRoute(origin, destination, error.googleStatus || error.apiMessage || error.message),
    });
  }
});

module.exports = router;
