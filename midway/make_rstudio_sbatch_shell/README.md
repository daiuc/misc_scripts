# Generate sbatch shell script using yaml config file and template


Run this script to generate a shell script used to spin up a juyter and container based rstudio server.

```
rstudio_script_gen.py [-h] [--YAML YAML] [--TEMP TEMP] [--OUT OUT]
```
- yaml: must fill out information correctly in the yaml file
- template: the template is what the final script is based on
- output: output a bash script with variables filled in from the yaml config file

This should work for both Uchicago midway2 and midway3


## Prerequisites

### conda environment

You don't have to but it's preferred that you have your conda environment set up. I set up my own environment `smk` that includes `python3, jupyter lab, R` along with necessary packages.

For example, my conda environment is
```
smk    *  /scratch/midway2/chaodai/miniconda3/envs/smk
```

## Configure jupyter environment

I have jupyter under:

```
/scratch/midway2/chaodai/miniconda3/envs/smk/bin/jupyter
```

Before running jupyter lab, you should configure ip, port and password at the minimum. Refer to docs [here](https://jupyter-notebook.readthedocs.io/en/stable/public_server.html).
```
jupyter lab --generate-config
jupyter server --generate-config # with newer versions of jupyter
jupyter password # to generate a hashed password
```


## Configure R environment

I have R binary here:
```
/scratch/midway2/chaodai/miniconda3/envs/smk/bin/R
```

And my my R `.libpaths()` here:
```
/scratch/midway2/chaodai/miniconda3/envs/smk/lib/R/library
```

It's a little tricky to use your own versions of R in conda, instead of midway's versions with `module load`. The problem is R sometimes doesn't know where the underlying C/C++ libraries are. Therefore you should create or modify your `$HOME/.Renviron`. The key is to export correct PATH into R. I basically copied the PATH variable into `.Renvion`. Here's an example of mine:
```
PATH=/scratch/midway2/chaodai/miniconda3/envs/smk/bin:/bin:/software/ruby-2.6-el7-x86_64/bin:/scratch/midway2/chaodai/miniconda3/condabin:/software/git-2.10-el7-x86_64/bin:/software/subversion-1.9.4-el7-x86_64/bin:/software/bin:/srv/adm/bin:/usr/lib64/qt-3.3/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/usr/lpp/mmfs/bin:/home/chaodai/bin:/home/chaodai/.local/bin:/software/slurm-current-el7-x86_64/bin
```

You might also consider write something in your `$HOME/.Rprofile` to ensure appending the correct R library path. Here's mine:
```
r.ver = gsub("\\.[0-9]{1,2} \\(.+\\)$", "", gsub("R version ", "", R.version.string))

if (r.ver == "4.1") {
  .libPaths(c("/scratch/midway2/chaodai/miniconda3/envs/smk/bin/R/library"))
}
```

You can test run R by launching a basic R console in shell with your correct conda environment activated. Check if you have correct library, that you can load expected library, and that you can install libraries correctly. Very likely you would run into errors sometimes telling you some library is missing. This is often because you don't have the correct c library in conda env path. Look for the error, google for how to install that library. Often you can `conda install -c pickchannel -n yourenv neededlibrary` to have it installed. Then try install again in R.

## Configure singularity

Both midway2 and midway3 has singularity installed. Load them using `module load`. Note midway3's singularity versions are higher.

An important difference between singularity and docker is that singularity does not allow root. So you can't do anything that requires root or sudo. Also singularity's image files (.sif) are read only.

You can use any linux based images that has R and rstudio. There are plenty on docker hub. The most popular one is by `rocker`. You can learn morea bout the rocker singularity project [here](https://rocker-project.org/use/singularity.html). I modified the `rocker/tidyverse` docker image and it's availble here: `bajiame/rstudio:latest`. 

You can build a singularity image file with this command. I recommend that you create a folder under scratch. For instance mine is `singularity` under my scrtach folder.

This tag below is my latest build. It adds FiraCode Nerd Fonts so that it's available in Rstudio. I like that this fonts support ligatures and icons, which works well for both coding editors and terminals.

```
singularity pull bajiame/rstudio:rstudio_2022_12
```

## Create config yaml and generate sbatch sh script

Here comes the tedious part.

I wrote a python script that takes in a yaml config file and a sbatch shell script template to generate a shell script that you can just sbatch, which then requests a compute node, spin up a jupyter server, and a singularity container that runs rstudio server.

Note jupyter server is run directly on the compute node, while Rstudio server is run inside a container on the compute node. However, the R-binary and relevant library is from your conda environment. Essentially, when you are working inside of rstudio, all the hardware resource is from the container, but your R and R libraries come from conda. So your bash/zsh terminal inside of Rstudio is from the container! But your bash/zsh terminal in jupyter is directly from compute node!

You need to:

-   carefully modify the yaml file `rstudio_sbatch.yml`. Make sure you don't use the same ports I used. Don't remove any variables from yaml file without removing them also from the template.

-   run the python script 
```
./rstudio_script_gen.py --YAML rstudio_sbatch.yml --TEMP rstudio_sbatch_template.sh --OUT yoursbatchscript.sh
```

-   if you don't want to use the explicit password in the output script. You change it to an environment variable that stores your rstudio password.

## Set up your jupyter and rstudio servers

This is simple...

```
sbatch yoursbatchscript.sh
```

Remember we have time limits on compute nodes. So the maximum your sever will run is set at about 36h in my script.

## Accessing your servers

There are two ways of accessing your rstudio and jupyter. 

1. My preferred way - portforward to your local ports. Suppose the compute node ip is `10.50.221.1` and your jupyter port is `8111` and rstudio port is `8121` and the compute node is on midway2. Then on your local machine, without vpn:

```
ssh -NL 8111:10.50.221.1:8111 yourname@midway2.rcc.uchicago.edu # forward jupyter
ssh -NL 8121:10.50.221.1:8121 yourname@midway2.rcc.uchicago.edu # forward rstudio
```

In your browser (chrom preferred), access jupyter via `http://localhost:8111` and rstudio via `http://localhost:8121`. 

Jupyter password is what you have entered after running `jupyter password`, it is stored at `$HOME/.jupyter/jupyter_server_config.json` or `HOME/.jupyter/jupyter_lab_config.json` depending on whether you generated the config using `jupyter server --generate-config` or `jupyter lab --generate-config`.

Rstudio server user name and password is what you had set in the yaml config.

2. You can also access `http://10.50.221.1:port` directly if you are on campus, or behind VPN.

I like the first option, because all your sessions will be under `localhost:port`, so jupyter and rstudio will resume your sessions automatically. The second options likely results in a new cookie id each time, thereby a brand new workspace.

Another tip for the first opition is to access midway using vscode, and use vscode's builtin portforward function. That way you don't have to enter passwords and 2 factor multiple times.

## Good luck. Be mindful of security! And do not request more resources than you need.
