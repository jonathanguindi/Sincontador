# Activar verificación de correo por código (anti cuentas falsas)

La app ya tiene la pantalla para ingresar el código (se activa sola cuando
Supabase exige confirmación). Solo faltan **2 ajustes en el panel de Supabase**.

## Paso 1 — Exigir confirmación de correo
1. Supabase → **Authentication** → **Sign In / Providers** (o **Providers → Email**).
2. Activa el interruptor **"Confirm email"** (Confirmar correo).
3. Guarda.

Con esto, quien se registre **no podrá entrar** hasta verificar su correo.

## Paso 2 — Que el correo traiga un CÓDIGO (no un enlace)
Por defecto Supabase manda un enlace; nosotros queremos un código de 6 dígitos.

1. Supabase → **Authentication** → **Email Templates** → pestaña **"Confirm signup"**.
2. Reemplaza el contenido por esto (usa `{{ .Token }}`, que es el código):

```html
<h2>Confirma tu cuenta en SinContador</h2>
<p>Hola, gracias por registrarte. Tu código de verificación es:</p>
<p style="font-size:32px;font-weight:bold;letter-spacing:8px;color:#102650">{{ .Token }}</p>
<p>Escríbelo en la app para activar tu cuenta. El código vence en 1 hora.</p>
<p style="color:#888;font-size:12px">Si tú no creaste esta cuenta, ignora este correo.</p>
```

3. Guarda.

(Opcional) En **Authentication → Settings** puedes ajustar el tiempo de
expiración del código (**Email OTP Expiration**), por defecto 1 hora.

## Cómo queda el flujo
1. La persona se registra → la app muestra "Verifica tu correo" y un campo para el código.
2. Le llega el correo con el código de 6 dígitos.
3. Lo escribe → su cuenta se activa y entra. (Solo la primera vez.)

## Probarlo
Regístrate con un correo real tuyo: debe pedirte el código y, al ponerlo, entrar.
Si pones un correo falso, nunca llega el código → no se crea cuenta usable. ✅

## Nota
Estos correos de verificación los envía **Supabase** (no Resend). Si quieres
que se vean con tu marca, en Authentication → Settings → SMTP puedes configurar
un SMTP propio (por ejemplo el de Resend), pero no es obligatorio para que
funcione la verificación.
