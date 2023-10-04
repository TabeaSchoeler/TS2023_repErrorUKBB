#!/usr/bin/Rscript

args = commandArgs(trailingOnly=TRUE)
HOME=args[1]
source(paste0(HOME, "/analysis/input.R"))
source(paste0(HOME, "/analysis/functions.R"))
UKBBdir=UKBB
library("pcaMethods")
library(plyr)
library(matrixStats)

con <- file(paste0(HOME, "/output/log/pca_R.log"))
sink(con, append=TRUE, type="output")

print("Read in individual-level data")
withinVarDF=readRDS(paste0(HOME,"/output/rds/varCoded.rds"))


print("Read in descriptives for R2 variables")
r2=readRDS(paste0(HOME,"/output/rds/r2Res.rds"))

print("Select variables for PCA/factor analysis")
variablesAll=readVar()

r2=merge(r2, subset(variablesAll, select=c(label, type)),  by.x="pair", by.y="label", all.x=T )

print("Select only variables with >20k")
varComp=subset(r2, n>=50000)$pair
variables=subset(variablesAll, label %in% varComp)

f1=subset(variables, resPCA=="yes")$label
paste0(NROW(f1), " variables selected for resPCA, including:")
print(f1)



print("================ PC analysis ========================")
set.seed(1238)
PCAsumD=runPCA(pca="resPCA", return="PCsum", df=withinVarDF, selectVars=f1)
PCAloadD=runPCA(pca="resPCA", return="PCload", df=withinVarDF, selectVars=f1)
PCAobj=runPCA(pca="resPCA", return="PCobject", df=withinVarDF, selectVars=f1)
PCAdf=runPCA(pca="resPCA", return="dataframe", df=withinVarDF, selectVars=f1)
PCAage=merge(PCAdf, subset(withinVarDF, select=c(eid,age_0)), by="eid", all.x=T)

print("Prepare phenotype file for regenie")
prepGWAdat(df=PCAage, varIn="RESPCA", saveFile="pca")


print("=================================================")
print("========= CORRELATIONS WITH WEIGHTS =============")
print("=================================================")
print("Read in UKBB weights")
weightsAll=readRDS(paste0(HOME,"/data/weights/datHSEUKBB.rds"))
weights=subset(weightsAll, sampleName=="UKBB", select=c(eid, probs, propensity.weight.normalized))

corWPdf=merge(weights, PCAdf, by="eid", all=T)
corWPo=cor.test(corWPdf$probs, corWPdf$RESPCA, method="pearson")
saveRDS(corWPo, paste0(HOME,"/output/rds/corWPo.rds"))
uploadDropbox(file="corWPo.rds", folder="rds")

print("Get trait variance and predicted variance")
repWL=lapply(f1, function(x) reWeight(var=x, df=withinVarDF))
repW=Reduce(function(x,y) dplyr::full_join(x = x, y = y, by = "eid"), repWL)
repWC=repW[rowSums(is.na(repW)) <= length(repW)-3, ] 
repWC$varMean <- rowMeans(subset(repWC, select=paste0(f1, "_withinVar")), na.rm = TRUE)

head(repWC)
print("Merge with weights")
errorW=merge(subset(repWC, select=c("eid", "varMean")), weights, by="eid", all=T)

print("Generate weights based on participation probability")
errorC=errorW[complete.cases(errorW), ]
errorC$participationIPW=(1-errorC$probs)/errorC$probs
errorC$participationIPWnorm=errorC$participationIPW/mean(errorC$participationIPW)

print("Generate weights based on reporting error")
errorC$repErrorIPW=1/(1+errorC$varMean)
errorC$repErrorIPWnorm=errorC$repErrorIPW/mean(errorC$repErrorIPW)
errorC$propensityMultiplied=errorC$participationIPWnorm*errorC$repErrorIPWnorm

#errorC$propensityMultiplied=errorC$propensityMultiplied/mean(errorC$propensityMultiplied)
errorCs=subset(errorC, select=c(eid,participationIPWnorm, repErrorIPWnorm, propensityMultiplied))

print("Get weighted reporting error scores")
UKBBresW=merge(withinVarDF, errorCs, by="eid", all.x=T)
varRecDF=readVarNames(do="residuals")

head(r2)
r2large=subset(r2, type=="subjective_fixed") %>% 
  top_n(3, -r2) 
vRepE=c(f1, r2large$pair)


print("Get summary of residuals (participation weights only)")
r2ResPWL=lapply(vRepE, function(x) extractRes(var=x, FU=varRecDF, df=UKBBresW, weights="participationIPWnorm"))
r2ResPW=do.call(rbind, r2ResPWL)
r2ResPW$scheme='participation'

print("Get summary of residuals (reporting error weights only)")
r2ErrorWL=lapply(vRepE, function(x) extractRes(var=x, FU=varRecDF, df=UKBBresW, weights="repErrorIPWnorm"))
r2ErrorW=do.call(rbind, r2ErrorWL)
r2ErrorW$scheme='reportingerror'

print("Get summary of residuals (reporting error * participation weights)")
r2ErrorPartWL=lapply(vRepE, function(x) extractRes(var=x, FU=varRecDF, df=UKBBresW, weights="propensityMultiplied"))
r2ErrorPartW=do.call(rbind, r2ErrorPartWL)
r2ErrorPartW$scheme='reportingerrorParticipation'


r2SumW=subset(rbind(r2ResPW, r2ErrorW, r2ErrorPartW), select=c(pair, r2sub, r2W, meanDiff, scheme))
r2SumW$r2Diff=r2SumW$r2sub-r2SumW$r2W


print("Upload data")
saveRDS(r2SumW, paste0(HOME,"/output/rds/r2SumW.rds"))
uploadDropbox(file="r2SumW.rds", folder="rds")

print("Upload weights")
saveRDS(errorCs, paste0(HOME,"/output/rds/weights.rds"))
uploadDropbox(file="weights.rds", folder="rds")




print(" ========================================================= ")
print(" ====================== Save output ====================== ")
print(" ========================================================= ")

print("Upload PCA object")
saveRDS(PCAloadD , paste0(HOME,"/output/rds/PCAobj.rds"))
uploadDropbox(file="PCAobj.rds", folder="rds")


print("Upload UKBB data containing PCA")
saveRDS(PCAage , paste0(HOME,"/output/rds/PCAdat.rds"))


uploadLog(file=paste0("pca_R.log"))
uploadLog(file=paste0("pca_C.lo"))

