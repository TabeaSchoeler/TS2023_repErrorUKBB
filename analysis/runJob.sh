#!/bin/bash
#SBATCH --mail-type=NONE
#SBATCH --mail-user=t.schoeler@ucl.ac.uk
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=15000
#SBATCH --account=sgg


export LC_ALL=C
unset LANGUAGE
unset LANG
tmpdir=/scratch/$USER/$SLURM_JOBID
resdir=$PWD
mkdir -p $tmpdir $resdir



if [ $task == "extractPheno" ]; then
echo "extract UKBB data"
$HOME/programs/R-4.2.2/bin/R --no-save < $HOME/analysis/extractPheno.R --args $HOME > $HOME/output/log/exractUKBB_C.log  
fi


if [ $task == "processPheno" ]; then
echo "process UKBB data"
$HOME/programs/R-4.2.2/bin/R --no-save < $HOME/analysis/processPheno.R --args $HOME > $HOME/output/log/processUKBB_C.log  
fi


if [ $task == "pca" ]; then
  echo "run PCA analysis"
  $HOME/programs/R-4.2.2/bin/R --no-save < $HOME/analysis/pca.R --args $HOME > $HOME/output/log/pca_C.log  
fi



if [ $task == "gwaS1" ]; then
echo $run

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK 
source /software/bin/mklvars.sh intel64
myprog=/software/regenie-2.0.2/regenie


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

echo "upload log file"
cp $HOME/output/gwas/${run}_s1.log $HOME/output/log/
rm $HOME/output/gwas/${run}_s1.log
uploadFile=${run}_s1.log
$HOME/programs/R-4.2.2/bin/R --no-save < $HOME/analysis/uploadLog.R --args $HOME $uploadFile > $HOME/output/log/uloadLog.log 


fi

if [ $task == "gwaS2" ]; then
echo "run GWA (step 2) in regenie"

echo $run

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK 
source /software/bin/mklvars.sh intel64
myprog=/software/regenie-2.0.2/regenie

a=${SLURM_ARRAY_TASK_ID}

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

fi

if [ $task == "processREGENIE" ]; then
  echo "process REGENIE output"
  echo "do for $run"
  export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK 
  a=${SLURM_ARRAY_TASK_ID}
  line=$(sed "${a}q;d" $HOME/data/gwas/gwaCorr)
  pheno=$(echo "$line"| awk -F" "  '{print $1}')
  echo "do for $pheno"
  
  $HOME/programs/R-4.2.2/bin/R --no-save < $HOME/analysis/processREGENIE.R --args $HOME $run $pheno > $HOME/output/log/processREGENIE_C.log  
fi

if [ $task == "JK" ]; then
  run="JK"

  export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK 
  a=${SLURM_ARRAY_TASK_ID}

  line=$(sed "${a}q;d" $HOME/data/gwas/gwaCorr)
  pheno=$(echo "$line"| awk -F" "  '{print $1}')
  echo "do for $pheno"
  $HOME/programs/R-4.2.2/bin/R --no-save < $HOME/analysis/processREGENIE.R --args $HOME $run $pheno > $HOME/output/log/JK_${pheno}_C.log  

fi


if [ $task == "phenolist" ]; then
echo "create list"
$HOME/programs/R-4.2.2/bin/R --no-save < $HOME/analysis/munge.R --args $HOME $task > $HOME/output/log/${task}_C.log  
fi


if [ $task == "mungePCA" ]; then
echo "munge PCA files"
$HOME/programs/R-4.2.2/bin/R --no-save < $HOME/analysis/munge.R --args $HOME $task> $HOME/output/log/${task}_${a}_C.log  
fi

if [ $task == "JKldsc" ]; then
echo "prepare LD scores for Jacknife procedure"
$HOME/programs/R-4.2.2/bin/R --no-save < $HOME/analysis/munge.R --args $HOME $task > $HOME/output/log/${task}_C.log  
fi




if [ $task == "rg" ]; then
echo "run LD score regression"
$HOME/programs/R-4.2.2/bin/R --no-save < $HOME/analysis/ldsc.R --args $HOME $task > $HOME/output/log/${task}_C.log  
fi

if [ $task == "runMR" ]; then
echo "run MR"
cd $HOME/analysis
singularity run -B $HOME:$HOME -B $GWA:$GWA docker://tabeaschoeler/r-env Rscript $HOME/analysis/mr.R > $HOME/output/log/MR_C.log
fi


if [ $task == "comparePB" ]; then
echo "Lasso participation  // reporting error"
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK 
a=${SLURM_ARRAY_TASK_ID}
$HOME/programs/R-4.2.2/bin/R --no-save < $HOME/analysis/comparePB.R --args $HOME $a > $HOME/output/log/comparePB_C.$a.log  
fi


