pipeline {
    agent {
        node {
            label 'git'
        }
    }

    stages {
        stage ('checkout') {
            steps {
                checkout scm
            }
        }

        stage ('build') {
            steps {
                // Report status of stage 'build' back to Gitlab
                gitlabCommitStatus(name: 'build') {
                    // Populate changelog file with version information from git tag
                    dir ('debian') {
                        sh './make-changelog'
                    }

                    script {
                        //---------------------------
                        // Build Ubuntu 18.04 package
                        //---------------------------
                        def buildDir1804 = 'pkg-build/1804'

                        // Clean the build directory before starting
                        sh "rm -rf ${buildDir1804}"

                        sh './package 1804'
                        
                        switch (GIT_BRANCH) {
                            case "origin/master":
                                publishPackages buildDir1804.toString(), 'common/bionic/stable', 'bionic'
                                break
                            case "origin/release/5.0":
                                publishPackages buildDir1804.toString(), 'common/bionic/unstable', 'bionic'
                                break
                            case "origin/develop":
                                publishPackages buildDir1804.toString(), 'common/bionic/unstable', 'bionic'
                                break
                        }

                        archiveArtifacts(artifacts: "${buildDir1804}/*")
                    }
                }
            }
        }
    }
}
