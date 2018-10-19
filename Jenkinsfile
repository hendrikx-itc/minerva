node('git'){
  stage('Checkout') {
    checkout scm
  }

  stage('Unittests database') {
    sh "rm -f test_results/*"

    def img = docker.build('minerva50db', '-f develop.dockerfile .')
    img.withRun("-v ${WORKSPACE}/test_results:/test_results -v ${WORKSPACE}/tests:/tests"){

    }

    archive('database/test_results/*.tap')
    step([$class: 'TapPublisher', testResults: 'database/test_results/*.tap'])
  }

  stage('Build documentation') {
    sh 'ls -l'
    def img = docker.build('readthedocs', '-f readthedocs.dockerfile .')
    img.withRun("-v ${WORKSPACE}/doc:/documents"){
      sh "make html"
    }
  }
}
