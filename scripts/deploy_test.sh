#!/usr/bin/env bash
# Despliega la aplicación en el "entorno de prueba" y comprueba que responde (prueba de humo).
#
# El entorno de prueba vive dentro del contenedor de Jenkins (carpeta ~/entorno-prueba)
# y se publica en tu equipo en http://localhost:5000
set -euo pipefail

DESTINO="${DEPLOY_DIR:-$HOME/entorno-prueba}"
PUERTO="${APP_PORT:-5000}"
APP_VERSION="${APP_VERSION:-dev}"
PIDFILE="$DESTINO/app.pid"

echo ">> 1/4 Deteniendo la versión anterior (si existe)"
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  kill "$(cat "$PIDFILE")" || true
  sleep 1
fi
rm -f "$PIDFILE"

echo ">> 2/4 Copiando artefactos a $DESTINO"
mkdir -p "$DESTINO"
cp app.py Pipfile Pipfile.lock "$DESTINO/"

echo ">> 3/4 Instalando solo las dependencias de ejecución (sin las de desarrollo)"
( cd "$DESTINO" && PIPENV_VENV_IN_PROJECT=1 PIPENV_IGNORE_VIRTUALENVS=1 pipenv install --deploy )

echo ">> 4/4 Iniciando la aplicación (APP_VERSION=$APP_VERSION)"
cd "$DESTINO"
# JENKINS_NODE_COOKIE=dontKillMe evita que Jenkins mate el proceso cuando termina el build.
# --host 0.0.0.0 es necesario dentro del contenedor; Docker solo lo publica en 127.0.0.1 de tu equipo.
APP_VERSION="$APP_VERSION" FLASK_APP=app.py JENKINS_NODE_COOKIE=dontKillMe \
  setsid nohup .venv/bin/python -m flask run --host 0.0.0.0 --port "$PUERTO" \
  < /dev/null > app.log 2>&1 &
echo $! > "$PIDFILE"

echo ">> Prueba de humo"
for _ in $(seq 1 20); do
  if curl -fsS "http://127.0.0.1:$PUERTO/health" > /dev/null 2>&1; then break; fi
  sleep 1
done
curl -fsS "http://127.0.0.1:$PUERTO/health" > /dev/null || { echo "ERROR: /health no responde"; cat app.log; exit 1; }
curl -fsS "http://127.0.0.1:$PUERTO/alumnos" > /dev/null || { echo "ERROR: /alumnos no responde"; exit 1; }
DESPLEGADA="$(curl -fsS "http://127.0.0.1:$PUERTO/version")"
echo "/version -> $DESPLEGADA"
echo "$DESPLEGADA" | grep -qF "\"$APP_VERSION\"" || { echo "ERROR: la versión desplegada no coincide con $APP_VERSION"; exit 1; }
echo "OK: la aplicación está desplegada y responde en el puerto $PUERTO"
