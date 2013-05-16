suppressPackageStartupMessages({
  require(knitr)
library(Biobase)
library(devtools)
library(latticeExtra)
library(ggplot2)
library(reshape)
library(plyr)
library(flowWorkspace)
library(gdata)
  })
Plots<-vector('list')
setwd("/Users/gfinak/Documents/Projects/flowCAPIII/Evaluation/Challenge 4/")

scale <- .8                             #Downscale plots modestly
onecolinch <- 86/25.4/scale                   #one column figure
twocolinch <- 178/25.4/scale                  #two column figures
aspects <- c(1, .8, .75)                #aspect ratios
opts_chunk$set(fig.width=twocolinch,autodep=TRUE, fig.height=aspects[1]*twocolinch, dev='pdf', cache=FALSE, echo=FALSE,message=FALSE,warning=FALSE,error=FALSE,results='hide')

ltheme <- canonical.theme(color = FALSE)      ## in-built B&W theme
ltheme$strip.background$col <- "transparent" ## change strip bg
lattice.options(default.theme = ltheme)      ## set as default




fill <- function(x,y=''){
wh <- which(!x%in%y)
wh <- c(wh,length(x)+1)
for(i in 1:((length(wh)-1))){
x[wh[i]:(wh[i+1]-1)] <- x[wh[i]]
}
x
}

data<-read.xls("/Users/gfinak/Documents/Projects/flowCAPIII/Evaluation/Challenge 4/central_manual_gating/CA T-cell.zip/CA T-cell.xlsx",check.names=FALSE,as.is=TRUE)

#Fill missing cells
data[,1] <- fill(data[,1])
#Remove NA columns
data <- data[,which(apply(data,2,function(x)!all(is.na(x))))]
#Remove Mean, CV and SD rows
data <- subset(data,!Sample%in%c("Mean","StdDev","CV"))
#Make Center column
colnames(data)[1] <- "Center"
data$Center <- factor(data$Center)
#remove Sample column, don't need it
data$Sample <- NULL
#Replicates
data$Replicate <- rep(1:4,9)[-c(9:10)]
data <- as.data.frame(data)
#make other columns numeric rather than factors
for(i in 1:ncol(data)){
    if(class(data[,i])=="character")
        data[,i] <- as.numeric(data[,i])
}
colnames(data) <- gsub("\\n"," ",colnames(data))
data <- melt(data,id=c("Center","Replicate"))
data <- rename(data,c(variable="Population",value="Percentage"))
data <- subset(data,!Population%in%c("CD3","CD4","CD8"))
data$Population <- gsub("\\.1"," CD8",data$Population)
data$Population[1:170] <- sprintf("%s CD4",data$Population[1:170])
data$Population <- factor(data$Population)


suppressPackageStartupMessages({
require(lme4)
require(languageR)
require(multcomp)
require(contrast)})
lm1 <- lmer((Percentage)/100~Center*Population+(1|Center:Population),data)


lm1.st<-lm(Percentage~Population*Center,data)
eg <- combn(9,2)
eg <- cbind(levels(data$Center)[combn(9,2)[1,]],levels(data$Center)[combn(9,2)[2,]])
res <- vector('list',nrow(eg))
for(i in 1:nrow(eg)){
    if(eg[i,1]==eg[i,2])
        next
cc<-contrast(lm1.st,a=list(Population=levels(data$Population),Center=eg[i,1]),b=list(Population=levels(data$Population),Center=eg[i,2]))

rownames(cc$X)<-as.character(gl(1,10,labels=paste(as.matrix(eg[i,]),collapse=" vs ")):factor(rep(levels(data$Population),1)))

res[[i]] <- summary(glht(lm1,cc$X))

}


data$fitted <- fitted(lm1)
p<-list(ggplot(data)+geom_boxplot(aes(x=Center,y=Percentage,col=Center))+facet_wrap(~Population,scale="free")+theme_bw()+theme(axis.text.x=element_text(angle=90,hjust=1),strip.text.x=element_text(size=6)))
Plots<-c(Plots,p)

p<-list(ggplot(data)+geom_boxplot(aes(y=fitted,x=Population))+theme_bw()+theme(strip.text.x=element_text(size=6),axis.text.x=element_text(angle=90,hjust=1))+ggtitle("Variability of Centrally Gated Populations Across Centers")+scale_y_continuous(name="Fraction"))
Plots<-c(Plots,p)



foo.central <- do.call(rbind,with(unique(subset(data,select=c("Population","Center","fitted"))),{by(cbind(fitted,Center,Population),Population,function(x)unique(data.frame(Population=x$Population,CV=sd(x$fitted)/mean(x$fitted))))}))
foo.central$Population <- rownames(foo.central)
p<-list(ggplot(foo.central)+geom_bar(aes(x=Population,y=CV,stat="identity"))+theme_bw()+theme(axis.text.x=element_text(angle=90,hjust=1))+ggtitle("Cross-Center Variability of Centrally Gated Data")+scale_y_continuous(name="C.V."))
Plots<-c(Plots,p)



data.b<-read.xls("/Users/gfinak/Documents/Projects/flowCAPIII/Evaluation/Challenge 4/central_manual_gating/CA B-cell/CA B-cell.xlsx",check.names=FALSE,as.is=TRUE)


#Fill missing cells
data.b[,1] <- fill(data.b[,1])
#Remove NA columns
data.b <- data.b[,which(apply(data.b,2,function(x)!all(is.na(x))))]
#Remove Mean, CV and SD rows
data.b <- subset(data.b,!Sample%in%c("Mean","StDev","StdDev","CV"))
#Make Center column
colnames(data.b)[1] <- "Center"
data.b$Center <- factor(data.b$Center)
#remove Sample column, don't need it
data.b$Sample <- NULL
#Replicates
data.b$Replicate <- rep(1:4,9)[-c(9:10)]
data.b <- as.data.frame(data.b)
#make other columns numeric rather than factors
for(i in 1:ncol(data.b)){
    if(class(data.b[,i])=="character")
        data.b[,i] <- as.numeric(data.b[,i])
}
colnames(data.b) <- gsub("\\n"," ",colnames(data.b))
data.b <- melt(data.b,id=c("Center","Replicate"))
data.b <- rename(data.b,c(variable="Population",value="Percentage"))
data.b <- subset(data.b,!Population%in%c("CD3","CD4","CD8"))
data.b <- subset(data.b,!Population%in%c("plasmablasts % of (total CD19+)","total 19+ (count)","38+ 27+ plasmablasts (count)"))
data.b$Population <- factor(data.b$Population)



lm2 <- lmer((Percentage)/100~Center*Population+(1|Center:Population),data.b)
data.b$fitted <- fitted(lm2)
p<-list(ggplot(data.b)+geom_boxplot(aes(x=Center,y=Percentage,col=Center))+facet_wrap(~Population,scale="free")+theme_bw()+theme(axis.text.x=element_text(angle=90,hjust=1),strip.text.x=element_text(size=6)))
Plots<-c(Plots,p)

foo.b.central <- do.call(rbind,with(unique(subset(data.b,select=c("Population","Center","fitted"))),{by(cbind(fitted,Center,Population),Population,function(x)unique(data.frame(Population=x$Population,CV=sd(x$fitted)/mean(x$fitted))))}))
foo.b.central$Population <- rownames(foo.b.central)
p<-list(ggplot(foo.b.central)+geom_bar(aes(x=Population,y=CV,stat="identity"))+theme_bw()+theme(axis.text.x=element_text(angle=90,hjust=1))+ggtitle("Cross-Center Variability of Centrally Gated Data")+scale_y_continuous(name="C.V."))
Plots<-c(Plots,p)


DENSE<-read.csv("/Users/gfinak/Documents/Projects/flowCAPIII/Evaluation/Challenge 4/submissions/Aaron/AaronBrandesBigPropTable.csv")
DENSE2<-read.csv("/Users/gfinak/Documents/Projects/flowCAPIII/Evaluation/Challenge 4/submissions/Aaron/HIPCProportionsData_Final.csv")
flowAP<-read.csv("/Users/gfinak/Documents/Projects/flowCAPIII/Evaluation/Challenge 4/submissions/FHCRC/FlowCAP-Submission/results.csv")
JCVI.B<-read.csv("/Users/gfinak/Documents/Projects/flowCAPIII/Evaluation/Challenge 4/submissions/JVCI/ResultTemplate_JCVI.csv")
JCVI.T<-read.csv("/Users/gfinak/Documents/Projects/flowCAPIII/Evaluation/Challenge 4/submissions/JVCI/resultTemplate_challenge4_T_stanford_submit.csv.csv")
emcytom<-read.csv("/Users/gfinak/Documents/Projects/flowCAPIII/Evaluation/Challenge 4/submissions/SamWang/CH4_submit/flowCAP3_CH4.csv")            
flowDensity<-read.csv("/Users/gfinak/Documents/Projects/flowCAPIII/Evaluation/Challenge 4/submissions/flowDensity/flowCAP3_Challeng4/Results/allStats.csv")

scores<- vector('list',5)
names(scores)<-c("DENSE","flowAP","flowDensity","JCVI","emcytom")
scores<-lapply(scores,function(x){x<-0;x})

#clean up JCVI Data
colnames(JCVI.T)<-colnames(JCVI.B)
cbind(as.matrix(lapply(JCVI.T,class)),as.matrix(lapply(JCVI.B,class)))

colnames(DENSE2)
#Check if each submission has all panels
if(all(levels(DENSE2$Panel)%in%c("Bcell","Tcell")))
  message("DENSE2 okay")
if(all(levels(emcytom$Panel)%in%c("Bcell","Tcell")))
  scores$emcytom<-scores$emcytom+1
if(all(levels(JCVI.B$Panel)%in%c("Bcell","Tcell"))&all(levels(JCVI.T$Panel)%in%c("Bcell","Tcell")))
  scores[["JCVI"]]<-scores[["JCVI"]]+1
if(all(levels(flowAP$Panel)%in%c("Bcell","Tcell")))
  scores$flowAP<-scores$flowAP+1
if(all(levels(DENSE$Panel)%in%c("Bcell","Tcell")))
  scores$DENSE<-scores$DENSE+1
if(all(levels(flowDensity$Panel)%in%c("Bcell","Tcell")))
  scores$flowDensity<-scores$flowDensity+1

#clean up the panels for Broad and JCVI
DENSE<-subset(DENSE,Panel%in%c("Tcell","Bcell"))
DENSE2<-subset(DENSE2,Panel%in%c("Tcell","Bcell"))
JCVI.B$Panel<-factor(gsub("Tcell *","Tcell",gsub("\t*","",JCVI.B$Panel)))
JCVI.T$Panel<-factor(gsub("Tcell *","Tcell",gsub("\t*","",JCVI.T$Panel)))
JCVI.B<-subset(JCVI.B,Panel%in%c("Tcell","Bcell"))
JCVI.T<-subset(JCVI.T,Panel%in%c("Tcell","Bcell"))


#Check algorithms
levels(DENSE2$Algorithm)
levels(emcytom$Algorithm)
scores$emcytom<-scores$emcytom+1
levels(flowAP$Algorithm)
scores$flowAP<-scores$flowAP+1
levels(DENSE$Algorithm)
scores$DENSE<-scores$DENSE+1
levels(flowDensity$Algorithm)
scores$flowDensity<-scores$flowDensity+1
levels(factor(JCVI.B$Algorithm))
levels(factor(JCVI.T$Algorithm))

#check if all column names match
cnames<-c("Panel","Population.Name","Alias","Parent","Count","Proportion.of.Parent","Algorithm","Center","Replicate")
all(colnames(DENSE2)%in%cnames)
if(all(colnames(DENSE)%in%cnames))
  scores$DENSE<-scores$DENSE+1
if(all(colnames(flowAP)%in%cnames))
  scores$flowAP<-scores$flowAP+1
if(all(colnames(JCVI.B)%in%cnames)&all(colnames(JCVI.T)%in%cnames))
  scores$JCVI<-scores$JCVI+1
if(all(colnames(emcytom)%in%cnames))
  scores$emcytom<-scores$emcytom+1
if(all(colnames(flowDensity)%in%cnames))
  scores$flowDensity<-scores$flowDensity+1

#fix up the column names
DENSE<-DENSE[,-1L]
all(colnames(DENSE)%in%cnames)

colnames(flowAP)[which(!colnames(flowAP)%in%cnames)]<-cnames[2]
all(colnames(flowAP)%in%cnames)

#check the order of column names
match(colnames(DENSE),cnames)
match(colnames(flowAP),cnames)
match(colnames(flowDensity),cnames)
match(colnames(emcytom),cnames)
match(colnames(JCVI.T),cnames)
match(colnames(JCVI.B),cnames)
match(colnames(DENSE2),cnames)

#check that the stats columns are numeric or integer and not factors
class(flowAP$Count)
class(flowDensity$Count)
class(emcytom$Count)
class(DENSE$Count)%in%"integer"
class(JCVI.B$Count)%in%"integer"&class(JCVI.T$Count)%in%"integer"
class(DENSE2$Count)%in%"integer"

#fix counts
DENSE$Count<-as.numeric(as.character(factor(DENSE$Count)))
JCVI.B$Count<-as.numeric(as.character(factor(JCVI.B$Count)))
JCVI.T$Count<-as.numeric(as.character(factor(JCVI.T$Count)))
DENSE2$Count<-as.numeric(DENSE2$Count)

class(flowAP$Proportion.of.Parent)%in%"numeric"
class(flowDensity$Proportion.of.Parent)%in%"numeric"
class(emcytom$Proportion.of.Parent)%in%"numeric"
class(DENSE$Proportion.of.Parent)%in%"numeric"
class(JCVI.B$Proportion.of.Parent)%in%"numeric"
class(JCVI.T$Proportion.of.Parent)%in%"numeric"
class(DENSE2$Proportion.of.Parent)%in%"numeric"

DENSE$Proportion.of.Parent<-as.numeric(as.character(factor(DENSE$Proportion.of.Parent)))
JCVI.T$Proportion.of.Parent<-as.numeric(as.character(factor(JCVI.T$Proportion.of.Parent)))


JCVI.B$Algorithm<-factor(JCVI.B$Algorithm)
JCVI.B$Replicate<-factor(JCVI.B$Replicate)

head(JCVI.T)
head(DENSE2)
head(JCVI.B)
head(emcytom)
head(flowDensity)
head(flowAP)
head(DENSE)


#Population levels
JCVI.T$Population.Name<-gsub(" *$","",gsub("\t","",JCVI.T$Population.Name))
JCVI.B$Population.Name<-factor(JCVI.B$Population.Name)

emcytom$Population.Name<-factor(emcytom$Population.Name)

DENSE2$Population.Name <- factor(DENSE2$Population.Name)

flowDensity$Population.Name<-factor(flowDensity$Population.Name)

flowAP$Population.Name<-factor(flowAP$Population.Name)

DENSE$Population.Name<-factor(DENSE$Population.Name)

#Parents
levels(factor(JCVI.T$Parent))
levels(factor(JCVI.B$Parent))
JCVI<-rbind(JCVI.B,JCVI.T)

levels(factor(DENSE$Parent))
levels(factor(flowDensity$Parent))
levels(factor(flowAP$Parent))
levels(factor(emcytom$Parent))
levels(factor(JCVI$Parent))
levels(factor(DENSE2$Parent))

JCVI$Algorithm<-factor("JVCI")
DENSE$Algorithm<-factor(DENSE$Algorithm)
DENSE2$Algorithm<-factor(DENSE2$Algorithm,label="DENSE2")

#Make sure percentages are all on the right scale
flowAP$Proportion.of.Parent
emcytom$Proportion.of.Parent<-emcytom$Proportion.of.Parent/100
DENSE$Proportion.of.Parent
JCVI$Proportion.of.Parent<-JCVI$Proportion.of.Parent/100
flowDensity$Proportion.of.Parent<-flowDensity$Proportion.of.Parent/100

combined<-rbind(DENSE,flowDensity,flowAP,emcytom,JCVI,DENSE2)
combined[,1]<-factor(combined[,1])
combined[,2]<-factor(combined[,2])
combined[,3]<-factor(gsub(" *$","",gsub("\t","",combined[,3])))
combined[,4]<-factor(combined[,4])
combined[,5]<-factor(combined[,5])
combined[,5]<-as.numeric(as.character(combined[,5]))


combined[,6]<-factor(combined[,6])
combined[,6]<-as.numeric(as.character(combined[,6]))
combined[,7]<-factor(combined[,7])
combined[,8]<-factor(combined[,8])
combined[,8]<-factor(toupper(combined[,8]))
combined[,9]<-factor(combined[,9])
combined[,9]<-factor(gsub("A","1",gsub("_","",gsub("_([1234])_[1234]","\\1",gsub(".*C04","4",gsub(".*C03","3",gsub(".*C02","2",gsub(".*C01","1",gsub(".*A04","4",gsub(".*A03","3",gsub(".*A02","2",gsub(".*A01","1",gsub("4-2","2",gsub("3-2","2",gsub("3-1","1",gsub("4-1","1",gsub("s","",gsub("B","",gsub("T","",gsub("[ABC][789]","",gsub("Cyto_Troll","",gsub("T_CELL","",gsub("BCELL","",gsub("T-Cell","",gsub("[ABC][78901][7890]","",gsub("BSMS_Cytotrol","",gsub("B_CELL","",gsub("TCELL","",gsub("BCELLS","",gsub("T-Cells","",gsub(" ","",gsub("cell","",gsub("CytTrol","",gsub("T Cell","",gsub("B Cell","",gsub("Cyto-Trol","",gsub("CytoTrol","",gsub("\\.fcs","",combined[,9]))))))))))))))))))))))))))))))))))))))
combined[combined[,9]%in%"","Replicate"]<-"2"
combined[,9]<-factor(combined[,9])

centraldata<-rbind(data.frame(data,Panel="Tcell"),data.frame(data.b[,],Panel="Bcell"))
saveRDS(centraldata,file="/Users/gfinak/Documents/Projects/AdvDataAnalysisCyto2013/RFlowToolsFlowCAP/Data/centraldata.rds")
saveRDS(combined,file="/Users/gfinak/Documents/Projects/AdvDataAnalysisCyto2013/RFlowToolsFlowCAP/Data/combined.rds")

orig.levels.central<-levels(factor(centraldata$Panel:centraldata$Population))

orig.levels.combined<-levels(factor(combined$Parent:combined$Population.Name))

new.levels.central<-rep(NA,length(orig.levels.central))
new.levels.combined<-rep(NA,length(orig.levels.combined))

new.levels.central[1]<-"activated CD4"
new.levels.combined[9]<-"activated CD4"
new.levels.central[2]<-"activated CD8"
new.levels.combined[14]<-"activated CD8"
new.levels.central[3]<-"EM CD4"
new.levels.combined[12]<-"EM CD4"
new.levels.central[4]<-"EM CD8"
new.levels.combined[17]<-"EM CD8"
new.levels.central[5]<-"Effector CD4"
new.levels.combined[11]<-"Effector CD4"
new.levels.central[6]<-"Effector CD8"
new.levels.combined[16]<-"Effector CD8"
new.levels.central[7]<-"CM CD4"
new.levels.combined[10]<-"CM CD4"
new.levels.central[8]<-"CM CD8"
new.levels.combined[15]<-"CM CD8"
new.levels.central[9]<-"Naive CD4"
new.levels.combined[13]<-"Naive CD4"
new.levels.central[10]<-"Naive CD8"
new.levels.combined[18]<-"Naive CD8"
new.levels.central[11]<-"CD3-"
new.levels.combined[5]<-"CD3-"
new.levels.central[12]<-"(19+20+)"
new.levels.central[13]<-"Naive B"
new.levels.combined[20]<-"Naive B"
new.levels.central[14]<-"Memory IgD+"
new.levels.combined[23]<-"Memory IgD+"
new.levels.central[15]<-"Memory IgD-"
new.levels.combined[22]<-"Memory IgD-"
new.levels.central[16]<-"transitional B"
new.levels.combined[24]<-"transitional B"
new.levels.central[17]<-"(19+20-)"
new.levels.central[18]<-"Plasmablasts"
new.levels.combined[19]<-"Plasmablasts"

to.omit<-is.na(new.levels.combined)
new.levels.combined[is.na(new.levels.combined)]<-orig.levels.combined[to.omit]

centraldata$Popname<-factor(centraldata$Panel:centraldata$Population,levels=orig.levels.central,labels=new.levels.central)
combined$Popname<-factor(combined$Parent:combined$Population.Name,levels=orig.levels.combined,labels=new.levels.combined)

combined$Percentage<-combined$Proportion.of.Parent*100
centraldata$Algorithm<-"CentralGating"
fulldata<-rbind(combined[,c("Panel","Algorithm","Center","Popname","Replicate","Percentage")],centraldata[,c("Panel","Algorithm","Center","Popname","Replicate","Percentage")])
fulldata$Center<-factor(gsub("BIIR","BAYLOR",toupper(gsub("'","",fulldata$Center))))
saveRDS(fulldata,file="fulldata.rds")
fulldata$Algorithm <- factor(fulldata$Algorithm,labels=c("DENSE","flowDensity","OpenCyto","emcytom","JCVI","DENSE2","CentralGating"))

#Compute CVS within each center
CVS<-do.call(rbind,with(fulldata,by(fulldata,Algorithm:Panel:Popname:Center,function(x)unique(data.frame(Algorithm=x$Algorithm,Panel=x$Panel,Popname=x$Popname,Center=x$Center,CV=sd(x$Percentage)/mean(x$Percentage))))))
#remove populations we are not evaluating
CVS2<-subset(CVS,!Popname%in%levels(CVS$Popname)[c(1,2,3,4,5,6,7,8,25,26)])
CVS2$Popname<-factor(CVS2$Popname)


p<-list(ggplot(data=subset(CVS2,Panel%in%"Tcell"),aes(x=Algorithm,y=CV,fill=Center))+geom_bar(stat="identity",position="dodge")+facet_wrap(~Popname,scales="free")+theme_bw()+theme(axis.text.x=element_text(angle=90,hjust=1))+scale_fill_brewer(palette="Set1"))
Plots<-c(Plots,p)

p<-list(ggplot(data=subset(CVS2,Panel%in%"Bcell"),aes(x=Algorithm,y=CV,fill=Center))+geom_bar(stat="identity",position="dodge")+facet_wrap(~Popname,scales="free")+theme_bw()+theme(axis.text.x=element_text(angle=90,hjust=1))+scale_fill_brewer(palette="Set1"))
Plots<-c(Plots,p)

#compute CVS across centers for each algorithm
avg<-(do.call(rbind,with(fulldata,by(fulldata,Algorithm:Panel:Popname:Center,function(x)unique(data.frame(Algorithm=x$Algorithm,Panel=x$Panel,Popname=x$Popname,Center=x$Center,mu=mean(x$Percentage)))))))

CV.crosscenter<-do.call(rbind,with(avg,by(avg,Algorithm:Panel:Popname,function(x){
  unique(data.frame(Algorithm=x$Algorithm,Panel=x$Panel,Popname=x$Popname,CV=sd(x$mu)/mean(x$mu)))
}
)))
CV.crosscenter<-subset(CV.crosscenter,Popname%in%levels(CV.crosscenter$Popname)[c(9:24)])

p<-list(ggplot(data=subset(CV.crosscenter,Panel%in%"Tcell"&!Algorithm%in%"JCVI"))+geom_bar(stat="identity",position="dodge",aes(x=Algorithm,y=CV*100,fill=Algorithm))+facet_wrap(~Popname,scales="free",nrow=2)+theme_bw()+theme(axis.text.x=element_text(angle=90,hjust=1))+scale_fill_manual(values=c("DENSE"="red","OpenCyto"="blue","flowDensity"="green","emcytom"="cyan","JCVI"="pink","CentralGating"="yellow","DENSE2"="orange"))+scale_y_continuous(name="Coefficient of Variability")+theme(strip.text.x=element_text(size=18),axis.text.x=element_text(size=16),axis.text.y=element_text(size=16),axis.title.x=element_text(size=21),axis.title.y=element_text(size=21)))
Plots<-c(Plots,p)

p<-list(ggplot(data=subset(CV.crosscenter,Panel%in%"Bcell"))+geom_bar(stat="identity",position="dodge",aes(x=Algorithm,y=CV*100,fill=Algorithm))+facet_wrap(~Popname,scales="free")+theme_bw()+theme(axis.text.x=element_text(angle=90,hjust=1))+scale_fill_manual(values=c("DENSE"="red","OpenCyto"="blue","flowDensity"="green","emcytom"="cyan","JCVI"="pink","CentralGating"="yellow","DENSE2"="orange"))+scale_y_continuous(name="Coefficient of Variability")+theme(strip.text.x=element_text(size=18),axis.text.x=element_text(size=16),axis.text.y=element_text(size=16),axis.title.x=element_text(size=21),axis.title.y=element_text(size=21)))
Plots<-c(Plots,p)

##Boxplots to assess bias
p<-list(ggplot(data=subset(fulldata,Panel%in%"Tcell"&Popname%in%levels(fulldata$Popname)[c(9:20,22:24)]))+geom_boxplot(aes(x=Algorithm,y=Percentage,fill=Algorithm))+facet_wrap(~Popname,scale="free")+theme_bw()+theme(axis.text.x=element_text(angle=90,hjust=1))+scale_fill_manual(values=c("DENSE"="red","OpenCyto"="blue","flowDensity"="green","emcytom"="cyan","JCVI"="pink","CentralGating"="yellow","DENSE2"="orange")))
Plots<-c(Plots,p)

p<-list(ggplot(data=subset(fulldata,Panel%in%"Bcell"&Popname%in%levels(fulldata$Popname)[c(9:20,22:24)]))+geom_boxplot(aes(x=Algorithm,y=Percentage,fill=Algorithm))+facet_wrap(~Popname,scale="free")+theme_bw()+theme(axis.text.x=element_text(angle=90,hjust=1))+scale_fill_manual(values=c("DENSE"="red","OpenCyto"="blue","flowDensity"="green","emcytom"="cyan","JCVI"="pink","CentralGating"="yellow","DENSE2"="orange")))
Plots<-c(Plots,p)



require(lme4)
require(languageR)
require(multcomp)
require(contrast)
imputed<-fulldata
imputed$imputed<-imputed$Percentage
imputed$imputed[is.na(imputed$imputed)]<-0

impT<-subset(imputed,Panel%in%"Tcell"&Popname%in%levels(fulldata$Popname)[c(9:20,22:24)])
impB<-subset(imputed,Panel%in%"Bcell"&Popname%in%levels(fulldata$Popname)[c(9:20,22:24)])
impT$Popname<-factor(impT$Popname)
impT$Algorithm<-factor(impT$Algorithm)
impB$Popname<-factor(impB$Popname)
impB$Algorithm<-factor(impB$Algorithm)

lm1.T <- lmer(((imputed)/100)~Algorithm*Popname+(1|Center:Popname)+(1|Algorithm:Popname),impT)
lm1.B <- lmer(((imputed)/100)~Algorithm*Popname+(1|Center:Popname)+(1|Algorithm:Popname),impB)

lm1.st.T<-lm((imputed/100)~Algorithm*Popname,impT)
eg <- combn(7,2)
eg <- cbind(levels(impT$Algorithm)[combn(7,2)[1,]],levels(impT$Algorithm)[combn(7,2)[2,]])
res <- vector('list',nrow(eg))
for(i in 1:nrow(eg)){
    if(eg[i,1]==eg[i,2])
        next
cc<-contrast(lm1.st.T,a=list(Popname=levels(impT$Popname),Algorithm=eg[i,2]),b=list(Popname=levels(impT$Popname),Algorithm=eg[i,1]))

rownames(cc$X)<-as.character(gl(1,10,labels=paste(as.matrix(eg[i,2:1]),collapse=" vs ")):factor(rep(levels(impT$Popname),1)))

res[[i]] <- (glht(lm1.T,cc$X))

}
res.T<-res[which(eg[,2]=="CentralGating")]

#B cells GLHT
lm1.st.B<-lm(imputed/100~Algorithm*Popname,impB)
eg <- combn(6,2)
eg <- cbind(levels(impB$Algorithm)[combn(6,2)[1,]],levels(impB$Algorithm)[combn(6,2)[2,]])
res <- vector('list',nrow(eg))
for(i in 1:nrow(eg)){
    if(eg[i,1]==eg[i,2])
        next
cc<-contrast(lm1.st.B,a=list(Popname=levels(impB$Popname),Algorithm=eg[i,2]),b=list(Popname=levels(impB$Popname),Algorithm=eg[i,1]))

rownames(cc$X)<-as.character(gl(1,5,labels=paste(as.matrix(eg[i,2:1]),collapse=" vs ")):factor(rep(levels(impB$Popname),1)))

res[[i]] <- (glht(lm1.B,cc$X))

}
res.B<-res[which(eg[,2]=="CentralGating")]


ggplot.confint<-function(x,lw,up){
  if(class(x)!="glht"){
    stop("x must be glht object")
  }
  ci<-confint(x)$confint
  annotation<-do.call(rbind,lapply(strsplit(rownames(ci),":"),function(x){alg<-gsub(".*vs ","",x[[1]]);pop<-x[[2]];c(alg,pop)}))
  colnames(annotation)<-c("algorithm","pop")
  df<-data.frame(ci,Effect=as.vector(rownames(ci)),p=summary(x)$test$pvalues)
  df$Effect<-annotation[,"pop"]
  g<-ggplot(data=df,aes(x=Effect,y=Estimate,ymin=lwr,ymax=upr,color=p<0.05))+geom_pointrange(lwd=1)+coord_flip(ylim=c(lw,up))+geom_hline(aes(x=0),lty=2)+xlab("Cell Population")+ylab("Effect Size")+theme_bw()+theme(legend.position="none",axis.text.y=element_text(size=18),axis.text.x=element_text(size=18),axis.title.x=element_text(size=18),axis.title.y=element_text(size=18),plot.title=element_text(size=21))+scale_color_manual(values=c("black","red"))+labs(title=annotation[1,"algorithm"])
g
}

lw<-min(do.call(c,lapply(res.T,function(x){
  min(confint(x)$confint[,"lwr"])
})))
up<-max(do.call(c,lapply(res.T,function(x){
  max(confint(x)$confint[,"upr"])
})))
plots.t<-lapply(res.T,function(x)ggplot.confint(x,lw=lw,up=up))

lw<-min(do.call(c,lapply(res.B,function(x){
  min(confint(x)$confint[,"lwr"])
})))
up<-max(do.call(c,lapply(res.B,function(x){
  max(confint(x)$confint[,"upr"])
})))
plots.b<-lapply(res.B,function(x)ggplot.confint(x,lw=lw,up=up))

p<-do.call(grid.arrange,plots.t)
Plots<-c(Plots,list(p))

p<-do.call(grid.arrange,plots.b)
Plots<-c(Plots,list(p))




impT$fitted<-lm1.T@X%*%fixef(lm1.T)
impB$fitted<-lm1.B@X%*%fixef(lm1.B)

percent.diff.B<-do.call(rbind,with(unique(impB[,c(1,2,4,8)]),by(data.frame(fitted,Algorithm,Popname),Popname,function(x)data.frame(x,percent.difference=(x$fitted[x$Algorithm%in%"CentralGating"]-x$fitted)/(x$fitted[x$Algorithm%in%"CentralGating"])*100))))

percent.diff.T<-do.call(rbind,with(unique(impT[,c(1,2,4,8)]),by(data.frame(fitted,Algorithm,Popname),Popname,function(x)data.frame(x,percent.difference=(x$fitted[x$Algorithm%in%"CentralGating"]-x$fitted)/(x$fitted[x$Algorithm%in%"CentralGating"])*100))))

by(percent.diff.T,percent.diff.T$Algorithm,function(x)sum(abs(x$percent.diff)))
by(percent.diff.B,percent.diff.B$Algorithm,function(x)sum(abs(x$percent.diff)))

# mse<-function(x,y){
#     (sqrt(sum((y-mean(x,na.rm=TRUE))^2,na.rm=TRUE))/mean(x,na.rm=TRUE))*100
#   }

mse2<-function(x,ref="CentralGating",test="DENSE"){
  ref<-subset(x,Algorithm%in%ref)
  test<-subset(x,Algorithm%in%test)
  ref<-ddply(ref,.(Center:Popname),summarise,Center=unique(Center),Popname=unique(Popname),muref=mean(Percentage))
  test$Key<-test$Center:test$Popname
  colnames(test)[ncol(test)]<-"Center:Popname"
  merge(test,ref[,c(1,4)],by="Center:Popname")
  ref<-merge(test,ref[,c(1,4)],by="Center:Popname")
  ref<-ddply(ref,.(Algorithm:Center:Popname),summarise,Algorithm=unique(Algorithm),Center=unique(Center),Popname=unique(Popname),RMSD=sqrt(mean((Percentage-muref)^2)),RMSD.Percent=100*(sqrt(mean((Percentage-muref)^2))/unique(muref)))[,-1L]
  ref
}

mseT<-rbind(mse2(x=impT,ref="CentralGating",test="DENSE"),
mse2(x=impT,ref="CentralGating",test="flowDensity"),
mse2(x=impT,ref="CentralGating",test="OpenCyto"),
mse2(x=impT,ref="CentralGating",test="CentralGating"),
mse2(x=impT,ref="CentralGating",test="JCVI"),
mse2(x=impT,ref="CentralGating",test="emcytom"),
mse2(x=impT,ref="CentralGating",test="DENSE2"))

p<-list(ggplot(mseT)+geom_bar(aes(x=Algorithm,y=RMSD.Percent,fill=Algorithm),stat="identity")+facet_grid(Popname~Center,scale="free_y")+theme_bw()+theme(axis.text.x=element_text(angle=90,hjust=1),strip.text.y=element_text(size=8))+scale_fill_manual(values=c("DENSE"="red","OpenCyto"="blue","flowDensity"="green","emcytom"="cyan","JCVI"="pink","CentralGating"="yellow","DENSE2"="orange")))
Plots<-c(Plots,p)

p<-list(ggplot(ddply(mseT,.(Algorithm:Popname),summarise,Algorithm=unique(Algorithm),Popname=unique(Popname),Mean.RMSD.Percent=mean(RMSD.Percent)))+geom_bar(aes(x=Algorithm,y=Mean.RMSD.Percent,fill=Algorithm),stat="identity")+facet_wrap(~Popname,scale="free_y")+theme_bw()+theme(axis.text.x=element_text(angle=90,hjust=1))+scale_fill_manual(values=c("DENSE"="red","OpenCyto"="blue","flowDensity"="green","emcytom"="cyan","JCVI"="pink","CentralGating"="yellow","DENSE2"="orange")))
Plots<-c(Plots,p)



mseB<-rbind(mse2(x=impB,ref="CentralGating",test="DENSE"),
mse2(x=impB,ref="CentralGating",test="flowDensity"),
mse2(x=impB,ref="CentralGating",test="OpenCyto"),
mse2(x=impB,ref="CentralGating",test="CentralGating"),
mse2(x=impB,ref="CentralGating",test="JCVI"),
mse2(x=impB,ref="CentralGating",test="emcytom"),
mse2(x=impB,ref="CentralGating",test="DENSE2"))

p<-list(ggplot(mseB)+geom_bar(aes(x=Algorithm,y=RMSD.Percent,fill=Algorithm),stat="identity")+facet_grid(Popname~Center,scale="free_y")+theme_bw()+theme(axis.text.x=element_text(angle=90,hjust=1),strip.text.y=element_text(size=8))+scale_fill_manual(values=c("DENSE"="red","OpenCyto"="blue","flowDensity"="green","emcytom"="cyan","JCVI"="pink","CentralGating"="yellow","DENSE2"="orange")))
Plots<-c(Plots,p)

p<-list(ggplot(ddply(mseB,.(Algorithm:Popname),summarise,Algorithm=unique(Algorithm),Popname=unique(Popname),Mean.RMSD.Percent=mean(RMSD.Percent)))+geom_bar(aes(x=Algorithm,y=Mean.RMSD.Percent,fill=Algorithm),stat="identity")+facet_wrap(~Popname,scale="free_y")+theme_bw()+theme(axis.text.x=element_text(angle=90,hjust=1))+scale_fill_manual(values=c("DENSE"="red","OpenCyto"="blue","flowDensity"="green","emcytom"="cyan","JCVI"="pink","CentralGating"="yellow","DENSE2"="orange")))
Plots<-c(Plots,p)

setwd("/Users/gfinak/Documents/Projects/AdvDataAnalysisCyto2013/LyoplateFlowCAP3/")

