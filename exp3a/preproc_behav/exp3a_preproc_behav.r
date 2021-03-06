## This code is for preparing data of exp3;
# specifically, it clude three parts
# First, clean the data, and record the basic information of participants
# Second, get the d prime, mean ACC and mean RT of this experiment, and save the in csv file;
#      because we will have a meta-analysis for the effect of moralit, the data the combine self and other condition was also saved.
# Third, plot the results (d prime and RT)

## initializing ####
# Get the directory of the current R script
# Set the working directory to the directory where this script is 

curDir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(curDir)
source('Initial_exp3a.r')

curDir = dirname(rstudioapi::getSourceEditorContext()$path)
resDir = "D:/HCP_cloud/Exps/P1_Pos_Self/Exp_Behav_Moral_Asso/Results_exp1_5/Data_Analysis/exp3a"

## load data and edite data
df3a <- read.csv("rawdata_behav_exp3_2018.csv",header = TRUE, sep = ",",stringsAsFactors=FALSE,na.strings=c("","NA"))

# rename colnames
colnames(df3a)[colnames(df3a)=="Target.ACC"] <- "ACC"
colnames(df3a)[colnames(df3a)=="Target.RT"]  <- "RT"
colnames(df3a)[colnames(df3a)=="YesNoResp"]  <- "Matchness"
colnames(df3a)[colnames(df3a)=="self"]       <- "Identity"
colnames(df3a)[colnames(df3a)=="Morality"]   <- "Morality"

# renames independent variables
df3a$Morality[df3a$morality == "moral"]   <- "Good"
df3a$Morality[df3a$morality == "normal"]  <- "Neutral"
df3a$Morality[df3a$morality == "immoral"] <- "Bad"
df3a$Matchness[df3a$Matchness == "Yes"]   <- "Match"
df3a$Matchness[df3a$Matchness == "No"]    <- "Mismatch"

# there recode are important for test trials (not for practice trials)
df3a$Morality[df3a$Shape == 'Goodself' | df3a$Shape == 'Goodother']    <- "Good"
df3a$Morality[df3a$Shape == 'Normalself'| df3a$Shape == 'Normalother'] <- "Neutral"
df3a$Morality[df3a$Shape == 'Badself' | df3a$Shape == 'Badother']      <- "Bad"
df3a$Identity[df3a$Shape == 'Goodself' | df3a$Shape == 'Badself' | df3a$Shape == 'Normalself']    <- "Self"
df3a$Identity[df3a$Shape == 'Goodother'| df3a$Shape == 'Badother'| df3a$Shape == 'Normalother']   <- "Other"
df3a$Morality  <- factor(df3a$Morality, levels=c("Good", "Neutral","Bad")) # make the variables in a specified order
df3a$Identity  <- factor(df3a$Identity, levels=c("Self", "Other"))

df3a <- df3a[,-which(names(df3a) %in% c("Shape","morality"))]  # delete column "Shape", "morality"

df3a.P <- df3a[is.na(df3a$BlockList.Sample),]       # data from practice
df3a.T <- df3a[!(is.na(df3a$BlockList.Sample)),]    # data from test

# number of participant who didn't finished the experiment
nQuit <- length(unique(df3a.P$Subject)) - length(unique(df3a.T$Subject))

### good self is at high level of accuracy at the very beginning of the experiment. other conditions not.

# trials that should be excluded from analysis because of less than 200 ms
# note that this should be reconsidered when doinng DDM analysis
# and also the trials without response
excld.trials <- df3a.T[df3a.T$RT <= 200 & df3a.T$ACC == 1,]
ratio.excld.trials <- nrow(excld.trials)/nrow(df3a.T) # ratio of excluded trials in all triasl.
# caculate the overall accuracy for each subject
subj <- group_by(df3a.T,Subject)
df3a.acc.g <-  plyr::ddply(df3a.T,.(Subject), summarise,
                    N = length(ACC),
                    countN = sum(ACC),
                    ACC = sum(ACC)/length(ACC))
excld.sub <- df3a.acc.g$Subject[df3a.acc.g$ACC < 0.6]  # find participants whose overall ACC is less than 60%
df3a.valid <- df3a.T[!(df3a.T$Subject %in% excld.sub),] # exclude the invalid participants


### 
### Get the ACC and RT for each bin (10 trials of the same condition)
df3a.T.v <- df3a.T[!(df3a.T$Subject %in% excld.sub),]
learnCurve <- df3a.T.v %>%
  select(Subject,                          # select the columns
         BlockList.Sample,
         Matchness,
         Identity,
         Morality,
         ACC,
         RT) %>%
  group_by(Subject,Matchness,Identity,Morality,BlockList.Sample)  %>%  # separate by subj, Conds and blocks
  dplyr::summarise(N = length(RT),  
                   RT_m = mean(RT, na.rm = T),  
                   RT_sd = sd(RT, na.rm = T),
                   ACC_m = sum(ACC) / length(ACC)) %>%
  group_by(Matchness,Identity,Morality,BlockList.Sample) %>%
  dplyr::summarise(N = length(RT_m),                              # sample size for each condition
                   RT_m_g  = mean(RT_m, na.rm = T),               # mean RT for group
                   RT_sd_g = sd(RT_m, na.rm = T),                 # sd of RT for group
                   ACC_m_g = mean(ACC_m),                         # mean ACC of gorup
                   ACC_sd_g = sd(ACC_m))                          # sd ACC of gorup

### plot
learnCurve$cond <- paste(learnCurve$Morality,learnCurve$Identity,sep = '')
pd <- position_dodge(0.1) # move them .05 to the left and right
ggplot(learnCurve[learnCurve$Matchness == 'Match',], aes(x=BlockList.Sample, y=ACC_m_g, colour=cond)) + 
#  geom_errorbar(aes(ymin=len-se, ymax=len+se), width=.1, position=pd) +
  geom_line(position=pd) +
  geom_point(position=pd)

# Check the accuracy of the participants number
length(unique(df3a.valid$Subject)) + length(excld.sub) + nQuit == length(unique(df3a$Subject))

# exclude the invalid trials again for data from valid participants
excld.trials2 <- df3a.valid[df3a.valid$RT <= 200 & df3a.valid$ACC == 1,]
df3a.V         <- df3a.valid[!(df3a.valid$RT <= 200 & df3a.valid$ACC == 1),]  

## Basic information of the data ####
df3a.T.basic <- df3a[!duplicated(df3a$Subject), 1:4]  
num.subj    <- nrow(df3a.T.basic)                         # total number of participants
numT.female <- sum(df3a.T.basic$Sex == 'female');         # number of female
numT.male   <- sum(df3a.T.basic$Sex == 'male');           # number of male
mingAge     <- min(df3a.T.basic$Age)                      # minimum age (detect or other error input)
ageT.mean   <- round(mean(df3a.T.basic$Age),2);           # mean age of all participants
ageT.std    <- round(sd(df3a.T.basic$Age),2);             # standard deviation of age from all
num.excld.sub <- length(unique(excld.sub))               # number of participant excluded
df3a.V.basic   <- df3a.V[!duplicated(df3a.V$Subject), 1:4]  # Get basic information for valid data
numV.female   <- sum(df3a.V.basic$Sex == 'female');       # number of female
numV.male     <- sum(df3a.V.basic$Sex == 'male');         # number of male
ageV.mean     <- round(mean(df3a.V.basic$Age),2);         # mean age
ageV.std      <- round(sd(df3a.V.basic$Age),2);           # SD of age
ratio.excld.trials2 <- nrow(excld.trials2)/nrow(df3a.valid) # excluded trials

## ACC data ####
# ACC for each condition
df3a.acc <-  ddply(df3a.V,.(Subject,Matchness, Morality,Identity), summarise,
                  N = length(ACC),
                  countN = sum(ACC),
                  ACC = sum(ACC)/length(ACC))

# ACC for the data without considering Idenity
df3a.acc_moral <-  ddply(df3a.V,.(Subject,Matchness, Morality), summarise,
                  N = length(ACC),
                  countN = sum(ACC),
                  ACC = sum(ACC)/length(ACC))


# transfer to wide-formate for further analysis in JASP
df3a.acc_w <- dcast(df3a.acc, Subject ~ Matchness + Morality + Identity,value.var = "ACC")
df3a.acc_moral_w <- dcast(df3a.acc_moral, Subject ~ Matchness + Morality,value.var = "ACC")

# add 'ACC' to column names
colnames(df3a.acc_w)[2:13] <- paste("ACC", colnames(df3a.acc_w[,2:13]), sep = "_")
colnames(df3a.acc_moral_w)[2:7] <- paste("ACC", colnames(df3a.acc_moral_w[,2:7]), sep = "_")

## d prime ####

df3a.V$sdt <- NA  # new column called sdt, means signal detection theory

# classify each trial to one category.
for (i in 1:nrow(df3a.V)){
  if (df3a.V$ACC[i] == 1 & (df3a.V$Matchness[i] == "Match")){           # matched trials and correct as hit
    df3a.V$sdt[i] <- "hit"
  } else if (df3a.V$ACC[i] == 1 & (df3a.V$Matchness[i] == "Mismatch")){ # mismatched trials and correct as correct rejection
    df3a.V$sdt[i] <- "CR"
  } else if (df3a.V$ACC[i] != 1 & (df3a.V$Matchness[i] == "Match")){    # mathced trials and wrong at miss
    df3a.V$sdt[i] <- "miss"
  } else if (df3a.V$ACC[i] != 1 & (df3a.V$Matchness[i] == "Mismatch")){ # mismatched trials and wrong as false alarms  
    df3a.V$sdt[i] <- "FA"
  }
}

# calculate the number of each for each condition
df3a.V.SDT <-  ddply(df3a.V,.(Subject,Age, Sex,Morality, Identity,sdt), summarise, N = length(sdt))


# long format to wide
df3a.V.dprime_calc <- dcast(df3a.V.SDT, Subject + Age + Sex + Morality + Identity ~ sdt,value.var = "N")
df3a.V.dprime_calc$miss[is.na(df3a.V.dprime_calc$miss)] <- 0 # set na to 0
df3a.V.dprime_calc$FA[is.na(df3a.V.dprime_calc$FA)]     <- 0

# calculate the hit and false alarm rate
df3a.V.dprime_calc$hitR <- df3a.V.dprime_calc$hit/(df3a.V.dprime_calc$hit + df3a.V.dprime_calc$miss)
df3a.V.dprime_calc$faR <- df3a.V.dprime_calc$FA/(df3a.V.dprime_calc$FA + df3a.V.dprime_calc$CR)

# use the standardized way to deal with the extreme values
for (i in 1:nrow(df3a.V.dprime_calc)){
  if (df3a.V.dprime_calc$hitR[i] == 1){
    df3a.V.dprime_calc$hitR[i] <- 1 - 1/(2*(df3a.V.dprime_calc$hit[i] + df3a.V.dprime_calc$miss[i]))
  }
}

for (i in 1:nrow(df3a.V.dprime_calc)){
  if (df3a.V.dprime_calc$faR[i] == 0){
    df3a.V.dprime_calc$faR[i] <- 1/(2*(df3a.V.dprime_calc$FA[i] + df3a.V.dprime_calc$CR[i]))
  }
}

# calculate the d prime for each condition
df3a.V.dprime_calc$dprime <- mapply(dprime,df3a.V.dprime_calc$hitR,df3a.V.dprime_calc$faR)

# change dprime data from long format to wide
df3a.V.dprime_w <- dcast(df3a.V.dprime_calc, Subject + Age + Sex ~ Identity + Morality ,value.var = "dprime")
df3a.V.dprime_l     <- df3a.V.dprime_calc[,c("Subject", "Age","Sex","Morality",'Identity',"dprime")]
#df3a.V.dprime_w <- df3a.V.dprime_ww

####### calculate the number of each for each condition ########
# this is the same procedure to calculate the d prime, only consider the moral valence 
df3a.V.d_moral_calc <-  ddply(df3a.V,.(Subject,Age, Sex,Morality,sdt), summarise, N = length(sdt))

# long format to wide
df3a.V.d_moral_calc <- dcast(df3a.V.d_moral_calc, Subject + Age + Sex + Morality ~ sdt,value.var = "N")
df3a.V.d_moral_calc$miss[is.na(df3a.V.d_moral_calc$miss)] <- 0
df3a.V.d_moral_calc$FA[is.na(df3a.V.d_moral_calc$FA)] <- 0
df3a.V.d_moral_calc$hitR <- df3a.V.d_moral_calc$hit/(df3a.V.d_moral_calc$hit + df3a.V.d_moral_calc$miss)
df3a.V.d_moral_calc$faR <- df3a.V.d_moral_calc$FA/(df3a.V.d_moral_calc$FA + df3a.V.d_moral_calc$CR)

# standardized way to deal with the extreme values
for (i in 1:nrow(df3a.V.d_moral_calc)){
  if (df3a.V.d_moral_calc$hitR[i] == 1){
    df3a.V.d_moral_calc$hitR[i] <- 1 - 1/(2*(df3a.V.d_moral_calc$hit[i] + df3a.V.d_moral_calc$miss[i]))
  }
}

for (i in 1:nrow(df3a.V.d_moral_calc)){
  if (df3a.V.d_moral_calc$faR[i] == 0){
    df3a.V.d_moral_calc$faR[i] <- 1/(2*(df3a.V.d_moral_calc$FA[i] + df3a.V.d_moral_calc$CR[i]))
  }
}

# calculate the d prime for each condition
df3a.V.d_moral_calc$dprime <- mapply(dprime,df3a.V.d_moral_calc$hitR,df3a.V.d_moral_calc$faR)
df3a.V.d_moral_w <- dcast(df3a.V.d_moral_calc, Subject + Age + Sex ~ Morality ,value.var = "dprime")
df3a.V.d_moral_l     <- df3a.V.d_moral_calc[,c("Subject", "Age","Sex","Morality","dprime")]

##################

# rename the column number
colnames(df3a.V.dprime_w)[4:9] <- paste("d", colnames(df3a.V.dprime_w[,4:9]), sep = "_")
colnames(df3a.V.d_moral_w)[4:6] <- paste("d", colnames(df3a.V.d_moral_w[,4:6]), sep = "_")

## RT ####
df3a.V.RT <- df3a.V[df3a.V$ACC ==1,]  # exclued inaccurate data
df3a.V.RT.subj <- summarySEwithin(df3a.V.RT,measurevar = 'RT', withinvar = c('Subject','Matchness','Morality','Identity'),idvar = 'Subject', na.rm = TRUE)
df3a.V.RT.subj_moral <- summarySEwithin(df3a.V.RT,measurevar = 'RT', withinvar = c('Subject','Matchness','Morality'),idvar = 'Subject', na.rm = TRUE)

# long to wide
df3a.V.RT.subj_w <- dcast(df3a.V.RT.subj, Subject ~ Matchness + Identity + Morality ,value.var = "RT") 
df3a.V.RT.subj_moral_w <- dcast(df3a.V.RT.subj_moral, Subject ~ Matchness + Morality ,value.var = "RT") 

# rename the columns of RT data
colnames(df3a.V.RT.subj_w)[2:13] <- paste("RT", colnames(df3a.V.RT.subj_w[,2:13]), sep = "_")
colnames(df3a.V.RT.subj_moral_w)[2:7] <- paste("RT", colnames(df3a.V.RT.subj_moral_w[,2:7]), sep = "_")

# merge files####
# the dprime and RT data and save
df3a.V.sum_w <- merge(df3a.acc_w,df3a.V.dprime_w,by = "Subject")
df3a.V.sum_w <- merge(df3a.V.sum_w,df3a.V.RT.subj_w,by = 'Subject')
df3a.V.sum_moral_w <- merge(df3a.acc_moral_w,df3a.V.d_moral_w,by = "Subject")
df3a.V.sum_moral_w <- merge(df3a.V.sum_moral_w,df3a.V.RT.subj_moral_w,by = 'Subject')
# order the columns
df3a.V.sum_w <- df3a.V.sum_w[,c(colnames(df3a.V.sum_w)[c(1,14,15)],colnames(df3a.V.sum_w)[c(2:13,16:33)])]
df3a.V.sum_moral_w <- df3a.V.sum_moral_w[,c(colnames(df3a.V.sum_moral_w)[c(1,8:9)],colnames(df3a.V.sum_moral_w)[c(2:7,10:18)])]

# save the long-format data
df3a.v.sum_rt_acc_l <- merge(df3a.acc,df3a.V.RT.subj,by = c("Subject","Matchness","Morality",'Identity'))
df3a.v.sum_rt_acc_l <- df3a.v.sum_rt_acc_l[order(df3a.v.sum_rt_acc_l$Subject),]
df3a.v.sum_rt_acc_l <- df3a.v.sum_rt_acc_l[,c("Subject","Matchness","Morality",'Identity',"N.x","countN","ACC","RT")]
colnames(df3a.v.sum_rt_acc_l) <- c("Subject","Matchness","Morality",'Identity',"Ntrials","corrtrials","ACC","RT")

df3a.v.sum_rt_acc_moral_l <- merge(df3a.acc_moral,df3a.V.RT.subj_moral,by = c("Subject","Matchness","Morality"))
df3a.v.sum_rt_acc_moral_l <- df3a.v.sum_rt_acc_moral_l[order(df3a.v.sum_rt_acc_moral_l$Subject),]
df3a.v.sum_rt_acc_moral_l <- df3a.v.sum_rt_acc_moral_l[,c("Subject","Matchness","Morality","N.x","countN","ACC","RT")]
colnames(df3a.v.sum_rt_acc_moral_l) <- c("Subject","Matchness","Morality","Ntrials","corrtrials","ACC","RT")

## write files ####
setwd(resDir)
write.csv(df3a.V.sum_w,'exp3_behav_wide.csv',row.names = F)
write.csv(df3a.v.sum_rt_acc_l,'exp3_rt_acc_long.csv',row.names = F)
write.csv(df3a.V.dprime_l,'exp3_dprime_long.csv',row.names = F)

write.csv(df3a.V.sum_moral_w,'exp3_behav_moral_wide.csv',row.names = F)
write.csv(df3a.v.sum_rt_acc_moral_l,'exp3_rt_acc_moral_long.csv',row.names = F)
write.csv(df3a.V.d_moral_l,'exp3_dprime_moral_long.csv',row.names = F)
setwd(curDir)
## plot ####
Mplots(saveDir = resDir, curDir = curDir, expName = 'exp3a', df3a.V.dprime_l,df3a.v.sum_rt_acc_l[df3a.v.sum_rt_acc_l$Matchness == 'Match',])
