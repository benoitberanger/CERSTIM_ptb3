function plotSPMnod(names, onsets, durations, pmod )
%PLOTSPMNOD plots names onsets and durations (n.o.d.) defined for SPM
%
%  SYNTAX
%  plotSPMnod( names , onsets , durations )
%
%  INPUTS
%  1. names     : cellstr
%  2. onsets    : cell of vectors
%  3. durations : cell of vectors
% (4) pmod      : struct('name',{''},'param',{},'poly',{})
%
%  OPTIONAL
%  pmod : parametric modulators
%
% See also spm


args   = {'names','onsets','durations'};
n_args = length(args);


%% Check input arguments

% Correct arguments ?
l_args = nan(size(args));
for iarg = 1 : n_args
    assert(exist(args{iarg},'var'), 'required argument %d : %s', iarg, args{iarg})
    validateattributes(eval(args{iarg}),{'cell'},{'vector'},mfilename,args{iarg},iarg)
    l_args(iarg) = length(eval(args{iarg}));
end

% All inputs with the same dimension ?
collinear = cross( l_args , ones(size(args)) ); % is l_args vector collinear to [1 ; 1 ; 1] ?
assert(~any(collinear), ...
    'All inputs must have the same dimensions : n=%d o=%d d=%d', ...
    l_args(1), l_args(2), l_args(3))

% names is only strings ?
assert(iscellstr(names),'names must be a cell array of strings')

% check onsets and durations size
for ireg  = 1 : l_args(1)
    assert(length(onsets{ireg}) == length(durations{ireg}) , ...
        'onsets{%d} and durations{%d} have different dimensions : %d and %d ' , ...
        ireg , ireg , length(onsets{ireg}) , length(durations{ireg}) )
    assert(isnumeric(onsets   {ireg}),    'onsets{%d} must be numeric ', ireg )
    assert(isnumeric(durations{ireg}), 'durations{%d} must be numeric ', ireg )
end

% check good structure of pmod
use_pmod = exist('pmod','var');
if use_pmod
    validateattributes(pmod,{'struct'},{'vector','nonempty'},mfilename,'pmod',4)
    fields = fieldnames(pmod);
    assert(any(strcmp(fields, 'name')) || any(strcmp(fields, 'param')) || any(strcmp(fields, 'poly')), 'pmod must have fieds `name`, param`, `poly')
    for p = 1 : length(pmod)
        if ~isempty(pmod(p).name)
            validateattributes(pmod(p).param,{'cell'},{'vector','nonempty'},mfilename,'pmod(p).name')
            assert(all(cellfun(@length, pmod(p).param) == length(onsets{p})), 'all modulators must have the same length as the onsets/durations vectors')
        end
    end
end


%% Prepare curves

% structure to hold the data in convenient way
graph_data = struct;
for ireg = 1:length(names)
    graph_data(ireg).name     = names    {ireg};
    graph_data(ireg).onset    = onsets   {ireg};
    graph_data(ireg).duration = durations{ireg};
    graph_data(ireg).has_pmod = false;
    if use_pmod && ireg<=length(pmod) && ~isempty(pmod(ireg).name)
        graph_data(ireg).has_pmod = true;
        graph_data(ireg).pmod = pmod(ireg);
    end
end

for ireg = 1 : length(graph_data) % For each regressor

    n_mod = 0;
    if graph_data(ireg).has_pmod
        n_mod = length(graph_data(ireg).pmod.param);
    end

    N    = length(graph_data(ireg).onset);
    pts  = 5; % build : rectangle -> 4 corners + 1 invisible point between event
    data = nan(N*pts,2+n_mod);

    for n = 1 : N

        if graph_data(ireg).has_pmod
            all_mudulators = cell2mat(graph_data(ireg).pmod.param);
            all_mudulators = all_mudulators ./ max(abs(all_mudulators),[],1) / 2; % normalize them
        end

        % 4 corner X
        data(pts*n+0,1) = graph_data(ireg).onset(n);
        data(pts*n+1,1) = graph_data(ireg).onset(n);
        data(pts*n+2,1) = graph_data(ireg).onset(n) + graph_data(ireg).duration(n);
        data(pts*n+3,1) = graph_data(ireg).onset(n) + graph_data(ireg).duration(n);

        % 4 corners Y
        data(pts*n+0,2:end) = 0;
        data(pts*n+1,2:end) = 1;
        data(pts*n+2,2:end) = 1;
        data(pts*n+3,2:end) = 0;
        if graph_data(ireg).has_pmod
            data(pts*n+1,3:end) = all_mudulators(n,:);
            data(pts*n+2,3:end) = NaN;
            data(pts*n+3,3:end) = NaN;
        end

        % +1 invisible point between events
        if n < N
            data(pts*n+4,1) = graph_data(ireg).onset(n+1);
            data(pts*n+4,2:end) = NaN;
        end

    end

    % Store curves
    graph_data(ireg).x = data(:,1);
    graph_data(ireg).y = data(:,2);

    if graph_data(ireg).has_pmod
        graph_data(ireg).pmod.y = data(:,3:end);
    end

end % e


%% Plot

% Figure
f = figure('Name', mfilename, 'NumberTitle', 'off');
a = axes(f);
hold(a,'on')

% For each Event, plot the curve
offcet = 0;
center = [];
for e = 1 : length(graph_data)

    offcet = offcet + 1; % shift of 1, because events are {0,1} rects
    center(end+1) = offcet + 0.5;
    plot(a, graph_data(e).x, graph_data(e).y + offcet, 'DisplayName', graph_data(e).name)

    if graph_data(e).has_pmod
        offcet = offcet + 0.5; % initial shift of +0.5 because modulators are {-0.5,+0.5} rects

        for m = 1 : length(graph_data(e).pmod.name)
            offcet = offcet + 1;
            plot(a, graph_data(e).x, graph_data(e).pmod.y(:,m) + offcet, ...
                'Marker','.', 'MarkerSize', 0.1, 'DisplayName',[graph_data(e).name ' x ' graph_data(e).pmod.name{m}])
            % marker : just used to force rendering a modulator=0 points
            center(end+1) = offcet;
        end
    end
end

% Legend
lgd = legend(a,'Interpreter','none','Location','Best');
labels = get(lgd,'String');

% Put 1 tick in the middle of each event
set(a, 'YTick', center )
set(a, 'YTickLabel', labels )
set(a, 'TickLabelInterpreter', 'none')

% Change the limit of the graph so we can clearly see the rectangles.
UTILS.ScaleAxisLimits(a)


end
