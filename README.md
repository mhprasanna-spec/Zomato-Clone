# Zomato Clone — Secure Deployment with DevSecOps CI/CD

## 📌 Project Overview

This project demonstrates a complete **DevSecOps CI/CD pipeline** for deploying a Zomato Clone application using Jenkins, SonarQube, OWASP Dependency Check, Trivy, Docker, and AWS EC2.

The main objective is to automate:
- Code checkout from GitHub
- Static code analysis (SonarQube)
- Dependency vulnerability scanning (OWASP)
- Filesystem & container image scanning (Trivy)
- Docker image build and push to DockerHub
- Automated application deployment on AWS EC2

This project follows **DevSecOps principles** by integrating security scanning into every stage of the CI/CD pipeline — shifting security left and catching vulnerabilities before production.

---

## 🛠️ Tech Stack

| Category | Tools |
|---|---|
| CI/CD | Jenkins |
| Security | SonarQube, OWASP Dependency Check, Trivy |
| Containerization | Docker, DockerHub |
| Cloud | AWS EC2 (Ubuntu 22.04) |
| Application | ReactJS, NodeJS, NPM |

---

## 🚀 Architecture Workflow

```
Developer → GitHub → Jenkins Pipeline
    → SonarQube Analysis
    → Quality Gate
    → OWASP Dependency Scan
    → Trivy Filesystem Scan
    → Docker Build & Push
    → Trivy Image Scan
    → Deploy Container (Port 3000)
```

---

## 📂 Project Features

- ✅ Automated CI/CD Pipeline with Jenkins
- ✅ Static Code Analysis using SonarQube
- ✅ Dependency Vulnerability Scanning via OWASP Dependency Check
- ✅ Filesystem & Image Security Scanning via Trivy
- ✅ Docker Image Build & Push to DockerHub
- ✅ Automated Container Deployment
- ✅ Full DevSecOps Integration

---

## ⚙️ Prerequisites

Ensure the following are available before setup:

- AWS EC2 Ubuntu 22.04 Instance (T2 Large recommended)
- Jenkins
- Docker
- Java 17 (Temurin)
- NodeJS 16
- SonarQube
- Trivy
- OWASP Dependency Check Plugin

---

## ☁️ AWS EC2 Setup

### Launch EC2 Instance
- **OS:** Ubuntu 22.04
- **Type:** T2 Large

### Open Inbound Ports

| Port | Purpose |
|---|---|
| 22 | SSH |
| 8080 | Jenkins |
| 9000 | SonarQube |
| 3000 | Application |

---

## 🔧 Jenkins Installation

```bash
sudo apt update -y

wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public \
  | tee /etc/apt/keyrings/adoptium.asc

echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] \
  https://packages.adoptium.net/artifactory/deb \
  $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" \
  | tee /etc/apt/sources.list.d/adoptium.list

sudo apt update -y && sudo apt install temurin-17-jdk -y

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
  | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update -y && sudo apt install jenkins -y
sudo systemctl start jenkins && sudo systemctl enable jenkins
```

**Access Jenkins:** `http://<EC2-PUBLIC-IP>:8080`

```bash
# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

## 🐳 Docker Installation

```bash
sudo apt update && sudo apt install docker.io -y
sudo usermod -aG docker ubuntu
newgrp docker
sudo chmod 777 /var/run/docker.sock
docker --version
```

---

## 🔍 SonarQube Setup

```bash
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community
```

**Access:** `http://<EC2-PUBLIC-IP>:9000`  
**Default credentials:** `admin / admin`

---

## 🔐 Trivy Installation

```bash
sudo apt install wget apt-transport-https gnupg lsb-release -y

wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
  | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] \
  https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" \
  | sudo tee -a /etc/apt/sources.list.d/trivy.list

sudo apt update && sudo apt install trivy -y
trivy --version
```

---

## 🔌 Jenkins Plugins to Install

Navigate to **Manage Jenkins → Plugins → Available** and install:

- Eclipse Temurin Installer
- SonarQube Scanner
- NodeJS Plugin
- OWASP Dependency Check
- Docker Pipeline
- Docker API Plugin
- Docker Commons Plugin

---

## ⚙️ Jenkins Global Tool Configuration

Configure under **Manage Jenkins → Global Tool Configuration:**

| Tool | Name |
|---|---|
| JDK | `jdk17` |
| NodeJS | `node16` |
| SonarQube Scanner | `sonar-scanner` |
| Dependency-Check | `DP-Check` |

---

## 🔑 Jenkins Credentials to Add

| ID | Type | Purpose |
|---|---|---|
| `sonar-token` | Secret Text | SonarQube authentication token |
| `docker` | Username/Password | DockerHub credentials |

---

## 📜 Jenkins Pipeline

```groovy
pipeline {
    agent any

    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }

    stages {

        stage('Clean Workspace') {
            steps { cleanWs() }
        }

        stage('Checkout from Git') {
            steps {
                git branch: 'main',
                url: 'https://github.com/mudit097/Zomato-Clone.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh '''
                    $SCANNER_HOME/bin/sonar-scanner \
                    -Dsonar.projectName=zomato \
                    -Dsonar.projectKey=zomato
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                waitForQualityGate abortPipeline: false,
                credentialsId: 'sonar-token'
            }
        }

        stage('Install Dependencies') {
            steps { sh 'npm install' }
        }

        stage('OWASP FS SCAN') {
            steps {
                dependencyCheck(
                    additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit',
                    odcInstallation: 'DP-Check'
                )
                dependencyCheckPublisher(
                    pattern: '**/dependency-check-report.xml'
                )
            }
        }

        stage('TRIVY FS SCAN') {
            steps {
                sh 'trivy fs . > trivyfs.txt'
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                        sh 'docker build -t zomato .'
                        sh 'docker tag zomato yourdockerhub/zomato:latest'
                        sh 'docker push yourdockerhub/zomato:latest'
                    }
                }
            }
        }

        stage('TRIVY Image Scan') {
            steps {
                sh 'trivy image yourdockerhub/zomato:latest > trivy-image.txt'
            }
        }

        stage('Deploy Container') {
            steps {
                sh '''
                docker run -d \
                  --name zomato \
                  -p 3000:3000 \
                  yourdockerhub/zomato:latest
                '''
            }
        }
    }
}
```

---

## 🧪 Pipeline Stages Explained

| Stage | Purpose |
|---|---|
| Clean Workspace | Wipes Jenkins workspace for a fresh build |
| Checkout | Pulls latest code from GitHub main branch |
| SonarQube Analysis | Performs static code analysis for bugs & code smells |
| Quality Gate | Validates SonarQube quality thresholds |
| Install Dependencies | Runs `npm install` |
| OWASP FS Scan | Scans dependencies for known CVE vulnerabilities |
| Trivy FS Scan | Scans the filesystem for misconfigurations & vulnerabilities |
| Docker Build & Push | Builds image and pushes to DockerHub |
| Trivy Image Scan | Scans the Docker image before deployment |
| Deploy Container | Runs the containerized app on port 3000 |

---

## 📊 Security Tools Summary

| Tool | Layer | What It Catches |
|---|---|---|
| SonarQube | Code | Bugs, code smells, security hotspots |
| OWASP Dependency Check | Dependencies | Known CVEs in npm packages |
| Trivy (FS) | Filesystem | Misconfigurations, vulnerable libraries |
| Trivy (Image) | Container | OS/package vulnerabilities in Docker image |

---

## 🌐 Application Access

Once deployed:

```
http://<EC2-PUBLIC-IP>:3000
```

---

## 📈 Benefits of This DevSecOps Approach

- 🔒 Security integrated at every pipeline stage
- 🐛 Early vulnerability detection before production
- 🤖 Fully automated — no manual deployment steps
- ⚡ Faster release cycles with consistent quality gates
- 📋 Audit trail via scan reports (OWASP XML, Trivy TXT)

---

## 🔮 Future Enhancements

- [ ] Kubernetes deployment with Helm charts
- [ ] ArgoCD for GitOps-based continuous delivery
- [ ] Terraform for infrastructure as code
- [ ] Monitoring with Prometheus & Grafana
- [ ] Slack/email notifications on pipeline failure
- [ ] Upgrade to Node 18/20 and fix npm vulnerabilities

---

## 👨‍💻 Author

**Prasanna Waghmare**  
DevOps Engineer | Cloud & Automation

---

## ⭐ Conclusion

This project is a hands-on implementation of DevSecOps principles using industry-standard tools. By automating security scanning at every layer — code, dependencies, filesystem, and container — it ensures vulnerabilities are caught early, reducing risk and improving the overall reliability of the software delivery lifecycle.
if needed visit --> https://blog.prodevopsguytech.com/zomato-clone-secure-deployment-with-devsecops-cicd#heading-step-3-install-plugins-like-jdk-sonarqube-scanner-nodejs-owasp-dependency-check
