function FearConditionD

% SETUP
% > Connect the water valve in the box to Bpod Port#1.
% > Connect the shock box.
% > Lick: Bpod Port#1
% > Hanfei updated 02/25/2023

global BpodSystem

%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    
    S.GUI.PunishAmount = 0.5; % s (tail shock)
    S.GUI.VideoDuration = 2;
    S.GUI.CueDuration = 5;
    
    S.SessionTrialNum = 1000;
    
    S.GUI.TrainingLevel = 1; % Configurable training level
    S.GUIMeta.TrainingLevel.Style = 'popupmenu'; % the GUIMeta field is used by the ParameterGUI plugin to customize UI objects.
    S.GUIMeta.TrainingLevel.String = {'CS only','Conditioning'};
    
    S.CueDelay = 1; % the time from cue to response
    S.GUI.US_Delay = 0; % the time from cue to response
    S.ITI = 60;
    S.ITI_min=S.ITI-5; S.ITI_max=S.ITI+5;

    
    S.trial_seq = [0, 0]; % [0,2] 0 for shock; 2 for neutral
    % S.trial_seq = [0, 0]; % shock only
    
    S.Laser = 0; %0,1
    S.LaserDuration = 1; % the duration of laser stimulation
    S.LaserDelayFromTrialOnset = 0; % the onset of laser stimulation from CS onset
    
end

% Initialize parameter GUI plugin
BpodParameterGUI('init', S);
TotalRewardDisplay('init');

%% Define trials
MaxTrials = 1000;

TrialTypes = zeros(1,MaxTrials);
seq_type = S.trial_seq;
for ii=1:length(seq_type):MaxTrials
    TrialTypes(ii:ii+length(seq_type)-1) = seq_type(randperm(length(seq_type)));
end

LaserTrial = zeros(1,MaxTrials);
if S.Laser
    seq_type = [1,0];
    for ii=1:length(seq_type):MaxTrials
        LaserTrial(ii:ii+length(seq_type)-1) = seq_type(randperm(length(seq_type)));
    end
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
sounddata1 = GenerateSineWave(SF, SinWaveFreq1, S.GUI.CueDuration); % Sampling freq (hz), Sine frequency (hz), duration (s)
SinWaveFreq2 = 3000;
sounddata2 = GenerateSineWave(SF, SinWaveFreq2, S.GUI.CueDuration); % Sampling freq (hz), Sine frequency (hz), duration (s)

% Program sound server
PsychToolboxSoundServer('init')
PsychToolboxSoundServer('Load', 1, 0.12*sounddata1);
PsychToolboxSoundServer('Load', 2, 0.12*sounddata2);

%% Main trial loop
for currentTrial = 1:MaxTrials
    
    if currentTrial>S.SessionTrialNum
        error('Maximum trial number reached!');
    end
    
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    
    switch TrialTypes(currentTrial) % Determine trial-specific state matrix fields
        case 2 % neutral trial
            sound_arg = {'SoftCode', 1};
            Tup_Action = 'Neutral';
        case 0 % punishment trial            
            sound_arg = {'SoftCode', 2};
            Tup_Action = 'Punishment';
    end
    
    if LaserTrial(currentTrial)
        laser_arg = {'GlobalTimerTrig', 2};
    else
        laser_arg = {};
    end
    
    if S.GUI.TrainingLevel==1
        shock_arg = {};
    elseif S.GUI.TrainingLevel==2
        shock_arg = {'PWM5', 255};
    end
    
    sma = NewStateMatrix(); % Assemble state matrix
    
    sma = SetGlobalTimer(sma, 'TimerID', 1, 'Duration', S.GUI.VideoDuration, 'OnsetDelay', 0, 'Channel', 'Wire1');
    sma = SetGlobalTimer(sma, 'TimerID', 2, 'Duration', S.LaserDuration, 'OnsetDelay', S.LaserDelayFromTrialOnset, 'Channel', 'BNC1');
    
    sma = AddState(sma, 'Name', 'Base', ...
        'Timer', 1,...
        'StateChangeConditions', {'Tup', 'TrialStart'},...
        'OutputActions', {});    
    sma = AddState(sma, 'Name', 'TrialStart', ...
        'Timer', 2,...
        'StateChangeConditions', {'Tup', 'StimulusDeliver'},...
        'OutputActions', {'BNC2',1,'PWM3',255});
    sma = AddState(sma, 'Name', 'StimulusDeliver', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'CueDelay'},...
        'OutputActions', [laser_arg, sound_arg]);
    sma = AddState(sma, 'Name', 'CueDelay', ...
        'Timer',S.GUI.CueDuration-S.GUI.PunishAmount,...
        'StateChangeConditions', {'Tup', Tup_Action},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'Neutral', ...
        'Timer', S.GUI.US_Delay,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'Punishment', ...
        'Timer',S.GUI.US_Delay,...
        'StateChangeConditions', {'Tup', 'DeliverPunishment'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'DeliverPunishment', ...
        'Timer', S.GUI.PunishAmount,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', shock_arg);
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
        if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Punishment(1))
            BpodSystem.Data.Outcomes(currentTrial) = 0;
        else
            BpodSystem.Data.Outcomes(currentTrial) = 2;
        end
        
        UpdateTotalRewardDisplay(S.GUI.PunishAmount, currentTrial);
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
    if ~isnan(Data.RawEvents.Trial{x}.States.Punishment(1))
        Outcomes(x) = 0;
    else
        Outcomes(x) = 2;
    end
end
GoNoGoOutcomePlot(BpodSystem.GUIHandles.SideOutcomePlot,'update',Data.nTrials+1,TrialTypes,Outcomes);

function UpdateTotalRewardDisplay(RewardAmount, currentTrial)
% If rewarded based on the state data, update the TotalRewardDisplay
global BpodSystem
if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Punishment(1))
    TotalRewardDisplay('add', RewardAmount);
end
