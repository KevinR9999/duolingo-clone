self.addEventListener("install", () => {
  console.log("Service Worker instalado");
});

self.addEventListener("activate", () => {
  console.log("Service Worker activado");
});

self.addEventListener("fetch", (event) => {
  // Aquí puedes agregar lógica de caché si lo deseas
});
