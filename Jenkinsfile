pipeline {
  agent {
    kubernetes {
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    some-label: jenkins-kaniko
spec:
  serviceAccountName: jenkins-sa
  containers:
    - name: kaniko
      image: gcr.io/kaniko-project/executor:v1.16.0-debug
      imagePullPolicy: Always
      command:
        - sleep
      args:
        - 99d
    - name: git
      image: alpine/git:2.45.2
      imagePullPolicy: Always
      command:
        -sleep
      args:
        - 99d
"""
    }
  }

  environment {
    ECR_REGISTRY = "265766434317.dkr.ecr.us-east-2.amazonaws.com"
    IMAGE_NAME   = "django-app"
    IMAGE_TAG    = "latest"

    COMMIT_EMAIL = "jenkins@localhost"
    COMMIT_NAME  = "jenkins"
  }

  stages {
    stage('Build & Push Docker Image') {
      steps {
        container('kaniko') {
          sh '''
            /kaniko/executor \\
              --context $(pwd)/docker/django \\
              --dockerfile Dockerfile \\
              --destination=$ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG \\
              --cache=false \\
              --insecure \\
              --skip-tls-verify
          '''
        }
      }
    }
    stage('Update Chart Tag in Git') {
      steps {
        container('git') {
          withCredentials([usernamePassword(credentialsId: 'github-token', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PAT')]) {
            sh '''
              REPO_URL="https://$GIT_USERNAME:$GIT_PAT@github.com/demosph/goit-devops-hw.git"
              git clone --branch lesson-8-9 "$REPO_URL"
              cd goit-devops-hw

              sed -i 's/^\\s*tag:\\s*.*/  tag: '"$IMAGE_TAG"'/' lesson-8-9/charts/django-app/values.yaml

              git config user.email "$COMMIT_EMAIL"
              git config user.name "$COMMIT_NAME"

              git add lesson-8-9/charts/django-app/values.yaml
              git commit -m "Update image tag to $IMAGE_TAG" || echo "No changes to commit."
              git push origin lesson-8-9
            '''
          }
        }
      }
    }
  }
}