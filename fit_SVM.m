function [ train_pred, test_pred  ] = ...
    fit_SVM(train_data,train_target,test_data,test_target)

% train the SVM using LIBSVM
mdl = svmtrain(train_target, train_data, '-b 1');
[train_pred, tr_acc, tr_prob] = svmpredict(train_target, train_data, mdl, '-b 1');
[test_pred, v_acc, t_prob] = svmpredict(test_target, test_data, mdl, '-b 1');

if sum(round(t_prob(:,1)))==sum(test_pred)
    train_pred=tr_prob(:,1);
    test_pred=t_prob(:,1);
else
    train_pred=tr_prob(:,2);
    test_pred=t_prob(:,2);
end

end
  
    

    

            






