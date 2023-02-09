#!/bin/sh
#SBATCH --time 35:59:00
#SBATCH -p broadwl
#SBATCH -c 4
#SBATCH --mem 20g
#SBATCH --job-name=rstudio
#SBATCH --account=pi-yangili1
#SBATCH --output=logs/sbatchLogRstudioContainer.log



##-----------------------------------------------------##
##             General set up                          ##
##-----------------------------------------------------##

WHICH_MIDWAY=midway3
log=logs/sbatchLogRstudioContainer.log

cd ~ && source ~/.bash_profile && pwd >$log

echo -e "\n Submited job: $SLURM_JOB_ID\n\n\n" >> $log

module load singularity/3.4.0 &>> $log
conda activate smk &>> $log


JPORT=9798 # configured in .jupyter/jupyter_server_config.py
RPORT=8282 # for rstudio
CPORT= # configured in .config/code-server/config.yaml


if [[ $WHICH_MIDWAY == midway2 ]]; then
    IP=$(/sbin/ip route get 8.8.8.8 | awk '{print $NF;exit}')
    echo -e "### DATE: $(date) ### \n" >> $log
    echo -e "### IP: ${IP}\n\n" >> $log
elif [[ $WHICH_MIDWAY == midway3 ]]; then
    IP=$(/sbin/ip route get 8.8.8.8 | awk '{print $(NF-2);exit}')
    echo -e "### DATE: $(date) ### \n" >> $log
    echo -e "### IP: ${IP}\n\n" >> $log
else
    echo -e "Can't determine if it's midway2 or midway3 \n" >> $log
fi

##-----------------------------------------------------##
##             Launch jupyter notebook                 ##
##-----------------------------------------------------##

echo -e "\n\n### 1.  Jupyter ###"
echo -e "jupyter server runing on http://${IP}:${JPORT}/lab \n" >> $log

#jupyter lab --ip=${IP}  >> showJupyterAddress.txt &
jupyter lab --port=$JPORT  >> $log &


##-----------------------------------------------------##
##             Launch code-server                      ##
##-----------------------------------------------------##

# configured to run with self signed certificate
# and accept all ip on port 8783
#echo "code-server runing on http://${IP}:${CPORT}" >> showRstudioAddress.txt
#sleep 5
#screen -dm bash -c "code-server igv"

##-----------------------------------------------------##
##             Launch rstudio server                   ##
##-----------------------------------------------------##
echo -e "\n\n### 2.  Rstudio ###"
echo "rstudio server running on http://${IP}:${RPORT}" >> $log
## set SIF
SIF=/scratch/midway2/chaodai/singularity/bajiame_rstudio_rstudio_2022_12.sif
#SIF="/scratch/midway2/chaodai/singularity/rstudio_R4.1.0-Rstudio2022.12-v2.sif"
RSTUDIO_TMP=/scratch/midway2/chaodai/singularity/rstudio-tmp

echo "using image $SIF" >> showRstudioAddress.txt
echo -e "---------------\n\n\n"
# set conda, R, python binary
CONDA_PREFIX=/scratch/midway2/chaodai/miniconda3/envs/smk
R_BIN=$CONDA_PREFIX/bin/R
PY_BIN=$CONDA_PREFIX/bin/python

## export conda environment to container
export SINGULARITYENV_USER=chaodai
export SINGULARITYENV_RSTUDIO_WHICH_R=${R_BIN}
export SINGULARITYENV_CONDA_PREFIX=${CONDA_PREFIX}
export SINGULARITYENV_PATH=/opt/pyenv/plugins/pyenv-virtualenv/shims:/home/chaodai/.pyenv/shims:/opt/pyenv/bin:/home/chaodai/.local/bin:/usr/lib/rstudio-server/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/chaodai/bin:/home/chaodai/.local/bin:/scratch/midway2/chaodai/miniconda3/envs/smk/bin:\$PATH
export SINGULARITYENV_CACHEDIR=/scratch/midway2/chaodai/singularity/singularity_cache
export SINGULARITYENV_MODULES_CMD=/software/modules/libexec/modulecmd.tcl
export SINGULARITYENV_MODULEPATH=/software/modules/modulefiles:/software/modulefiles2


RSTUDIO_SERVER_USER=chaodai # change to your own
COOKIE_KEY=/scratch/midway2/chaodai/singularity/rstudio-tmp/secure-cookie-key

## make sure these directories and files exists
mkdir -p $RSTUDIO_TMP/var/lib $RSTUDIO_TMP/var/run $RSTUDIO_TMP/tmp

if [[ ! -e $RSTUDIO_TMP/database.conf ]]; then
    touch $RSTUDIO_TMP/database.conf
fi

if [[ ! -e $COOKIE_KEY ]]; then
    uuidgen > $COOKIE_KEY
fi

## run container app
sleep 5 

### you can alternatively save your password to env variable and replace explicit password with the env variable
PASSWORD='password' singularity exec \
    --bind $RSTUDIO_TMP/var/lib:/var/lib/rstudio-server \
    --bind $RSTUDIO_TMP/var/run:/var/run/rstudio-server \
    --bind $RSTUDIO_TMP/tmp:/tmp \
    --bind $RSTUDIO_TMP/database.conf:/etc/rstudio/database.conf \
    --bind /sys/fs/cgroup/:/sys/fs/cgroup/:ro \
     --bind /home/chaodai:/home/rstudio --bind /project2/yangili1:/project2/yangili1 --bind /project2/jstaley:/project2/jstaley --bind /scratch/midway2/chaodai:/scratch/midway2/chaodai --bind /software:/software  \
    $SIF \
    rserver --server-user $RSTUDIO_SERVER_USER \
        --rsession-which-r=${R_BIN} \
        --www-port=${RPORT} \
        --auth-none=0 \
        --auth-pam-helper-path=pam-helper \
        --auth-timeout-minutes=0 \
        --auth-stay-signed-in-days=30 \
        --secure-cookie-key-file=${COOKIE_KEY}




