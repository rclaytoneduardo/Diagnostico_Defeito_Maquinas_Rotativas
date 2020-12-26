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

%digitDatasetPath = fullfile('C:\Users\Clayton\Documents\Mestrado_ITA\Dissertacao\2Modelagem Matlab\00_DATA\Data');
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



Outputtest = [];
Targettest = [];
Outputexp = [];
Targetexp = [];


for j = 1:k
    Xsim = [];
    Ysim = [];
    Xtest = [];
    Ytest = [];
    Xexp = [];
    Yexp = [];
    test_idx = (idx == j);
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

[nrow ncol] = size(train_StoreDS.Files);
for i=1:nrow
   matrix_i = load(train_StoreDS.Files{i});
   Xsim(i,:) = matrix_i.matrix(:)';
      
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
Xsim = Xsim';
Ysim = Ysim';


net = lvqnet(15)
net.trainParam.epochs = 30;
timer1=tic;
net = train(net,Xsim,Ysim);
timetrain(j)=toc(timer1)




[nrow ncol] = size(test_StoreDS.Files);
for i=1:nrow
   matrix2_i = load(test_StoreDS.Files{i});
   Xtest(i,:) = matrix2_i.matrix(:)';
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
Xtest = Xtest';
Ytest = Ytest';

[nrow ncol] = size(validationDS.Files);
for i=1:nrow
   matrix2_i = load(validationDS.Files{i});
   Xexp(i,:) = matrix2_i.matrix(:)';
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
Xexp = Xexp';
Yexp = Yexp';


%% Classify the Images in the Test Data and Compute Accuracy
timer2=tic;
YYtest = categorical(vec2ind(net(Xtest)));
timetest(j)=toc(timer2);
TYtest = categorical(vec2ind(Ytest));

YYexp = categorical(vec2ind(net(Xexp))); 
TYexp = categorical(vec2ind(Yexp));

%% Calculate the accuracy. 
acctest(j)= sum(YYtest == TYtest)/numel(TYtest)

accexp(j)= sum(YYexp == TYexp)/numel(TYexp)


%% Build confusion matrix with experiment
Outputtest = vertcat(Outputtest,YYtest');
Targettest = vertcat(Targettest,TYtest');

plotconfusion(TYexp,YYexp)

Outputexp = vertcat(Outputexp,YYexp');
Targetexp = vertcat(Targetexp,TYexp');

end
figure(1)
plotconfusion(categorical(Targettest),categorical(Outputtest))

figure(2)
plotconfusion(categorical(Targetexp),categorical(Outputexp))


acctest_m = mean(acctest)
acctest_s = std(acctest)
accexp_m = mean(accexp)
accexp_s = std(accexp)

timetrain_m = mean(timetrain(2:end))
stdtimetrain_s = std(timetrain(2:end))
timetest_m = mean(timetest(2:end))
stdtimetest_s = std(timetest(2:end))