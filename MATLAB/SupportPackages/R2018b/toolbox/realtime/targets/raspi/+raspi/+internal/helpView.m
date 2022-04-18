function helpView(sppkgLabelStr, topicId, varargin) 
% HELPVIEW Helper function to view a block help for a support package.
%
% Copyright 2014 The MathWorks, Inc.

validateattributes(sppkgLabelStr, {'char'}, {'nonempty'}, 'helpView', 'blkPlatform');
validateattributes(topicId, {'char'}, {'nonempty'}, 'helpView', 'blockId');

sppkgTag = realtime.convertStringToTag(sppkgLabelStr);
assert(isequal(exist(['raspi.internal.' sppkgTag ],'class'), 8),['Undefined class raspi.internal.' sppkgTag ]);
assert(ismethod(['raspi.internal.' sppkgTag ], 'getDocRoot'),...
   ['getDocRoot method not defined for class raspi.internal.' sppkgTag]);
docRoot = feval(['raspi.internal.' sppkgTag '.getDocRoot']);
helpview(fullfile(docRoot,'helptargets.map'), topicId);

