# ⚠️ ARREGLAR: no llega el código (PIN) por correo al iniciar sesión

## Qué está pasando
El código de 6 dígitos lo envía **Supabase** con su correo *por defecto*, que
está limitado a ~3–4 correos por hora para TODO el proyecto y es "solo para
pruebas". Por eso a usuarios reales (como Teófilo) el código llega tarde, cae en
spam, o no llega. Hay que arreglarlo en el panel de Supabase.

---

## OPCIÓN A — La más rápida (recomendada): quitar la verificación por código
Con esto NADIE necesita código: entran directo con **correo + contraseña**.
Además, desbloquea de inmediato a quien ya se había registrado (como Teófilo).

1. Entra a https://supabase.com → tu proyecto **SinContador**.
2. Menú izquierdo: **Authentication** → **Sign In / Providers** → **Email**.
3. **APAGA** el interruptor **"Confirm email"** (Confirmar correo).
4. Dale **Save**.

Listo. Teófilo (y todos) ya pueden entrar con su correo y contraseña, sin código.

> Nota: esto quita la barrera "anti cuentas falsas" que se había activado. Para
> una app de pago como esta no es crítico (Apple la aprobó sin eso, y ya hay
> control por suscripción). Si prefieres MANTENER la verificación, usa la Opción B.

---

## OPCIÓN B — Mantener el código, pero que SÍ llegue (conectar tu Resend)
Ya usas **Resend** para los recibos (`reportes@sincontador.app`). Vamos a que
Supabase use ese mismo Resend para enviar los códigos, sin límite y al instante.

1. Consigue tu **API Key de Resend**:
   - Entra a https://resend.com → **API Keys** → copia una que empiece con `re_...`
     (o crea una nueva).
2. En Supabase → **Authentication** → **Emails** → **SMTP Settings** → activa
   **"Enable Custom SMTP"** y llena:
   - **Host:** `smtp.resend.com`
   - **Port:** `465`
   - **Username:** `resend`
   - **Password:** tu API Key de Resend (`re_...`)
   - **Sender email:** `reportes@sincontador.app`
   - **Sender name:** `SinContador`
3. Dale **Save**.

Con esto los códigos llegan al instante y sin límite de cantidad.

---

## Desbloquear a Teófilo AHORA MISMO (si usas la Opción B)
Si eliges la Opción B y quieres que Teófilo entre ya, sin esperar:
1. Supabase → **Authentication** → **Users**.
2. Busca el correo de Teófilo → haz clic en él.
3. Activa **"Confirm email"** para ese usuario.
4. Entra con su correo + contraseña (sin código).

*(Con la Opción A no hace falta este paso: al apagar "Confirm email" ya entra.)*
