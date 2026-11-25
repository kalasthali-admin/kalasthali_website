const fs = require('node:fs');
const path = require('node:path');

const names = ['INSTAGRAM_URL', 'FACEBOOK_URL', 'AMAZON_URL', 'MYNTRA_URL'];
const values = Object.fromEntries(names.map((name) => [name, process.env[name] || '']));
fs.writeFileSync(
  path.resolve('build/web/public-config.js'),
  `window.KALASTHALI_SOCIAL=${JSON.stringify(values).replace(/</g, '\\u003c')};\n`,
);
