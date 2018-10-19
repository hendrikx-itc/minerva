node('git'){
  stage('Checkout') {
    checkout scm
  }

  stage('Unittests database') {
    sh "mkdir -p test_results && chmod 777 test_results"
    sh "rm -f test_results/*"

    def img = docker.build("database_unittest", "-f test.dockerfile .")
    img.withRun("-v ${WORKSPACE}/test_results:/test_results -v ${WORKSPACE}/tests:/tests") {
        /* do nothning */
    }

    archiveArtifacts("test_results/*.tap")
    step([$class: 'TapPublisher', testResults: 'test_results/*.tap'])
  }

  stage('Build documentation') {
    def img = docker.build('readthedocs', '-f readthedocs.dockerfile .')
    img.inside(){
      sh "cd doc/ && make html"
    }

    sh "tar -czvf readthedocs.tar.gz doc/_build/*"
    archiveArtifacts("readthedocs.tar.gz")
  }

  stage('Publish documentation') {
    sh "cp -R ${WORKSPACE}/doc/_build/html/* /documentation/minerva-prototype-doc/"
  }
}
