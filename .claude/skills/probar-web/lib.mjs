// Helper para manejar un navegador real (Chromium headless) con Playwright.
// Detecta el binario de Chromium del entorno y abre la app como un usuario.
import { chromium } from "playwright";
import fs from "fs";

// Busca el ejecutable de Chromium instalado (entornos Claude lo traen en /opt/pw-browsers)
function findChromium() {
  const base = "/opt/pw-browsers";
  try {
    if (fs.existsSync(base)) {
      for (const d of fs.readdirSync(base)) {
        const p = `${base}/${d}/chrome-linux/chrome`;
        if (fs.existsSync(p)) return p;
      }
    }
  } catch {}
  return undefined; // si no se encuentra, Playwright usa su navegador por defecto
}

const REPO = "/home/user/Sincontador";

// En modo offline, redirige los CDN (que el sandbox puede bloquear) a copias
// locales de npm, y simula el backend (Supabase/XLSX/html2pdf) para que la app
// React renderice sin red. Requiere: npm install react@18.2.0 react-dom@18.2.0 @babel/standalone
async function rutearOffline(context) {
  const send = (route, path, body) =>
    route.fulfill(path ? { path, contentType: "application/javascript" }
                       : { body, contentType: "application/javascript" });

  await context.route(/react\.production\.min\.js/, (r) => send(r, `${REPO}/node_modules/react/umd/react.production.min.js`));
  await context.route(/react-dom\.production\.min\.js/, (r) => send(r, `${REPO}/node_modules/react-dom/umd/react-dom.production.min.js`));
  await context.route(/babel.*\.js/, (r) => send(r, `${REPO}/node_modules/@babel/standalone/babel.js`));

  // Stub de Supabase: cliente falso encadenable, sin sesión (muestra el login).
  const supaStub = `window.supabase={createClient:function(){return {auth:{getSession:async()=>({data:{session:null}}),onAuthStateChange:()=>({data:{subscription:{unsubscribe(){}}}}),getUser:async()=>({data:{user:null}}),signInWithPassword:async()=>({error:null}),signUp:async()=>({data:{},error:null}),signOut:async()=>({error:null}),resetPasswordForEmail:async()=>({error:null}),verifyOtp:async()=>({error:null}),resend:async()=>({error:null})},from:function(){var q={select:()=>q,eq:()=>q,order:()=>q,gte:()=>q,maybeSingle:async()=>({data:null}),single:async()=>({data:null}),insert:()=>q,update:()=>q,upsert:async()=>({}),delete:()=>q};return q;},functions:{invoke:async()=>({data:null})},channel:function(){var c={on:()=>c,subscribe:()=>c};return c;},removeChannel(){}};}};`;
  await context.route(/supabase-js/, (r) => send(r, null, supaStub));
  await context.route(/xlsx.*\.js/, (r) => send(r, null, "window.XLSX={utils:{},writeFile:function(){}};"));
  await context.route(/html2pdf.*\.js/, (r) => send(r, null, "window.html2pdf=function(){var o={set:()=>o,from:()=>o,save:()=>o};return o;};"));
}

/**
 * Lanza un navegador y devuelve { browser, page }.
 * @param {object} opts
 * @param {boolean} opts.mobile   true = viewport de celular (390x844)
 * @param {boolean} opts.logs     true = imprime console y errores de la página
 * @param {boolean} opts.offline  true = sirve React/Babel locales y simula el backend
 *                                 (úsalo si el sandbox bloquea los CDN; ideal con APP_LOCAL)
 */
export async function launch({ mobile = false, logs = true, offline = false } = {}) {
  const executablePath = findChromium();
  const browser = await chromium.launch({
    ...(executablePath ? { executablePath } : {}),
    // El sandbox intercepta HTTPS con un cert no confiable; sin esto fallan los CDN (Babel/React).
    args: ["--ignore-certificate-errors"],
  });
  const context = await browser.newContext({
    ignoreHTTPSErrors: true,
    ...(mobile
      ? { viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true }
      : { viewport: { width: 1280, height: 900 }, deviceScaleFactor: 1 }),
  });
  if (offline) await rutearOffline(context);
  const page = await context.newPage();
  if (logs) {
    page.on("console", (m) => console.log("  [console]", m.type(), m.text()));
    page.on("pageerror", (e) => console.log("  [pageerror]", e.message));
    page.on("requestfailed", (r) => console.log("  [requestfailed]", r.url()));
  }
  return { browser, page };
}

// URL local de la app en este repo (la landing + app React en un solo archivo)
export const APP_LOCAL = "file:///home/user/Sincontador/index.html";
// URL en producción
export const APP_PROD = "https://sincontador.app";
