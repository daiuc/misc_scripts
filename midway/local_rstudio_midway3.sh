#!/bin/bash 



##-----------------------------------------------------##
##             Set up rstudio server on login          ##
##-----------------------------------------------------##


cd ~ && source ~/.bash_profile && pwd 


module load singularity/3.9.2
conda activate smk

RPORT=8755 # for rstudio

IP=$(/sbin/ip route get 8.8.8.8 | awk '{print $(NF-2);exit}') # different from midway2
echo -e "### DATE: $(date) ### \n"
echo -e "### IP: ${IP}\n\n"



##-----------------------------------------------------##
##             Launch rstudio server                   ##
##-----------------------------------------------------##
echo -e "\n\n### 2.  Rstudio ###"
echo "rstudio server running on http://${IP}:${RPORT}"

## set SIF

SIF="/scratch/midway3/chaodai/singularity/rstudio_rstudio-2023_06.sif" # R4.1.0 Rstudio 2023.06


# Rstudio server dir
RSTUDIO_TMP=/scratch/midway3/chaodai/singularity/rstudio-tmp-login-node
COOKIE_ID=/home/chaodai/rstudio-server/secure-cookie-key-login-node

echo -e "---------------\n\n\n"
# set conda, R, python binary
CONDA_PREFIX=/scratch/midway3/chaodai/miniconda3/envs/smk
R_BIN=$CONDA_PREFIX/bin/R
PY_BIN=$CONDA_PREFIX/bin/python

## export conda environment to container
export SINGULARITYENV_USER=chaodai
export SINGULARITYENV_RSTUDIO_WHICH_R=${R_BIN}
export SINGULARITYENV_CONDA_PREFIX=${CONDA_PREFIX}
export SINGULARITYENV_PATH="/software/singularity-3.9.2-el8-x86_64/bin:/scratch/midway3/chaodai/miniconda3/envs/smk/bin:/home/chaodai/bin:/usr/local/bin:/scratch/midway3/chaodai/miniconda3/condabin:/software/bin:/software/slurm-current-el8-x86_64/bin:/software/modules/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/opt/thinlinc/bin:\$PATH"
export SINGULARITYENV_CACHEDIR="/scratch/midway3/chaodai/singularity/singularity_cache"
export SINGULARITYENV_RSTUDIO_PASS=$RSTUDIO_PASS

RSTUDIO_SERVER_USER=chaodai # change to your own

## Bind project folder, note the if statement is to deal with RCC's mounting problem
if [[ -d "/project2" ]]; then
    PROJECTS="/project,/project2" # when omitting the destination path, it defaults to equal source
else
    PROJECTS="/project"
fi

# make sure RSTUDIO_PASS is exported in your bash profile
PASSWORD=${RSTUDIO_PASS} singularity exec \
    --bind $RSTUDIO_TMP/var/lib:/var/lib/rstudio-server \
    --bind $RSTUDIO_TMP/var/run:/var/run/rstudio-server \
    --bind $RSTUDIO_TMP/tmp:/tmp \
    --bind $RSTUDIO_TMP/database.conf:/etc/rstudio/database.conf \
    --bind $RSTUDIO_TMP/rsession.conf:/etc/rstudio/rsession.conf \
    --bind $RSTUDIO_TMP/rserver.conf:/etc/rstudio/rserver.conf \
    --bind $RSTUDIO_TMP/logging.conf:/etc/rstudio/logging.conf \
    --bind $RSTUDIO_TMP/file-locks:/etc/rstudio/file-locks \
    --bind /sys/fs/cgroup/:/sys/fs/cgroup/:ro \
    --bind /home/chaodai,/scratch/midway3/chaodai,/software \
    --bind $PROJECTS \
    $SIF \
    rserver --server-user $RSTUDIO_SERVER_USER \
        --rsession-which-r=${R_BIN} \
        --www-port=${RPORT} \
        --auth-none=0 \
        --auth-pam-helper-path=pam-helper \
        --auth-timeout-minutes=0 \
        --auth-stay-signed-in-days=30 \
        --secure-cookie-key-file=$COOKIE_ID







