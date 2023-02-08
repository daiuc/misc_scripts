# Generate sbatch shell script using yaml config file and template


Run this script to generate a shell script used to spin up a juyter and container based rstudio server.

```
rstudio_script_gen.py [-h] [--YAML YAML] [--TEMP TEMP] [--OUT OUT]
```
- yaml: must fill out information correctly in the yaml file
- template: the template is what the final script is based on
- output: output a bash script with variables filled in from the yaml config file

This should work for both Uchicago midway2 and midway 3


