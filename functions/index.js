const { onCall } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const functions = require("firebase-functions/v2");
const admin = require("firebase-admin");
const sgMail = require("@sendgrid/mail");

// Definir el secreto
const SENDGRID_API_KEY = defineSecret("SENDGRID_API_KEY");

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

exports.sendOtpEmail = onCall({ secrets: [SENDGRID_API_KEY] }, async (request, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "El usuario no está autenticado.");
  }

  const { email, code } = request.data;

  if (!email || !code) {
    throw new functions.https.HttpsError("invalid-argument", "Faltan email o código.");
  }

  const msg = {
    to: email,
    from: "senemarket.notifications@gmail.com",
    subject: "Tu código OTP de SeneMarket",
    text: `Tu código es: ${code}. Expira en 5 minutos.`,
  };

  try {
    // ✅ Obtener el API key desde process.env (no desde .value())
    sgMail.setApiKey(process.env.SENDGRID_API_KEY);
    await sgMail.send(msg);
    return { success: true };
  } catch (err) {
    console.error("Error al enviar OTP:", err);
    throw new functions.https.HttpsError("internal", "Error al enviar el correo");
  }
});
