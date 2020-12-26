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
       
          if train_StoreDS.Labels(i) == 'Crack'
               Ysim(i,:) = [1 0 0 0 0];
           elseif train_StoreDS.Labels(i) == 'Instability'
               Ysim(i,:) = [0 1 0 0 0];
           elseif train_StoreDS.Labels(i) == 'Misalignment'
               Ysim(i,:) = [0 0 1 0 0];
           elseif train_StoreDS.Labels(i) == 'Rub'
               Ysim(i,:) = [0 0 0 1 0];
           else
               Ysim(i,:) = [0 0 0 0 1];
           end
    end
    %Stacked Autoencoders
    
    hiddenSize1 = 120;
    timer1=tic;
    autoenc1 = trainAutoencoder(Xsim,hiddenSize1, ...
    'MaxEpochs',100, ...
    'L2WeightRegularization',0.002, ...
    'SparsityRegularization',0.001, ...
    'SparsityProportion',0.015, ...
    'ScaleData', false);
    feat1 = encode(autoenc1,Xsim);
    
%     hiddenSize2 = 25;
%     autoenc2 = trainAutoencoder(feat1,hiddenSize2, ...
%     'MaxEpochs',100, ...
%     'L2WeightRegularization',0.002, ...
%     'SparsityRegularization',4, ...
%     'SparsityProportion',0.1, ...
%     'ScaleData', false);
%     feat2 = encode(autoenc2,feat1);
    softnet = trainSoftmaxLayer(feat1,Ysim','MaxEpochs',400);
    stackednet = stack(autoenc1,softnet);
    %view(stackednet)
    
    % Turn the training images into vectors and put them in a matrix
    xTrain = zeros(900,numel(Xsim));
    for i = 1:numel(Xsim)
        xTrain(:,i) = Xsim{i}(:);
    end

    % Perform fine tuning
    
    stackednet = train(stackednet,xTrain,Ysim');
    timetrain(ii)=toc(timer1);
    
    
    

%     template = templateSVM('KernelFunction', 'gaussian');
%     svm = fitcecoc(features,Ysim,'Learners', template);
    
    
    %% Test the Network Using Training Data
    Xtest=[];
    Ytest=[];
    [nrowtest ncol] = size(test_StoreDS.Files);
    for i=1:nrowtest
       matrix2_i = load(test_StoreDS.Files{i});
       Xtest(:,i) = matrix2_i.matrix(:);
       if test_StoreDS.Labels(i) == 'Crack'
           Ytest(i,:) = [1 0 0 0 0];
       elseif test_StoreDS.Labels(i) == 'Instability'
           Ytest(i,:) = [0 1 0 0 0];
       elseif test_StoreDS.Labels(i) == 'Misalignment'
           Ytest(i,:) = [0 0 1 0 0];
       elseif test_StoreDS.Labels(i) == 'Rub'
           Ytest(i,:) = [0 0 0 1 0];
       else
           Ytest(i,:) = [0 0 0 0 1];
       end
    end
    Ytest = Ytest';

    
    %% Test Exp the Network Using Training Data
    Xexp=[];
    Yexp=[];
    [nrowexp ncol] = size(validationDS.Files);
    for i=1:nrowexp
       matrix3_i = load(validationDS.Files{i});
       Xexp(:,i) = matrix3_i.matrix(:);
       if validationDS.Labels(i) == 'Crack'
           Yexp(i,:) = [1 0 0 0 0];
       elseif validationDS.Labels(i) == 'Instability'
           Yexp(i,:) = [0 1 0 0 0];
       elseif validationDS.Labels(i) == 'Misalignment'
           Yexp(i,:) = [0 0 1 0 0];
       elseif validationDS.Labels(i) == 'Rub'
           Yexp(i,:) = [0 0 0 1 0];
       else
           Yexp(i,:) = [0 0 0 0 1];
       end
    end
    Yexp = Yexp';

    

    
%% Classify the Images in the Test Data and Compute Accuracy
timer2=tic;
YYtest = categorical(vec2ind(stackednet(Xtest)));
timetest(ii)=toc(timer2);
TYtest = categorical(vec2ind(Ytest));

YYexp = categorical(vec2ind(stackednet(Xexp))); 
TYexp = categorical(vec2ind(Yexp));

%% 
% Calculate the accuracy. 
acctrain(ii)= sum(YYtest == TYtest)/length(TYtest)

acctest(ii)= sum(YYexp == TYexp)/length(TYexp)

%%
% Build confusion matrix with experiment

Outputsim = vertcat(Outputsim,YYtest');
Targetsim = vertcat(Targetsim,TYtest');

Outputexp = vertcat(Outputexp,YYexp');
Targetexp = vertcat(Targetexp,TYexp');

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
