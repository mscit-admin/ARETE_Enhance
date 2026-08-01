const app = require('./app');

const port = process.env.PORT || 4000;
// Bind all interfaces by default so it's reachable by the server's public IP.
const host = process.env.HOST || '0.0.0.0';

app.listen(port, host, () => {
  // eslint-disable-next-line no-console
  console.log(`ARETE admin API listening on http://${host}:${port}`);
});
