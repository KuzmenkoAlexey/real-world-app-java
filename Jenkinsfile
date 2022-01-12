def _message

pipeline {
  agent {
      kubernetes {
      defaultContainer 'jnlp'
      yaml """
apiVersion: v1
kind: Pod
metadata:
labels:
  component: ci
spec:
  serviceAccountName: jenkins-robot
  containers:
  - name: docker
    image: google/cloud-sdk:368.0.0
    command:
    - cat
    tty: true
    volumeMounts:
    - mountPath: /var/run/docker.sock
      name: docker-sock
  - name: kctl
    image: alpine/k8s:1.21.2
    command:
    - cat
    tty: true
  volumes:
    - name: docker-sock
      hostPath:
        path: /var/run/docker.sock
"""
    }
  }

  triggers {
    GenericTrigger(
     genericVariables: [
      [key: 'ref', value: '$.ref']
     ],

     causeString: 'Triggered on $ref',

     token: 'backend-deploy-ababcd',
     tokenCredentialId: '',

     printContributedVariables: true,
     printPostContent: true,

     silentResponse: false,

     regexpFilterText: '$ref',
     regexpFilterExpression: 'refs/heads/main'
    )
  }

  options {
    disableConcurrentBuilds()
    timeout(time: 30, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '30'))
  }

  parameters {
    string(name: '_git_repo', defaultValue: 'https://github.com/KuzmenkoAlexey/real-world-app-java.git')
    string(name: '_git_branch', defaultValue: 'main' )
    string(name: '_gcp_repo', defaultValue: 'gcr.io/data-buckeye-288515/onboarding-springboot')
    string(name: '_namespace', defaultValue: 'kuzmenko-onboarding')
    string(name: '_deployment_name', defaultValue: 'javaapp')
    string(name: '_container_name', defaultValue: 'javaapp')
  }

  stages {
    stage('Git checkout') {
        steps {
            script {
              echo "Git checkout 1"
            }
            checkout([
              $class: 'GitSCM',
              userRemoteConfigs: [[credentialsId: "git", url: "${_git_repo}"]],
              branches: [[name: "${_git_branch}"]]
            ])
            script {
              echo "Git checkout 2"
              _git_commit = sh(returnStdout: true, script: "git log -n 1 --pretty=format:'%h'").trim()
              echo "Git Commit: ${_git_commit}"
            }
        }
    }

    stage('Build') {
        steps {
            container('docker') {
                script {
                    _build_args = """\
                      --network=host \
                    """
                    withCredentials([file(credentialsId: 'gcp_sa_key', variable: 'GC_KEY')]) {
                        sh("gcloud auth activate-service-account --key-file=${GC_KEY}")
                        sh("gcloud auth configure-docker")
                        def backendImage = docker.build("${_gcp_repo}:${_git_commit}", ".")
                        backendImage.push()
                    }
                }
            }
        }
    }

    stage('Deploy') {
        steps {
            container('kctl') {
                sh("kubectl -n ${_namespace} set image deployment/${_deployment_name} ${_container_name}=${_gcp_repo}:${_git_commit}")
            }
        }
    }
  }

  post {
   success {
      script {
        echo "success!!!"
      }
    }
  }

}
