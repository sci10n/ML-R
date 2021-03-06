library(tree)
library(boot)
library(ggplot2)

set.seed(12345)
data = read.csv2("State.csv", header = TRUE)
data = data[order(data$MET),]

control = tree.control(nrow(data), minsize=8)
fit = tree(EX~MET, data, control=control)
fit.cv = cv.tree(fit)
best_k = fit.cv$size[which.min(fit.cv$dev)]
optimal_tree = prune.tree(fit, best=best_k)

predictions = predict(optimal_tree, newdata=data)

fig_data = data.frame(x = data$MET, pred = predictions, orig = data$EX)
fig = ggplot(fig_data, aes(x, pred, orig) , xlab = "Metropolitan" , ylab = "Expendature")
fig = fig + geom_point(aes(x,orig), colour = "#FF1111") + geom_point(aes(x, pred))
print(fig)

hist(residuals(optimal_tree))

 set.seed(12345)
 nonparama = function(data,index) {
     sample = data[index,]
     control = tree.control(nrow(sample), minsize = 8)
     fit = tree( EX ~ MET, data=sample, control = control)
     optimal_tree = prune.tree(fit, best=best_k)
     return(predict(optimal_tree, newdata=data))
 }

 nonparam_boot = boot(data, statistic = nonparama, R=1000)
 confidence_bound = envelope(nonparam_boot,level=0.95)
 predictions = predict(optimal_tree,data)


plot(nonparam_boot)

fig_data = data.frame(orig = data$EX, x=data$MET, pred=predictions, upper=confidence_bound$point[1,], lower=confidence_bound$point[2,])
fig = ggplot(fig_data, aes(x,predictions,upper,lower), xlab = "Metropolitan" , ylab = "Predicted Expendature")
fig = fig +
    geom_point(aes(x, pred)) + 
    geom_point(aes(x, orig),colour="#CC1111") + 
    geom_line(aes(x,upper)) +
    geom_line(aes(x,lower)) +
    geom_ribbon(aes(x = x, ymin=lower, ymax=upper), alpha=0.05)
print(fig)

set.seed(12345)
parama_conf = function(data){
  control = tree.control(nrow(data), minsize = 8)
  fit = tree( EX ~ MET, data=data, control = control)
  optimal_tree = prune.tree(fit, best=best_k) 
  return(predict(optimal_tree, newdata=data))
}

parama_predic = function(data){
  control = tree.control(nrow(data), minsize = 8)
  fit = tree( EX ~ MET, data=data, control = control)
  optimal_tree = prune.tree(fit, best=best_k) 
  predictions = predict(optimal_tree, newdata=data)
  return(rnorm(nrow(data),predictions,sd(resid(fit))))
}

random_samples = function(data, model){
  sample = data.frame(MET=data$MET, EX=data$EX)
  sample$EX = rnorm(nrow(data), predict(model,newdata=data),sd(resid(model)))
  return(sample)
}

param_boot_conf = boot(data, statistic = parama_conf, R=1000, mle = optimal_tree, ran.gen = random_samples, sim = "parametric")
confidence_bound_param = envelope(param_boot_conf, level=0.95)
param_boot_pred = boot(data, statistic = parama_predic, R=1000, mle = optimal_tree, ran.gen = random_samples, sim = "parametric")
prediction_bound_param = envelope(param_boot_pred, level=0.95)

predictions = predict(optimal_tree,data)
fig_data = data.frame(orig = data$EX, x=data$MET, pred=predictions, upper_c=confidence_bound_param$point[1,], lower_c=confidence_bound_param$point[2,], upper_p=prediction_bound_param$point[1,], lower_p=prediction_bound_param$point[2,])

  fig = ggplot(fig_data, aes(orig,x,pred,upper_c,lower_c, upper_p, lower_p), xlab = "Metropolitan" , ylab = "Predicted Expendature")
  fig = fig +
    geom_point(aes(x, pred)) + 
    geom_point(aes(x, orig),colour="#CC1111") + 
    geom_line(aes(x,upper_c)) +
    geom_line(aes(x,lower_c)) +
    geom_ribbon(aes(x = x, ymin=lower_c, ymax=upper_c), alpha=0.05, colour = "#110011")+
    geom_line(aes(x,upper_p)) +
    geom_line(aes(x,lower_p))+
    geom_ribbon(aes(x = x, ymin=lower_p, ymax=upper_p), alpha=0.05)
    
  print(fig)
 
