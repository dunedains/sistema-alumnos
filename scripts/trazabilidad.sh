#!/usr/bin/env bash
# Agrega una fila a docs/TRAZABILIDAD.md para enlazar: build <-> versión <-> commit <-> estado de calidad.
# La ejecuta el pipeline en la etapa "Version Control", antes de hacer commit de la carpeta docs/.
set -euo pipefail

ARCHIVO="docs/TRAZABILIDAD.md"
mkdir -p docs

if [ ! -f "$ARCHIVO" ]; then
  {
    echo "# Registro de trazabilidad"
    echo
    echo "Cada fila la agrega el pipeline de Jenkins (etapa *Version Control*)."
    echo
    echo "| Build | Fecha (UTC) | Versión | Commit origen | Pruebas | Hallazgos pip-audit | Advertencias Doxygen | Enlace al build |"
    echo "|---|---|---|---|---|---|---|---|"
  } > "$ARCHIVO"
fi

FECHA="$(date -u +"%Y-%m-%d %H:%M")"
COMMIT="$(git rev-parse --short HEAD)"

PRUEBAS="$(python3 -I - <<'PY'
import xml.etree.ElementTree as ET
raiz = ET.parse('reports/junit.xml').getroot()
suite = raiz if raiz.tag == 'testsuite' else raiz.find('testsuite')
total = int(suite.get('tests'))
malas = int(suite.get('failures')) + int(suite.get('errors'))
print(f"{total - malas}/{total} OK")
PY
)"

# reports/pip-audit.json solo existe si el pipeline tiene la etapa "Dependency Management" (guía 1)
if [ -f reports/pip-audit.json ]; then
  HALLAZGOS="$(python3 -I - <<'PY'
import json
datos = json.load(open('reports/pip-audit.json'))
print(len({v['id'] for dep in datos['dependencies'] for v in dep.get('vulns', [])}))
PY
)"
else
  HALLAZGOS="n/a"
fi

if [ -f reports/doxygen_warnings.log ]; then
  ADVERTENCIAS="$(wc -l < reports/doxygen_warnings.log | tr -d ' ')"
else
  ADVERTENCIAS=0
fi

echo "| ${BUILD_NUMBER:-local} | $FECHA | ${APP_VERSION:-dev} | \`$COMMIT\` | $PRUEBAS | $HALLAZGOS | $ADVERTENCIAS | ${BUILD_URL:-n/a} |" >> "$ARCHIVO"
echo "Registro agregado en $ARCHIVO"
