function [R, names] = Generate_SPM_NamesOnsetsDurations_regressor()
global S

U(1).u    = S.recSensor.data(:,S.recSensor.Get('target'));
U(1).name = {'target'};

U(2).u    = S.recSensor.data(:,S.recSensor.Get('sensor'));
U(2).name = {'sensor'};


xBF.T      = 16;
xBF.T0     = 8;
xBF.dt     = S.Window.ifi; % use our sampling time
xBF.name   = 'hrf';

xBF        = UTILS.SPM.spm_get_bf(xBF); % get HRF

X          = UTILS.SPM.spm_Volterra(U, xBF.bf, 1); % convolution

TR = CONFIG.TR();
n_volume = ceil((S.ENDtime-S.STARTtime)/TR);

% time_highres_reg = (0:(size(X,1)-1))*S.Window.ifi;
idx_time_reg_at_TR = round(linspace(1, size(X,1), n_volume));

R     = X(idx_time_reg_at_TR,:);
names = [U.name];


end % fcn
