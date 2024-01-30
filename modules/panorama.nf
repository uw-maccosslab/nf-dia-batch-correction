
def exec_java_command(mem) {
    def xmx = "-Xmx${mem.toGiga()-1}G"
    return "java -Djava.aws.headless=true ${xmx} -jar /usr/local/bin/PanoramaClient.jar"
}

def url_name_to_file_name(url_basename) {
    return url_basename.replaceAll('%20', ' ')
}

process PANORAMA_GET_FILE {
    label 'process_low_constant'
    container 'mriffle/panorama-client:1.0.0'
    publishDir "${params.result_dir}/panorama", failOnError: true, mode: 'copy', pattern: "*.stdout"
    publishDir "${params.result_dir}/panorama", failOnError: true, mode: 'copy', pattern: "*.stderr"

    input:
        tuple val(study_name), val(file_path)

    output:
        tuple val(study_name), path("${url_name_to_file_name(file(file_path).name)}")

    script:
        file_name = file(file_path).name
        
        """
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
