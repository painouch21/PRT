classdef prtClassKnn < prtClass
    % prtClassKnn  K-nearest neighbors classifier
    %
    %    CLASSIFIER = prtClassKnn returns a K-nearest neighbors classifier
    %
    %    CLASSIFIER = prtClassKnn(PROPERTY1, VALUE1, ...) constructs a
    %    prtClassKnn object CLASSIFIER with properties as specified by
    %    PROPERTY/VALUE pairs.
    %
    %    A prtClassKnn object inherits all properties from the abstract class
    %    prtClass. In addition is has the following properties:
    %
    %    k                  - The number of neigbors to be considered
    %    distanceFunction   - The function to be used to compute the
    %                         distance from samples to cluster centers. 
    %                         It must be a function handle of the form:
    %                         @(x1,x2)distFun(x1,x2). Most prtDistance*
    %                         functions will work.
    %
    %    For information on the  K-nearest neighbors classifier algorithm, please
    %    refer to the following URL:
    %
    %    http://en.wikipedia.org/wiki/K-nearest_neighbor_algorithm    
    %
    %    A prtClassKnn object inherits the TRAIN, RUN, CROSSVALIDATE and
    %    KFOLDS methods from prtAction. It also inherits the PLOT method
    %    from prtClass.
    %
    %    Example:
    %
    %     TestDataSet = prtDataGenUnimodal;      % Create some test and 
    %     TrainingDataSet = prtDataGenUnimodal;  % training data
    %     classifier = prtClassKnn;           % Create a classifier
    %     classifier = classifier.train(TrainingDataSet);    % Train
    %     classified = run(classifier, TestDataSet);         % Test
    %     classifier.plot;
    %
    %    See also prtClass, prtClassLogisticDiscriminant, prtClassBagging,
    %    prtClassMap, prtClassCap, prtClassBinaryToMaryOneVsAll, prtClassDlrt,
    %    prtClassPlsda, prtClassFld, prtClassRvm, prtClassGlrt,  prtClass
    
    properties (SetAccess=private)
       
        name = 'K-Nearest Neighbor'   % K-Nearest Neighbor
        nameAbbreviation = 'KNN'      % KNN  
        isNativeMary = true;         % False
        
    end
    
    properties
      
        k = 3;   % The number of neighbors to consider in the voting
        
        distanceFunction = @(x1,x2)prtDistanceEuclidean(x1,x2);   % Function handle to compute distance
    end
    
    methods
        function Obj = prtClassKnn(varargin)
            
            Obj = prtUtilAssignStringValuePairs(Obj,varargin{:});
            Obj.verboseStorage = true;
        end
    end
    
    methods (Access=protected, Hidden = true)
        function Obj = preTrainProcessing(Obj,DataSet)
            if ~Obj.verboseStorage
                warning('prtClassKnn:verboseStorage:false','prtClassKnn requires verboseStorage to be true; overriding manual settings');
            end
            Obj.verboseStorage = true;
            Obj = preTrainProcessing@prtClass(Obj,DataSet);
        end
        function Obj = trainAction(Obj,~)
            %Do nothing; we've already specified "verboseStorage = true",
            %so the ".DataSet" field will be set when it comes time to test
        end
        
        function ClassifierResults = runAction(Obj,PrtDataSet)
            
            x = getObservations(PrtDataSet);
            n = PrtDataSet.nObservations;
            
            nClasses = Obj.DataSet.nClasses;
            uClasses = Obj.DataSet.uniqueClasses;
            labels = getTargets(Obj.DataSet);
            y = zeros(n,nClasses);
            
            xTrain = getObservations(Obj.DataSet);
            
            largestMatrixSize = prtOptionsGet('prtOptionsComputation','largestMatrixSize');
            memBlock = max(floor(largestMatrixSize/size(xTrain,1)),1);
            
            if n > memBlock
                for start = 1:memBlock:n
                    indices = start:min(start+memBlock-1,n);
                    
                    distanceMat = feval(Obj.distanceFunction,xTrain,x(indices,:));
                    
                    [~,I] = sort(distanceMat,1,'ascend');
                    I = I(1:Obj.k,:);
                    L = labels(I)';
                    
                    for class = 1:nClasses
                        y(indices,class) = sum(L == uClasses(class),2);
                    end
                end
            else
                distanceMat = feval(Obj.distanceFunction,xTrain,x);
                
                [~,I] = sort(distanceMat,1,'ascend');
                I = I(1:Obj.k,:);
                L = labels(I)';
                
                for class = 1:nClasses
                    y(:,class) = sum(L == uClasses(class),2);
                end
            end
            
            [Etc.nVotes,Etc.MapGuessInd] = max(y,[],2);
            Etc.MapGuess = uClasses(Etc.MapGuessInd);
            ClassifierResults = prtDataSetClass(y);
            
        end
        
    end
end
