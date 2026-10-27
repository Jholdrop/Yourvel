const { test } = require('node:test');
const assert = require('node:assert/strict');
const { validateEntry, validId } = require('../functions/validation');
const entry = { id: 'abc123', placeName: 'São Paulo', memory: 'Uma caminhada.', latitude: -23.5,
  longitude: -46.6, locationSource: 'places', placeProvider: 'open-meteo' };
test('normaliza os textos e preserva coordenadas', () => {
  assert.equal(validateEntry({ ...entry, placeName: '  São Paulo  ' }).placeName, 'São Paulo');
  assert.equal(validateEntry(entry).latitude, -23.5);
});
test('recusa caminhos arbitrários e tipos inválidos', () => {
  for (const id of ['../outro', 'a/b', '', 7, null]) assert.throws(() => validId({ id }));
  assert.throws(() => validateEntry(null));
  assert.throws(() => validateEntry({ ...entry, memory: 1 }));
});
test('valida limites dos textos e coordenadas', () => {
  for (const [field, value] of [['placeName', 'a'], ['placeName', 'a'.repeat(101)], ['memory', ' '],
    ['memory', 'a'.repeat(1001)], ['latitude', 91], ['longitude', -181], ['latitude', NaN], ['longitude', '20']]) {
    assert.throws(() => validateEntry({ ...entry, [field]: value }));
  }
  assert.doesNotThrow(() => validateEntry({ ...entry, latitude: 90, longitude: -180, placeName: 'a'.repeat(100), memory: 'a'.repeat(1000) }));
});
test('só aceita combinações de origem conhecidas', () => {
  assert.throws(() => validateEntry({ ...entry, locationSource: 'device' }));
  assert.doesNotThrow(() => validateEntry({ ...entry, locationSource: 'device', placeProvider: 'device' }));
});
