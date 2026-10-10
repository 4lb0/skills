#!/usr/bin/env bash
# Imprime un HTML a PDF con Chrome y Firefox headless y exporta PNGs
# de cada página para revisar visualmente que no haya texto cortado.
#
# Uso: verificar.sh <ruta.html> [carpeta_salida]
#
# Variables de entorno:
#   SALIDA_DIR   carpeta de salida (por defecto: temporal)
#
# Notas:
#   - Chrome se asume en /Applications/Google Chrome.app (macOS).
#   - Firefox es opcional: sólo se prueba si `puppeteer-core` está
#     instalado (npm i puppeteer-core en el proyecto donde se corre).
set -euo pipefail

HTML="${1:?Uso: verificar.sh <ruta.html> [carpeta_salida]}"
HTML="$(cd "$(dirname "$HTML")" && pwd)/$(basename "$HTML")"
OUT="${2:-${SALIDA_DIR:-$(mktemp -d)}}"
mkdir -p "$OUT"

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
HERE="$(cd "$(dirname "$0")" && pwd)"

pages() { pdfinfo "$1" 2>/dev/null | awk '/^Pages/{print $2}'; }

echo "HTML:  $HTML"
echo "Salida: $OUT"

if [ -x "$CHROME" ]; then
  "$CHROME" --headless=new --disable-gpu --no-pdf-header-footer \
    --print-to-pdf="$OUT/chrome.pdf" "file://$HTML" >/dev/null 2>&1
  pdftoppm -png -r 80 "$OUT/chrome.pdf" "$OUT/chrome"
  echo "Chrome : $(pages "$OUT/chrome.pdf") página(s)  ->  $OUT/chrome.pdf"
else
  echo "Chrome : no encontrado en $CHROME (omitido)"
fi

if node -e "require.resolve('puppeteer-core',{paths:[process.cwd()]})" >/dev/null 2>&1; then
  if node "$HERE/firefox-print.js" "$OUT/firefox.pdf" "file://$HTML"; then
    pdftoppm -png -r 80 "$OUT/firefox.pdf" "$OUT/firefox"
    echo "Firefox: $(pages "$OUT/firefox.pdf") página(s)  ->  $OUT/firefox.pdf"
  else
    echo "Firefox: falló la impresión (se continúa igual)."
  fi
else
  echo "Firefox: omitido (falta puppeteer-core; instalar con: npm i puppeteer-core)"
fi

echo
echo "Revisá los PNG ($OUT/*.png) para confirmar que ninguna página tenga"
echo "texto cortado abajo o tapado por el pie (colophon)."
