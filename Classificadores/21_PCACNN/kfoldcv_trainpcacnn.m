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

%%
% |splitEachLabel| splits the image files in |digitData| into two new datastores,
% |trainDigitData| and |testDigitData|.  

%% Define the Network Layers
% Define the convolutional neural network architecture. 
numClasses = 5;
dropoutProb = 0.4;
numF = 24;
layers = [
    imageInputLayer([1 19 1])

    convolution2dLayer([1 2],numF,'Padding',[0 0 0 0])
    batchNormalizationLayer
    reluLayer
    
    
    convolution2dLayer([1 2],1*numF,'Padding',[0 0 0 0])
    batchNormalizationLayer
    reluLayer
    
    
    
    dropoutLayer(dropoutProb)
    fullyConnectedLayer(numClasses)
    softmaxLayer
    classificationLayer];


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
       Xsim(i,:) = matrix_i.matrix(:)';
       Ysim(i)= categorical(train_StoreDS.Labels(i));
    end

    %PCA
    numComponentsToKeep = 19;
    timer1 = tic;
    [pcaCoefficients, pcaScores, ~, ~, explained, pcaCenters] = pca(...
    Xsim, 'NumComponents', numComponentsToKeep);
    XpcaScores = reshape(pcaScores', [1,size(pcaScores',1),1,size(pcaScores',2)]);
    timepcatrain = toc(timer1);

    %% Test the Network Using Training Data
    Xtest=[];
    [nrowtest ncol] = size(test_StoreDS.Files);
    for i=1:nrowtest
       matrix2_i = load(test_StoreDS.Files{i});
       Xtest(i,:) = matrix2_i.matrix(:)';
       Ytest(i) = test_StoreDS.Labels(i);
    end
    %PCA converting
    timer2 = tic;
    pcaXtest = (Xtest - pcaCenters) * pcaCoefficients;
    XpcaXtest = reshape(pcaXtest', [1,size(pcaXtest',1),1,size(pcaXtest',2)]);
    timepcatest = toc(timer2)
    
    %% Test Exp the Network Using Training Data
    [nrowexp ncol] = size(validationDS.Files);
    for i=1:nrowexp
       matrix3_i = load(validationDS.Files{i});
       Xexp(i,:) = matrix3_i.matrix(:)';
       Yexp(i)= validationDS.Labels(i);
    end
    % PCA converting
    pcaXexp = (Xexp - pcaCenters) * pcaCoefficients;
    XpcaXexp = reshape(pcaXexp', [1,size(pcaXexp',1),1,size(pcaXexp',2)]);
    
    %% Specify the Training Options
    options = trainingOptions('sgdm', ...
    'ExecutionEnvironment','cpu',...
    'MaxEpochs',25, ...
    'Shuffle','every-epoch', ...
    'ValidationFrequency',10, ...
    'Verbose',false, ...
    'ValidationData',{XpcaXexp,validationDS.Labels}, ...
    'L2Regularization',0.12,...
    'MiniBatchSize',128, ...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropFactor',0.2, ...
    'LearnRateDropPeriod',10);
%% Train the Network Using Training Data
% Train the network you defined in layers, using the training data and the
% training options you defined in the previous steps.

timer3 = tic;
convnet = trainNetwork(XpcaScores,train_StoreDS.Labels,layers,options);
timetrain(ii)= toc(timer3)+timepcatrain;


%% Classify the Images in the Test Data and Compute Accuracy
timer4 = tic;
YYsim = classify(convnet,XpcaXtest);
timetest(ii)=  toc(timer4)+timepcatest;
Tsim = Ytest;

YTest = classify(convnet,XpcaXexp);
TTest = Yexp;

%% 
% Calculate the accuracy. 
acctrain(ii)= sum(YYsim == Tsim')/length(Tsim)

acctest(ii)= sum(YTest == TTest')/length(TTest)


%%
% Build confusion matrix with experiment

Outputsim = vertcat(Outputsim,YYsim);
Targetsim = vertcat(Targetsim,Tsim');

plotconfusion(TTest,YTest')

Outputexp = vertcat(Outputexp,YTest);
Targetexp = vertcat(Targetexp,TTest');

end
figure(1)
plotconfusion(Targetsim,Outputsim)

figure(2)
plotconfusion(Targetexp,Outputexp)

acctrain_m = mean(acctrain)
acctrain_s = std(acctrain)
acctest_m = mean(acctest)
acctest_s = std(acctest)

timetrain_m = mean(timetrain(2:end))
stdtimetrain_s = std(timetrain(2:end))
timetest_m = mean(timetest(2:end))
stdtimetest_s = std(timetest(2:end))