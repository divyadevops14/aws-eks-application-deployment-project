// Simple web app with no external dependencies (uses Node's built-in http module).
const http = require("http");
const os = require("os");

const PORT = process.env.PORT || 3000;
const APP_VERSION = process.env.APP_VERSION || "v1";

const server = http.createServer((req, res) => {
  // Health endpoint used by Kubernetes liveness/readiness probes
  if (req.url === "/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    return res.end(JSON.stringify({ status: "ok" }));
  }

  // Main page: shows which pod answered, so load balancing is visible on refresh
  res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
  res.end(`<!doctype html>
<html>
  <head><meta charset="utf-8"><title>EKS Demo App</title></head>
  <body style="font-family: sans-serif; text-align: center; margin-top: 15vh;">
    <h1>Hello from AWS EKS!</h1>
    <p>App version: <b>${APP_VERSION}</b></p>
    <p>Served by pod: <b>${os.hostname()}</b></p>
    <p>Refresh the page: the pod name can change as the load balancer spreads traffic.</p>
  </body>
</html>`);
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`App ${APP_VERSION} listening on port ${PORT}`);
});

// Shut down cleanly when Kubernetes stops the pod
process.on("SIGTERM", () => {
  console.log("SIGTERM received, shutting down");
  server.close(() => process.exit(0));
});
