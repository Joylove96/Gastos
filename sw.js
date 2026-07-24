/* Service worker · Gastos JoyLovePets SpA v12
   SOLO cachea archivos locales (HTML, JS, CSS, imágenes, fuentes).
   NUNCA cachea: Supabase, CDN externo, ni APIs.
   Network-first siempre para APIs + CDN. */

const CACHE = "joyregist-v13";

const LOCAL_FILES = [
  "./",
  "./index.html",
  "./app.js",
  "./manifest.json",
  "./icon-192.png",
  "./icon-512.png",
  "./icon-maskable-512.png",
  "./favicon.png",
  "./avatar-canela.png",
  "./avatar-tequila.png",
  "./joylovepets-logo.png",
  "./joylovepets-logo.svg"
];

self.addEventListener("install", e => {
  e.waitUntil(
    caches.open(CACHE)
      .then(c => Promise.allSettled(LOCAL_FILES.map(u => c.add(u))))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys()
      .then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", e => {
  const req = e.request;
  if (req.method !== "GET") return;

  const url = new URL(req.url);
  if (url.protocol !== "http:" && url.protocol !== "https:") return;

  // NUNCA cachear: Supabase, CDN, APIs
  // SIEMPRE network-first (sin cache) para poder sincronizar
  if (url.hostname.includes("supabase.co") || 
      url.hostname.includes("cdn.") || 
      url.hostname.includes("cdnjs.") ||
      url.hostname.includes("jsdelivr.net") ||
      url.hostname.includes("googleapis.com")) {
    e.respondWith(fetch(req));
    return;
  }

  // Archivos locales (HTML, JS, PNG, SVG): network-first, cache como respaldo
  e.respondWith(
    fetch(req).then(res => {
      if (res && res.ok) {
        const copy = res.clone();
        caches.open(CACHE).then(c => c.put(req, copy)).catch(() => {});
      }
      return res;
    }).catch(() => 
      caches.match(req).then(hit => hit || caches.match("./index.html"))
    )
  );
});
