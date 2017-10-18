library(readr)  # provide additional data-reading functions
library(corrplot) # attractive correlation graphs
library(MASS)  # Package MASS includes the LDA function
library(ggplot2)
library(lattice)
library(e1071)  # for SVM model
library(nnet)   # for basic neural network model
library(party)
library(zoo)

white <- read_delim("Data/winequality-white.csv",",") 

n <- nrow(white)
set.seed(12)
test_idx <- sample.int(n, size= round(0.2 * n))  # 20% test set
train <- white[-test_idx,]  # train has all rows except the index 
testset <- white[test_idx,]


corrtrain <- cor(train, method = "pearson")
corrplot(corrtrain,method = "ellipse",type = "lower")


train$quality <- factor(train$quality)
testset$quality <- factor(testset$quality)


form3 <- as.formula(quality ~ `fixed acidity` + `volatile acidity`+chlorides+`free sulfur dioxide`+density+pH+alcohol)
multinomial3 <- multinom(form3,  data=train)

z3 <- summary(multinomial3)$coefficients/summary(multinomial3)$standard.errors
p3 <- (1 - pnorm(abs(z3), 0, 1)) * 2
p3


# Decision Tree model training
datactree <- ctree(form1, train, controls=ctree_control(mincriterion=0.9, minsplit=50))


## multinomial logit model 
# train set prediction
predict1 <- predict(multinomial3, data = train)
tab1 <- table(predict1, train$quality)
print(tab1)
# Confusion Matrix
1-sum(diag(tab1))/sum(tab1)  

# test set prediction
predict2 <- predict(multinomial3,testset)
tab1a <- table(predict2, testset$quality)
print(tab1a)
1-sum(diag(tab1a))/sum(tab1a)  

#neural network

mod_nn <- nnet(form3, data = train, size = 15)

##train set prediction
pred_nn <- predict(mod_nn, data=train, type = "class")  
table(pred_nn)
tab2 <- table(pred_nn, train$quality)
print(tab2)
#misclassification rate
1-sum(diag(tab2))/sum(tab2)  


##test set prediction
pred_nn1 <- predict(mod_nn,testset, type = "class")  
table(pred_nn1)
tab2a <- table(pred_nn1, testset$quality)
print(tab2a)
#misclassification rate
1-sum(tab2a[1,2], tab2a[2,3], tab2a[3,4], tab2a[4,5])/sum(tab2a)


##SVM

svm1 <- svm(form3, data=train)

##train set prediction
pred_svm <- predict(svm1,train)
table(pred_svm)
tab3 <- table(pred_svm, train$quality)
print(tab3)
#misclassification rate
1-sum(diag(tab3))/sum(tab3)  

##test set prediction
pred_svm1 <- predict(svm1,testset)
table(pred_svm1)
tab3a <- table(pred_svm1, testset$quality)
print(tab3a)
#misclassification rate
1-sum(diag(tab3a))/sum(tab3a)  


# Linear Discriminant Analysis

fit <- lda(form3, data=train,
           na.action="na.omit") 

##train set prediction
pred_lda <- predict(fit, train)$class  # use lda model to predict using orig data
table(pred_lda)  # tabulate the predictions
tab4 <- table(pred_lda, train$quality)
print(tab4)
#misclassification rate
1-sum(diag(tab4))/sum(tab4)

##test set prediction
pred_lda1 <- predict(fit, testset)$class  # use lda model to predict using orig data
table(pred_lda1)  # tabulate the predictions
tab4a <- table(pred_lda1, testset$quality)
print(tab4a)
#misclassification rate
1-sum(diag(tab4a))/sum(tab4a)


# CART model

tree <- ctree(form3, train, 
              controls=ctree_control(mincriterion=0.90, minsplit=10))

##train set prediction
pred_tree <- predict(tree, train)
table(pred_tree)
tab5 <- table(pred_tree, train$quality)
print(tab5)
#misclassification rate
1-sum(diag(tab5))/sum(tab5)

##test set prediction
pred_tree1 <- predict(tree, testset)
table(pred_tree1)
tab5a <- table(pred_tree1, testset$quality)
print(tab5a)
#misclassification rate
1-sum(diag(tab5a))/sum(tab5a)

##Summary of misclassification rate of 5 models

misclassification.rate <- read.csv("~/BUS211/Data/misclassification rate.csv")
misclassification.rate


##predict 10 samples using SVM model

new_white <- read_csv("Data/new_white.csv")
pred_svm_white <- predict(svm1,new_white)
table(pred_svm_white)
