function Pupil
% SETUP
% > Connect the water valve in the box to Bpod Port#1.
% > Connect the air valve in the box to Bpod Port#2.
% > Lick: Bpod Port#3
% > Hanfei,10/23/2022
% This protocol is to deliver laser (measuring heart beat/respiration)

global BpodSystem

%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    
    S.GUI.PreGoTrialNum = 1;
    
    S.ITI = 10;
    S.ITI_min=S.ITI-1; S.ITI_max=S.ITI+2;
    S.SoundDuration = 1.0;
    
    S.LaserDuration = 4; % the duration of laser stimulation
    S.LaserDelayFromTrialOnset = 2; % the onset of laser stimulation from trial onset
    
    S.GUI.RecordDuration = S.LaserDuration+10;
    
end

% Initialize parameter GUI plugin
BpodParameterGUI('init', S);
TotalRewardDisplay('init');

%% Define trials
MaxTrials = 500;
TrialTypes = ones(1,MaxTrials);

LaserTrial = zeros(1,MaxTrials);
%seq_type = [1,0,0,0,0,0,0,0,0,0];
seq_type = [1,0];%laser percentage
% seq_type = [zeros(1,20),ones(1,20)];
for ii=(S.GUI.PreGoTrialNum+1):length(seq_type):MaxTrials
    LaserTrial(ii:ii+length(seq_type)-1) = seq_type(randperm(length(seq_type)));
    LaserTrial(ii:ii+length(seq_type)-1) = seq_type;
end
    
R = repmat(S.ITI,1,MaxTrials);
for k=1:MaxTrials
    candidate_delay = exprnd(S.ITI);
    while candidate_delay>S.ITI_max || candidate_delay<S.ITI_min
        candidate_delay = exprnd(S.ITI);
    end
    R(k) = candidate_delay;
end
ITI = R;

BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
BpodSystem.Data.ITI = [];
BpodSystem.Data.LaserTrial = [];

%% Initialize plots
BpodSystem.ProtocolFigures.SideOutcomePlotFig = figure('Position', [100 200 1200 300],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.SideOutcomePlot = axes('Position', [.075 .3 .89 .6]);
% BpodSystem.ProtocolFigures.LickPlotFig = figure('Position', [600 200 600 200],'name','Licking','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
GoNoGoOutcomePlot(BpodSystem.GUIHandles.SideOutcomePlot,'init',TrialTypes);

% Set soft code handler to trigger sounds
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySoundX';

SF = 192000; % Sound card sampling rate
SinWaveFreq1 = 3000;
sounddata1 = GenerateSineWave(SF, SinWaveFreq1, S.SoundDuration); % Sampling freq (hz), Sine frequency (hz), duration (s)
SinWaveFreq2 = 10000;
sounddata2 = GenerateSineWave(SF, SinWaveFreq2, S.SoundDuration); % Sampling freq (hz), Sine frequency (hz), duration (s)

% Program sound server
PsychToolboxSoundServer('init')
PsychToolboxSoundServer('Load', 1, 0.25*sounddata1);
PsychToolboxSoundServer('Load', 2, 0.85*sounddata2);

%% Main trial loop
for currentTrial = 1:MaxTrials
    
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin    
    
    if LaserTrial(currentTrial)
        laser_arg = {'GlobalTimerTrig', 2};
    else
        laser_arg = {};
    end
    
    sma = NewStateMatrix(); % Assemble state matrix
    
    % sma = SetGlobalTimer(sma, 'TimerID', 1, 'Duration', S.GUI.RecordDuration, 'OnsetDelay', 1, 'Channel', 'BNC2');
    sma = SetGlobalTimer(sma, 'TimerID', 1, 'Duration', S.GUI.RecordDuration, 'OnsetDelay', 1, 'Channel', 'Wire1');
    sma = SetGlobalTimer(sma, 'TimerID', 2, 'Duration', S.LaserDuration, 'OnsetDelay', S.LaserDelayFromTrialOnset, 'Channel', 'BNC1');
    
    sma = AddState(sma, 'Name', 'TrialStart00', ...
        'Timer', 1,...
        'StateChangeConditions', {'Tup', 'TrialStart0'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'TrialStart0', ...
        'Timer', 1,...
        'StateChangeConditions', {'Tup', 'TrialStart'},...
        'OutputActions', {'GlobalTimerTrig', 1});
    sma = AddState(sma, 'Name', 'TrialStart', ...
        'Timer', 4,...
        'StateChangeConditions', {'Tup', 'StimulusDeliver'},...
        'OutputActions', laser_arg);
    sma = AddState(sma, 'Name', 'StimulusDeliver', ...
        'Timer', S.LaserDuration,...
        'StateChangeConditions', {'Tup', 'CueDelay'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'CueDelay', ...
        'Timer', 2,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'ITI', ...
        'Timer', ITI(currentTrial),...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {});
    
    SendStateMatrix(sma);
    BpodSystem.Data.TrialStartTime_PC(currentTrial) = now;
    RawEvents = RunStateMatrix;
    
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data
        BpodSystem.Data.ITI(currentTrial) = ITI(currentTrial);
        BpodSystem.Data.LaserTrial(currentTrial) = LaserTrial(currentTrial);
        
        %Outcome        
        if LaserTrial(currentTrial)
            BpodSystem.Data.Outcomes(currentTrial) = 1;
        else
            BpodSystem.Data.Outcomes(currentTrial) = 0;
        end
        
        UpdateGoNoGoOutcomePlot(TrialTypes, BpodSystem.Data);
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.Status.BeingUsed == 0
        return
    end
end

function UpdateGoNoGoOutcomePlot(TrialTypes, Data)
global BpodSystem
Outcomes = zeros(1,Data.nTrials);
for x = 1:Data.nTrials
    if Data.LaserTrial(x)
        Outcomes(x) = 1;
    else
        Outcomes(x) = 0;
    end
end
GoNoGoOutcomePlot(BpodSystem.GUIHandles.SideOutcomePlot,'update',Data.nTrials+1,TrialTypes,Outcomes);
