import copy

import pytest

import app as modulo_app


@pytest.fixture
def client():
    """Cliente de pruebas de Flask con la lista de alumnos restaurada en cada test."""
    original = copy.deepcopy(modulo_app.ALUMNOS)
    modulo_app.app.config["TESTING"] = True
    with modulo_app.app.test_client() as c:
        yield c
    modulo_app.ALUMNOS[:] = original


def test_hello_saluda_al_usuario(client):
    r = client.get("/hello?name=Ana")
    assert r.status_code == 200
    assert b"Hello, Ana!" in r.data


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.get_json() == {"estado": "ok"}


def test_version_por_defecto(client):
    r = client.get("/version")
    assert r.status_code == 200
    assert r.get_json()["aplicacion"] == "Sistema Alumnos"


def test_listar_alumnos(client):
    r = client.get("/alumnos")
    assert r.status_code == 200
    assert len(r.get_json()) == 3


def test_obtener_alumno_existente(client):
    r = client.get("/alumnos/1")
    assert r.status_code == 200
    assert r.get_json()["nombre"] == "Ana Pérez"


def test_obtener_alumno_inexistente(client):
    r = client.get("/alumnos/999")
    assert r.status_code == 404


def test_crear_alumno(client):
    r = client.post("/alumnos", json={"nombre": "Diego Muñoz", "carrera": "Informática", "promedio": 5.9})
    assert r.status_code == 201
    assert r.get_json()["id"] == 4
    assert len(client.get("/alumnos").get_json()) == 4


def test_crear_alumno_sin_nombre_es_rechazado(client):
    r = client.post("/alumnos", json={"promedio": 5.0})
    assert r.status_code == 400


def test_crear_alumno_con_promedio_invalido_es_rechazado(client):
    r = client.post("/alumnos", json={"nombre": "Eva", "promedio": 9.5})
    assert r.status_code == 400
