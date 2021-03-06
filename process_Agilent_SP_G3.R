##########################################
#Code to process agilent S3 G3 data
#
#Pichai Raman
#3/21/16
#
#http://matticklab.com/index.php?title=Single_channel_analysis_of_Agilent_microarray_data_with_Limma
##########################################


#This is to pass arguments to R
options(echo=TRUE) # if you want see commands in output file
args <- commandArgs(trailingOnly = TRUE)
print(args)


#call libraries
library(limma);

curDir <- getwd(); 
celDir = args[1];
setwd(celDir);


#read data files
x <- read.maimages(files=list.files(), source="agilent",green.only=TRUE);

#subtract background
y <- backgroundCorrect(x, method="normexp", offset=16)

#Normalize between arrays
y <- normalizeBetweenArrays(y, method="quantile")

#Average spots
y.ave <- avereps(y, ID=y$genes$ProbeName)

#Create data frame
dataExp <- data.frame(y.ave$genes, y.ave$E);
dataExp <- dataExp[dataExp[,"ControlType"]==0,];
rownames(dataExp) <-dataExp[,"ProbeName"];
dataExp <- dataExp[-1:-5];
numCol <- ncol(dataExp);

#Get Annotation
annot <- read.delim(args[2]);
rownames(annot) <- annot[,1];

#Update with gene names instead of probes 
dataExp[,"MAX"] <- apply(dataExp, FUN=max, MARGIN=1);
dataExp <- dataExp[order(-dataExp[,"MAX"]),]
annot <- annot[rownames(dataExp),];
dataExp[,"Hugo_Gene_Symbol"] <- as.character(annot[,"GENE_SYMBOL"]);
dataExp[,"Entrez_Gene_Id"] <- as.character(annot[,"GENE"]);


dataExp <- dataExp[!duplicated(dataExp[,"Hugo_Gene_Symbol"]),]
dataExp <- dataExp[!grepl("\\//", dataExp[,"Hugo_Gene_Symbol"]),];
rownames(dataExp) <- dataExp[,"Hugo_Gene_Symbol"];
dataAnnot <- dataExp[,c((numCol+2):ncol(dataExp))];
dataExp <- dataExp[,c(1:numCol)];
dataExp <- 2^dataExp;

zLog <- function(x)
{
tmp <- log2(x);
tmp <- (tmp-mean(tmp))/sd(tmp);
}

zDataExp <- data.frame(t(apply(dataExp, FUN=zLog, MARGIN=1)));
dataExp <- data.frame(dataAnnot, dataExp);
zDataExp <- data.frame(dataAnnot, zDataExp);

colnames(dataExp) <- gsub(".CEL", "", colnames(dataExp));
colnames(zDataExp) <- gsub(".CEL", "", colnames(zDataExp));


expFileName <- paste(args[3], "_Exprs.txt", sep="");
zExpFileName <- paste(args[3], "_Z_Scores.txt", sep="");

setwd(curDir);
write.table(dataExp, expFileName, sep="\t", row.names=F);
write.table(zDataExp, zExpFileName, sep="\t", row.names=F);














