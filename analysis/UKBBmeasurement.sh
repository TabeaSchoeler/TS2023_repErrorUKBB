##############################################################################
# ======================== UKBB reporting error ==============================
##############################################################################

# ======== EXTRACT PHENOTYPE DATA =============
hours="4"; task="extractPheno"; array="1"
submitJob $task $hours

# ======== PROCESS PHENOTYPE DATA =============
hours="2"; task="processPheno"; array="1" 
submitJob $task $hours

# ======== GENERATE PRINCIPAL COMPONENTS ======
hours="24"; task="pca"; array="1" 
submitJob $task $hours

# ======= COMPARE WITH PARTICIPATION ==========
hours="10"; task="comparePB"; array="1-3" 
submitJob $task $hours

# ======= RUN REGENIE =========================
# step 1
hours="23"; task="gwaS1"; array="1"; run="pca"
submitJob $task $hours

# step 2
hours="23"; task="gwaS2"; array="1-22"; run="pca" 
submitJob $task $hours

# process REGENIE
hours="2"; task="processREGENIE"; array="1"; run="pca"
submitJob $task $hours


# ============ Prepare LD scores for Jacknife ==============
hours="2"; task="JKldsc"; array="1" #=> DONE
submitJob $task $hours 

# ============== LD SCORE REGRESSION ==================
hours="6"; task="rg"; array="1" # run ldsc regression on the PCs
submitJob $task $hours

# ============ Mendelian Randomization ==================
# run MR on the PCs
hours="6"; task="runMR"; array="1" 
submitJob $task $hours 

# ======= GWA on error-corrected phenotypes =============
# step 1 
hours="23"; task="gwaS1"; array="1"; run="gwaCor" 
submitJob $task $hours

# step 2
hours="47"; task="gwaS2"; array="1-22"; run="gwaCor" 
submitJob $task $hours

# process REGENIE
numPheno=$(wc -l "$HOME/data/gwas/gwaCorr")
$numPheno
hours="2"; task="processREGENIE"; array="1-23"; run="gwaCorr" 
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




