function I = readFcn1(filename)
% Load data and get matrices from the structure
I = load(filename);
I = I.matrix;