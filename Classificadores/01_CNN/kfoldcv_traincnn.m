clear all
close all
clc
%% Load and Explore the Image Data
% Load the digit sample data as an |ImageDatastore| object.
mypath=pwd;
mypathsplit=strsplit(mypath,filesep);
myfolder =mypathsplit{1,end};
mysubpath=mypath(1:end-length(myfolder));
digitDatasetPath = fullfile(mysubpath,'00_DATA\Data')
%digitDatasetPath = fullfile('C:\Users\Clayton\Documents\Mestrado_ITA\Dissertacao\2Modelagem Matlab\01_CNN\Data');
digitData = imageDatastore(digitDatasetPath, ...
        'FileExtensions', '.mat','IncludeSubfolders',true,'LabelSource','foldernames');

% Check the number of images in each category. 
CountLabel = digitData.countEachLabel

%% Specify Training and Test Sets

digitDataDS = digitData;
digitDataDS.Labels = categorical(digitData.Labels);
digitDataDS.ReadFcn = @readFcn1;

digitDatasetPathexp=fullfile(mysubpath,'00_DATA\Dataexp')
%digitDatasetPathexp = fullfile('C:\Users\Clayton\Documents\Mestrado_ITA\Dissertacao\2Modelagem Matlab\01_CNN\Dataexp');
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
dropoutProb = 0.5;
numF = 32;
layers = [
    imageInputLayer([30 30 1])
    
    convolution2dLayer(3,numF,'Padding',[0 0 0 0])
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer(2,'Stride',2,'Padding',[0 0 0 0])

    convolution2dLayer(4,2*numF-8,'Padding',[0 0 0 0])
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer(3,'Stride',1,'Padding',[0 0 0 0])

    
    dropoutLayer(dropoutProb)
    fullyConnectedLayer(numClasses)
    softmaxLayer
    classificationLayer];

 % analyzeNetwork(layers)

%% Specify the Training Options
options = trainingOptions('sgdm', ...
    'ExecutionEnvironment','cpu',...
    'MaxEpochs',25, ...
    'Shuffle','every-epoch', ...
    'ValidationFrequency',10, ...
    'Verbose',false, ...
    'ValidationData',validationDS, ... %'Plots','training-progress',...
    'L2Regularization',0.12,...
    'MiniBatchSize',128, ...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropFactor',0.2, ...
    'LearnRateDropPeriod',10);

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

for i = 1:k
    test_idx = (idx == i);
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
% Train the network you defined in layers, using the training data and the
% training options you defined in the previous steps.
time1 = tic;
convnet = trainNetwork(train_StoreDS,layers,options);
timetrain(i) = toc(time1);


%% Classify the Images in the Test Data and Compute Accuracy
time2 = tic;
YYsim = classify(convnet,test_StoreDS);
timetest(i) = toc(time2);
Tsim = test_StoreDS.Labels;

YTest = classify(convnet,validationDS);
TTest = validationDS.Labels;

%% 
% Calculate the accuracy. 
acctrain(i)= sum(YYsim == Tsim)/numel(Tsim)


acctest(i)= sum(YTest == TTest)/numel(TTest)


%%
% Build confusion matrix with experiment

Outputsim = vertcat(Outputsim,YYsim);
Targetsim = vertcat(Targetsim,Tsim);

plotconfusion(TTest,YTest)

Outputexp = vertcat(Outputexp,YTest);
Targetexp = vertcat(Targetexp,TTest);

end
figure(1)
plotconfusion(Targetsim,Outputsim)

figure(2)
plotconfusion(Targetexp,Outputexp)

acctrain_m = mean(acctrain)
acctrain_s = std(acctrain)
acctest_m = mean(acctest)
acctest_s = std(acctest)