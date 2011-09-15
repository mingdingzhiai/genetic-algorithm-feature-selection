%% INITIALISE

% Clear - clean plots
% clear
% close all

% Load data
% Call you data file here.
% It should contain:
%     - data: a NxP matrix where N is the number of samples and P the number of variables
%     - labels : struct 1xP strings with variables names
%     - outcome :1xN bool giving the outcome [-1..1]
% loaddata;



%% RUN GA
% try

% Clean data : Whatever pre-processes.
% Do NOT normalized your variables here, as data hasn't been split
% into train/test/valid yet.
%   [data labels xxxxx]  = clean_data(data,labels,....outcome,1) ;

%     % Open Results file
%     fid = fopen(['AlgoGen_results.csv'],'w');
%     % Print Headers file
%     fprintf(fid,'RMSE test\t RMSE train \t ITE \t');
Nbre_var = size(data,2);
%     for v=1:Nbre_var
%         fprintf(fid,[labels{v} '\t']);
%     end
%     fprintf(fid,'\n');
opts=ga_opt_set('Parallelize',0,'CostFcn',@cost_AUROC,...
    'OptDir',1,'ErrorIterations',30,'ErrorGradient',0.005,'PopulationSize', 48,...
    'Repetitions', 1,'MaxIterations',100,'Display','none');


% Load matlabpool
% If you want to use parallel threats
if ~isempty(opts.Parallelize) && opts.Parallelize==1 && matlabpool('size')<=0
    matlabpool;
end
tic;
% ALGO GEN
%try
    [ga_out, ga_options] =  AlgoGen(data,outcome,opts);
%catch me
    if ~isempty(opts.Parallelize) && opts.Parallelize==1 && matlabpool('size')>0
        matlabpool close;
    end
  %  rethrow(me)
    
%end
toc;


% save ('ga_30rep.mat','ga_out','ga_options');
%
% fclose(fid)
% if matlabpool('size')>0
% matlabpool close;
% end
%
%

