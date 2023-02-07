#!/bin/env python
'''
Generate sbatch_rstudio script based on a template

author: Chao Dai
date: 1/2023

'''

import yaml
from jinja2 import Template
import argparse




def args_parser():
    parser = argparse.ArgumentParser(
            description=__doc__,
            formatter_class=argparse.RawDescriptionHelpFormatter)
    
    parser.add_argument("--YAML",
            help= "YAML config file",
            default=None)
    
    parser.add_argument("--TEMP",
            help= "template file",
            default=None)
    
    parser.add_argument("--OUT",
            help= "output script file",
            default=None)
    
    return(parser.parse_args())

args = args_parser()

with open(args.YAML) as f:
    CONFIG = yaml.safe_load(f)

with open(args.TEMP) as tplt:
    temp_contents = tplt.read()
    temp = Template(temp_contents)
    fill_template = temp.render(
        TIME = CONFIG['TIME'],
        PARTITION = CONFIG['PARTITION'],
        CPU = CONFIG['CPU'],
        MEM = CONFIG['MEM'],
        JOBNAME = CONFIG['JOBNAME'],
        ACCT = CONFIG['ACCT'],
        LOGFILE = CONFIG['LOGFILE'],
        JPORT = CONFIG['JPORT'],
        RPORT = CONFIG['RPORT'],
        CONDAENV = CONFIG['CONDAENV'],
        CONDA_PREFIX = CONFIG['CONDA_PREFIX'],
        SIF = CONFIG['SIF'],
        SINGULARITYENV_USER = CONFIG['SINGULARITYENV_USER'],
        SINGULARITYENV_PATH = CONFIG['SINGULARITYENV_PATH'],
        SINGULARITYENV_CACHEDIR = CONFIG['SINGULARITYENV_CACHEDIR'],
        SINGULARITYENV_MODULES_CMD = CONFIG['SINGULARITYENV_MODULES_CMD'],
        SINGULARITYENV_MODULEPATH = CONFIG['SINGULARITYENV_MODULEPATH'],
        RSTUDIO_SERVER_USER = CONFIG['RSTUDIO_SERVER_USER'],
        RSTUDIO_TMP = CONFIG['RSTUDIO_TMP'],
        CUSTOM_BIND = CONFIG['CUSTOM_BIND'],
        COOKIE_KEY = CONFIG['COOKIE_KEY']
    )
    
with open(args.OUT, 'w') as fo:
    fo.write(fill_template)
