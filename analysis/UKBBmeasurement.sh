##############################################################################
# ============================== UKBB weighting ==============================
##############################################################################

# filzilla
# sftp://hpc1-login.chuv.ch
# name: ta6000
# port: 22

# ======= Define Home directory ==============
srun -n 1 --pty --account=sgg --partition=sgg /bin/bash
HOME="/data/sgg3/tabea/TS2022_UKBBmeasurement"
source $HOME/analysis/functions.sh
squeue
squeue -u ta6000
scancel 1331548


# Delete all files in output folder (but keep directories)
# find $HOME/output/ -type f -delete


# ====== Start R ==============================
alias R='$HOME/programs/R-4.2.2/bin/R'
cd $HOME
R
# Load libraries
source("analysis/input.R")


rm $HOME/output/log/*
singularity run -B $HOME:$HOME -B $GWA:$GWA docker://tabeaschoeler/r-env R


# ======== EXTRACT PHENOTYPE DATA =============
hours="4"; task="extractPheno"; array="1" #=> DONE
submitJob $task $hours

# ======== PROCESS PHENOTYPE DATA =============
hours="2"; task="processPheno"; array="1" #=> DONE
submitJob $task $hours

# ======== GENERATE PRINCIPAL COMPONENTS ======
hours="24"; task="pca"; array="1" #=> DONE
submitJob $task $hours

# ======= COMPARE WITH PARTICIPATION ==========
hours="10"; task="comparePB"; array="1-3" #=> DONE
submitJob $task $hours

# ======= RUN REGENIE =========================
# step 1
hours="23"; task="gwaS1"; array="1"; run="pca" #=> DONE
submitJob $task $hours

# step 2
hours="23"; task="gwaS2"; array="1-22"; run="pca" #=> DONE
submitJob $task $hours

# process REGENIE
hours="2"; task="processREGENIE"; array="1"; run="pca" #=> DONE
submitJob $task $hours


# ============ Prepare LD scores for Jacknife ==============
# prepare for jacknife (do only once)
hours="2"; task="JKldsc"; array="1" #=> DONE
submitJob $task $hours 

# ============== LD SCORE REGRESSION ==================
# run ldsc regression on the PCs
hours="6"; task="rg"; array="1" #=> DONE
submitJob $task $hours

# ============ Mendelian Randomization ==================
# run MR on the PCs
hours="6"; task="runMR"; array="1"  #=> DONE
submitJob $task $hours 


# ======= GWA on error-corrected phenotypes =============
# step 1 (requires data generated from 'processPheno')
hours="23"; task="gwaS1"; array="1"; run="gwaCor" #=> DONE
submitJob $task $hours

# step 2
hours="47"; task="gwaS2"; array="1-22"; run="gwaCor" #=> done
submitJob $task $hours

# process REGENIE
numPheno=$(wc -l "$HOME/data/gwas/gwaCorr")
$numPheno
hours="2"; task="processREGENIE"; array="1-23"; run="gwaCorr" #=> done
submitJob $task $hours #=> running

# get Jacknife estimates
numPheno=$(wc -l "$HOME/data/gwas/gwaCorr") #=> running
$numPheno
hours="20"; task="JK"; array="1-23"
submitJob $task $hours

# upload ldsc files
hours="2"; task="processREGENIE"; array="1"; run="upload"
submitJob $task $hours


###########################################################################
## =================== Upload all analytical scripts =================== ##
###########################################################################
$HOME/programs/R-4.2.2/bin/R --no-save < $HOME/analysis/uploadScripts.R --args $HOME > $HOME/output/log/uploadScripts.log  2>&1 & disown




