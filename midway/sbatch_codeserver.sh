#!/bin/zsh 
#SBATCH --time 35:59:00
#SBATCH -p broadwl
#SBATCH -c 4
#SBATCH --mem 25g
#SBATCH --job-name=rstudio
####SBATCH --account=pi-yangili1
#SBATCH --account=pi-jstaley
#SBATCH --output=logs/sbatchLogRstudioContainer.log



##-----------------------------------------------------##
##             General set up                          ##
##-----------------------------------------------------##

log=logs/sbatchLogRstudioContainer.log

export PATH=/scratch/midway2/chaodai/miniconda3/envs/cs/bin:$PATH

CPORT=8783 # configured in .config/code-server/config.yaml

IP=$(/sbin/ip route get 8.8.8.8 | awk '{print $NF;exit}')
echo -e "### DATE: $(date) ### \n" >> $log
echo -e "### IP: ${IP}\n\n" >> $log

code-server --version

npm --version


##-----------------------------------------------------##
##             Launch code-server                      ##
##-----------------------------------------------------##

echo "code-server runing on http://${IP}:${CPORT}" >> showRstudioAddress.txt
code-server --bind-addr ${IP}:${CPORT} /home/chaodai/igv 





