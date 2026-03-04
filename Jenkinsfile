pipeline {
    agent {
        docker {
            image 'node:22-alpine'
            args '-v pnpm-store:/home/node/.local/share/pnpm/store'
        }
    }

    environment {
        CI = 'true'
        PNPM_HOME = '/usr/local/share/pnpm'
        PATH = "${PNPM_HOME}:${env.PATH}"
    }

    stages {
        stage('Setup') {
            steps {
                sh 'corepack enable && corepack prepare pnpm@latest --activate'
                sh 'pnpm install --frozen-lockfile'
            }
        }

        stage('Quality Checks') {
            parallel {
                stage('Lint') {
                    steps { sh 'pnpm run lint' }
                }
                stage('Type Check') {
                    steps { sh 'pnpm run typecheck' }
                }
                stage('Code Duplication') {
                    steps {
                        sh 'pnpm run cpd:ci'
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'reports/cpd/**', allowEmptyArchive: true
                        }
                    }
                }
            }
        }

        stage('Build') {
            steps { sh 'pnpm run build' }
        }

        stage('Test') {
            steps { sh 'pnpm run test' }
            post {
                always {
                    junit allowEmptyResults: true, testResults: '**/junit-report.xml'
                }
            }
        }
    }

    post {
        always { cleanWs() }
        failure {
            echo 'Pipeline fehlgeschlagen — prüfe die Logs.'
        }
    }
}
