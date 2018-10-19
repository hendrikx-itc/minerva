node('git'){
  stage('Checkout') {
    checkout scm
  }

  stage('Unittests database') {
    sh "mkdir -p test_results && chmod 777 test_results"
    sh "rm -f test_results/*"

    def img = docker.build('minerva50db_test', '-f test.dockerfile .')
    img.withRun("-v ${WORKSPACE}/test_results/:/test_results/ -v ${WORKSPACE}/tests/:/tests/"){

    }

    sh "echo ${WORKSPACE}"

    archiveArtifacts("${WORKSPACE}/test_results/*.tap")
    step([$class: 'TapPublisher', testResults: "${WORKSPACE}/test_results/*.tap"])
  }

  stage('Build documentation') {
    def img = docker.build('readthedocs', '-f readthedocs.dockerfile .')
    img.withRun("-v ${WORKSPACE}/doc/:/documents/", "make html"){

    }


  }
}
