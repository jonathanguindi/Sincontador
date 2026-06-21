---
name: probar-web
description: Probar la app SinContador en un navegador real (Chromium headless con Playwright), como si fueras un usuario. Usar cuando se quiera abrir la web, navegar, hacer clic, llenar formularios (registro, login, calculadora), revisar errores de consola y tomar capturas para verificar visualmente que algo funciona o reproducir un bug. La app es un único index.html (landing + app React con Supabase); rutas por hash: #/app (app), #/admin, #/privacidad, #/terminos.
---

# Probar la web como un usuario (navegador real)

Esta skill maneja **Chromium headless con Playwright** para usar la app igual
que una persona: abrir páginas, hacer clic, escribir en formularios, leer errores
de consola y tomar capturas. El binario de Chromium ya viene en el entorno
(`/opt/pw-browsers/...`); `lib.mjs` lo detecta solo.

## ⚠️ Red del sandbox
Este entorno suele **bloquear los CDN externos** (cdnjs/jsdelivr → 403/cert),
así que la app React (`#/app`) **no carga sola** y se ve en blanco. NO es un bug
de la app. Para probarla aquí usa **modo offline** (`launch({ offline: true })`),
que sirve React/Babel desde copias locales de npm y simula el backend. La landing
(estática) sí carga sin offline.

## Pasos para usarla

1. **Instala Playwright** (y, para modo offline, React/Babel locales — Babel debe
   ser la v7, que usa el runtime clásico igual que el CDN del sitio):
   ```bash
   cd /home/user/Sincontador && npm install playwright react@18.2.0 react-dom@18.2.0 @babel/standalone@7.23.5 >/dev/null 2>&1
   ```

2. **Escribe un escenario** en `/tmp/escenario.mjs` importando el helper. Ejemplos abajo.

3. **Córrelo** desde la raíz del repo (para que resuelva `playwright`):
   ```bash
   cd /home/user/Sincontador && node /tmp/escenario.mjs
   ```

4. **Mira la captura** con la tool Read sobre el PNG generado. Si pruebas algo
   visual, manda la captura al usuario con SendUserFile.

5. **Limpieza al terminar:** `rm -rf node_modules package-lock.json && git checkout package.json 2>/dev/null` (Playwright deja node_modules; no debe commitearse).

## Helper (`lib.mjs`)
- `launch({ mobile, logs })` → `{ browser, page }`. `mobile:true` usa viewport de celular. `logs:true` (por defecto) imprime consola/errores de la página — útil para cazar bugs (pantalla blanca, etc.).
- `APP_LOCAL` = `file:///home/user/Sincontador/index.html` (prueba el código de este repo).
- `APP_PROD` = `https://sincontador.app` (prueba lo que está en vivo).

> Importa con ruta absoluta: `import { launch, APP_LOCAL } from "/home/user/Sincontador/.claude/skills/probar-web/lib.mjs";`

## Ejemplo 1 — Abrir la app y capturar (detecta pantalla blanca)
```js
import { launch, APP_LOCAL } from "/home/user/Sincontador/.claude/skills/probar-web/lib.mjs";
const { browser, page } = await launch({ offline: true });   // offline: necesario en el sandbox
await page.goto(APP_LOCAL + "#/app", { waitUntil: "load", timeout: 20000 });
await page.waitForTimeout(2500);                 // deja transpilar Babel + render
const txt = await page.locator("#root").innerText().catch(() => "");
console.log("Texto visible en #root (primeros 200):", txt.slice(0, 200) || "(VACÍO = pantalla blanca)");
await page.screenshot({ path: "/tmp/app.png", fullPage: true });
await browser.close();
```

## Ejemplo 2 — Probar el registro como usuario
```js
import { launch, APP_LOCAL } from "/home/user/Sincontador/.claude/skills/probar-web/lib.mjs";
const { browser, page } = await launch({ mobile: true });
await page.goto(APP_LOCAL + "#/app", { waitUntil: "load" });
await page.waitForTimeout(2500);
await page.getByText("Crear cuenta gratis").click();
await page.getByPlaceholder("Ej. María González").fill("Prueba QA");
await page.getByPlaceholder("tu@correo.com").fill("qa+" + Date.now() + "@example.com");
await page.getByPlaceholder("Mínimo 6 caracteres").fill("123456");
await page.screenshot({ path: "/tmp/registro.png", fullPage: true });
// await page.getByText("Crear mi cuenta").click();  // ⚠️ esto crea un usuario REAL en Supabase
await browser.close();
```

## Notas importantes
- **La app usa el Supabase REAL.** Registrarse/loguear crea datos reales (usuarios de prueba). Úsalo con criterio; prefiere `APP_LOCAL` y no completes el submit de registro salvo que quieras crear un usuario de verdad.
- Para verificar que un cambio del repo funciona, usa `APP_LOCAL` (prueba el index.html local). Para ver lo que ya está publicado, usa `APP_PROD`.
- Selectores útiles de Playwright: `page.getByText("...")`, `getByPlaceholder("...")`, `getByRole("button", { name: "..." })`, `page.locator("css")`.
- Si la página queda en blanco, los listeners de `console`/`pageerror` imprimen el error de JS (suele ser la causa).
