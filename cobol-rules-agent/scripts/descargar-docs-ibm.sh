#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

echo "Raiz del proyecto: $ROOT"
echo ""

BASE_64="https://www.ibm.com/docs/en/SS6SG3_6.4.0/pdf"
BASE_42="https://publibfp.dhe.ibm.com/epubs/pdf"

DEST="docs-ibm/6.4"
TXT="$DEST/txt"
ORIGEN="docs-ibm/origen"
ORIGEN_TXT="$ORIGEN/txt"

mkdir -p "$DEST" "$TXT" "$ORIGEN" "$ORIGEN_TXT" salidas
mkdir -p entradas/fuentes entradas/copybooks entradas/listados entradas/opciones

DOCS_64="
mg.pdf|Migration-Guide-GC27-8715-03
pgmvs.pdf|Programming-Guide-SC27-8714-03
lrmvs.pdf|Language-Reference-SC27-8713-03
cg.pdf|Customization-Guide-SC27-8712-03
perfguide.pdf|Performance-Tuning-Guide-SC27-9202-02
new.pdf|What-Is-New
"

DOCS_42="
igy3pg50.pdf|V42-Programming-Guide-SC23-8529-01
igy3lr50.pdf|V42-Language-Reference-SC23-8528-01
igy3cg50.pdf|V42-Customization-Guide-SC23-8526-01
"

descargar() {
  base_url="$1"
  destino="$2"
  lista="$3"
  etiqueta="$4"

  echo "== $etiqueta =="
  echo "$lista" | while IFS='|' read -r remoto local; do
    [ -z "$remoto" ] && continue
    salida="$destino/$local.pdf"
    if [ -f "$salida" ]; then
      echo "  ya existe: $local.pdf"
      continue
    fi
    echo "  descargando: $remoto"
    if curl -fsSL --retry 3 --retry-delay 2 -A "Mozilla/5.0" -o "$salida" "$base_url/$remoto"; then
      echo "    ok -> $local.pdf"
    else
      echo "    FALLO: $remoto"
      rm -f "$salida"
    fi
  done
  echo ""
}

descargar "$BASE_64" "$DEST" "$DOCS_64" "Destino 6.4"
descargar "$BASE_42" "$ORIGEN" "$DOCS_42" "Origen V4.2"

if ! command -v pdftotext >/dev/null 2>&1; then
  echo "pdftotext no esta instalado. Los agentes de Copilot no indexan PDF."
  echo "Instalar con: brew install poppler"
  echo "Luego volver a ejecutar este script para generar el texto."
  exit 1
fi

convertir() {
  origen="$1"
  destino="$2"
  for pdf in "$origen"/*.pdf; do
    [ -e "$pdf" ] || continue
    base="$(basename "$pdf" .pdf)"
    salida="$destino/$base.txt"
    [ -f "$salida" ] && continue
    echo "  convirtiendo: $base"
    pdftotext -layout "$pdf" "$salida"
  done
}

echo "== Conversion a texto =="
convertir "$DEST" "$TXT"
convertir "$ORIGEN" "$ORIGEN_TXT"
echo ""

echo "== Resumen =="
pdf_64=$(ls -1 "$DEST"/*.pdf 2>/dev/null | wc -l | tr -d ' ')
pdf_42=$(ls -1 "$ORIGEN"/*.pdf 2>/dev/null | wc -l | tr -d ' ')
txt_64=$(ls -1 "$TXT"/*.txt 2>/dev/null | wc -l | tr -d ' ')
txt_42=$(ls -1 "$ORIGEN_TXT"/*.txt 2>/dev/null | wc -l | tr -d ' ')

echo "  6.4   PDF: $pdf_64 de 6    TXT: $txt_64"
echo "  V4.2  PDF: $pdf_42 de 3    TXT: $txt_42"
echo ""

if [ "$txt_64" -eq 6 ] && [ "$txt_42" -eq 3 ]; then
  echo "Corpus completo. Continuar con la etapa 1 del INSTRUCTIVO."
else
  echo "Corpus incompleto. Revisar los FALLO de arriba antes de usar el agente."
fi
