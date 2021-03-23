function varargout = preproSEEG(varargin)
% PREPROSEEG MATLAB code for preprosEEG.fig
%      PREPROSEEG, by itself, creates a new PREPROSEEG or raises the existing
%      singleton*.
%
%      H = PREPROSEEG returns the handle to a new PREPROSEEG or the handle to
%      the existing singleton*.
%
%      PREPROSEEG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PREPROSEEG.M with the given input arguments.
%
%      PREPROSEEG('Property','Value',...) creates a new PREPROSEEG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before preprosEEG_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to preprosEEG_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help preprosEEG

% Last Modified by GUIDE v2.5 11-Mar-2020 13:13:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @preprosEEG_OpeningFcn, ...
                   'gui_OutputFcn',  @preprosEEG_OutputFcn, ...
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


% --- Executes just before preprosEEG is made visible.
function preprosEEG_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to preprosEEG (see VARARGIN)

% Choose default command line output for preprosEEG
global ppsEEG
ppsEEG.preproInfo.SoftStep = 1;
handles.output = hObject;
movegui('center')
axes(handles.axesLogo);
imshow('logo.png')
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes preprosEEG wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = preprosEEG_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function editPath_Callback(hObject, eventdata, handles)
% hObject    handle to editPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPath as text
%        str2double(get(hObject,'String')) returns contents of editPath as a double


% --- Executes during object creation, after setting all properties.
function editPath_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbtnFOpen.
function pushbtnFOpen_Callback(hObject, eventdata, handles)
% hObject    handle to pushbtnFOpen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global ppsEEG
[filename, pathname, ~] = uigetfile('*.dat', 'Pick a BCI2000 File');
if ~isequal(filename,0)
    [channelNames,refChannel,numLeads]=GetChannelNames(filename);
    if numLeads > 0
        set(gcf,'pointer','watch')
        drawnow;
        handles.editPath.String = filename;
        ppsEEG.preproInfo.subjectFile = filename;
        ppsEEG.preproInfo.pcUser = getenv('username');
        ppsEEG.preproInfo.leadsInfo.channelNames = channelNames;
        ppsEEG.preproInfo.leadsInfo.refChannel = refChannel;
        ppsEEG.preproInfo.leadsInfo.numLeads = numLeads;
        [signal,states,params]=load_bcidat([pathname,filename],'-calibrated');
        ppsEEG.data.signal = signal;
        ppsEEG.data.states = states;
        ppsEEG.data.params = params;
        ppsEEG.preproInfo.samplingRate = params.SamplingRate.NumericValue;
        ppsEEG.data.signalComb60Hz = comb_filter60Hz(signal,ppsEEG.preproInfo.samplingRate);
        handles.pushbtnNext.Enable = 'on';
        set(gcf,'pointer','arrow')
        drawnow;
    else
        errordlg('Subject not found in GetChannelNames.m','File Error');
    end
end


% --- Executes on button press in pushbtnFolder.
function pushbtnFolder_Callback(hObject, eventdata, handles)
global ppsEEG
pathname = uigetdir('','Open Subject Directory');
if ~isequal(pathname,0)
    handles.editSubFolder.String = pathname;
    ppsEEG.preproInfo.subjectPath = pathname;
    ppsFileLog = [pathname '\ppsEEG.mat'];
    if isfile(ppsFileLog)
        answer = questdlg('We found previous steps completed. Proceed to last finsihed step?', ...
            'Log File Found','Yes','Start Over','Yes');
        if isequal(answer,'Yes')
            wb = waitbar(0,'Loading data...','windowstyle', 'modal');
            wbch = allchild(wb);
            wbch(1).JavaPeer.setIndeterminate(1);
            ppsFileLog = [ppsEEG.preproInfo.subjectPath '\ppsEEG.mat'];
            ppsEEG = load(ppsFileLog);
            close(wb)
            closereq
            switch ppsEEG.preproInfo.SoftStep
                case 2
                    reviewData
                case 3
                    unrefChannels
                case 4
                    reviewRefData
                % case 5 
            end
        end
    end
end

function signalfilt = comb_filter60Hz(signal,fs)
%Notch Filter 
fo = 60; %Hz
Q = 50; %quality factor
bw = (fo/(fs/2))/Q;
[b,a] = iircomb(fs/fo,bw,'notch');
signalfilt = filtfilt(b,a,double(signal));

% --- Executes on button press in pushbtnNext.
function pushbtnNext_Callback(hObject, eventdata, handles)
% hObject    handle to pushbtnNext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global ppsEEG
answer = questdlg('Do you want to backup this step?', ...
            'Saving Backup','Yes','No','Yes');
if isequal(answer,'Yes')
    wb = waitbar(0,'Backing up data...','windowstyle', 'modal');
    wbch = allchild(wb);
    wbch(1).JavaPeer.setIndeterminate(1);
    ppsEEG.preproInfo.SoftStep = 2;
    ppsFileLog = [ppsEEG.preproInfo.subjectPath '\ppsEEG.mat'];
    save(ppsFileLog,'-struct','ppsEEG')
    close(wb)
end
closereq
reviewData



function editSubFolder_Callback(hObject, eventdata, handles)
% hObject    handle to editSubFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSubFolder as text
%        str2double(get(hObject,'String')) returns contents of editSubFolder as a double


% --- Executes during object creation, after setting all properties.
function editSubFolder_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSubFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
