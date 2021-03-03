[docker@kfdcel01 ~]$ cat ./docker_build/aem-adobe/buildAndPush.sh
#!/usr/bin/env bash

PROJECT=$1
[[ -n "${PROJECT}" ]] || exit 1

BASEDIR=/home/hl/docker/docker_build/${PROJECT}

DB_HOSTS_DEVE='"esdb:9200"'
DB_HOSTS_TEST='"esdb:9200"'
DB_HOSTS_PROD='"kfdcel02.hlcl.com:9200", "kfdcel03.hlcl.com:9200", "kfdcel04.hlcl.com:9200", "kfdcel05.hlcl.com:9200"'

DB_TEAM_INDEX="\"hlog-${PROJECT}-%{+yyyy.MM.dd}\""

for ENV in "deve" "test" "prod"
do
    echo -e "\n\n#######################\n#### BUILDING ${ENV} ####\n#######################\n"

    # create env dirs
    cd "${BASEDIR}"
    mkdir -p "${ENV}/pipeline"

    # copy files to env dirs
    cp 1-input/1-input.conf 2-filter/*.conf 3-output/3-output.conf ${ENV}/pipeline/
    cp Dockerfile logstash.yml ${ENV}/
    cd "${BASEDIR}/${ENV}"

    # preparing files based on environment and project
    [[ ${ENV} == 'deve' ]] && DB="${DB_HOSTS_DEVE}"
    [[ ${ENV} == 'test' ]] && DB="${DB_HOSTS_TEST}"
    [[ ${ENV} == 'prod' ]] && DB="${DB_HOSTS_PROD}"

    sed -i "s/DB_HOSTS/${DB}/g" logstash.yml
    sed -i "s/DB_HOSTS/${DB}/g" pipeline/3-output.conf
    sed -i "s/DB_TEAM_INDEX/${DB_TEAM_INDEX}/g" pipeline/3-output.conf

    # build images and push to registry
    /bin/docker image rm -f localhost:5000/logstash-"${PROJECT}"-"${ENV}" >/dev/null 2>&1 || true
    /bin/docker build --no-cache -t localhost:5000/logstash-"${PROJECT}"-"${ENV}" "${BASEDIR}"/"${ENV}"
    /bin/docker push localhost:5000/logstash-"${PROJECT}"-"${ENV}"
done
[docker@kfdcel01 ~]$
