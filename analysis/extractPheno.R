#!/usr/bin/Rscript

args = commandArgs(trailingOnly=TRUE)
HOME=args[1]
source(paste0(HOME, "/analysis/input.R"))
source(paste0(HOME, "/analysis/functions.R"))
library("stringr") 

con <- file(paste0(HOME, "/output/log/extractUKBB_R.log"))
sink(con, append=TRUE, type="output")

print("Remove old file")
file.remove(paste0(HOME,"/output/UKBB.rds"))

redIn=c("ukb672662.csv", "ukb39955.csv","ukb672736.csv","ukb672735.csv","ukb672730.csv", "ukb672731.csv", "ukb672732.csv", "ukb672733.csv", "ukb672734.csv", "ukb672663.csv", "ukb672709.csv")
# ukb28603.csv (old file) but includes FEV (exlude as leads to loss of data)
# ukb672662 has to be first as file with most complete data on dates

print(paste0("Read in ", paste0(unique(redIn), collapse=", ")  ))
UKBBList=lapply(unique(redIn), function(x) fread(paste0(UKBB, "/pheno/", x))) # , nrows = 1000
names(UKBBList)=c(redIn)


extractPheno=function(var, varFile, dfL){
  print("=======================================")
   varInfo=subset(varFile, label==var)


for ( i in 1:length(dfL) ) {
  print(i)
    df=dfL[[i]]
    dfOut=data.frame(eid=df$eid)

    col=data.frame(str_split_fixed(colnames(df), "-", 2))
    colAvail=subset(col, X1==varInfo$ID)
    print(colAvail)


    if(NROW(colAvail)==0) next
    
    if(NROW(colAvail)>0){
        print(paste0(var, " available in ", names(dfL)[i]))
        print("================")
        print("Colnames")
        print("================")
        print(colAvail)
        tIn=grep(".0",colAvail$X2, value=T)
        colAvail=subset(colAvail, X2 %in% tIn)

        timePoint=NROW(colAvail)-1
       print(paste0("Number of follow ups for ", var, ": ", timePoint))
               print(colAvail)
       dfSel=subset(df, select=paste0(varInfo$ID, "-",seq(0,timePoint, 1),".0"))
       colnames(dfSel)=paste0(varInfo$label, "_",seq(0,timePoint, 1))
       dfSel$eid=df$eid
       head(dfSel)

        return(dfSel)
        }
        }
}

varIncLabel=readVarNames(do="extract")
UKBBL=lapply(varIncLabel$label, function(x) extractPheno(var=x, varFile=varIncLabel, dfL=UKBBList))
UKBBdf=Reduce(function(x,y) dplyr::full_join(x = x, y = y, by = "eid", suffix=c("", "") ),  UKBBL)

print("Exclude participants withdrawing from the study")
exclude=read.csv(paste0(HOME, "/data/w16389_2023-04-25.csv"), header=F)
UKBBind=subset(UKBBdf, !eid %in% exclude$V1)
print("Excluded individuals (consent withdrawn):")
print(NROW(UKBBdf)-NROW(UKBBind))

print("Save selected data")
saveRDS(UKBBind, paste0(HOME, "/output/UKBB.rds"))

print("All output saved")
uploadLog(file=paste0("extractUKBB_R.log"))
uploadLog(file=paste0("exractUKBB_C.log"))

print("All data saved on cluster")
