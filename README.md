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


### Perform genome-wide scans on reporting error (REGENIE)

- Perform GWA and process the results using [processREGENIE.R](https://github.com/TabeaSchoeler/TS2023_repErrorUKBB/blob/main/analysis/processREGENIE.R)


#### Step 1:

```
$myprog \
--step 1 \
--bed $UKBB/plink/_001_ukb_cal_allchr_v2 \
--extract $UKBB/plink/qc_pass_for_regenie.snplist \
--phenoFile $HOME/data/gwas/$run \
--covarFile $HOME/data/gwas/${run}Covar \
--covarColList AGE,PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10 \
--catCovarList SEX,batch \
--maxCatLevels 3000 \
--bsize 1000 \
--lowmem \
--lowmem-prefix $HOME/data/gwas/ \
--out ${HOME}/output/gwas/${run}_s1 \
--threads $SLURM_CPUS_PER_TASK
```

#### Step 2:

```
$myprog \
--step 2 \
--bgen $UKBB/imp/_001_ukb_imp_chr"$a"_v2.REGENIE.bgen \
--ref-first \
--sample $UKBB/imp/ukb1638_imp_chr1_v2_s487398.sample \
--phenoFile $HOME/data/gwas/$run \
--covarFile $HOME/data/gwas/${run}Covar \
--covarColList AGE,PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10 \
--catCovarList SEX,batch \
--maxCatLevels 3000 \
--approx \
--pred $HOME/output/gwas/${run}_s1_pred.list \
--bsize 400 \
--split \
--out $HOME/output/gwas/chr"$a" 
```


### LD Score Regression and Mendelian Randomization

Prepare LD scores for Jacknife

- Perform GWA and process the results using [munge.R](https://github.com/TabeaSchoeler/TS2023_repErrorUKBB/blob/main/analysis/munge.R)
- Parameter to specify: `task = JKldsc`

```



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




