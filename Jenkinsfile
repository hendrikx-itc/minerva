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
                    def image = docker.build('minerva50', 'dockerfile.develop')
                }
            }
        }
    }
}
