# Self-report inaccuracy in the UK Biobank: Impact on inference and interplay with selective participation



</br></br>

# Overview

The complete analytical pipeline used to run the analyses is included in the script
[UKBBmeasurement.sh](https://github.com/TabeaSchoeler/TS2023_repErrorUKBB/blob/main/analysis/UKBBmeasurement.sh).


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


### Perform genome-wide scans using REGENIE

- Perform on reporting error [specify `run=pca`
- Perform on error-corrected phenotypes [specify `run=gwaCor`
- Process the results using [processREGENIE.R](https://github.com/TabeaSchoeler/TS2023_repErrorUKBB/blob/main/analysis/processREGENIE.R)


#### GWA in REGENIE - Step 1:

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

#### GWA in REGENIE - Step 2:

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

#### Prepare LD scores for Jacknife

- Perform GWA and process the results using [munge.R](https://github.com/TabeaSchoeler/TS2023_repErrorUKBB/blob/main/analysis/munge.R)
- Parameter to specify: `task = JKldsc`

#### Run LD Score regression 

- Perform GWA and process the results using [ldsc.R](https://github.com/TabeaSchoeler/TS2023_repErrorUKBB/blob/main/analysis/ldsc.R)
  - Parameter to specify: `task = rg`


#### Perform Mendelian Randomization Analysis

- Perform GWA and process the results using [mr.R](https://github.com/TabeaSchoeler/TS2023_repErrorUKBB/blob/main/analysis/mr.R)





</br>

## Results

This repository includes the following files:

-   [Data pre-processing](#data-pre-processing)


</br></br>


### Data pre-processing

</br>

#### Figure 1. Number of included studies and study participants per study design, according to year of publication

<img src="results/figures/Figure1.png" alt="A caption" width="50%" />




