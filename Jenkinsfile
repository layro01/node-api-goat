pipeline {
  agent {
    docker {
      image 'node:8.16.0'
    }
  }
  stages {
    stage('Build') {
      steps {
        sh 'rm -rf node_modules && npm install'
      }
    }
    stage('Test') {
      steps {
        wrap([$class: 'VeracodeInteractiveBuildWrapper', location: 'host.docker.internal', port: '10010']) {
          sh 'curl -sSL https://s3.us-east-2.amazonaws.com/app.veracode-iast.io/iast-ci.sh | sh'
          sh 'export IASTAGENT_LOGGING_STDERR_LEVEL=info'
          sh 'LD_LIBRARY_PATH=$WORKSPACE npm run test-iast'
        }
      }
    }
    stage('Deploy') {
      steps {
        sh 'echo npm package would run here...'
      }
    }
  }
}