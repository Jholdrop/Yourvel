'use strict';

const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, GeoPoint } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { validateEntry, validId } = require('./validation');

initializeApp();
const db = getFirestore();

function requireUser(request) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Entre na sua conta para continuar.');
  return request.auth.uid;
}
function validate(fn, data) {
  try { return fn(data); } catch (error) { throw new HttpsError('invalid-argument', error.message); }
}

// Admin SDK não depende das regras do cliente. Toda entrada é validada aqui.
exports.finalizeEntry = onCall({ region: 'us-central1', maxInstances: 5 }, async (request) => {
  const uid = requireUser(request);
  const data = validate(validateEntry, request.data);
  const doc = db.doc(`users/${uid}/travel_entries/${data.id}`);
  if ((await doc.get()).exists) return { id: data.id };
  const path = `users/${uid}/travel_entries/${data.id}/photo`;
  const bucket = getStorage().bucket();
  const file = bucket.file(path);
  let metadata;
  try { [metadata] = await file.getMetadata(); }
  catch (error) {
    if (Number(error.code) === 404) throw new HttpsError('failed-precondition', 'Envie a foto antes de salvar.');
    throw new HttpsError('unavailable', 'Não foi possível verificar a foto. Tente novamente.');
  }
  if (!['image/jpeg', 'image/png'].includes(metadata.contentType) || Number(metadata.size) <= 0 || Number(metadata.size) > 5242880) {
    throw new HttpsError('invalid-argument', 'Foto inválida ou maior que 5 MiB.');
  }
  // Regravar via API administrativa cria uma geração sem tokens públicos.
  // Também funciona no emulador, que não remove tokens com metadata=null.
  const [bytes] = await file.download();
  const png = bytes.length >= 8 && bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]));
  const jpeg = bytes.length >= 3 && bytes[0] === 255 && bytes[1] === 216 && bytes[2] === 255;
  if ((metadata.contentType === 'image/png' && !png) || (metadata.contentType === 'image/jpeg' && !jpeg)) {
    throw new HttpsError('invalid-argument', 'O conteúdo da foto não corresponde ao formato informado.');
  }
  await file.save(bytes, { resumable: false, metadata: {
    contentType: metadata.contentType, cacheControl: 'private, no-store', metadata: {},
  } });
  const imageUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(path)}?alt=media`;
  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(doc);
    if (!existing.exists) transaction.create(doc, {
      ownerId: uid, placeName: data.placeName, memory: data.memory,
      imagePath: path, imageUrl, coordinates: new GeoPoint(data.latitude, data.longitude),
      locationSource: data.locationSource, placeProvider: data.placeProvider,
      createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(), schemaVersion: 1,
    });
  });
  return { id: data.id };
});

exports.deleteEntry = onCall({ region: 'us-central1', maxInstances: 5 }, async (request) => {
  const uid = requireUser(request);
  const id = validate(validId, request.data);
  // O caminho é calculado com a identidade autenticada, nunca recebido do cliente.
  const path = `users/${uid}/travel_entries/${id}/photo`;
  await getStorage().bucket().file(path).delete({ ignoreNotFound: true });
  await db.doc(`users/${uid}/travel_entries/${id}`).delete();
  return { deleted: true };
});
