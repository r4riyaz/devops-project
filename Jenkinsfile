pipeline {
  agent { label 'linux' }

  stages {
    stage('Clone Repo') {
      steps {
        sh 'git --version'
        git branch: 'main',
            url: '<URL-OF-YOUR_REPO>'
      }
    }

    stage('Build Docker Image') {
      steps {
        dir('apache-web') {
          sh 'docker rmi --force apache-web || true'
          sh 'docker build -t apache-web .'
        }
      }
    }

    stage('Run Apache Container') {
      steps {
        sh 'docker stop apache-web || true'
        sh 'docker rm apache-web || true'
        sh 'docker run -d -p 8899:80 --name apache-web apache-web'
      }
    }
  }
}
