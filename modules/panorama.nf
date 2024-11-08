
def exec_java_command(mem) {
    def xmx = "-Xmx${mem.toGiga()-1}G"
    return "java -Djava.aws.headless=true ${xmx} -jar /usr/local/bin/PanoramaClient.jar"
}

def url_name_to_file_name(url_basename) {
    return url_basename.replaceAll('%20', ' ')
}

String setupPanoramaAPIKeySecret(secret_id, executor_type) {

    if(executor_type != 'awsbatch') {
        return ''
    } else {
        SECRET_NAME = 'PANORAMA_API_KEY'
        REGION = params.aws.region

        return """
            echo "Getting Panorama API key from AWS secrets manager..."
            SECRET_JSON=\$(${params.aws.batch.cliPath} secretsmanager get-secret-value --secret-id ${secret_id} --region ${REGION} --query 'SecretString' --output text)
            PANORAMA_API_KEY=\$(echo \$SECRET_JSON | sed -n 's/.*"${SECRET_NAME}":"\\([^"]*\\)".*/\\1/p')
        """
    }
}

process PANORAMA_GET_PROJECT_FILE {
    label 'process_low_constant'
    container params.images.panorama_client
    publishDir "${params.result_dir}/panorama", failOnError: true, mode: 'copy', pattern: "*.stdout"
    publishDir "${params.result_dir}/panorama", failOnError: true, mode: 'copy', pattern: "*.stderr"
    secret 'PANORAMA_API_KEY'

    input:
        tuple val(study_name), val(file_path)
        val aws_secret_id

    output:
        tuple val(study_name), path("${url_name_to_file_name(file(file_path).name)}")

    script:
        file_name = file(file_path).name
        
        """
        ${setupPanoramaAPIKeySecret(aws_secret_id, task.executor)}

        echo "Downloading ${file_name} from Panorama..."
        ${exec_java_command(task.memory)} \
            -d \
            -w "${file_path}" \
            -k \$PANORAMA_API_KEY \
            > >(tee "panorama-get-${file_name}.stdout") 2> >(tee "panorama-get-${file_name}.stderr" >&2)
        echo "Done!" # Needed for proper exit
        """

    stub:
        """
        touch "${url_name_to_file_name(file(file_path).name)}"
        touch stub.stdout stub.stderr
        """
}

process PANORAMA_GET_FILE {
    label 'process_low_constant'
    container params.images.panorama_client
    publishDir "${params.result_dir}/panorama", failOnError: true, mode: 'copy', pattern: "*.stdout"
    publishDir "${params.result_dir}/panorama", failOnError: true, mode: 'copy', pattern: "*.stderr"
    secret 'PANORAMA_API_KEY'

    input:
        val web_dav_dir_url
        val aws_secret_id

    output:
        path("${file(web_dav_dir_url).name}"), emit: panorama_file
        path("*.stdout"), emit: stdout
        path("*.stderr"), emit: stderr

    script:
        file_name = file(web_dav_dir_url).name

        """
        ${setupPanoramaAPIKeySecret(aws_secret_id, task.executor)}

        echo "Downloading ${file_name} from Panorama..."
        ${exec_java_command(task.memory)} \
            -d \
            -w "${web_dav_dir_url}" \
            -k \$PANORAMA_API_KEY \
            > >(tee "panorama-get-${file_name}.stdout") 2> >(tee "panorama-get-${file_name}.stderr" >&2)
        echo "Done!" # Needed for proper exit
        """

    stub:
    """
    touch "${file(web_dav_dir_url).name}"
    touch stub.stdout stub.stderr
    """
}
