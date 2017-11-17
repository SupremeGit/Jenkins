pipeline {
    //agent { docker 'python:3.5.1' }
    /*stages {
       stage('build') {
            steps {
                sh 'python --version'
            }
        }
    }
    */

    agent any
    stages {
       stage('Build') {
            steps {
                //sh 'rm "test/helloworld/helloworld" '
		//sh "echo 'PWD = ' ${pwd()}"
		dir ('test/helloworld') {
		   //sh "echo 'New PWD =' ${pwd()}"
		   sh './build.sh'
		}

                //sh 'echo "Hello World"'
                /*sh '''
                    echo "Kewl. Multiline shell steps works too"
                    ls -lah
                '''
		*/
            }
	}

        stage('Test') {
            steps {
                sh 'test/helloworld/helloworld'
            }
        }

        stage('Deploy') {
            steps {
                sh 'echo Deploying...'
            }
	}
    }

    post {
        always {
	    //junit 'build/reports/**/*.xml'
	    deleteDir() /* clean up our workspace */
            echo 'Post: Build finished.'
        }
        success {
            echo 'Post: Build successful.'
        }
        failure {
            echo 'Post: Build failed.'
        }
        unstable {
            echo 'Post: Build marked as unstable.'
        }
        changed {
            echo 'Post: Pipeline state has changed.'
            //echo 'For example, if the Pipeline was previously failing but is now successful'
        }
    }

}
