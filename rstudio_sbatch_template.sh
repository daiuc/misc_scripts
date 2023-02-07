#!/bin/bash 
#SBATCH --time {{ TIME }}
#SBATCH -p {{ PARTITION }}
#SBATCH -c {{ CPU }}
#SBATCH --mem {{ MEM }}
#SBATCH --job-name={{ JOBNAME}}
#SBATCH --account={{ ACCT }}
#SBATCH --output={{ LOGFILE }}



##-----------------------------------------------------##
##             General set up                          ##
##-----------------------------------------------------##


log={{ LOGFILE }}

cd ~ && source ~/.bash_profile && pwd >$log

echo -e "\n Submited job: $SLURM_JOB_ID\n\n\n" >> $log

module load singularity/3.4.0 &>> $log
conda activate {{ CONDAENV }} &>> $log


JPORT={{ JPORT }} # configured in .jupyter/jupyter_server_config.py
RPORT={{ RPORT }} # for rstudio
CPORT={{ CPORT }} # configured in .config/code-server/config.yaml

IP=$(/sbin/ip route get 8.8.8.8 | awk '{print $NF;exit}')
echo -e "### DATE: $(date) ### \n" >> $log
echo -e "### IP: ${IP}\n\n" >> $log


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
SIF={{ SIF }}
#SIF="/scratch/midway2/chaodai/singularity/rstudio_R4.1.0-Rstudio2022.12-v2.sif"
RSTUDIO_TMP={{ RSTUDIO_TMP }}

echo "using image $SIF" >> showRstudioAddress.txt
echo -e "---------------\n\n\n"
# set conda, R, python binary
CONDA_PREFIX={{ CONDA_PREFIX }}
R_BIN=$CONDA_PREFIX/bin/R
PY_BIN=$CONDA_PREFIX/bin/python

## export conda environment to container
export SINGULARITYENV_USER={{ SINGULARITYENV_USER }}
export SINGULARITYENV_RSTUDIO_WHICH_R=${R_BIN}
export SINGULARITYENV_CONDA_PREFIX=${CONDA_PREFIX}
export SINGULARITYENV_PATH={{ SINGULARITYENV_PATH }}
export SINGULARITYENV_CACHEDIR={{ SINGULARITYENV_CACHEDIR }}
export SINGULARITYENV_MODULES_CMD={{ SINGULARITYENV_MODULES_CMD }}
export SINGULARITYENV_MODULEPATH={{ SINGULARITYENV_MODULEPATH }}


RSTUDIO_SERVER_USER={{ RSTUDIO_SERVER_USER }} # change to your own
COOKIE_KEY={{ COOKIE_KEY }}

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



# make sure MY_PASS is exported in your bash profile
PASSWORD=${{ PASSWORD_VARIABLE }} singularity exec \
    --bind $RSTUDIO_TMP/var/lib:/var/lib/rstudio-server \
    --bind $RSTUDIO_TMP/var/run:/var/run/rstudio-server \
    --bind $RSTUDIO_TMP/tmp:/tmp \
    --bind $RSTUDIO_TMP/database.conf:/etc/rstudio/database.conf \
    --bind /sys/fs/cgroup/:/sys/fs/cgroup/:ro \
    {{ CUSTOM_BIND }} \
    $SIF \
    rserver --server-user $RSTUDIO_SERVER_USER \
        --rsession-which-r=${R_BIN} \
        --www-port=${RPORT} \
        --auth-none=0 \
        --auth-pam-helper-path=pam-helper \
        --auth-timeout-minutes=0 \
        --auth-stay-signed-in-days=30 \
        --secure-cookie-key-file=${COOKIE_KEY}





