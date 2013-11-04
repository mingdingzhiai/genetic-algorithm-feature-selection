function [ SCORE_test, SCORE_train, miscOutputContent ] = ...
    evaluate_par(OriginalData , data_target, parents, options, train, test, KI)

fitFcn=options.FitnessFcn;
fitOpt=options.FitnessParam;
costFcn=options.CostFcn;
optDir = options.OptDir;
normalizeDataFlag = options.NormalizeData;

% Pre-allocate
P=size(parents,1);
SCORE_test=zeros(P,1);
SCORE_train=zeros(P,1);

% Output parameters
TestStats = cell(P,1);
TrainStats = cell(P,1);
TrainIndex = false(size(train,1),P);
TestIndex = false(size(test,1),P);

if mdlStorage==1
    model = cell(P,1);
end


if isfield(fitOpt,'lbl')
    lbl = fitOpt.lbl;
else
    lbl = [];
end

%=== Default cost values to very sub-optimal
% If the algorithm does not assign a cost value (due to missing values or
% unselected features), the genome will be heavily penalized

%TODO: Figure out a better limits than 9999 and -9999
if optDir % Maximizing cost -> low default value
    defaultCost=-Inf;
else % Minimizing cost -> high default value
    defaultCost=Inf;
end

%=== the genomes at the end will be indexing hyperparameters
if ~isempty(options.Hyperparameters)
    hyper = parents(:,size(OriginalData,2)+1:end);
    parents = parents(:,1:size(OriginalData,2));
else
    hyper = false(size(parents,1),1);
end


% For each individual
parfor individual=1:P
    % If you want to remove multiples warnings
    warning off all
    tr_cost=ones(KI,1)*defaultCost;
    t_cost=ones(KI,1)*defaultCost;
    
    % Convert Gene into selected variables
    FS = parents(individual,:)==1;
    
    if ~isempty(options.Hyperparameters)
        fitOptCurr = parseHyperparameters(fitOpt,fitFcn,hyper(individual,:),options);
    else
        fitOptCurr = fitOpt;
    end
    
    curr_model = cell(1,KI);
    curr_train_stats = cell(1,KI);
    curr_test_stats = cell(1,KI);
    
    % If enough variables selected to regress
    if any(FS)
        
        %=== update fitOpt label - needed for PSO range calculation
        if ~isempty(lbl)
            fitOptCurr.lbl = lbl(FS);
        end
        
        DATA = OriginalData(:,FS);
        
        fprintf('Number in label: %d. Number of data cols: %d. ',numel(fitOptCurr.lbl),size(DATA,2));
        
        % Cross-validation repeat for each data partition
        for ki=1:KI
            train_target = data_target(train(:,ki));
            test_target = data_target(test(:,ki));
            
            if normalizeDataFlag
                [train_data, test_data] = ...
                    normalizeData(DATA(train(:,ki),:),DATA(test(:,ki),:));
            else
                train_data = DATA(train(:,ki),:);
                test_data = DATA(test(:,ki),:);
            end
            
            % Use fitness function to train model/get predictions
            [ train_pred, test_pred, curr_model{ki} ]  = feval(fitFcn,...
                train_data,train_target,test_data, fitOptCurr);
            
            curr_train_stats{ki} = stat_calc_struct(train_pred,train_target);
            curr_test_stats{ki} = stat_calc_struct(test_pred,test_target);
            
            [ tr_cost(ki) ] = callStatFcn(costFcn,...
                train_pred, train_target, curr_model{ki});
            [ t_cost(ki) ] = callStatFcn(costFcn,...
                test_pred, test_target, curr_model{ki});
        end
        
        % Check/perform minimal feature selection is desired
        [ tr_cost, t_cost ] = fs_opt( tr_cost, t_cost, FS, options );
    else
        % Do nothing - leave costs as they were preallocated
    end
    
    % ...get median results on TEST set
    SCORE_test(individual) =  nanmedian(t_cost);
    idxMedian = find(t_cost==SCORE_test(individual),1);
    
    % ...save corresponding result from training set
    SCORE_train(individual) =  tr_cost(idxMedian);
    
    if any(FS)
        % ... save misc details
        TestStats{individual} = curr_test_stats{idxMedian};
        TrainStats{individual} = curr_train_stats{idxMedian};
        TrainIndex(:,individual) = train(:,idxMedian);
        TestIndex(:,individual) = test(:,idxMedian);
        if mdlStorage==1
            model{individual} = curr_model{idxMedian};
        end
    end
end
miscOutputContent.TestStats = TestStats;
miscOutputContent.TrainStats = TrainStats;
miscOutputContent.TrainIndex = TrainIndex;
miscOutputContent.TestIndex = TestIndex;
if mdlStorage==1
    miscOutputContent.model = model;
end

end

