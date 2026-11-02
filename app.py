"""!
@file app.py
@brief API de gestión de alumnos "Sistema Alumnos" (actividad OCY1102).
"""
import os

from flask import Flask, jsonify, request

app = Flask(__name__)

# Base de datos en memoria (solo para fines de la actividad)
ALUMNOS = [
    {"id": 1, "nombre": "Ana Pérez", "carrera": "Ingeniería en Informática", "promedio": 6.1},
    {"id": 2, "nombre": "Benjamín Rojas", "carrera": "Ingeniería en Ciberseguridad", "promedio": 5.4},
    {"id": 3, "nombre": "Camila Soto", "carrera": "Analista Programador", "promedio": 6.8},
]

# La versión la inyecta el pipeline (ver Jenkinsfile). Sirve para la trazabilidad.
VERSION = os.environ.get("APP_VERSION", "dev")


@app.route('/hello')
def hello():
    """
    Endpoint para saludar al usuario.

    Parámetros:
    name (str): Nombre del usuario.

    Retorna:
    str: Mensaje de saludo.
    """
    name = request.args.get('name')
    return f"Hello, {name}!"


@app.route('/health')
def health():
    return jsonify({"estado": "ok"})


@app.route('/version')
def version():
    return jsonify({"aplicacion": "Sistema Alumnos", "version": VERSION})


@app.route('/alumnos')
def listar_alumnos():
    return jsonify(ALUMNOS)


@app.route('/alumnos/<int:alumno_id>')
def obtener_alumno(alumno_id):
    for alumno in ALUMNOS:
        if alumno["id"] == alumno_id:
            return jsonify(alumno)
    return jsonify({"error": "Alumno no encontrado"}), 404


@app.route('/alumnos', methods=['POST'])
def crear_alumno():
    datos = request.get_json(silent=True) or {}
    nombre = str(datos.get("nombre", "")).strip()
    promedio = datos.get("promedio")

    if not nombre:
        return jsonify({"error": "El campo 'nombre' es obligatorio"}), 400
    if not isinstance(promedio, (int, float)) or not 1.0 <= promedio <= 7.0:
        return jsonify({"error": "El 'promedio' debe ser un número entre 1.0 y 7.0"}), 400

    nuevo = {
        "id": max(a["id"] for a in ALUMNOS) + 1,
        "nombre": nombre,
        "carrera": str(datos.get("carrera", "Sin carrera")),
        "promedio": promedio,
    }
    ALUMNOS.append(nuevo)
    return jsonify(nuevo), 201


if __name__ == '__main__':
    app.run(debug=True)
