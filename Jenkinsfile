pipeline {
    agent { label 'agent-1' }

    environment {
        SONAR_HOST   = "http://sonarqube-server:9000"
        STACK_NET    = "cicd-internal-network"
        IMAGE_NAME   = "backend-crud-app"
        PROJECT_NAME = "impresion-enterprise"
        HARBOR_URL   = "${env.GLOBAL_HARBOR_URL}" 
        
        SONAR_TOKEN  = credentials('sonar-token')
        HARBOR_CREDS = credentials('harbor-moline')
        
        // Variables de etiquetado dinámico
        FULL_IMAGE_V = "${HARBOR_URL}/${PROJECT_NAME}/${IMAGE_NAME}:${env.BUILD_ID}"
        FULL_IMAGE_L = "${HARBOR_URL}/${PROJECT_NAME}/${IMAGE_NAME}:latest"
    }

    stages {
        stage('1. Calidad (SonarQube)') {
            steps {
                sh """
                docker run --rm --network ${STACK_NET} --volumes-from ${HOSTNAME} -w ${WORKSPACE} \
                    sonarsource/sonar-scanner-cli:5.0.1 \
                    -Dsonar.host.url=$SONAR_HOST -Dsonar.login=$SONAR_TOKEN \
                    -Dsonar.projectKey=${IMAGE_NAME} -Dsonar.sources=src -Dsonar.scm.disabled=true
                """
            }
        }

        stage('2. Integración Efímera') {
            steps {
                script {
                    def testNet = "net-test-${env.BUILD_ID}"
                    def dbContainer = "db-test-${env.BUILD_ID}"
                    sh "docker network create ${testNet}"
                    try {
                        sh "docker run -d --name ${dbContainer} --network ${testNet} -e POSTGRES_PASSWORD=test_pass_secret postgres:15-alpine"
                        sh "docker build -t ${IMAGE_NAME}:test ."
                        
                        // Ejecución de tests
                        sh """
                        docker run --rm --network ${testNet} \
                            -e DB_HOST=${dbContainer} -e DB_USER=postgres -e DB_PASS=test_pass_secret \
                            -e DB_NAME=postgres -e NODE_ENV=test \
                            ${IMAGE_NAME}:test sh -c "npm run migrate && npm test"
                        """
                    } finally {
                        sh "docker rm -f ${dbContainer} || true"
                        sh "docker network rm ${testNet} || true"
                    }
                }
            }
        }

        stage('3. Harbor Push') {
            steps {
                script {
                    sh "echo ${HARBOR_CREDS_PSW} | docker login ${HARBOR_URL} -u ${HARBOR_CREDS_USR} --password-stdin"
                    sh "docker tag ${IMAGE_NAME}:test ${FULL_IMAGE_V}"
                    sh "docker tag ${IMAGE_NAME}:test ${FULL_IMAGE_L}"
                    sh "docker push ${FULL_IMAGE_V}"
                    sh "docker push ${FULL_IMAGE_L}"
                    sh "docker logout ${HARBOR_URL}"
                }
            }
        }
    }

    post {
        always {
            echo "--- LIMPIEZA PROFUNDA ---"
            sh """
                docker rmi ${IMAGE_NAME}:test || true
                docker rmi ${FULL_IMAGE_V} || true
                docker rmi ${FULL_IMAGE_L} || true
                docker image prune -f
            """
            cleanWs()
        }
    }
}