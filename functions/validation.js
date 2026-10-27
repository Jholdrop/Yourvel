'use strict';

function validateEntry(data) {
  if (!data || typeof data !== 'object' || Array.isArray(data)) throw new Error('Dados inválidos.');
  if (typeof data.id !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(data.id)) throw new Error('Identificador inválido.');
  const placeName = typeof data.placeName === 'string' ? data.placeName.trim() : '';
  const memory = typeof data.memory === 'string' ? data.memory.trim() : '';
  if (placeName.length < 2 || placeName.length > 100) throw new Error('O local deve ter entre 2 e 100 caracteres.');
  if (memory.length < 1 || memory.length > 1000) throw new Error('A memória deve ter entre 1 e 1000 caracteres.');
  if (typeof data.latitude !== 'number' || !Number.isFinite(data.latitude) || Math.abs(data.latitude) > 90 ||
      typeof data.longitude !== 'number' || !Number.isFinite(data.longitude) || Math.abs(data.longitude) > 180) throw new Error('Coordenadas inválidas.');
  if (!((data.locationSource === 'places' && data.placeProvider === 'open-meteo') ||
      (data.locationSource === 'device' && data.placeProvider === 'device'))) throw new Error('Origem da localização inválida.');
  return { id: data.id, placeName, memory, latitude: data.latitude, longitude: data.longitude,
    locationSource: data.locationSource, placeProvider: data.placeProvider };
}

function validId(data) {
  if (!data || typeof data.id !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(data.id)) throw new Error('Identificador inválido.');
  return data.id;
}

module.exports = { validateEntry, validId };
