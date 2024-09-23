function plotDelay( planning , event )
%PLOTDELAY Plot delay for each event between the onset scheduled ans the
%onset timestamp
%
%  SYNTAX
%  plotDelay( planning , event )
%
%  INPUTS
%  1. planning is an UTILS.RECORDER.Planning object
%  2. event is an UTILS.RECORDER.Event object
%
%  NOTES
%  1. Time unit is millisecond (ms)
%
% See also UTILS.RECORDER.Planning, UTILS.RECORDER.Event, UTILS.plotStim


%% Check input data

% Must be 2 input arguments
assert(nargin == 2, '%s uses 2 input argument(s)', mfilename)

assert( isa(planning,'UTILS.RECORDER.Planning'), 'planning must be an object of class UTILS.RECORDER.Planning')
assert( isa(event   ,'UTILS.RECORDER.Event'   ), 'event must be an object of class UTILS.RECORDER.event'      )


%% How many events can we use ?

range = min( planning.count , event.count );

% -1 to not take into acount END
if planning.count > event.count
    range = range - 1 ;
end

[event_name, idx_data2envent , idx_event2data] = unique( event.data(1:range,1), 'stable' );

Colors = lines( length(event_name) );


%% Prepare curves

icol_onset    = planning.icol_onset;
icol_duration = planning.icol_duration;

planned_onset     = cell2mat(planning.data(1:range,icol_onset));
recorded_onset    = cell2mat(event.data(1:range,icol_onset));
onset_delay       = (recorded_onset - planned_onset) * 1000;

planned_duration  = cell2mat(planning.data(1:range,icol_duration));
recorded_duration = cell2mat(event.data(1:range,icol_duration));
duration_delay    = (recorded_duration - planned_duration) * 1000;

% Build a structure to gather all infos ready to be plotted
CurvesDelay    = struct;
CurvesDuration = struct;
for c = 1 : length(event_name)

    CurvesDelay(c).name     = event_name{c};
    CurvesDelay(c).color    = Colors(c,:);
    CurvesDelay(c).X        = planned_onset((idx_event2data == c));
    CurvesDelay(c).Y        = onset_delay((idx_event2data == c));

    CurvesDuration(c).name  = event_name{c};
    CurvesDuration(c).color = Colors(c,:);
    CurvesDuration(c).X     = planned_onset((idx_event2data == c));
    CurvesDuration(c).Y     = duration_delay((idx_event2data == c));

end

%% Plot

% Command window display
t = table(event.data(1:range,1), planned_onset, recorded_onset, onset_delay, planned_duration, recorded_duration, duration_delay);
t.Properties.VariableNames = { 'event_name' 'p_ons (s)' 'r_ons (s)' 'd_ons (ms)' 'p_dur (s)' 'r_dur (s)' 'd_dur (ms)' };
disp(t)

% Figure
figure('Name',mfilename, 'NumberTitle','off')

% --- First graph ---------------------------------------------------------
graph_parts(1) = subplot(2,1,1);
hold all

% Plot each event type
for c = 1 : length(event_name)
    stem( graph_parts(1) , CurvesDelay(c).X , CurvesDelay(c).Y , 's' , 'Color' , CurvesDelay(c).color )
end

% Curve that crosses each point
plot( planned_onset , onset_delay ,':' , 'Color' , [0 0 0] )

xlabel('time (s)','interpreter','none')
ylabel('onset_delay (ms)','interpreter','none')

lgd = legend([ event_name ; 'onset_delay(time)' ]);
set(lgd,'interpreter','none','Location','Best')

UTILS.ScaleAxisLimits()


% --- Second graph --------------------------------------------------------
graph_parts(2) = subplot(2,1,2);
hold all

% Plot each event type
for c = 1 : length(event_name)
    stem( graph_parts(2) , CurvesDuration(c).X , CurvesDuration(c).Y , 's' , 'Color' , CurvesDuration(c).color )
end

% Curve that crosses each point
plot( planned_onset , duration_delay ,':' , 'Color' , [0 0 0] )

xlabel('time (s)','interpreter','none')
ylabel('duration_delay (ms)','interpreter','none')

event_dur1 = num2str( planned_duration(idx_data2envent) );
event_dur2 = cellstr( event_dur1 );
event_dur3 = regexprep( event_dur2 , ' ' , '' );
event_dur4 = strcat(event_dur3, ' (s)');

lgd = legend([ event_dur4 ; 'duration_delay(time)' ]);
set(lgd,'interpreter','none','Location','Best')

UTILS.ScaleAxisLimits()


end % fcn
