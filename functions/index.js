const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Asegúrate de tener el archivo serviceAccountKey.json en la carpeta functions.
// Puedes obtener este archivo desde la consola de Firebase, en la sección de "Service Accounts".
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

exports.notifyPriceChange = functions.firestore
  .document("products/{productId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // Si el precio no cambió, no hacemos nada.
    if (beforeData.price === afterData.price) {
      console.log("El precio no ha cambiado.");
      return null;
    }

    const productId = context.params.productId;
    const newPrice = afterData.price;
    const productName = afterData.name || "Tu producto";

    console.log(`Producto ${productId}: precio antes = ${beforeData.price}, precio ahora = ${newPrice}`);

    // Obtenemos la lista de usuarios que tienen este producto como favorito.
    const favoritedBy = afterData.favoritedBy || [];
    if (favoritedBy.length === 0) {
      console.log("No hay usuarios favoritos para este producto.");
      return null;
    }

    // Recolecta los tokens FCM de esos usuarios.
    const tokens = [];
    const userPromises = favoritedBy.map(async (userId) => {
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      if (userDoc.exists) {
        const token = userDoc.data().fcmToken;
        if (token) {
          tokens.push(token);
        }
      }
    });
    await Promise.all(userPromises);

    console.log("Tokens obtenidos:", tokens);

    if (tokens.length === 0) {
      console.log("No se encontraron tokens FCM para enviar notificaciones.");
      return null;
    }

    // Configura el payload de la notificación.
    const payload = {
      notification: {
        title: "Precio actualizado",
        body: `El precio de ${productName} cambió a $${newPrice}.`,
      },
      data: {
        productId: String(productId), // Aseguramos que productId sea un string.
      },
    };

    try {
      const response = await admin.messaging().sendToDevice(tokens, payload);
      console.log("Notificaciones enviadas:", response);

      // Recorre los resultados para ver si hubo algún error en cada token.
      response.results.forEach((result, index) => {
        if (result.error) {
          console.error(`Error al enviar a ${tokens[index]}: ${result.error.message}`);
        }
      });
    } catch (error) {
      console.error("Error enviando notificaciones:", error.message);
    }

    return null;
  });
