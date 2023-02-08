#!/bin/bash
#SBATCH --time 36:00:00
#SBATCH -c 1
#SBATCH --mem 25g
#SBATCH --job-name=jbrowse2
#SBATCH --account=pi-yangili1
#SBATCH --output=log/jbrowse.log

module load singularity


#echo " jbrowse running on http://"$(/sbin/ip route get 8.8.8.8 | awk '{print $NF;exit}')":9191"
echo "jbrowse2 running on http://"$(/sbin/ip route get 8.8.8.8 | awk '{print $NF;exit}')":9191" > log/jbrowse.log 

TMPDIR=/project2/yangili1/cdai/singularity/rstudio-tmp

## set SIF

#SIF="/project2/yangili1/cdai/singularity/rstudio_20210829.sif" # based on bajiame/rstudio:20210829, which is rocker/rstudio:4.1.0 + added folders under /mnt + many R packages
SIF="/scratch/midway2/chaodai/singularity/jbrowse2.sif"
 
#echo "using image $SIF"


## export conda environment to container


#export SINGULARITYENV_USER=chaodai
#export SINGULARITYENV_PATH="/opt/pyenv/plugins/pyenv-virtualenv/shims:/home/chaodai/.pyenv/shims:/opt/pyenv/bin:/home/chaodai/.local/bin:/usr/lib/rstudio-server/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/chaodai/bin:/home/chaodai/.local/bin"


#singularity exec -w --bind /project2/yangili1/cdai/jbrowse2:/jbrowse2 \
#		--bind /project2/yangili1/cdai/chRNA-editing:/project2/yangili1/cdai/chRNA-editing \
#		$SIF npx serve -p 9191 /jbrowse2

singularity shell --bind /project2/yangili1/cdai/jbrowse2:/jbrowse2 \
	--bind /project2/yangili1/cdai:/project2/yangili1/cdai \
	--bind $TMPDIR/tmp:/tmp \
  $SIF

# execute container rserver
#singularity exec \  
#    --bind /project2/yangili1/cdai/jbrowse2:/jbrowse2 \
#		--bind /project2/yangili1/cdai/chRNA-editing:/project2/yangili1/cdai/chRNA-editing \
#    --bind /scratch/midway2/chaodai:/scratch/midway2/chaodai \
#    $SIF npx serve -p 9191 /jbrowse2
				