pipeline {
    agent { 
        docker { 
            image 'node:9'
            args '-u 0:0 --net=host'
        }
    }
    stages {
        stage('Build') {
            steps {
                sh 'rm -rf node_modules'
                sh 'npm install'
            }
        }
        stage('Test'){
            steps {
                wrap([$class: 'HailstoneBuildWrapper', location: 'localhost', port: '10010']) {
                    sh 'export DEBUG=1 && curl -sSL https://s3.us-east-2.amazonaws.com/app.hailstone.io/iast-ci.sh | sh'
                    sh 'npm test'
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