const { test, before, after } = require('node:test');
const fs = require('node:fs');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, deleteDoc, GeoPoint, serverTimestamp, Timestamp } = require('firebase/firestore');
let env;
before(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-yourvel',
    firestore: { rules: fs.readFileSync('firestore.rules', 'utf8') } });
  await env.clearFirestore();
});
after(async () => env?.cleanup());
const data = (uid, id) => ({ placeName: 'Recife', memory: 'Uma viagem especial',
  imagePath: `users/${uid}/travel_entries/${id}/photo`, imageStorage: 'local',
  coordinates: new GeoPoint(-8, -34), locationSource: 'places',
  placeProvider: 'open-meteo', createdAt: serverTimestamp() });
const entry = (ctx, id) => doc(ctx.firestore(), `users/alice/travel_entries/${id}`);
test('owner CRUD; other users and anonymous denied; updates denied', async () => {
  const owner = env.authenticatedContext('alice');
  const other = env.authenticatedContext('bob');
  const anon = env.unauthenticatedContext();
  await assertSucceeds(setDoc(entry(owner, 'one'), data('alice', 'one')));
  await assertSucceeds(getDoc(entry(owner, 'one')));
  for (const ctx of [other, anon]) {
    await assertFails(getDoc(entry(ctx, 'one')));
    await assertFails(setDoc(entry(ctx, 'two'), data('alice', 'two')));
    await assertFails(deleteDoc(entry(ctx, 'one')));
  }
  await assertFails(setDoc(entry(owner, 'one'), data('alice', 'one')));
  await assertSucceeds(deleteDoc(entry(owner, 'one')));
});
test('reject invalid paths, extra fields, invalid types and forged dates', async () => {
  const owner = env.authenticatedContext('alice');
  const changes = [
    { imagePath: 'users/bob/travel_entries/invalid/photo' },
    { imagePath: '../photo' }, { imageStorage: 'cloud' },
    { coordinates: 'invalid' }, { memory: '' }, { placeName: 'x'.repeat(101) },
    { createdAt: Timestamp.fromMillis(0) }, { extra: true },
  ];
  for (let i = 0; i < changes.length; i++) {
    const id = `invalid${i}`;
    await assertFails(setDoc(entry(owner, id), { ...data('alice', id), ...changes[i] }));
  }
});
