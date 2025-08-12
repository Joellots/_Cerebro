pipeline {
  agent none

  environment {
    DB_HOST='localhost'
    DB_NAME='cerebro_db'
    DB_PORT='5432'
    REGISTRY = 'joellots/cerebro'
    SEMGREP_APP_TOKEN = credentials('SEMGREP_APP_TOKEN')
    GITOPS_REPO= credentials('gitops-repo')
  }

  parameters {
    choice(name: 'VERSION', choices: ['v1.1.0', 'v1.2.0', 'v1.3.0'], description: '')
    booleanParam(name: 'executeTests', defaultValue: false, description: '')
  }

  
  stages {

    stage('Checkout') {
        agent {
        label 'jenkins-agent-dind'
      }
      steps {
        checkout scm
      }
    }

    stage('Build') {
      agent {
        label 'jenkins-agent-dind'
      }
      steps {
        echo 'Building the application...'
        withCredentials([
          usernamePassword(credentialsId: 'DB_CREDENTIALS', usernameVariable: 'DB_USER', passwordVariable: 'DB_PASSWORD')
        ]) {
          withEnv(["VERSION=${params.VERSION}"]) {
          sh '''
            docker container rm cerebro --force || true
            docker container rm postgres --force || true
            docker rmi $REGISTRY:$VERSION || true

            docker build -t $REGISTRY:$VERSION .
            docker compose -f docker-compose-db.yaml up -d --build
            docker compose -f docker-compose-app.yaml up -d --build
          '''
          }
        }
      }
    }

    stage('Unit Tests') {
      when {
        expression { params.executeTests }
      }
      agent {
        label 'jenkins-agent-dind'
      }
      steps {
        sh '''
        echo [INFO]Running tests...
        docker exec cerebro pytest --junitxml=test-results.xml --cov || true
        docker cp cerebro:/cerebro/test-results.xml /tmp/test-results.xml
        docker cp /tmp/test-results.xml jenkins-agent-dind:$(pwd)/test-results.xml
        '''
      }
      post {
        always {
          junit 'test-results.xml'
          archiveArtifacts artifacts: 'test-results.xml', fingerprint: true
        }
      }
    }


    stage('Gitleaks Secret Scan') {
      agent {
        kubernetes {
        defaultContainer 'gitleaks'
        yaml '''
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: gitleaks
                image: zricethezav/gitleaks
                command:
                - cat
                tty: true
            '''
        }
      }
      steps {       
        sh '''
          echo "[INFO] Running Gitleaks scan..."
          gitleaks detect --verbose --source . -f json -r gitleaks.json || true
          echo "[INFO] Gitleaks scan complete. Artifacts will be archived."
        '''   
      }
      post {
        always {
          archiveArtifacts artifacts: 'gitleaks.json', fingerprint: true
        }
      }
    }

    stage('Semgrep Scan') {
      agent {
        kubernetes {
        defaultContainer 'semgrep'
        yaml '''
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: semgrep
                image: semgrep/semgrep
                command:
                - cat
                tty: true
                volumeMounts:
                - name: workspace-volume
                  mountPath: /src
            '''
        }
      }
      steps {
        sh ''' 
          echo "[INFO] Running Semgrep scan..."
          semgrep scan --json --output semgrep.json /src || true
          echo "[INFO] Semgrep scan complete. Artifacts will be archived."
        ''' 
      }
      post {
        always {
          archiveArtifacts artifacts: 'semgrep.json', fingerprint: true
        }
      }
    }


    stage('Bandit Scan') {
      agent {
        kubernetes {
        defaultContainer 'python'
        yaml '''
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: python
                image: python
                command:
                - cat
                tty: true
            '''
        }
      }
      steps {
        sh ''' 
          echo "[INFO] Installing Bandit scan..."
          pip3 install bandit
          echo "[INFO] Running Bandit scan..."
          bandit -r . -f json -o bandit.json || true
          echo "[INFO] Bandit scan complete. Artifacts will be archived."
        ''' 
      }
      post {
        always {
          archiveArtifacts artifacts: 'bandit.json', fingerprint: true
        }
      }
    }


    stage('Checkov Scan') {
      agent {
        kubernetes {
        defaultContainer 'checkov'
        yaml '''
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: checkov
                image: bridgecrew/checkov:latest
                command:
                - cat
                tty: true
            '''
        }
      }
      steps {
        sh '''
          echo "[INFO] Running Checkov scan..."
          checkov -d . -o junitxml | tee checkov.test.xml || true
          echo "[INFO] Checkov scan complete. Artifacts will be archived."
        ''' 
      }
      post {
        always {
          archiveArtifacts artifacts: 'checkov.test.xml', fingerprint: true
        }
      }
    }


    stage('Push Image') {
      agent {
        label 'jenkins-agent-dind'
      }
      steps {
        withCredentials([
          usernamePassword(credentialsId: 'joellots-dockerhub', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASSWORD')
        ]) {
          withEnv(["VERSION=${params.VERSION}"]) {
            sh '''
            echo $DH_PASSWORD | docker login -u $DH_USER --password-stdin
            docker push $REGISTRY:$VERSION
            '''
          }
        }
      }
    }


    stage('Deploy App') {
      agent {
        kubernetes {
        yaml '''
            apiVersion: v1
            kind: Pod
            spec:
            '''
        }
      }
      steps {
        withCredentials([
          usernamePassword(credentialsId: 'gitlab-credentials', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')
        ]) {
          withEnv(["VERSION=${params.VERSION}"]) {
            echo "Deploying version $VERSION of Cerebro Application"
            input message: 'Do you want to continue?', ok: 'Yes'
            echo "Pushing new deployment manifest to GitOps repo..."

            sh '''
            git config --global user.email "${GIT_USER}@gmail.com"
            git config --global user.name "${GIT_USER}"

            git clone https://${GIT_USER}:${GIT_PASS}@$GITOPS_REPO
            cd gitops-cerebro/base

            sed -i "s|image: $REGISTRY:.*|image: $REGISTRY:$VERSION|" deployment.yaml
            cat deployment.yaml
            
            cd ..
            git init
            git add .
            git commit -m "Deploy Cerebro $VERSION via CI pipeline"
            git branch -M main
            git remote remove origin || true
            git remote add origin https://${GIT_USER}:${GIT_PASS}@$GITOPS_REPO
            git push origin main
            '''
          }
        }
      }
    }
  }
}
