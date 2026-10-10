// Imprime un HTML a PDF con Firefox headless (WebDriver BiDi vía puppeteer-core).
// Uso: node firefox-print.js <salida.pdf> <url-o-ruta.html>
// Requiere que puppeteer-core esté instalado y Firefox en la Mac.
const path = require('path');

// puppeteer-core puede estar instalado en el proyecto (cwd) y no junto a este script,
// así que lo resolvemos también contra el directorio actual.
function loadPuppeteer() {
  const paths = [process.cwd(), __dirname];
  try {
    return require(require.resolve('puppeteer-core', { paths }));
  } catch (e) {
    throw new Error("puppeteer-core no encontrado. Instalalo con: npm i puppeteer-core");
  }
}

const out = process.argv[2] || 'firefox.pdf';
let target = process.argv[3] || '';
if (target && !/^[a-z]+:\/\//i.test(target)) target = 'file://' + path.resolve(target);

(async () => {
  const puppeteer = loadPuppeteer();
  const browser = await puppeteer.launch({
    browser: 'firefox',
    executablePath: '/Applications/Firefox.app/Contents/MacOS/firefox',
    headless: true,
  });
  const page = await browser.newPage();
  await page.goto(target, { waitUntil: 'load' });
  await page.pdf({ path: out, preferCSSPageSize: true, printBackground: true });
  await browser.close();
  console.log('firefox ->', out);
})().catch((e) => { console.error('ERR', e.message); process.exit(1); });
