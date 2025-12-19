function SessionData = CutOutSessionData_GNG(SessionDataOri,varargin)
% This function is to cut off Bpod SessionData with given starting and ending trial number
% Input CutOutSessionData(StartTrial,EndTrial,SessionDataOri)
% Example: SessionData_revised = CutOutSessionData(10,100,SessionData)
% Warning: Only for GNG Task Data

SessionData = SessionDataOri;
Names = fieldnames(SessionDataOri);
Names_Raw = fieldnames(SessionDataOri.RawData);

p = inputParser;            % 函数的输入解析器
addParameter(p,'StartTrial',1);      % 设置变量名和默认参数
addParameter(p,'EndTrial',SessionDataOri.nTrials);
parse(p,varargin{:});       % 对输入变量进行解析，如果检测到前面的变量被赋值，则更新变量取值

StartTrial = p.Results.StartTrial;
EndTrial = p.Results.EndTrial;


for i = 1:length(Names)
    
    k = Names(i);
    key = k{1};
    
    switch i
        case 2
            continue
        case 7
            continue
        case 8
            SessionData.(key) = EndTrial - StartTrial + 1;
        case 9
            SessionData.(key).Trial = SessionDataOri.(key).Trial(StartTrial:EndTrial);
        case 10
            for j = 1:length(Names_Raw)
                k_raw = Names_Raw(j);
                key_raw = k_raw{1};
                SessionData.(key).(key_raw) = SessionDataOri.(key).(key_raw)(StartTrial:EndTrial);
            end
        case 13
            continue
        otherwise
            SessionData.(key) = SessionDataOri.(key)(StartTrial:EndTrial);
    end
end
end