// index.js

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const sgMail = require("@sendgrid/mail");

// Solo si necesitas inicializar con un Service Account
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Configuramos SendGrid con la API Key almacenada en variables de entorno
sgMail.setApiKey(functions.config().sendgrid.key);

/**
 * notifyPriceChange
 *
 * Se ejecuta cuando se actualiza un documento en la colección "products".
 * Verifica si el precio cambió y, si es así, envía un correo a todos los
 * usuarios que tienen el producto en sus "favoritos".
 */
exports.notifyPriceChange = functions.firestore
  .document("products/{productId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // 1. Verificar si el precio cambió
    if (beforeData.price <= afterData.price) {
      console.log("El precio no ha bajado.");
      return null;
    }

    // 2. Extraer información del producto
    const productId = context.params.productId;
    const newPrice = afterData.price;
    const productName = afterData.name || "Tu producto";

    console.log(
      Producto ${productId}: precio antes = ${beforeData.price}, precio ahora = ${newPrice}
    );

    // 3. Obtener la lista de usuarios que tienen este producto como favorito
    const favoritedBy = afterData.favoritedBy || [];
    if (favoritedBy.length === 0) {
      console.log("No hay usuarios favoritos para este producto.");
      return null;
    }

    // 4. Recolectar los correos electrónicos de esos usuarios
    const emails = [];
    const userPromises = favoritedBy.map(async (userId) => {
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      if (userDoc.exists) {
        const userData = userDoc.data();
        if (userData.email) {
          emails.push(userData.email);
        }
      }
    });
    await Promise.all(userPromises);

    console.log("Correos obtenidos:", emails);

    if (emails.length === 0) {
      console.log("No se encontraron correos para enviar notificaciones.");
      return null;
    }

    // 5. Enviar un correo a cada usuario con SendGrid
    const mailPromises = emails.map(async (email) => {
      const msg = {
        to: email,
        from: "senemarket.notifications@gmail.com", // <--- Cambia esto a tu correo verificado en SendGrid
        subject: Uno de tus productos favoritos bajó de precio en SeneMarket: ${productName},

        text: Hola, el precio de tu producto favorito ${productName} bajó de precio. Pasó de estar de $${beforeData.price} a $${newPrice}. Este es un gran momento para comprar, no dudes en aprovechar este cambio,
      };

      try {
        await sgMail.send(msg);
        console.log(Correo enviado correctamente a: ${email});
      } catch (error) {
        console.error(Error al enviar el correo a ${email}:, error);
      }
    });

    await Promise.all(mailPromises);

    return null;
  });