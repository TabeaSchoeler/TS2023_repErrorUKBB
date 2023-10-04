#!/usr/bin/Rscript

args = commandArgs(trailingOnly=TRUE)
HOME=args[1]
source(paste0(HOME, "/analysis/input.R"))
source(paste0(HOME, "/analysis/functions.R"))
UKBBdir=UKBB

con <- file(paste0(HOME, "/output/log/processPheno_R.log"))
sink(con, append=TRUE, type="output")

print("Read in raw data (selected variables)")
UKBB=readRDS(paste0(HOME, "/output/UKBB.rds"))

library("GMCM")
varAll=readVarNames()
varInc=subset(varAll, extract=="yes")


print("Check missing data")
varRecDF=readVarNames(do="residuals")
varRec=varRecDF$label
nCompRawL=lapply(varRec, function(x) assessMiss(df=UKBB, var=x))
nCompRaw=do.call(rbind, nCompRawL)
print(nCompRaw)

print("Add dates")
ageDat=subset(UKBB, select=c(eid, age_0))
dates=c(paste0( "date_assessment_", 0:3), paste0( "date_diet_", 0:4), "date_cognitive_0", "date_occupQ_0", "date_acceleometer_0")
datesL=lapply(dates, function(x) recodeDate(df=UKBB, var=x))
datesDf=as.data.frame(do.call(cbind, datesL))


print(" ========================================================= ")
print(" ================== Data dictionary ====================== ")
print(" ========================================================= ")
checkCoding()

print(" ========================================================= ")
print(" ================== Consistency across time ============== ")
print(" ========================================================= ")

print("======== RECODE CAT / CON VARIABLES ACROSS TIME POINTS ==========")
print("Binary/categorical")
recodeCat=subset(varAll, scale=="cat" )$label
recodeCatAll=unique(recodeCat)
UKBBcatList=lapply(recodeCatAll, function(x) recodeVar(df=UKBB, var=x ))
UKBBcat=do.call(cbind,UKBBcatList)
print(lapply(UKBBcatList, function(x) NROW(x)))


print("Continuous")
recodeCon=subset(varAll, scale=="con" )$label
UKBBconL=lapply(recodeCon, function(x) recodeVarCon(df=UKBB, var=x ))
print(lapply(UKBBconL, function(x) NROW(x)))
UKBBcon=do.call(cbind,UKBBconL)

print("Combine recoded data, add dates")
UKBB=cbind(data.frame(eid=UKBB$eid), UKBBcat, UKBBcon, datesDf)


print(" ========================================================= ")
print(" ============ Objective versus subjective ================ ")
print(" ========================================================= ")

print("Number of hours of sleep per 24h (self-reported)")
UKBB$timeDiffAccel=round(as.numeric(difftime(UKBB$date_acceleometer_0, UKBB$date_assessment_0, units="weeks")),0)

cor.test(UKBB$activity_accel_0, UKBB$MET_sum_0, method="spearman")

r2_1=getR2(pheno="Sleep (accelerometer - self-reported)", 
      outcome=UKBB$sleep_accel_0,
      predictor=UKBB$sleep_duration_0,
      covariate=UKBB$timeDiffAccel)

r2_2=getR2(pheno="Physical activity (accelerometer - self-reported)", 
      outcome=UKBB$activity_accel_0,
      predictor=UKBB$MET_sum_0,
      covariate=UKBB$timeDiffAccel)

UKBB$timeDiffDiet=round(as.numeric(difftime(UKBB$date_diet_0, UKBB$date_assessment_0, units="weeks")),0)

r2_3=getR2(pheno="Sodium (urine - self-reported)", 
      outcome=UKBB$sodium_urine_0,
      predictor=UKBB$sodium_24hdiet_0,
      covariate=UKBB$timeDiffDiet)


r2_4=getR2(pheno="Vitamin d (measured - self-reported)", 
      outcome=UKBB$vitamin_d_measured_0,
      predictor=UKBB$vitamin_d_SR_0,
      covariate=UKBB$timeDiffDiet)

print("Birth weight")
UKBB$birth_weight_child_p=UKBB$birth_weight_child_0*453.592 # 1pound=453.592g
UKBB$birth_weight_child_p=ifelse(UKBB$birth_weight_child_p <=0, NA, UKBB$birth_weight_child_p)
UKBB$birth_weight_child_p=ifelse(UKBB$birth_weight_child_p>=7000, 7000, UKBB$birth_weight_child_p)
UKBB$birth_weight_child_p=round(UKBB$birth_weight_child_p, 0)
UKBB$birth_weight_child_hospital_0=ifelse(UKBB$birth_weight_child_hospital_0==9999, NA, UKBB$birth_weight_child_hospital_0)

r2_5=getR2(pheno="Birth weight first child (hospital record versus self-reported)", 
      outcome=UKBB$birth_weight_child_hospital_0,
      predictor=UKBB$birth_weight_child_p)

r2_OBJ=rbind(r2_1, r2_2, r2_3, r2_4, r2_5)


print(" ========================================================= ")
print(" ===================== Get FU data ===================== ")
print(" ========================================================= ")
library(tidyr)
UKBBfuL=lapply(varRec, function(x) getFU(var=x, df=UKBB, varDF=varAll))
UKBBfur=Reduce(function(x,y) dplyr::full_join(x = x, y = y, by = "eid", suffix=c("", "") ),  UKBBfuL)
UKBBfu=inner_join(subset(UKBB, select=c(eid, sex_0, age_0)),UKBBfur, by = join_by(eid))


print(" ========================================================= ")
print(" ===================== Get residuals ===================== ")
print(" ========================================================= ")
print("Read in weights")     
weightsAll=readRDS(paste0(HOME,"/data/weights/datHSEUKBB.rds"))
UKBBw=left_join(UKBBfu, subset(weightsAll, sampleName=="UKBB", select=c(eid, propensity.weight.normalized)), by = join_by(eid))

print("Get summary of residuals")
r2ResL=lapply(varRec, function(x) extractRes(var=x, FU=varRecDF, df=UKBBw, weights="propensity.weight.normalized"))
r2Res=do.call(rbind, r2ResL)
print("Get data including residual scores")
UKBBaL=lapply(varRec, function(x) extractRes(var=x, FU=varRecDF, df=UKBBw, return="data", weights="propensity.weight.normalized"))
UKBB=cbind(do.call(cbind, UKBBaL), UKBBfu)
  

print(" ========================================================= ")
print(" =============== Get sex differences ===================== ")
print(" ========================================================= ")
library(effsize)
dL=lapply(varRec, function(x) meanDiff(df=UKBB, var=x))
dSex=do.call(rbind, dL)


print(" ========================================================= ")
print(" ================ Export data for GWA ==================== ")
print(" ========================================================= ")
varGWA=readVarNames(do="gwa")$label
gwaDat=lapply(varGWA, function(x) exportGWA(x, df=UKBB))
gwaDFm=Reduce(function(x,y) dplyr::full_join(x = x, y = y, by = "eid", suffix=c("", "") ),  gwaDat)
gwaDF=merge(gwaDFm, ageDat, by="eid", all.x=T)

print("Prepare phenotype file for regenie")
prepGWAdat(df=gwaDF, varIn=c(varGWA, paste0(varGWA, "Mean")), saveFile="gwaCor")


write.table(data.frame(label=c(varGWA)),
             file= paste0(HOME, "/output/gwas/gwaCorr"),
            sep="\t",
            row.names = FALSE,
             col.names=FALSE,
             quote=F)

print(" ========================================================= ")
print(" ====================== Save output ====================== ")
print(" ========================================================= ")

print("Upload explained variance")
saveRDS(r2Res , paste0(HOME,"/output/rds/r2Res.rds"))
uploadDropbox(file="r2Res.rds", folder="rds")

print("Upload data")
saveRDS(UKBB, paste0(HOME,"/output/rds/varCoded.rds"))
uploadDropbox(file="varCoded.rds", folder="rds")

print("Upload data")
saveRDS(r2_OBJ, paste0(HOME,"/output/rds/r2OBJ.rds"))
uploadDropbox(file="r2OBJ.rds", folder="rds")

print("Upload data")
saveRDS(dSex, paste0(HOME,"/output/rds/dSex.rds"))
uploadDropbox(file="dSex.rds", folder="rds")

print("All output saved")
uploadLog(file=paste0("processPheno_R.log"))
uploadLog(file=paste0("processPheno_C.log"))

