function varargout = unrefChannels(varargin)
% UNREFCHANNELS MATLAB code for unrefChannels.fig
%      UNREFCHANNELS, by itself, creates a new UNREFCHANNELS or raises the existing
%      singleton*.
%
%      H = UNREFCHANNELS returns the handle to a new UNREFCHANNELS or the handle to
%      the existing singleton*.
%
%      UNREFCHANNELS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in UNREFCHANNELS.M with the given input arguments.
%
%      UNREFCHANNELS('Property','Value',...) creates a new UNREFCHANNELS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before unrefChannels_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to unrefChannels_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help unrefChannels

% Last Modified by GUIDE v2.5 03-May-2020 12:28:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @unrefChannels_OpeningFcn, ...
                   'gui_OutputFcn',  @unrefChannels_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before unrefChannels is made visible.
function unrefChannels_OpeningFcn(hObject, eventdata, handles, varargin)
global ppsEEG
ppsEEG.preproInfo.SoftStep = 3;
handles.output = hObject;
movegui('center')

% Check if ppsEEG struct exists 
if ~isfield(ppsEEG,'preproInfo')
    ppsFileLog = [ppsEEG.preproInfo.subjectPath '\ppsEEG.mat']; 
    ppsEEG = load(ppsFileLog);
end
% Initialize referencing channels
numLeads = ppsEEG.preproInfo.leadsInfo.numLeads;
ppsEEG.preproInfo.referencingInfo.numLeads = numLeads;
ppsEEG.preproInfo.referencingInfo.channelNames = cell(1,numLeads);
ppsEEG.preproInfo.referencingInfo.thresholds = zeros(1,numLeads);

handles.leadOn = 1;
handles.threshold = handles.sliderThreshold.Value;
handles = plotCorrelationMatrix(handles);
plotThreshold(handles);

% Update handles structure
guidata(hObject, handles);
% UIWAIT makes unrefChannels wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = unrefChannels_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

function handles = plotCorrelationMatrix(handles)
global ppsEEG
axes(handles.axesCorrelation);
numContacts = length(ppsEEG.preproInfo.leadsInfo.channelNames{handles.leadOn});
leadName = char(ppsEEG.preproInfo.leadsInfo.channelNames{handles.leadOn}(1));
leadName = leadName(1:end-1);
chIdx = 0; 
if handles.leadOn > 1
   len = cellfun('length',ppsEEG.preproInfo.leadsInfo.channelNames);
   chIdx = sum(len(1:handles.leadOn-1));
end
data = ppsEEG.data.signalComb60Hz(:,chIdx+1:chIdx+numContacts);
[R,~] = corrcoef(data);
imshow(R)
colormap('jet');
colorbar
set(gca, 'Visible', 'On', 'XAxisLocation','bottom')
numLeads = ppsEEG.preproInfo.leadsInfo.numLeads;
title(sprintf('Correlation Matrix for %s [%d/%d]',leadName,handles.leadOn,numLeads))
datacursormode on
handles.CorrMatrix = R;


function plotThreshold(handles)
global ppsEEG
axes(handles.axesThreshold);
numContacts = length(ppsEEG.preproInfo.leadsInfo.channelNames{handles.leadOn});
rejected = ppsEEG.preproInfo.leadsInfo.rejectedChannels{handles.leadOn};
thrmask = ones(size(handles.CorrMatrix));
thrmask(handles.CorrMatrix<handles.threshold) = 0;
leadIdx = zeros(1,numContacts);
i = 1;
while(i < numContacts)
    if rejected(i)
        i = i + 1;
    else
        for j=i+1:numContacts
            if rejected(j)
                i = j;
                break
            end
            submat = thrmask(i:j,i:j);
            if all(submat(:))
                leadIdx(i) = j;
                if j == numContacts
                    i = numContacts;
                    break
                end
                if handles.chkBipolar.Value
                    i=i+1;
                    break
                end
            else
                if leadIdx(i)>0
                    i = leadIdx(i);
                else
                    i=i+1;
                end
                break
            end
        end
    end
end 
numCMasks = nnz(leadIdx);
pairMasks = [1:numContacts;leadIdx];
pairMasks = pairMasks(:,pairMasks(2,:)>0);
corrMasks = zeros(numContacts,numContacts,numCMasks);
leadName = char(ppsEEG.preproInfo.leadsInfo.channelNames{handles.leadOn}(1));
leadName = leadName(1:end-1);
idx = 1;
channelNames = {};
for i=1:numCMasks
    iniIdx = pairMasks(1,i);
    endIdx = pairMasks(2,i);
    corrMasks(iniIdx:endIdx,iniIdx:endIdx,i) = 1;
    for j=1:(endIdx-iniIdx)
        name = sprintf('%s%d@%d-%d',leadName,j,iniIdx,endIdx);
        if i > 1 && j == 1
           if iniIdx == pairMasks(2,i-1)  
               iniIdx_prev = pairMasks(1,i-1);
               endIdx_prev = pairMasks(2,i-1);
               num = endIdx_prev - iniIdx_prev + 1;
               name = sprintf('%s%d@%d-%d',leadName,num,iniIdx_prev,endIdx);
           end
        end
        channelNames{idx} = name;
        idx = idx + 1;
    end 
end
ppsEEG.preproInfo.referencingInfo.channelNames{handles.leadOn} = channelNames;
ppsEEG.preproInfo.referencingInfo.thresholds(handles.leadOn) = handles.threshold;
GeneralMask = sum(corrMasks,3)>0;
R_rgb = ind2rgb(round(handles.CorrMatrix*255), jet(256)).*GeneralMask; 
imshow(R_rgb)

% --- Executes on slider movement.
function sliderThreshold_Callback(hObject, eventdata, handles)
handles.threshold = get(hObject,'Value');
handles.txtThreshold.String = sprintf('Threshold: %.2f',handles.threshold);
plotThreshold(handles);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function sliderThreshold_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in chkBipolar.
function chkBipolar_Callback(hObject, eventdata, handles)
% hObject    handle to chkBipolar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = plotCorrelationMatrix(handles);
plotThreshold(handles);

% --- Executes on button press in pushNext.
function pushNext_Callback(hObject, eventdata, handles)
global ppsEEG
numLeads = ppsEEG.preproInfo.leadsInfo.numLeads;
if handles.leadOn < numLeads
    handles.leadOn = handles.leadOn + 1;   
    handles = plotCorrelationMatrix(handles);
    plotThreshold(handles);
    handles.pushBack.Enable = 'on';
     if handles.leadOn == numLeads
        handles.pushNext.String = 'Save & Next >>';
    end
    guidata(hObject, handles);
elseif handles.leadOn == numLeads
    wb = waitbar(0,'Re-referencing data...','windowstyle', 'modal');
    wbch = allchild(wb);
    wbch(1).JavaPeer.setIndeterminate(1);
    generate_Data(handles);
    close(wb)
    answer = questdlg('Do you want to backup this step?', ...
            'Saving Backup','Yes','No','Yes');
    if isequal(answer,'Yes')
        wb = waitbar(0,'Backing up data...','windowstyle', 'modal');
        wbch = allchild(wb);
        wbch(1).JavaPeer.setIndeterminate(1);
        %generate_Data(handles);
        ppsEEG.preproInfo.SoftStep = 4;
        ppsFileLog = [ppsEEG.preproInfo.subjectPath '\ppsEEG.mat'];
        save(ppsFileLog,'-struct','ppsEEG')
        close(wb)
    end
    closereq
    reviewRefData
end

% --- Executes on button press in pushBack.
function pushBack_Callback(hObject, eventdata, handles)
global ppsEEG
numLeads = ppsEEG.preproInfo.leadsInfo.numLeads;
if handles.leadOn > 1
    handles.leadOn = handles.leadOn - 1;
    handles = plotCorrelationMatrix(handles);
    plotThreshold(handles);
    handles.pushNext.String = 'Next >>';
    if handles.leadOn == 1
        handles.pushBack.Enable = 'off';
    else
        
    end
   
end
guidata(hObject, handles);

% --- Generate decorrelated data
function generate_Data(handles)
global ppsEEG
newChannels = cellfun('length',ppsEEG.preproInfo.referencingInfo.channelNames);
samples = size(ppsEEG.data.signal,1);
newSignal = zeros(samples,sum(newChannels));
idx = 1;
for i=1:ppsEEG.preproInfo.referencingInfo.numLeads
    offset = 0;
    if i>1
        len = cellfun('length',ppsEEG.preproInfo.leadsInfo.channelNames);
        offset = sum(len(1:i-1));
    end
    mainleadName = char(ppsEEG.preproInfo.leadsInfo.channelNames{i}(1));
    mainleadName = mainleadName(1:end-1);
    leadNames = ppsEEG.preproInfo.referencingInfo.channelNames{i};
    for j=1:length(leadNames) 
        strTmp = split(leadNames{j},'@');
        limitIdx = sscanf(strTmp{2},'%d-%d'); 
        newIdx = sscanf(strTmp{1},[mainleadName '%d']);
        lo = offset + limitIdx(1);
        hi = offset + limitIdx(2);
        group_signal = ppsEEG.data.signalComb60Hz(:,lo:hi);
        newSignal(:,idx) = group_signal(:,newIdx) - mean(group_signal,2);
        idx = idx + 1;
    end
end
ppsEEG.data.signalReferenced = newSignal;
