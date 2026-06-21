// =============================================================================
// Edge Function: tilopay-webhook
// =============================================================================
// Objetivo de seguridad (riesgo C1 de la auditoría):
// Hoy la SUSCRIPCIÓN se activa desde el navegador leyendo parámetros de la URL
// (?suscripcion=success&code=1&plan=anual). Eso es manipulable: cualquiera puede
// abrir esa URL y activarse el plan sin pagar.
//
// La solución correcta: que SOLO el servidor active la suscripción, confirmando
// el pago directamente con Tilopay. Esta función recibe la notificación
// (webhook) de Tilopay, valida que el pago es real, y escribe en `suscripciones`
// usando la SERVICE ROLE (que ignora RLS). El navegador nunca más decide esto.
//
// -----------------------------------------------------------------------------
// CÓMO DESPLEGARLA (resumen; ver supabase/GUIA-TILOPAY.md para el paso a paso):
//   1. Instala Supabase CLI y enlaza el proyecto:  supabase link
//   2. Define los secretos:
//        supabase secrets set TILOPAY_WEBHOOK_TOKEN=algo-secreto-largo
//        supabase secrets set TILOPAY_API_KEY=...        (tu API key de Tilopay)
//        supabase secrets set TILOPAY_API_USER=...       (si Tilopay lo requiere)
//        supabase secrets set TILOPAY_API_PASSWORD=...
//      (SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY ya existen automáticamente.)
//   3. Deploy:   supabase functions deploy tilopay-webhook --no-verify-jwt
//   4. En el panel de Tilopay, configura la URL de notificación/webhook:
//        https://rxmyewcccqencycjqxpe.functions.supabase.co/tilopay-webhook?token=EL-MISMO-TOKEN
//
// ⚠️ IMPORTANTE: el formato EXACTO del payload de Tilopay (nombres de campos,
//    firma) debe ajustarse a su documentación. Abajo está marcado con  // AJUSTAR
//    cada punto que depende de Tilopay. Lo dejé con nombres razonables y una
//    verificación por token compartido; lo ideal es además re-consultar el estado
//    del pago contra la API de Tilopay antes de activar.
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    // --- 1) Verificar que la llamada viene de Tilopay (no de un atacante) -----
    // Mecanismo simple: un token secreto compartido en la URL del webhook.
    const url = new URL(req.url);
    const token = url.searchParams.get("token");
    const expected = Deno.env.get("TILOPAY_WEBHOOK_TOKEN");
    if (!expected || token !== expected) {
      return new Response("Unauthorized", { status: 401 });
    }

    const payload = await req.json().catch(() => ({}));

    // --- 2) Extraer datos del pago -------------------------------------------
    // AJUSTAR: nombres de campos según el payload real de Tilopay.
    const code = String(payload.code ?? payload.status ?? "");      // AJUSTAR
    const orderNumber = payload.orderNumber ?? payload.order ?? null; // AJUSTAR
    const userId = payload.userId ?? payload.reference ?? null;       // AJUSTAR (debe identificar al usuario)
    const plan = (payload.plan === "anual" || payload.plan === "mensual")
      ? payload.plan : "mensual";                                     // AJUSTAR

    // Solo activamos si el pago fue aprobado.
    const aprobado = code === "1" || code === "approved" || code === "success"; // AJUSTAR
    if (!aprobado || !userId) {
      // Respondemos 200 para que Tilopay no reintente infinitamente,
      // pero no activamos nada.
      return new Response(JSON.stringify({ ok: true, activated: false }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    // --- 3) (Recomendado) Re-verificar el pago contra la API de Tilopay ------
    // En vez de confiar en el payload, lo más seguro es preguntarle a Tilopay
    // "¿la orden X está realmente pagada?". Descomenta y ajusta a su API:
    //
    // const verify = await fetch(`https://app.tilopay.com/api/v1/payment/${orderNumber}`, {
    //   headers: { "Authorization": `Bearer ${Deno.env.get("TILOPAY_API_KEY")}` },
    // });
    // const vJson = await verify.json();
    // if (vJson.status !== "paid") return new Response("not paid", { status: 200 });

    // --- 4) Activar la suscripción con SERVICE ROLE (ignora RLS) --------------
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const ahora = new Date();
    const proximoPago = new Date(ahora);
    if (plan === "anual") proximoPago.setFullYear(proximoPago.getFullYear() + 1);
    else proximoPago.setMonth(proximoPago.getMonth() + 1);

    const { error } = await supabase
      .from("suscripciones")
      .update({
        plan,
        estado: "activa",
        proximo_pago: proximoPago.toISOString(),
        tilopay_subscription_id: orderNumber,
      })
      .eq("user_id", userId);

    if (error) {
      console.error("Error activando suscripción:", error);
      return new Response("DB error", { status: 500 });
    }

    return new Response(JSON.stringify({ ok: true, activated: true }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("Webhook error:", e);
    return new Response("Error", { status: 500 });
  }
});
