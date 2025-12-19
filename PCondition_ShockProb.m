function PCondition_ShockProb

% SETUP
% > Connect the shock in the box to Bpod Port#3.
% > Lick: Bpod Port#1
% > Xiong and Dinglan,01/29/2023

global BpodSystem

%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    
    S.GUI.RewardAmount = 8; % ul
    S.GUI.PunishAmount = 0.2; % s (shock)
    S.GUI.PreGoTrialNum = 0;
    S.GUI.VideoDuration = 8;
    
    S.SessionTrialNum = 1000;
    
    S.GUI.ResponseTimeGo = 1; % How long until the mouse must make a choice, or forefeit the trial
    S.GUI.ResponseTimeNoGo = 1; % How long until the mouse must make a choice, or forefeit the trial
    
    S.GUI.TrainingLevel = 4; % Configurable training level
    S.GUIMeta.TrainingLevel.Style = 'popupmenu'; % the GUIMeta field is used by the ParameterGUI plugin to customize UI objects.
    S.GUIMeta.TrainingLevel.String = {'Habituation','Reward','Shock','Full_Task','Reward_Shock_Block'};
    
    % US_Levels = [1*ones(1,30),3*ones(1,30),1*ones(1,100)]; % 
    US_Levels = [1*ones(1,100)];
    us_level_bock_design_or = 0;
    
    block_design_or = 0; % 1, block design; 0, random
    % Trial identity: 1=sucrose  2=water  0=quinine -1=airpuff
    % trial_seq_type = [1,1,0,0];
    trial_seq_type = [0,0,0,0];
    
    S.reward_sequence = [1,1,1,1,0,2]; % 0, omission; 2, surprise reward
    S.punish_sequence = [1,1,1,1,0,2]; %     TrainingLevel=4 full task  0, omission; 2, surprise punish
%     S.punish_sequence = [1,1,1,1]; %  TrainingLevel=3 shock learning     0, omission; 2, surprise punish
        
    S.GUI.PunishDelay = 1;
    S.GUI.RewardDelay = 1;

    S.CueDelay = 0.5; % the time from cue to response
    S.ITI = 6;
    S.ITI_min=S.ITI-1; S.ITI_max=S.ITI+2;
    S.SoundDuration = 0.5;
    
    S.Laser = 0; %0,1
    S.LaserDuration = 1; % the duration of laser stimulation
    S.LaserDelayFromTrialOnset = 0; % the onset of laser stimulation from CS onset
    
end

LickPort = 'Port1In';
reward_valve_id = 1; % 1, water (signle)
RewardValveState = 1; % 1, water (signle)
% PunishValveState = 2;

% Initialize parameter GUI plugin
BpodParameterGUI('init', S);
TotalRewardDisplay('init');

%% Define trials
MaxTrials = 1000;
TrialUSLevels = ones(1,MaxTrials);

for ii=(S.GUI.PreGoTrialNum+1):length(US_Levels):MaxTrials
    if us_level_bock_design_or
        TrialUSLevels(ii:ii+length(US_Levels)-1) = US_Levels;
    else
        TrialUSLevels(ii:ii+length(US_Levels)-1) = US_Levels(randperm(length(US_Levels)));
    end
end
TrialUSLevels(1:S.GUI.PreGoTrialNum) = 1;

if S.GUI.TrainingLevel<3
    TrialTypes = ones(1,MaxTrials);
elseif S.GUI.TrainingLevel==3
    TrialTypes = zeros(1,MaxTrials);
elseif S.GUI.TrainingLevel==4
    % TrialTypes = ceil(rand(1,MaxTrials)*2)-1;
    TrialTypes = ones(1,MaxTrials);
    
    seq_type = trial_seq_type;
    for ii=(S.GUI.PreGoTrialNum+1):length(seq_type):MaxTrials
        TrialTypes(ii:ii+length(seq_type)-1) = seq_type(randperm(length(seq_type)));
    end
    
elseif S.GUI.TrainingLevel==5
    TrialTypes = ones(1,MaxTrials);
    TrialTypes(51:70) = 0;
end

if block_design_or
    TrialTypes(S.GUI.PreGoTrialNum+1:S.GUI.PreGoTrialNum+1+length(trial_seq_type)-1) = trial_seq_type;
else
    for ii=(S.GUI.PreGoTrialNum+1):length(trial_seq_type):MaxTrials        
        TrialTypes(ii:ii+length(trial_seq_type)-1) = trial_seq_type(randperm(length(trial_seq_type)));        
    end
end

LaserTrial = zeros(1,MaxTrials);
if S.Laser
    seq_type = [1,0];
    for ii=(S.GUI.PreGoTrialNum+1):length(seq_type):MaxTrials
        LaserTrial(ii:ii+length(seq_type)-1) = seq_type(randperm(length(seq_type)));
    end
end

RewardTrial = ones(1,MaxTrials);
for ii=(S.GUI.PreGoTrialNum+1):length(S.reward_sequence):MaxTrials
    RewardTrial(ii:ii+length(S.reward_sequence)-1) = S.reward_sequence(randperm(length(S.reward_sequence)));
end

PunishTrial = ones(1,MaxTrials);
for ii=(S.GUI.PreGoTrialNum+1):length(S.punish_sequence):MaxTrials
    PunishTrial(ii:ii+length(S.punish_sequence)-1) = S.punish_sequence(randperm(length(S.punish_sequence)));
end

PunishDelay = repmat(S.GUI.PunishDelay,1,MaxTrials);
RewardDelay = repmat(S.GUI.RewardDelay,1,MaxTrials);

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
BpodSystem.Data.TrialRewarded = []; % The trial type of each trial completed will be added here.
BpodSystem.Data.RewardDelay = [];
BpodSystem.Data.PunishDelay = [];
BpodSystem.Data.ITI = [];
BpodSystem.Data.TrialUSLevels = []; % The trial type of each trial completed will be added here.
BpodSystem.Data.LaserTrial = [];
BpodSystem.Data.RewardTrial = [];
BpodSystem.Data.PunishTrial = [];

%% Initialize plots
BpodSystem.ProtocolFigures.SideOutcomePlotFig = figure('Position', [100 200 1200 300],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.SideOutcomePlot = axes('Position', [.075 .3 .89 .6]);
% BpodSystem.ProtocolFigures.LickPlotFig = figure('Position', [600 200 600 200],'name','Licking','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
GoNoGoOutcomePlot(BpodSystem.GUIHandles.SideOutcomePlot,'init',TrialTypes);

% Set soft code handler to trigger sounds
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySoundX';

SF = 192000; % Sound card sampling rate
SinWaveFreq1 = 12000;
sounddata1 = GenerateSineWave(SF, SinWaveFreq1, S.SoundDuration); % Sampling freq (hz), Sine frequency (hz), duration (s)
% SinWaveFreq2 = 4000;
% sounddata2 = GenerateSineWave(SF, SinWaveFreq2, S.SoundDuration); % Sampling freq (hz), Sine frequency (hz), duration (s)
sounddata2 = (rand(1,SF*S.SoundDuration)*2) - 1;

% Program sound server
PsychToolboxSoundServer('init')
PsychToolboxSoundServer('Load', 1, 0.68*sounddata1);
PsychToolboxSoundServer('Load', 2, 0.2*sounddata2);

%% Main trial loop
for currentTrial = 1:MaxTrials
    
    if currentTrial>S.SessionTrialNum
        error('Maximum trial number reached!');
    end
    
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    RewardValveTime = GetValveTimes(S.GUI.RewardAmount*TrialUSLevels(currentTrial), reward_valve_id); % Update reward amounts
  
    switch TrialTypes(currentTrial) % Determine trial-specific state matrix fields
        case 1 % reward trial
            ResponseTime = S.GUI.ResponseTimeGo;
            OutcomeDelay = S.GUI.RewardDelay;
            sound_arg = {'SoftCode', 1};
            Tup_Action = 'ITI';
            if RewardTrial(currentTrial)==1
                Tup_Action = 'Reward';
            elseif RewardTrial(currentTrial)==2
                Tup_Action = 'Reward';
                sound_arg = {};
            end
        case 0 % punishment trial
            ResponseTime = S.GUI.ResponseTimeNoGo;
            OutcomeDelay = S.GUI.PunishDelay;
            sound_arg = {'SoftCode', 2};
            Tup_Action = 'ITI';
            if PunishTrial(currentTrial)==1
                Tup_Action = 'Punishment';
            elseif PunishTrial(currentTrial)==2
                Tup_Action = 'Punishment';
                sound_arg = {};
            end           
    end
    
    if LaserTrial(currentTrial)
        laser_arg = {'GlobalTimerTrig', 2};
    else
        laser_arg = {};
    end
    
    sma = NewStateMatrix(); % Assemble state matrix
    
    if S.GUI.TrainingLevel==1 % habituation
        
        sma = AddState(sma, 'Name', 'TrialStart', ...
            'Timer', 0.1+1,... % time before trial start
            'StateChangeConditions', {'Tup', 'ResponseW'},...
            'OutputActions', {});
        sma = AddState(sma, 'Name', 'ResponseW', ...
            'Timer', 15,... % reponse time window
            'StateChangeConditions', {LickPort, 'Reward'},...
            'OutputActions', {});
        sma = AddState(sma, 'Name', 'Reward', ...
            'Timer', 0,... % reward delay
            'StateChangeConditions', {'Tup', 'DeliverReward'},...
            'OutputActions', {});
        sma = AddState(sma, 'Name', 'DeliverReward', ...
            'Timer', RewardValveTime,... % reward amount
            'StateChangeConditions', {'Tup', 'ITI'},...
            'OutputActions', {'ValveState', RewardValveState}); % 'SoftCode', soundID
        sma = AddState(sma, 'Name', 'ITI', ...
            'Timer', 1.*rand(1) + 0,...
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions', {});
        
    else % full task
        sma = SetGlobalTimer(sma, 'TimerID', 1, 'Duration', S.GUI.VideoDuration, 'OnsetDelay', 0, 'Channel', 'Wire1');
        sma = SetGlobalTimer(sma, 'TimerID', 2, 'Duration', S.LaserDuration, 'OnsetDelay', S.LaserDelayFromTrialOnset, 'Channel', 'BNC1');
        
        sma = AddState(sma, 'Name', 'Base', ...
            'Timer', 1,...
            'StateChangeConditions', {'Tup', 'TrialStart'},...
            'OutputActions', {});
        
        sma = AddState(sma, 'Name', 'TrialStart', ...
            'Timer', 2,...
            'StateChangeConditions', {'Tup', 'StimulusDeliver'},...
            'OutputActions', {'GlobalTimerTrig', 1});
        
        sma = AddState(sma, 'Name', 'StimulusDeliver', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'CueDelay'},...
            'OutputActions', [laser_arg, sound_arg]);
        sma = AddState(sma, 'Name', 'CueDelay', ...
            'Timer', S.CueDelay,...
            'StateChangeConditions', {'Tup', 'ResponseW'},...
            'OutputActions', {'BNC2',1});
        sma = AddState(sma, 'Name', 'ResponseW', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', Tup_Action},...
            'OutputActions', {});
        sma = AddState(sma, 'Name', 'Reward', ...
            'Timer', RewardDelay(currentTrial),...
            'StateChangeConditions', {'Tup', 'DeliverReward'},...
            'OutputActions', {});
        sma = AddState(sma, 'Name', 'Punishment', ...
            'Timer', PunishDelay(currentTrial),...
            'StateChangeConditions', {'Tup', 'DeliverPunishment'},...
            'OutputActions', {});
        sma = AddState(sma, 'Name', 'DeliverReward', ...
            'Timer', RewardValveTime,...
            'StateChangeConditions', {'Tup', 'ITI'},...
            'OutputActions', {'ValveState', RewardValveState});
        sma = AddState(sma, 'Name', 'DeliverPunishment', ...
            'Timer', S.GUI.PunishAmount,...
            'StateChangeConditions', {'Tup', 'ITI'},...
            'OutputActions', {'PWM3', 255});
        sma = AddState(sma, 'Name', 'ITI', ...
            'Timer', ITI(currentTrial),...
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions', {});
    end
    
    SendStateMatrix(sma);
    BpodSystem.Data.TrialStartTime_PC(currentTrial) = now;
    RawEvents = RunStateMatrix;
    
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data
        BpodSystem.Data.RewardDelay(currentTrial) = RewardDelay(currentTrial);
        BpodSystem.Data.PunishDelay(currentTrial) = PunishDelay(currentTrial);
        BpodSystem.Data.ITI(currentTrial) = ITI(currentTrial);
        BpodSystem.Data.TrialUSLevels(currentTrial) = TrialUSLevels(currentTrial);
        BpodSystem.Data.LaserTrial(currentTrial) = LaserTrial(currentTrial);
        BpodSystem.Data.RewardTrial(currentTrial) = RewardTrial(currentTrial);
        BpodSystem.Data.PunishTrial(currentTrial) = PunishTrial(currentTrial);
        
        %Outcome
        if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Reward(1))
            BpodSystem.Data.Outcomes(currentTrial) = 1;
        elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Punishment(1))
            BpodSystem.Data.Outcomes(currentTrial) = 0;
        elseif TrialTypes(currentTrial)==1
            BpodSystem.Data.Outcomes(currentTrial) = -1;
        else
            BpodSystem.Data.Outcomes(currentTrial) = 2;
        end

        UpdateTotalRewardDisplay(S.GUI.RewardAmount*TrialUSLevels(currentTrial), currentTrial);
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
    if ~isnan(Data.RawEvents.Trial{x}.States.Reward(1))
        Outcomes(x) = 1;
    elseif ~isnan(Data.RawEvents.Trial{x}.States.Punishment(1))
        Outcomes(x) = 0;
    elseif BpodSystem.Data.TrialTypes(x)==1
        Outcomes(x) = -1;
    else
        Outcomes(x) = 2;
    end
end
GoNoGoOutcomePlot(BpodSystem.GUIHandles.SideOutcomePlot,'update',Data.nTrials+1,TrialTypes,Outcomes);

function UpdateTotalRewardDisplay(RewardAmount, currentTrial)
% If rewarded based on the state data, update the TotalRewardDisplay
global BpodSystem
if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Reward(1))
    TotalRewardDisplay('add', RewardAmount);
end
