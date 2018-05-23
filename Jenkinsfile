pipeline {
    agent any
    stages {
        stage ('checkout') {
            steps {
                checkout scm
            }
        }

        stage ('build') {
            steps {
                gitlabCommitStatus(name: 'build') {
                    script {
                        def image = docker.build('minerva50', "-f develop.dockerfile ${WORKSPACE}")
                    }
                }
            }
        }
    }
}
