pipeline {
    agent { label 'agent-1' } // Tu jenkins-agent configurado en /opt/cicd-stack/

    environment {
        // 1. Configuración de tu Stack en VM1
        // IMPORTANTE: Se usa guion medio (-) porque el guion bajo (_) es ilegal para el motor Tomcat de Sonar
        SONAR_HOST   = "http://sonarqube-server:9000"
        STACK_NET    = "cicd-internal-network"
        
        // 2. Configuración de la App
        IMAGE_NAME   = "backend-crud-app"
        
        // 3. Credenciales
        HARBOR_URL   = "${env.GLOBAL_HARBOR_URL}" 
        PROJECT_NAME = "impresion-enterprise"
        SONAR_TOKEN  = credentials('sonar-token')

        HARBOR_CREDS = credentials('harbor-moline')
    }

    stages {
        stage('1. Calidad (SonarQube)') {
            steps {
                script {
                    echo "Verificando conectividad básica (Ping)..."
                    sh "docker run --rm --network ${STACK_NET} alpine ping -c 2 sonarqube-server"

                    echo "Analizando código con herencia dinámica de volúmenes..."
                    sh '''
                    docker run --rm \
                        --network ${STACK_NET} \
                        --volumes-from ${HOSTNAME} \
                        -w ${WORKSPACE} \
                        sonarsource/sonar-scanner-cli:5.0.1 \
                        -Dsonar.host.url=$SONAR_HOST \
                        -Dsonar.login=$SONAR_TOKEN \
                        -Dsonar.projectKey=${IMAGE_NAME} \
                        -Dsonar.sources=src \
                        -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \
                        -Dsonar.scm.disabled=true
                    '''
                }
            }
        }

        stage('2. Integración Efímera (Test con BD)') {
            steps {
                script {
                    def testNet = "net-test-${env.BUILD_ID}"
                    def dbContainer = "db-test-${env.BUILD_ID}"
                    def dbPass = "test_pass_secret"
                    
                    echo "Creando red temporal: ${testNet}"
                    sh "docker network create ${testNet}"
                    
                    try {
                        echo "Iniciando Postgres Efímero..."
                        sh """
                        docker run -d --name ${dbContainer} \
                            --network ${testNet} \
                            -e POSTGRES_PASSWORD=${dbPass} \
                            postgres:15-alpine
                        """
                        
                        echo "Esperando a que Postgres esté listo..."
                        sh """
                          for i in {1..30}; do
                            if docker exec ${dbContainer} pg_isready -U postgres; then
                              echo "Postgres está listo!"
                              break
                            fi
                            echo "Esperando 1 segundo más... (\$i/30)"
                            sleep 1
                          done
                        """
                        
                        echo "Construyendo imagen de App..."
                        sh "docker build -t ${IMAGE_NAME}:test ."
                        
                        echo "Corriendo Migraciones y Tests de Humo..."
                        sh """
                        docker run --rm --network ${testNet} \
                            -e DB_HOST=${dbContainer} \
                            -e DB_USER=postgres \
                            -e DB_PASS=${dbPass} \
                            -e DB_NAME=postgres \
                            -e NODE_ENV=test \
                            ${IMAGE_NAME}:test \
                            sh -c "npm run migrate && npm test"
                        """
                        echo "¡Integración Efímera Exitosa! Imagen certificada localmente."
                    } finally {
                        echo "Limpieza profunda de recursos temporales..."
                        sh "docker rm -f ${dbContainer} || true"
                        sh "docker network rm ${testNet} || true"
                    }
                }
            }
        }

        stage('3. Entrega Certificada (Harbor)') {
            steps {
                script {
                    echo "Enviando imagen certificada a VM2 (Harbor)..."
                    
                    // 1. Login Seguro (Usando las variables de Jenkins)
                    sh "echo ${HARBOR_CREDS_PSW} | docker login ${HARBOR_URL} -u ${HARBOR_CREDS_USR} --password-stdin"
                    
                    // 2. Tagueo de la imagen (Build ID para versionamiento y Latest para producción)
                    sh """
                    docker tag ${IMAGE_NAME}:test ${HARBOR_URL}/${PROJECT_NAME}/${IMAGE_NAME}:${env.BUILD_ID}
                    docker tag ${IMAGE_NAME}:test ${HARBOR_URL}/${PROJECT_NAME}/${IMAGE_NAME}:latest
                    """
                    
                    // 3. Empuje (Push) a la VM2
                    sh """
                    docker push ${HARBOR_URL}/${PROJECT_NAME}/${IMAGE_NAME}:${env.BUILD_ID}
                    docker push ${HARBOR_URL}/${PROJECT_NAME}/${IMAGE_NAME}:latest
                    """
                    
                    echo "¡Proceso completado! Imagen disponible en: ${HARBOR_URL}/${PROJECT_NAME}/${IMAGE_NAME}"
                }
            }
        }
    }
    

    post {
        always {
            echo "Ahorrando espacio en VM1..."
            sh "docker image prune -f"
            cleanWs()
        }
    }
}
