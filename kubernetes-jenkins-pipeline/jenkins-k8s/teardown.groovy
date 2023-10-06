final JUJU_CREDENTIAL_TEMPLATE = '''
credentials:
  aws:
    aws-juju-user:
      access-key: ${access_key}
      auth-type: access-key
      secret-key: ${access_secret}
'''

final CFG_PATH = './credentials.yaml'

import groovy.text.StreamingTemplateEngine

def renderTemplate(input, variables) {
    def engine = new StreamingTemplateEngine()
    return engine.createTemplate(input).make(variables).toString()
}

def base64Decode(encodedString){
    byte[] decoded = encodedString.decodeBase64()
    String decode = new String(decoded)
    return decode
}
// TODO: clean Teardown

pipeline {
    agent any
    parameters {
        string(name: 'UBUNTU_IMAGE_ID', defaultValue: 'none', description: 'Openstack image ID')
        string(name: 'OS_SERIES', defaultValue: 'jammy', description: 'Ubuntu OS Series')
        string(name: 'OPENSTACK_REGION', defaultValue: 'RegionOne', description: 'Openstack regions')
        string(name: 'OPENSTACK_URL', defaultValue: 'https://keystone.orange.box:5000/v3', description: 'Keystone URL')
        string(name: 'GIT_REPO', defaultValue: 'https://github.com/VariableDeclared/jenkins-terraform', description: 'Git URL')
        string(name: 'O7K_USER_NAME', defaultValue: 'Alice', description: 'O7K User to be created')
        string(name: 'O7K_PASSWD', defaultValue: 'Alice', description: 'O7K User to be created')
        string(name: 'KUBERNETES_NAME', defaultValue: 'jenkins-k8s', description: 'The name for Kubernetes')
        string(name: 'CONTROLLER_NAME', defaultValue: 'openstack-controller', description: 'Juju controller name')
        
    }
    stages {
        stage('Git Checkout') {
            steps {
                checkout scmGit(branches: [[name: 'main']],
                    userRemoteConfigs: [
                        [url: params.GIT_REPO]
                    ],
                    extensions: [[$class: 'RelativeTargetDirectory',
                        relativeTargetDir: 'jenkins-terraform']]
                    )
            }
        }
        stage('Build Openstack Environment') {
            environment {
                SSH_PUBLIC_KEY = credentials('public-ssh-key')
            }
            steps {
                dir('jenkins-terraform') {
                    sh 'sudo snap install terraform --classic || true'
                    sh 'sudo snap install juju-wait --classic || true'
                    sh 'terraform init -upgrade || true'
                    writeFile file: './id_rsa.pub', text: SSH_PUBLIC_KEY
                    sh 'terraform apply -auto-approve'
                }
            }
        }
        stage('Bootstrap juju') {
            environment {
                NOVA_RC_BASE64 = credentials('jenkins-novarc')
                OPENSTACK_CA_CERT = credentials('o7k-ca-cert')
            }
            steps {
                dir('jenkins-terraform') {
                    sh 'sudo snap install juju || true'
                    sh "mkdir -p ${HOME}/.local/share || true"

                    sh "./scripts/setup-juju-o7k-cloud.sh ${params.OPENSTACK_URL} \
                     ${OPENSTACK_CA_CERT} ${params.O7K_PASSWD} \
                    Engineering Development ${params.O7K_USER_NAME}"
                    // writeFile file: CFG_PATH, text:
                    // renderTemplate(JUJU_CREDENTIAL_TEMPLATE,
                    // ['access_key': JUJU_ACCESS_KEY, 'access_secret': 
                    // JUJU_ACCESS_SECRET])
                    writeFile file: "${WORKSPACE}/novarc", text: base64Decode(NOVA_RC_BASE64)
                    sh "./scripts/generate-jujumetadata.sh \
                    ${WORKSPACE}/novarc ${params.UBUNTU_IMAGE_ID} \
                    ${params.OS_SERIES} ${params.OPENSTACK_REGION} \
                    ${params.OPENSTACK_URL}"
                    sh "juju bootstrap openstack_cloud \
                     --metadata-source ~/simplestreams \
                     --model-default='network=Frontend' \
                     --model-default='external-network=ext-net'\
                     --bootstrap-constraints='allocate-public-ip=true'\
                     ${params.CONTROLLER_NAME}"
                }
            }
        }
        stage('Deploy Kubernetes') {
            steps {
                dir('jenkins-terraform') {
                    sh "juju add-model ${params.KUBERNETES_NAME}"
                    // TODO: below should be a configurable bundle.
                    sh 'juju deploy ./micro-ck8s.yaml'
                }
            }
        }
        stage('Juju wait') {
            steps {
                dir('jenkins-terraform') {
                    sh 'juju-wait -v'
                }
            }
        }
        stage('Copy Kubeconfig') {
            steps {
                sh "juju scp kubernetes-control-plane/0:~/config ./${params.KUBERNETES_NAME}.kubeconfig"
                echo "Complete. \
                Kubernetes configuration can be found at: \
                ${WORKSPACE}/${params.KUBERNETES_NAME}.kubeconfig"
            }
        }
    }
    post {
        // Clean after build
        always {
            cleanWs(cleanWhenNotBuilt: false,
                    deleteDirs: false,
                    disableDeferredWipeout: true,
                    notFailBuild: true,
                    patterns: [[pattern: '.gitignore', type: 'INCLUDE'],
                               [pattern: '.propsfile', type: 'EXCLUDE']])
        }
    }
}
