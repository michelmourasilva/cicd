/*
 * DEFININDO VARIAVEIS GLOBAIS PARA CRIAÇÃO DE APP E ROTA (PATH) NO OPENSHIFT
 */
def app = null
def path = null
def tag = "latest"

/*
 * FUNÇÃO PARA VALIDAR REBASE, AINDA SERÁ IMPLEMENTADA
 */
def validarRebase() {
	echo "Validar Rebase"
}

// INICIANDO O PIPELINE DO JENKINS COM A VERIFICAÇÃO DE VARIAVEIS NECESSÁRIAS
node(label: 'master') {

    // CRIA UM STAGE COM NOME DA TAREFA
    stage("Verificando variaveis necessarias") {
        /*
         * VERIFICA SE A VARIAVEL gitlabSourceRepoHttpUrl ESTA CRIADA
         * ESTA VARIAVEL E PASSADA ATRAVÉS DO PUSH DO GIT
         */
        if (!env.gitlabSourceRepoHttpUrl) {
            error "Preencha a variavel gitlabSourceRepoHttpUrl nas configurações do pipeline"
        }
    }

    /*
     * VARIAVEL CRIADA NO JOB PARA APRESENTAR AS VARIAVEIS DO JENKINS
     */
    if ((env.DEBUG) && (env.DEBUG.toBoolean())) {
        stage("Mostando variaveis do Jenkins") {
            sh "printenv"
        }
    }
}

/*
 * INICIA O BUILD
 */
node(label: 'master') {

    /*
     * DELETA TODOS OS ARQUIVOS DA PASTA
     */
    deleteDir()

    /*
     * REALIZA O CHECKOUT DO GIT COM AS INFORMAÇÕES DO GITLAB
     * E CREDENCIAL GLOBAL DO JENKINS
     */




    stage('Checkout do Git') {
        git url: '${gitlabSourceRepoHttpUrl}',
            branch: '${gitlabSourceBranch}',
            credentialsId: 'GIT_CREDENTIALS'
    }
}


def build(String ambiente, String imageBase, String imageFinal, String dockerEnv) {

    
	def AMBIENTE_ANGULAR
    def registry = "172.19.0.7:5000"

    def PATH_BUILD = "${WORKSPACE}"
	
    stage("Build do container - ${ambiente}") {
	
    echo " >>>>>>>>>>>>>>>  Método de build - Variáveis: 'ambiente': ${imageBase} | 'imagemFinal': ${imageFinal} | 'dockerEnv': ${dockerEnv} "
    
    
    	 docker.withRegistry('http://172.19.0.7:5000') {

        //   try {
        //       script {
        //           sh "docker images ${registry}/root/${imageBase} -q | xargs --no-run-if-empty docker rmi --force"
        //           sh "docker images ${registry}/root/${gitlabSourceRepoName}* -q | xargs --no-run-if-empty docker rmi --force"
        //       }
        //   }
        //   /*
        //    * CASO A EXCLUSÃO GERE UM ERRO DE IMAGEM AINDA ESTÁ EM USO
        //    * OU NÃO HÁ MAIS IMAGENS PARA SEREM EXCLUIDAS
        //    * ESTE SERÁ IGNORADO, POIS NÃO É UM ERRO DE BUILD
        //    */
        //   catch (all) {}
               echo ">>>>>>>>>> 1 >>>>>>>>>>>docker pull ${registry}/root/${gitlabSourceRepoName}/${imageBase}"
               echo ">>>>>>>>>> 3 >>>>>>>>>>>docker build -t ${PATH_BUILD} ${registry}/root/${gitlabSourceRepoName}/${imageBase} -t ${registry}/sistemas/${imageFinal} . -f Dockerfile.production ${dockerEnv}"
               echo ">>>>>>>>>> 3 >>>>>>>>>>>docker push ${registry}/root/${gitlabSourceRepoName}/${imageFinal}"



		//node(label: 'master') {
        node(label: 'dind-node') {

        echo "********************************************************"
        echo "Iniciando o processo de pull, build e push das imagens"
        echo "********************************************************"

        sh "docker pull ${registry}/root/${gitlabSourceRepoName}/${imageBase}"
        sh "docker build -t ${PATH_BUILD} ${registry}/root/${gitlabSourceRepoName}/${imageBase} -t ${registry}/sistemas/${imageFinal} . -f Dockerfile.production ${dockerEnv}"
        sh "docker push ${registry}/root/${gitlabSourceRepoName}/${imageFinal}"


           }

        }
	}
}	



/*
 * CRIADA FUNÇÃO PARA DEPLOY NOS PROJETOS NO KUBERNETS
 */
def deployKubernets(String cluster, String ambiente, String imageName, String subDominio){

	 stage("Kubernets - Deploy em ${ambiente}") {
		 script {
			  echo " >>>>>>>>>>>>>>>  Método de deploy - Variáveis: 'cluster': ${cluster} | 'ambiente': ${ambiente} | 'imageName': ${imageName}  | 'subDominio': ${subDominio}"
		 }
}
}


/*
 * CRIADA FUNÇÃO PARA CRIAR TAG NO GITLAB
 */
def criarTag(String tag, String mensagem) {

    stage("Criando tag") {

        echo " >>>>>>>>>>>>>>>  Método de tag - Variáveis: 'tag': ${tag} | 'mensagem': ${mensagem} "

        /*
         * TRATA AS CREDENCIAIS GLOBAIS DO GITLAB DEFINIDAS NO JENKINS
         */
        withCredentials([
            [$class: 'UsernamePasswordMultiBinding',
                credentialsId: 'GIT_CREDENTIALS',
                usernameVariable: 'GIT_USERNAME',
                passwordVariable: 'GIT_PASSWORD'
            ]
        ]) {

            /*
             * CRIA VARIAVEL COM O REPOSITORIO DO GIT E A TAG
             * ESTE SE FEZ NECESSÁRIO POIS O SH NÃO ESTAVA INTERPRETANDO A VARIAVEL "tag"
             */
            gitPush = sh(returnStdout: true, script: "echo ${gitlabSourceRepoHttpUrl} ${tag}| sed 's/http:\\/\\///g'")

            /*
             * CRIA, LOCALMENTE, A TAG A SER ENVIADA PARA O GITLAB
             * REPASSA O NOME DA TAG E A MENSAGEM DO COMMIT
             * DE ACORDO COM OS VALORES PASSADOS NA CHAMADA DA FUNÇÃO
             */
            sh("git tag -a ${tag} -m \"${mensagem}\" ")

            /*
             * REALIZA O PROCESSO DE PUSH DO COMMIT LOCAL
             */
            sh("git push http://${GIT_USERNAME}:${GIT_PASSWORD}@${gitPush}")

        }
    }
}


/*
 * REALIZA O BUILD DO PIPELINE COM CHAMADAS DE FUNÇÕES
 */

node {

    if (env.IMAGE_TAG) {
        tag = "${IMAGE_TAG}"
    }
    build("Único", "python-prf:${tag}", "${gitlabSourceRepoName}:${BUILD_NUMBER}", "--env=UPGRADE_PIP_TO_LATEST=True")

}
node(label: 'master') {

    echo "**********************************"
    echo "deploy kubernets - desenvolvimento"
    echo "**********************************"

	deployKubernets("kubernets-desenvolvimento", "desenvolvimento", "${gitlabSourceRepoName}:${BUILD_NUMBER}", "app")

}

stage('Aprovar para HOM') {
    timeout(time: 7, unit: 'DAYS') {
        input message: "Provomer para Homologação?", ok: "Promover"
    }
}

node(label: 'master') {

    echo "**********************************"
    echo "deploy kubernets - homologação    "
    echo "**********************************"

	deployKubernets("kubernets-homologacao", "homologacao", "${gitlabSourceRepoName}:${BUILD_NUMBER}", "app")

    criarTag("${gitlabSourceBranch}.${BUILD_NUMBER}", "Jenkins Tag Homologação")

}

stage('Aprovar para PROD'){
    timeout(time:7, unit:'DAYS'){
        input message: '''Deploy em Produção, somente membros da Equipe de Rede Linux

Promover para Produção?''',
        ok: "Promover",
        submitter: 'Equipe de Rede (Linux)'
    }
}

node(label: 'master') {

    echo "**********************************"
    echo "deploy kubernets - produção       "
    echo "**********************************"


//    stage('Verificar REBASE') {
//        validarRebase()
//    }

    retry(3){

        if (!env.PROJETO_PRODUCAO){
            PROJETO_PRODUCAO = input(message: 'Projeto em Produção', ok: 'Salvar', parameters: [string(defaultValue: 'Docker-teste', description: 'Digite o nome do projeto do Openshift para deploy em produção', name: 'PROJETO_PRODUCAO')])

            input message: """Caso o projeto seja novo, adicionar a seguinte permissão:
            oc policy add-role-to-user edit system:serviceaccount:openshift:jenkins -n ${PROJETO_PRODUCAO}
            Após, crie uma variável no pipeline do tipo String com nome PROJETO_PRODUCAO e valor ${PROJETO_PRODUCAO}"""

        }
		deployKubernets("kubernets-producao", "${PROJETO_PRODUCAO}", "${gitlabSourceRepoName}:${BUILD_NUMBER}", "apps")
    }
    criarTag("V-${gitlabSourceBranch}.${BUILD_NUMBER}", "Jenkins Tag Produção")
}
