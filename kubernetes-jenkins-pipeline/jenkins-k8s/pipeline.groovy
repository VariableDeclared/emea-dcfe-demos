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
                    sh 'terraform init -upgrade || true'
                    writeFile file: './id_rsa.pub', text: SSH_PUBLIC_KEY
                    // sh 'for domain in  Engineering Support Administration; \
                    // do openstack domain set --disable $domain; done'
                    // sh 'terraform apply -auto-approve -destroy'
                    sh 'terraform apply -auto-approve'
                // sh './scripts/generate-jujumetadata.sh'
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
                    sh 'juju bootstrap openstack_cloud \
                     --metadata-source ~/simplestreams \
                     --model-default="network=Frontend" \
                     --model-default=external-network="ext-net"\
                     --bootstrap-constraints="allocate-public-ip=true"'
                }
            }
        }
        stage('Deploy Kubernetes') {
            steps {
                dir('jenkins-terraform') {
                    sh 'juju add-model k8s-jenkins'
                    sh 'juju deploy ./micro-ck8s.yaml'
                }
            }
        }
    }
    post {
        // Clean after build
        always {
            cleanWs(cleanWhenNotBuilt: false,
                    deleteDirs: true,
                    disableDeferredWipeout: true,
                    notFailBuild: true,
                    patterns: [[pattern: '.gitignore', type: 'INCLUDE'],
                               [pattern: '.propsfile', type: 'EXCLUDE']])
        }
    }
}
