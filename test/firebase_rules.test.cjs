const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { initializeApp, deleteApp } = require('firebase/app');
const { getAuth, connectAuthEmulator, createUserWithEmailAndPassword } = require('firebase/auth');
const { getFirestore, connectFirestoreEmulator, doc, getDoc, setDoc, deleteDoc, GeoPoint } = require('firebase/firestore');
const { getStorage, connectStorageEmulator, ref, uploadBytes, getBytes, getDownloadURL, updateMetadata } = require('firebase/storage');
const { getFunctions, connectFunctionsEmulator, httpsCallable } = require('firebase/functions');

const projectId = 'demo-yourvel';
let env;
const apps = [];
const photo = new Uint8Array(Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a0ioAAAAASUVORK5CYII=', 'base64'));
before(async () => {
  env = await initializeTestEnvironment({ projectId,
    firestore: { rules: fs.readFileSync('firestore.rules', 'utf8') },
    storage: { rules: fs.readFileSync('storage.rules', 'utf8') } });
  await env.clearFirestore();
  await env.clearStorage();
});
after(async () => { await Promise.all(apps.map(deleteApp)); await env?.cleanup(); });

test('Firestore isola leitura e impede gravação direta mesmo pelo dono', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'users/alice/travel_entries/one'), { placeName: 'Recife' });
  });
  await assertSucceeds(getDoc(doc(env.authenticatedContext('alice').firestore(), 'users/alice/travel_entries/one')));
  await assertFails(getDoc(doc(env.authenticatedContext('bob').firestore(), 'users/alice/travel_entries/one')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'users/alice/travel_entries/one')));
  await assertFails(setDoc(doc(env.authenticatedContext('alice').firestore(), 'users/alice/travel_entries/new'), { ownerId: 'alice' }));
  await assertFails(deleteDoc(doc(env.authenticatedContext('alice').firestore(), 'users/alice/travel_entries/one')));
});

test('Storage limita proprietário, MIME, tamanho e alteração dos tokens', async () => {
  const owner = env.authenticatedContext('alice').storage();
  await assertSucceeds(uploadBytes(ref(owner, 'users/alice/travel_entries/photo/photo'), photo, { contentType: 'image/png' }));
  await assertFails(getBytes(ref(env.authenticatedContext('bob').storage(), 'users/alice/travel_entries/photo/photo')));
  await assertFails(getBytes(ref(env.unauthenticatedContext().storage(), 'users/alice/travel_entries/photo/photo')));
  await assertFails(uploadBytes(ref(owner, 'users/bob/travel_entries/wrong/photo'), photo, { contentType: 'image/png' }));
  await assertFails(uploadBytes(ref(owner, 'users/alice/travel_entries/bad-type/photo'), photo, { contentType: 'text/plain' }));
  await assertFails(uploadBytes(ref(owner, 'users/alice/travel_entries/too-big/photo'), new Uint8Array(5242881), { contentType: 'image/png' }));
  await assertFails(updateMetadata(ref(owner, 'users/alice/travel_entries/photo/photo'), { customMetadata: { firebaseStorageDownloadTokens: 'public' } }));
  await assertFails(uploadBytes(ref(owner, 'users/alice/travel_entries/photo/photo'), photo, { contentType: 'image/png' }));
});

function client(name) {
  const app = initializeApp({ apiKey: 'demo-key', projectId, appId: '1:123:web:demo', storageBucket: 'demo-yourvel.appspot.com' }, name);
  apps.push(app);
  const auth = getAuth(app); connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
  const db = getFirestore(app); connectFirestoreEmulator(db, '127.0.0.1', 8080);
  const storage = getStorage(app); connectStorageEmulator(storage, '127.0.0.1', 9199);
  const functions = getFunctions(app); connectFunctionsEmulator(functions, '127.0.0.1', 5001);
  return { auth, db, storage, functions };
}

test('fluxo real: conta → upload → função → GeoPoint → privacidade → exclusão idempotente', async () => {
  const alice = client('integration-alice');
  const bob = client('integration-bob');
  await createUserWithEmailAndPassword(alice.auth, `alice-${Date.now()}@test.local`, 'Senha123!');
  await createUserWithEmailAndPassword(bob.auth, `bob-${Date.now()}@test.local`, 'Senha123!');
  const uid = alice.auth.currentUser.uid;
  const path = `users/${uid}/travel_entries/integration/photo`;
  const object = ref(alice.storage, path);
  await uploadBytes(object, photo, { contentType: 'image/png' });
  const tokenUrl = await getDownloadURL(object);
  assert.equal((await fetch(tokenUrl)).status, 200);
  const data = { id: 'integration', placeName: 'Recife', memory: 'Minha viagem.', latitude: -8.05, longitude: -34.9, locationSource: 'places', placeProvider: 'open-meteo' };
  await httpsCallable(alice.functions, 'finalizeEntry', { timeout: 180000 })(data);
  await httpsCallable(alice.functions, 'finalizeEntry')(data);
  const saved = await getDoc(doc(alice.db, `users/${uid}/travel_entries/integration`));
  assert.equal(saved.data().ownerId, uid);
  assert.ok(saved.data().coordinates instanceof GeoPoint);
  assert.equal(saved.data().coordinates.latitude, -8.05);
  assert.ok(!saved.data().imageUrl.includes('token='));
  // URLs antigas não podem abrir a foto depois da finalização.
  const revokedStatus = (await fetch(tokenUrl)).status;
  assert.ok(revokedStatus >= 400 && revokedStatus < 500, `URL pública retornou HTTP ${revokedStatus}`);
  assert.equal((await getBytes(object)).byteLength, photo.byteLength);
  await assertFails(getBytes(ref(bob.storage, path)));
  await assertFails(getDoc(doc(bob.db, `users/${uid}/travel_entries/integration`)));
  await assert.rejects(httpsCallable(bob.functions, 'finalizeEntry')({ ...data, id: 'missing-photo' }), { code: 'functions/failed-precondition' });
  await assert.rejects(httpsCallable(alice.functions, 'finalizeEntry')({ ...data, id: 'invalid', latitude: 999 }), { code: 'functions/invalid-argument' });
  await httpsCallable(alice.functions, 'deleteEntry', { timeout: 180000 })({ id: 'integration' });
  await httpsCallable(alice.functions, 'deleteEntry')({ id: 'integration' });
  assert.equal((await getDoc(doc(alice.db, `users/${uid}/travel_entries/integration`))).exists(), false);
  await assert.rejects(getBytes(object));
});

test('funções rejeitam chamadas anônimas', async () => {
  const anon = client('anonymous-call');
  await assert.rejects(httpsCallable(anon.functions, 'deleteEntry', { timeout: 180000 })({ id: 'x' }), { code: 'functions/unauthenticated' });
});
