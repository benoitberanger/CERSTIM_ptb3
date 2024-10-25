function [R, names] = Generate_SPM_NamesOnsetsDurations_regressor()
global S

%% Prepare input

target = S.recSensor.data(:,S.recSensor.Get('target'));
sensor = S.recSensor.data(:,S.recSensor.Get('sensor_value'));
err    = sqrt( abs((target-sensor)).^2 );

U(1).u    = target;
U(1).name = {'target'};

U(2).u    = sensor;
U(2).name = {'sensor'};

U(3).u    = err;
U(3).name = {'error'};


%% Generate regressors

% Convolve
xBF.T      = 16;
xBF.T0     = 8;
xBF.dt     = S.Window.ifi; % use our sampling time
xBF.name   = 'hrf';
xBF        = UTILS.SPM.spm_get_bf(xBF); % get HRF
X          = UTILS.SPM.spm_Volterra(U, xBF.bf, 1); % convolution

% Downsample at TR
TR = CONFIG.TR();
n_volume = ceil((S.ENDtime-S.STARTtime)/TR);
idx_time_reg_at_TR = round(linspace(1, size(X,1), n_volume));
R = X(idx_time_reg_at_TR,:);

names = [U.name];


end % fcn
