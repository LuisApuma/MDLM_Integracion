pipeline {
    agent { label 'agent-1' } // Tu jenkins-agent configurado en /opt/cicd-stack/

    environment {
        // 1. Configuración de tu Stack en VM1
        // IMPORTANTE: Se usa guion medio (-) porque el guion bajo (_) es ilegal para el motor Tomcat de Sonar
        SONAR_HOST   = "http://sonarqube-server:9000"
        STACK_NET    = "cicd-internal-network"
        
        // 2. Configuración de la App
        IMAGE_NAME   = "backend-crud-app"
        
        // --- COMENTADO: Harbor no está listo aún ---
        // HARBOR_URL   = "${env.GLOBAL_HARBOR_URL}" 
        
        // 3. Credenciales
        SONAR_TOKEN  = credentials('sonar-token')
    }

    stages {
        stage('1. Calidad (SonarQube)') {
            steps {
                script {
                    echo "Verificando conectividad básica (Ping)..."
                    sh "docker run --rm --network ${STACK_NET} alpine ping -c 2 sonarqube-server"

                    echo "Analizando código en SonarQube..."
                    sh '''
                    docker run --rm \
                        --network ${STACK_NET} \
                        -v "$(pwd):/usr/src" \
                        sonarsource/sonar-scanner-cli:5.0.1 \
                        -Dsonar.host.url=$SONAR_HOST \
                        -Dsonar.login=$SONAR_TOKEN \
                        -Dsonar.projectKey=${IMAGE_NAME} \
                        -Dsonar.sources=src \
                        -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
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

        // --- STAGE COMENTADO: Harbor no está listo aún ---
        /*
        stage('3. Entrega Certificada (Harbor)') {
            steps {
                script {
                    echo "Enviando imagen certificada a VM2 (Harbor)..."
                    docker.withRegistry("https://${HARBOR_URL}", 'harbor-registry-auth') {
                        def customImage = docker.build("${HARBOR_URL}/library/${IMAGE_NAME}:${env.BUILD_ID}")
                        customImage.push()
                        customImage.push("latest")
                    }
                }
            }
        }
        */
    }

    post {
        always {
            echo "Ahorrando espacio en VM1..."
            sh "docker image prune -f"
            cleanWs()
        }
    }
}
