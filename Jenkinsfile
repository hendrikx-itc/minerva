node ('git') {
    stage ('checkout') {
        checkout scm
    }

    stage ('build') {
        gitlabCommitStatus(name: 'build') {
            sh "docker-compose -f develop-compose.yml up -d"
            sh "./wait-for-db"
            sh "bin/db stop"
        }
    }
}
