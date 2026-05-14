function Naive_US
% SETUP
% > Connect the water valve in the box to Bpod Port#1.
% > Connect the air valve in the box to Bpod Port#2.
% > Lick: Bpod Port#1
% > port #2: air-puff
% > BNC2 #2: shock
% > port #3: sucrose
% > port #4: quinine
% > BNC1: Laser
% > Hanfei Deng,12/22/2022

global BpodSystem

%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    
    S.GUI.WaterAmount = 6; % water (ul)
    S.GUI.AirpuffAmount = 0.2; % s
    S.GUI.ShockAmount = 2; % 1 s
    
    S.GUI.SucroseAmount = 8; % sucrose (ul)
    S.GUI.QuinineAmount = 5; % quinine (ul)
    
    S.GUI.LaserAmount = 5; % the duration of laser stimulation
    
    S.GUI.PreGoTrialNum = 0;
    
    US_Levels = [1,1,1,1,1,1]; % 1,1,2,2,4,4
    us_level_bock_design_or = 0;
    
    S.ITI = 30; % for shock 30 s
    ITI_min=S.ITI-2; ITI_max=S.ITI+2;
    
    block_design_or = 1; % 1, block design; 0, random
    % Trial identity: 1=water 2=sucrose  0=quinine -1=sham  -2=shock
    % 3=odor
    % trial_seq_type = [-1,-1]; % airpuff
%     trial_seq_type = [-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2]; % shock
    % trial_seq_type = [1,-1, 3]; % water, airpuff, laser
%     trial_seq_type = [-1,-1]; % water, airpuff, laser
    trial_seq_type = [repmat([-1,3],1,15)]% [1,1,1,1] [1,1,2,2]   [1,1,1,1,1,2,2,2,2,2,0,0,0,0,0]
    % trial_seq_type = [zeros(1,20)];
    
    S.GUI.RecordDuration = 8;
    
end

if S.GUI.RecordDuration>ITI_min
    error('ITI is too short!');
end

%% ==================== Custom Configuration ==============================
% Code
% LickPort = 'Port1In';
water_value_id = 1;
sucrose_value_id = 3;
quinine_value_id = 4;
airpuff_valve_id = 2;
% water, sucrose and quinine
SucroseValveState = 2^(sucrose_value_id-1);
WaterValveState = 2^(water_value_id-1);
QuinineValveState = 2^(quinine_value_id-1);
AirpuffValveState = 2^(airpuff_valve_id-1);

%% ========================================================================
% Initialize parameter GUI plugin
BpodParameterGUI('init', S);
TotalRewardDisplay('init');

%% Define trials
MaxTrials = 500;
TrialTypes = ones(1,MaxTrials).*0.5;
TrialUSLevels = ones(1,MaxTrials);

if block_design_or
    TrialTypes(S.GUI.PreGoTrialNum+1:S.GUI.PreGoTrialNum+1+length(trial_seq_type)-1) = trial_seq_type;
else
    for ii=(S.GUI.PreGoTrialNum+1):length(trial_seq_type):MaxTrials
        TrialTypes(ii:ii+length(trial_seq_type)-1) = trial_seq_type(randperm(length(trial_seq_type)));
    end
end

for ii=(S.GUI.PreGoTrialNum+1):length(US_Levels):MaxTrials
    if us_level_bock_design_or
        TrialUSLevels(ii:ii+length(US_Levels)-1) = US_Levels;
    else
        TrialUSLevels(ii:ii+length(US_Levels)-1) = US_Levels(randperm(length(US_Levels)));
    end
end

R = repmat(S.ITI,1,MaxTrials);
for k=1:MaxTrials
    candidate_delay = exprnd(S.ITI);
    while candidate_delay>ITI_max || candidate_delay<ITI_min
        candidate_delay = exprnd(S.ITI);
    end
    R(k) = candidate_delay;
end
ITI = R;

BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
BpodSystem.Data.TrialUSLevels = []; % The trial type of each trial completed will be added here.
BpodSystem.Data.TrialRewarded = []; % The trial type of each trial completed will be added here.
BpodSystem.Data.ITI = [];
BpodSystem.Data.LaserTrial = [];

%% Initialize plots
BpodSystem.ProtocolFigures.SideOutcomePlotFig = figure('Position', [100 200 1200 300],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.SideOutcomePlot = axes('Position', [.075 .3 .89 .6]);
GoNoGoOutcomePlot(BpodSystem.GUIHandles.SideOutcomePlot,'init',TrialTypes);

%% Main trial loop
for currentTrial = 1:MaxTrials
    
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    SucroseValveTime = GetValveTimes(S.GUI.SucroseAmount*TrialUSLevels(currentTrial), sucrose_value_id); % Update sucrose amounts
    WaterValveTime = GetValveTimes(S.GUI.WaterAmount*TrialUSLevels(currentTrial), water_value_id); % Update water amounts
    QuinineValveTime = GetValveTimes(S.GUI.QuinineAmount*TrialUSLevels(currentTrial), quinine_value_id); % Update quinine amounts
    AirpuffValveTime = S.GUI.AirpuffAmount*TrialUSLevels(currentTrial);
    ShockValveTime = S.GUI.ShockAmount*TrialUSLevels(currentTrial);
    LaserValveTime = S.GUI.LaserAmount*TrialUSLevels(currentTrial);
    
    switch TrialTypes(currentTrial) % Determine trial-specific state matrix fields
        case 2 % sucrose trial
            Tup_Action = 'SucroseReward';
        case 1 % water trial
            Tup_Action = 'WaterReward';
        case 0 % quinine trial
            Tup_Action = 'QuininePunishment';
        case -1 % air-puff trial
            Tup_Action = 'AirpuffPunishment';
        case -2 % shock trial
            Tup_Action = 'ShockPunishment';
        case 3 % laser trial
            Tup_Action = 'Laser';
        case 0.5 % empty trial
            Tup_Action = 'ITI';
    end
    
    sma = NewStateMatrix(); % Assemble state matrix
    sma = SetGlobalTimer(sma, 'TimerID', 1, 'Duration', S.GUI.RecordDuration, 'OnsetDelay', 1, 'Channel', 'Wire1');
    sma = SetGlobalTimer(sma, 'TimerID', 2, 'Duration', 5, 'OnsetDelay', 0, 'Channel', 'BNC2'); % BNC2 (for marker of photometry
    
    sma = AddState(sma, 'Name', 'TrialStart0', ...
        'Timer', 1,...
        'StateChangeConditions', {'Tup', 'TrialStart'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'TrialStart', ...
        'Timer', 3,...
        'StateChangeConditions', {'Tup', 'USDeliver'},...
        'OutputActions', {'GlobalTimerTrig', 1});
    sma = AddState(sma, 'Name', 'USDeliver', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', Tup_Action},...
        'OutputActions', {'GlobalTimerTrig', 2});
    sma = AddState(sma, 'Name', 'SucroseReward', ...
        'Timer', SucroseValveTime,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'ValveState', SucroseValveState});
    sma = AddState(sma, 'Name', 'WaterReward', ...
        'Timer', WaterValveTime,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'ValveState', WaterValveState});
    sma = AddState(sma, 'Name', 'QuininePunishment', ...
        'Timer', QuinineValveTime,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'ValveState', QuinineValveState});
    sma = AddState(sma, 'Name', 'AirpuffPunishment', ...
        'Timer', AirpuffValveTime,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'ValveState', AirpuffValveState});
    sma = AddState(sma, 'Name', 'ShockPunishment', ...
        'Timer', ShockValveTime,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'PWM5', 255});
    sma = AddState(sma, 'Name', 'Laser', ...
        'Timer', LaserValveTime,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'BNC1', 1});
    sma = AddState(sma, 'Name', 'ITI', ...
        'Timer', ITI(currentTrial),...
        'StateChangeConditions', {'Tup', 'TaskEnd'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'TaskEnd', ...
        'Timer', 1,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {});
    
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data
        BpodSystem.Data.TrialUSLevels(currentTrial) = TrialUSLevels(currentTrial);
        BpodSystem.Data.ITI(currentTrial) = ITI(currentTrial);
        
        %Outcome
        if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.SucroseReward(1)) || ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaterReward(1))
            BpodSystem.Data.Outcomes(currentTrial) = 1;
        elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.QuininePunishment(1)) || ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.AirpuffPunishment(1))
            BpodSystem.Data.Outcomes(currentTrial) = 0;
        elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.ShockPunishment(1))
            BpodSystem.Data.Outcomes(currentTrial) = -1;
        elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Laser(1))
            BpodSystem.Data.Outcomes(currentTrial) = 3;
        else
            BpodSystem.Data.Outcomes(currentTrial) = -2;
        end
        
        UpdateTotalRewardDisplay(S.GUI.SucroseAmount, currentTrial);
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
    if ~isnan(Data.RawEvents.Trial{x}.States.SucroseReward(1)) || ~isnan(Data.RawEvents.Trial{x}.States.WaterReward(1))
        Outcomes(x) = 1;
    elseif ~isnan(Data.RawEvents.Trial{x}.States.QuininePunishment(1)) || ~isnan(Data.RawEvents.Trial{x}.States.AirpuffPunishment(1))
        Outcomes(x) = 0;
    elseif ~isnan(Data.RawEvents.Trial{x}.States.ShockPunishment(1))
        Outcomes(x) = -1;
    elseif ~isnan(Data.RawEvents.Trial{x}.States.Laser(1))
        Outcomes(x) = 3;
    else
        Outcomes(x) = -2;
    end
end
GoNoGoOutcomePlot(BpodSystem.GUIHandles.SideOutcomePlot,'update',Data.nTrials+1,TrialTypes,Outcomes,Data.TrialUSLevels);

function UpdateTotalRewardDisplay(RewardAmount, currentTrial)
% If rewarded based on the state data, update the TotalRewardDisplay
global BpodSystem
if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.SucroseReward(1)) || ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaterReward(1))
    TotalRewardDisplay('add', RewardAmount);
end
