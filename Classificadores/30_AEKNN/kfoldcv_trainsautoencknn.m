clear all
close all
clc
%% Load and Explore the Image Data
% Load the digit sample data as an |ImageDatastore| object.
mypath=pwd;
mypathsplit=strsplit(mypath,filesep);
myfolder =mypathsplit{1,end};
mysubpath=mypath(1:end-length(myfolder));
digitDatasetPath = fullfile(mysubpath,'00_DATA\Data');
digitDatasetPathexp=fullfile(mysubpath,'00_DATA\Dataexp');

%digitDatasetPath = fullfile('C:\Users\Clayton\Documents\Mestrado_ITA\Dissertacao\2Modelagem Matlab\00_Data\Data');
digitData = imageDatastore(digitDatasetPath, ...
        'FileExtensions', '.mat','IncludeSubfolders',true,'LabelSource','foldernames');

% Check the number of images in each category. 
CountLabel = digitData.countEachLabel

%% Specify Training and Test Sets

digitDataDS = digitData;
digitDataDS.Labels = categorical(digitData.Labels);
digitDataDS.ReadFcn = @readFcn1;


%digitDatasetPathexp = fullfile('C:\Users\Clayton\Documents\Mestrado_ITA\Dissertacao\2Modelagem Matlab\00_DATA\Dataexp');
digitDataexp = imageDatastore(digitDatasetPathexp, ...
        'FileExtensions', '.mat','IncludeSubfolders',true,'LabelSource','foldernames');
CountLabelexp = digitDataexp.countEachLabel

validationDS = digitDataexp;
validationDS.Labels = categorical(validationDS.Labels);
validationDS.ReadFcn = @readFcn1;

%% Cross-validation
k = 10; % number of folds

% this will give us some randomization
% though it is still advisable to randomize the data before hand
idx = crossvalind('Kfold', digitDataDS.Labels, k);

partStores{1250} = [];
for i = 1:1250
   partStores{i} = {digitDataDS.Files{i}};
end

Outputsim = [];
Targetsim = [];
Outputexp = [];
Targetexp = [];

for ii = 1:k
    test_idx = (idx == ii);
    train_idx = ~test_idx;

    test_Store = imageDatastore(cat(1,partStores{test_idx}), ...
        'FileExtensions', '.mat','IncludeSubfolders',true,'LabelSource','foldernames');
    train_Store = imageDatastore(cat(1, partStores{train_idx}), ...
        'FileExtensions', '.mat','IncludeSubfolders',true,'LabelSource','foldernames');
    
    train_StoreDS = train_Store;
    train_StoreDS.Labels = categorical(train_StoreDS.Labels);
    train_StoreDS.ReadFcn = @readFcn1;

    test_StoreDS = test_Store;
    test_StoreDS.Labels = categorical(test_StoreDS.Labels);
    test_StoreDS.ReadFcn = @readFcn1;
    
    %% Train the Network Using Training Data
    Xsim=[];
    Ysim=[];
    [nrow ncol] = size(train_StoreDS.Files);
    for i=1:nrow
       matrix_i = load(train_StoreDS.Files{i});
       Xsim{1,i} = matrix_i.matrix;
       
       Ysim(i)= train_StoreDS.Labels(i);
    end
    %Stacked Autoencoders
    hiddenSize1 = 200; %200
    timer1=tic;
    autoenc1 = trainAutoencoder(Xsim,hiddenSize1, ...
    'EncoderTransferFunction', 'satlin',...
    'DecoderTransferFunction', 'logsig',...
    'MaxEpochs',400, ...
    'L2WeightRegularization',0.001, ...0.001
    'SparsityRegularization',1, ...%1
    'SparsityProportion',0.4, ...%0.05
    'ScaleData', false,...
    'UseGPU',false);
    
    XsimRec = predict(autoenc1,Xsim);
    mseError = mse(Xsim,XsimRec)
    
    feat1 = encode(autoenc1,Xsim);
    
%     hiddenSize2 = 40;
%     autoenc2 = trainAutoencoder(feat1,hiddenSize2, ...
%     'MaxEpochs',400, ...
%     'L2WeightRegularization',0.002, ...
%     'SparsityRegularization',1, ...
%     'SparsityProportion',0.4, ...
%     'ScaleData', false);
%     feat2 = encode(autoenc2,feat1);
%     softnet = trainSoftmaxLayer(feat2,Ysim','MaxEpochs',400);
%     stackednet = stack(autoenc1,autoenc2,softnet);
    %view(stackednet)
    
    % Turn the training images into vectors and put them in a matrix
%     xTrain = zeros(900,numel(Xsim));
%     for i = 1:numel(Xsim)
%         xTrain(:,i) = Xsim{i}(:);
%     end

    % Perform fine tuning
%     stackednet = train(stackednet,xTrain,Ysim');

%     classificationKNN = fitcknn(...
%     feat1', ...
%     Ysim','OptimizeHyperparameters','auto',...
%     'HyperparameterOptimizationOptions',...
%     struct('AcquisitionFunctionName','expected-improvement-plus'));

      classificationKNN = fitcknn(...
        feat1', ...
        Ysim',...
        'Distance', 'euclidean', ...
        'Exponent', [], ...
        'NumNeighbors', 1, ...
        'DistanceWeight', 'Equal', ...
        'Standardize', true, ...
        'ClassNames', [1; 2; 3; 4; 5]);
    timetrain(ii)=toc(timer1)

    
    %% Test the Network Using Training Data
    Xtest=[];
    Ytest=[];
    [nrowtest ncol] = size(test_StoreDS.Files);
    for i=1:nrowtest
       matrix2_i = load(test_StoreDS.Files{i});
       Xtest{1,i}= matrix2_i.matrix;
       Ytest(i)= test_StoreDS.Labels(i);
    end
    Ytest = Ytest';
    aeXtest = encode(autoenc1,Xtest);

    
    %% Test Exp the Network Using Training Data
    Xexp=[];
    Yexp=[];
    [nrowexp ncol] = size(validationDS.Files);
    for i=1:nrowexp
       matrix3_i = load(validationDS.Files{i});
       Xexp{1,i} = matrix3_i.matrix;
       Yexp(i)= validationDS.Labels(i);
    end
    Yexp = Yexp';
    aeXexp = encode(autoenc1,Xexp);

%% Classify the Images in the Test Data and Compute Accuracy
timer2=tic;
YYtest = categorical(predict(classificationKNN,aeXtest'));
timetest(ii)=toc(timer2);
TYtest = categorical(Ytest);

YYexp = categorical(predict(classificationKNN,aeXexp')); 
TYexp = categorical(Yexp);

%% 
% Calculate the accuracy. 
acctrain(ii)= sum(YYtest == TYtest)/length(TYtest)

acctest(ii)= sum(YYexp == TYexp)/length(TYexp)

%%
% Build confusion matrix with experiment

Outputsim = vertcat(Outputsim,YYtest);
Targetsim = vertcat(Targetsim,TYtest);

Outputexp = vertcat(Outputexp,YYexp);
Targetexp = vertcat(Targetexp,TYexp);

plotconfusion(TYexp,YYexp)

end
figure(1)
plotconfusion(categorical(Targetsim),categorical(Outputsim))

figure(2)
plotconfusion(categorical(Targetexp),categorical(Outputexp))

acctrain_m = mean(acctrain)
acctrain_s = std(acctrain)
acctest_m = mean(acctest)
acctest_s = std(acctest)

timetrain_m = mean(timetrain(2:end))
stdtimetrain_s = std(timetrain(2:end))
timetest_m = mean(timetest(2:end))
stdtimetest_s = std(timetest(2:end))

