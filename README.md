# Sistema Alumnos

API mínima (Flask) para gestionar alumnos. Es el proyecto de la actividad **OCY1102 – Ciberseguridad en desarrollo (EA 3)**:
sobre ella se construye un pipeline de Jenkins con gestión segura de dependencias, documentación automática y trazabilidad.

> Sigue la **GUIA_1_DEPENDENCIAS.html** o la **GUIA_2_DOCUMENTACION_TRAZABILIDAD.html** (en la carpeta superior). Este repositorio es solo el punto de partida.

## Endpoints

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/hello?name=Ana` | Saludo |
| GET | `/health` | Estado de la aplicación |
| GET | `/version` | Versión desplegada (la define el pipeline con `APP_VERSION`) |
| GET | `/alumnos` | Lista de alumnos |
| GET | `/alumnos/<id>` | Un alumno (404 si no existe) |
| POST | `/alumnos` | Crea un alumno. JSON: `nombre`, `promedio` (1.0–7.0), `carrera` (opcional) |

## Contenido

| Archivo | Para qué sirve |
|---|---|
| `app.py` | Aplicación Flask |
| `tests/` | Pruebas unitarias (pytest) |
| `requirements.txt` | Dependencias iniciales (antiguas a propósito) |
| `Jenkinsfile` | Pipeline (versión base; la guía te dice qué etapas agregar) |
| `Doxyfile` | Configuración de Doxygen (incompleta; la completas en la Parte B) |
| `.flake8` | Reglas de estilo del proyecto |
| `scripts/` | `deploy_test.sh` (despliegue de prueba) y `trazabilidad.sh` (registro de builds) |
