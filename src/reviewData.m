function varargout = reviewData(varargin)
% REVIEWDATA MATLAB code for reviewData.fig
%      REVIEWDATA, by itself, creates a new REVIEWDATA or raises the existing
%      singleton*.
%
%      H = REVIEWDATA returns the handle to a new REVIEWDATA or the handle to
%      the existing singleton*.
%
%      REVIEWDATA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in REVIEWDATA.M with the given input arguments.
%
%      REVIEWDATA('Property','Value',...) creates a new REVIEWDATA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before reviewData_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to reviewData_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help reviewData

% Last Modified by GUIDE v2.5 12-Mar-2020 13:02:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @reviewData_OpeningFcn, ...
                   'gui_OutputFcn',  @reviewData_OutputFcn, ...
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


% --- Executes just before reviewData is made visible.
function reviewData_OpeningFcn(hObject, eventdata, handles, varargin)
global ppsEEG
ppsEEG.preproInfo.SoftStep = 2;
handles.output = hObject;
movegui('center')
axes(handles.axesLead);
imshow('lead.png')
set(gca,'XTickLabel',[])
set(gca,'YTickLabel',[])

% Check if ppsEEG struct exists 
if ~isfield(ppsEEG,'preproInfo')
    ppsFileLog = [ppsEEG.preproInfo.subjectPath '\ppsEEG.mat'];
    ppsEEG = load(ppsFileLog);
end
% Initialize rejected channels structure
rejected = cell(1,length(ppsEEG.preproInfo.leadsInfo.channelNames));
for i=1:length(rejected)
    rejected{i} = zeros(1,length(ppsEEG.preproInfo.leadsInfo.channelNames{i}));
end
ppsEEG.preproInfo.leadsInfo.rejectedChannels = rejected;

handles.leadOn = 1;
handles.ampSpam = 10;
read_checkboxes(handles);
% Update handles structure
guidata(hObject, handles);
show_checkboxes(handles)
plot_sEEG(hObject,handles)

% --- Outputs from this function are returned to the command line.
function varargout = reviewData_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% ---
function show_checkboxes(handles)
global ppsEEG
numContacts = length(ppsEEG.preproInfo.leadsInfo.channelNames{handles.leadOn});
handles.txtRef.Visible = 'off';
refCh = ppsEEG.preproInfo.leadsInfo.refChannel;
chNames = ppsEEG.preproInfo.leadsInfo.channelNames{handles.leadOn};
idx = find(strcmp(chNames,refCh));
if isempty(idx)
    handles.txtRef.Visible = 'off';
else
    chkObj = findobj('Tag',sprintf('chkVal%d',idx));
    handles.txtRef.Position(2) = chkObj.Position(2);
    handles.txtRef.Visible = 'on';
end
for i=1:16
    chkObj = findobj('Tag',sprintf('chkVal%d',i));
    if i > numContacts
        chkObj.Visible = 'off';
    else
        chkObj.Visible = 'on';
    end
end

% ---
function read_checkboxes(handles)
global ppsEEG
rejected = ppsEEG.preproInfo.leadsInfo.rejectedChannels{handles.leadOn};
for i=1:length(rejected)
    chkObj = findobj('Tag',sprintf('chkVal%d',i));
    chkObj.Value = rejected(i);
end

% ---
function write_checkboxes(handles)
global ppsEEG
rejected = ppsEEG.preproInfo.leadsInfo.rejectedChannels{handles.leadOn};
for i=1:length(rejected)
    chkObj = findobj('Tag',sprintf('chkVal%d',i));
    rejected(i) = chkObj.Value;
end
ppsEEG.preproInfo.leadsInfo.rejectedChannels{handles.leadOn} = rejected;

% --- Plot multiple values ---
function plot_sEEG(hObject,handles)
global ppsEEG
axes(handles.axesSignal);
fs = ppsEEG.preproInfo.samplingRate;
numContacts = length(ppsEEG.preproInfo.leadsInfo.channelNames{handles.leadOn});
leadName = char(ppsEEG.preproInfo.leadsInfo.channelNames{handles.leadOn}(1));
leadName = leadName(1:end-1);
chIdx = 0; 

if handles.leadOn > 1
   len = cellfun('length',ppsEEG.preproInfo.leadsInfo.channelNames);
   chIdx = sum(len(1:handles.leadOn-1));
end
data = ppsEEG.data.signalComb60Hz(:,chIdx+1:chIdx+numContacts);
stdY = std(data(:));
midY = mean(data(:));
maxYax =  midY + handles.ampSpam*stdY;
minYax = midY - handles.ampSpam*stdY;
deltaYax = maxYax - minYax;
%data(:,3) = 0;
data = 1000*(data/deltaYax);
data = flip(data,2);
[NSamples,~] = size(data);
xAxis = (0:NSamples-1)./fs; 
xAxis = repmat(xAxis',1,numContacts);
idxMin = 1650 - numContacts*100;
offset = repmat(idxMin:100:1600,NSamples,1);

%dummy = zeros(NSamples,16);
%offset = repmat(50:100:1600,NSamples,1);
handles.axesSignal.ColorOrderIndex = 1;
plot(xAxis,data+offset,'LineWidth',2)
hold on
handles.axesSignal.ColorOrderIndex = 1;
handles.axesSignal
plot([zeros(1,numContacts);ones(1,numContacts)*((NSamples-1)/fs)],[idxMin:100:1600;idxMin:100:1600],'--');
hold off
%imagesc([180 198],[1000 1590],handles.leadImg, 'AlphaData', handles.leadImgAlpha)
xlim([0 10])
ylim([0 1600])
set(gca,'YTickLabel',[])
ylabel(sprintf('Amplitude [%d uV/div]',round(deltaYax/2)))
xlabel('Time (sec)')
numLeads = ppsEEG.preproInfo.leadsInfo.numLeads;
title(sprintf('Lead %s [%d/%d], %d contacts',leadName,handles.leadOn,numLeads,numContacts))
grid on
grid minor

% --- Executes on button press in pushbtnNext.
function pushbtnNext_Callback(hObject, eventdata, handles)
global ppsEEG
numLeads = ppsEEG.preproInfo.leadsInfo.numLeads;
if handles.leadOn < numLeads
    write_checkboxes(handles);
    handles.leadOn = handles.leadOn + 1; 
    show_checkboxes(handles);
    read_checkboxes(handles);
    plot_sEEG(hObject,handles)
    chkVal_updateaxes(handles)
    handles.pushbuttonBack.Enable = 'on';
    if handles.leadOn == numLeads
        handles.pushbtnNext.String = 'Save & Next >>';
    end
    guidata(hObject, handles);
elseif handles.leadOn == numLeads
    write_checkboxes(handles);
    answer = questdlg('Do you want to backup this step?', ...
            'Saving Backup','Yes','No','Yes');
    if isequal(answer,'Yes')
        wb = waitbar(0,'Backing up data...','windowstyle', 'modal');
        wbch = allchild(wb);
        wbch(1).JavaPeer.setIndeterminate(1);
        ppsEEG.preproInfo.SoftStep = 3;
        ppsFileLog = [ppsEEG.preproInfo.subjectPath '\ppsEEG.mat'];
        save(ppsFileLog,'-struct','ppsEEG')
        close(wb)
    end
    closereq
    unrefChannels
end

% --- Executes on button press in pushbuttonBack.
function pushbuttonBack_Callback(hObject, eventdata, handles)
global ppsEEG
numLeads = ppsEEG.preproInfo.leadsInfo.numLeads;
if handles.leadOn > 1
    write_checkboxes(handles);
    handles.leadOn = handles.leadOn - 1;
    guidata(hObject, handles);
    show_checkboxes(handles)
    read_checkboxes(handles);
    plot_sEEG(hObject,handles)
    chkVal_updateaxes(handles)
    handles.pushbtnNext.String = 'Next >>';
    if handles.leadOn == 1
        handles.pushbuttonBack.Enable = 'off';
    else
        
    end
end

% --------------------------------------------------------------------
function uitoggletoolZoom_ClickedCallback(hObject, eventdata, handles)
zoom xon

% --------------------------------------------------------------------
function uitoggletoolPan_ClickedCallback(hObject, eventdata, handles)
pan xon 


% --- Executes on button press in chkVal1.
function chkVal_Callback(hObject, eventdata, handles)
global ppsEEG
plots = handles.axesSignal.Children;
numContacts = length(ppsEEG.preproInfo.leadsInfo.channelNames{handles.leadOn});
contact = sscanf(hObject.Tag,'chkVal%d');
plots(contact + numContacts).Visible = ~hObject.Value;

function chkVal_updateaxes(handles)
global ppsEEG
rejected = ppsEEG.preproInfo.leadsInfo.rejectedChannels{handles.leadOn};
plots = handles.axesSignal.Children;
numContacts = length(ppsEEG.preproInfo.leadsInfo.channelNames{handles.leadOn});
for i=1:length(rejected)
    plots(numContacts + i).Visible = ~rejected(i);
end

% --- Executes on button press in pushbtnPamRight.
function pushbtnPamRight_Callback(hObject, eventdata, handles)
axes(handles.axesSignal);
xl = xlim;
delta = diff(xl);
newxl = xl(1)-delta;
if newxl < 0 
    xlim([0 delta])
else
    xlim([newxl (xl(1))])
end


% --- Executes on button press in pushbtnPamLeft.
function pushbtnPamLeft_Callback(hObject, eventdata, handles)
global ppsEEG
fs = ppsEEG.preproInfo.samplingRate;
maxX = size(ppsEEG.data.signal,1)/fs;
axes(handles.axesSignal);
xl = xlim;
delta = diff(xl);
newxl = xl(2)+delta;
if newxl > maxX
    xlim([(maxX-delta) maxX])
else
    xlim([xl(2) newxl])
end


% --- Executes on selection change in popupSpam.
function popupSpam_Callback(hObject, eventdata, handles)
switch get(hObject,'Value')
    case 1
        handles.ampSpam = 20;
    case 2
        handles.ampSpam = 10;
    case 3
        handles.ampSpam = 5;
end
write_checkboxes(handles)
plot_sEEG(hObject,handles)
chkVal_updateaxes(handles)
guidata(hObject, handles);

% hObject    handle to popupSpam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupSpam contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupSpam


% --- Executes during object creation, after setting all properties.
function popupSpam_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupSpam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
