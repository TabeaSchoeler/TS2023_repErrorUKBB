# Challenges related to self-report errors for biobank-scale research



</br></br>

# Overview

All analyses were performed in R. The complete analytical pipeline used to run the analyses is included in the script
[analysis.R](https://github.com/TabeaSchoeler/TS2023_repErrorUKBB/blob/main/analysis/litSearch.R).


</br>

## Analytical pipeline

### Extract and recode phenotype data

- [extractPheno.R](https://github.com/TabeaSchoeler/TS2023_repErrorUKBB/blob/main/analysis/extractPheno.R)


### Process phenotype data

- [processPheno.R](https://github.com/TabeaSchoeler/TS2023_repErrorUKBB/blob/main/analysis/processPheno.R)
- Script to prepare repeated measure data
- Generates the reporting error scores


### Perform principal component analysis on the reporting error scores
- [pca.R](https://github.com/TabeaSchoeler/TS2023_repErrorUKBB/blob/main/analysis/pca.R)
- 

### Compare predictors for participation and reporting error
- [comparePB.R](https://github.com/TabeaSchoeler/TS2023_repErrorUKBB/blob/main/analysis/comparePB.R)


```


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

```


</br>

## Results

This repository includes the following files:

-   [Data pre-processing](#data-pre-processing)


</br></br>


### Data pre-processing

</br>

#### Figure 1. Number of included studies and study participants per study design, according to year of publication

<img src="results/figures/Figure1.png" alt="A caption" width="50%" />




