node('docker'){
  stage('Checkout') {
    checkout scm
  }

  stage('Unittests database') {
    sh "rm -rf test_results"

    sh "bin/run-tests"

    archiveArtifacts("test_results/**/*.tap")
    step([$class: 'TapPublisher', testResults: 'test_results/**/*.tap'])
  }
}
