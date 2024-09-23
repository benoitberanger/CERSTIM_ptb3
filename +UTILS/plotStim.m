function plotStim( planning , event , keylogger )
%PLOTSTIM Plot all events from a run : events planned, events recorded, mri
%triggersUTILS.plotDelay
%
%  SYNTAX
%  plotStim( planning , event , keylogger )
%
%  INPUTS
%  1. eventplanning is a UTILS.RECORDER.Planning  object
%  2. eventrecorder is a UTILS.RECORDER.Event     object
%  3. kblogger      is a UTILS.RECORDER.Keylogger object
%
% See also UTILS.RECORDER.Planning, UTILS.RECORDER.Event, UTILS.RECORDER.Keylogger, UTILS.plotDelay


%% Check input data

% Must be 3 input arguments, or try with the base workspace
assert(nargin == 3, '%s uses 3 input argument(s)',mfilename)

assert( isa(planning,'UTILS.RECORDER.Planning'  ), 'planning must be an object of class UTILS.RECORDER.Planning'  )
assert( isa(event    ,'UTILS.RECORDER.Event'    ), 'event must be an object of class UTILS.RECORDER.event'        )
assert( isa(keylogger,'UTILS.RECORDER.Keylogger'), 'keylogger must be an object of class UTILS.RECORDER.Keylogger')


%% Preparation of curves

if isempty(planning .graph_data),  planning.BuildGraph(); end
if isempty(event    .graph_data),     event.BuildGraph(); end
if isempty(keylogger.graph_data), keylogger.BuildGraph(); end

n_line = length(planning.graph_data) + length(keylogger.graph_data);
colors = lines( n_line  );


%% Plot

% Figure
f = figure('Name',mfilename, 'NumberTitle','off');
a = axes(f);
hold(a, 'all');

label = {};

color_count = 0;
for evt = 1 : length(planning.graph_data)
    color_count = color_count + 1;
    label{end+1} = planning.graph_data(evt).name;
    plot(a, planning.graph_data(evt).x, planning.graph_data(evt).y + evt-1, ...
        'Color', colors(color_count,:), 'LineStyle', '-', 'LineWidth', 2.0, 'DisplayName', label{end})
end

color_count = 0;
for evt = 1 : length(event.graph_data)
    color_count = color_count + 1;
    plot(a,    event.graph_data(evt).x,    event.graph_data(evt).y + evt-1 +0.1   , ...
        'Color', colors(color_count,:), 'LineStyle','-.', 'LineWidth', 1.0, 'DisplayName', event.graph_data(evt).name)
end

color_count = length(planning.graph_data);
scale = color_count;
for evt = 1 : length(keylogger.graph_data)
    color_count = color_count + 1;
    label{end+1} = keylogger.graph_data(evt).name;
    plot(a, keylogger.graph_data(evt).x, keylogger.graph_data(evt).y * (scale+evt), ...
        'Color', colors(color_count,:), 'LineStyle', ':', 'LineWidth', 0.5, 'DisplayName', label{end})
end

legend('interpreter','none','Location','Best');


%%  Adapt the graph axes limits

% Change the limit of the graph so we can clearly see the
% rectangles.
UTILS.ScaleAxisLimits(a)


%% Change YTick and YTickLabel

set(a, 'YTick'               , (1:length(label)) - 0.5 )
set(a, 'YTickLabel'          , label )
set(a, 'TickLabelInterpreter', 'none')


end % fcn
