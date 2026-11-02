// Jenkinsfile - Pipeline de "Sistema Alumnos" (OCY1102)
//
// Esta es la versión BASE: solo compila y prueba.
// En la guía irás pegando etapas en los marcadores  >>> [ETIQUETA]  de más abajo.
pipeline {
    agent any

    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    triggers {
        // Auditoría programada (lunes a viernes, ~06:00): aparecen CVE nuevos aunque el código no cambie
        cron('H 6 * * 1-5')
    }

    environment {
        // pipenv crea el entorno virtual (.venv) dentro del workspace del job
        PIPENV_VENV_IN_PROJECT    = '1'
        PIPENV_IGNORE_VIRTUALENVS = '1'
        PIPENV_NOSPIN             = '1'
    }

    stages {
        stage('Build') {
            steps {
                script {
                    // Versión = 1.0.<nº de build>+<commit corto>. Sirve para la trazabilidad (Parte B)
                    def sha = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    env.GIT_SHA     = sha
                    env.APP_VERSION = "1.0.${env.BUILD_NUMBER}+${sha}"
                }
                echo "Versión de este build: ${env.APP_VERSION}"
                // Cada build parte limpio: sin reportes viejos y con un entorno virtual nuevo (reproducible)
                sh 'rm -rf .venv reports && mkdir -p reports'
                // --deploy: falla si Pipfile.lock no coincide con Pipfile (evita instalaciones "a ciegas")
                sh 'pipenv install --dev --deploy'
                sh 'pipenv run python -m compileall -q app.py'
            }
        }

        stage('Test') {
            steps {
                sh 'pipenv run pytest --junitxml=reports/junit.xml'
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'reports/junit.xml'
                }
            }
        }

        stage('Analyze') {
            steps {
                // catchError: si hay hallazgos el build queda INESTABLE (amarillo) pero el pipeline continúa
                catchError(buildResult: 'UNSTABLE', stageResult: 'UNSTABLE') {
                    sh '''#!/bin/bash
                        set -u
                        mkdir -p reports
                        rc=0
                        echo "== flake8 (estilo y errores de programación) =="
                        flake8 app.py tests > reports/flake8.txt || rc=1
                        cat reports/flake8.txt
                        echo "== bandit (seguridad del código) =="
                        bandit -q -r app.py -f txt -o reports/bandit.txt || rc=1
                        cat reports/bandit.txt
                        exit $rc
                    '''
                }
            }
        }

        stage('Dependency Management') {
            steps {
                catchError(buildResult: 'UNSTABLE', stageResult: 'UNSTABLE') {
                    sh '''#!/bin/bash
                        set -u
                        mkdir -p reports
                        # 1) Lista exacta (con hashes de integridad) de lo que dice Pipfile.lock
                        pipenv requirements --hash > reports/requirements.lock.txt
                        # 2) Dependencias con una versión más nueva disponible
                        pipenv run pip list --outdated > reports/dependencias-desactualizadas.txt || true
                        cat reports/dependencias-desactualizadas.txt
                        # 3) Vulnerabilidades conocidas (CVE) en las versiones instaladas
                        pip-audit -r reports/requirements.lock.txt --no-deps --disable-pip --aliases on -f json -o reports/pip-audit.json || true
                        rc=0
                        pip-audit -r reports/requirements.lock.txt --no-deps --disable-pip --aliases on -o reports/pip-audit.txt || rc=1
                        # Si no hay hallazgos pip-audit no escribe el archivo: lo dejamos explícito
                        [ -f reports/pip-audit.txt ] || echo "Sin vulnerabilidades conocidas" > reports/pip-audit.txt
                        cat reports/pip-audit.txt
                        exit $rc
                    '''
                }
            }
        }

        // >>> [B-DOCS] (Parte B, paso B3): aquí va la etapa "Generate Documentation"

        // >>> [B-VERSION] (Parte B, paso B4): aquí va la etapa "Version Control"

        // >>> [B-DEPLOY] (Parte B, paso B5): aquí va la etapa "Deploy"
    }

    post {
        always {
            archiveArtifacts artifacts: 'reports/**', allowEmptyArchive: true
        }
        unstable {
            echo '[ALERTA] El build quedó INESTABLE: hay hallazgos de seguridad. Revisa la carpeta reports/.'
            script { notificar('INESTABLE') }
        }
        failure {
            echo '[ALERTA] El build FALLÓ. Revisa el log de la etapa en rojo.'
            script { notificar('FALLIDO') }
        }
        success {
            echo '[OK] Build correcto: pruebas, análisis y dependencias sin hallazgos.'
        }
    }
}

// Envía una alerta a un webhook (Discord, Slack, Teams o webhook.site).
// La URL NO va en el repositorio: se guarda en Jenkins como credencial "Secret text" con ID "webhook-alertas".
def notificar(String estado) {
    String mensaje = "Sistema Alumnos - build #${env.BUILD_NUMBER} ${estado}: ${env.BUILD_URL}"
    echo "NOTIFICACION: ${mensaje}"
    try {
        withCredentials([string(credentialsId: 'webhook-alertas', variable: 'WEBHOOK_URL')]) {
            withEnv(["MENSAJE=${mensaje}"]) {
                sh 'curl -fsS -X POST -H "Content-Type: application/json" -d "{\\"content\\": \\"$MENSAJE\\", \\"text\\": \\"$MENSAJE\\"}" "$WEBHOOK_URL" > /dev/null'
            }
        }
    } catch (err) {
        echo "No se envió la notificación (¿creaste la credencial 'webhook-alertas'?): ${err.message}"
    }
}
