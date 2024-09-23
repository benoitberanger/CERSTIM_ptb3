classdef (Abstract) Stim < UTILS.RECORDER.Cell

    properties(GetAccess = public, SetAccess = public)
        header_data (1,:) cell   = {''} % Description of each columns EXEPT `name` `onset` `duration`
    end % properties

    properties(GetAccess = public, SetAccess = public, Abstract)
        display_symbol (1,1) char
    end % properties

    properties(GetAccess = public, SetAccess = protected)
        icol_name     (1,1) double = 1
        icol_onset    (1,1) double = 2
        icol_duration (1,1) double = 3
        icol_data     (1,1) double = 4
        graph_data    (1,:) struct
    end % props

    methods(Access = public)

        %---- Constructor -------------------------------------------------
        function self = Stim(nline,header_data)
            self = self@UTILS.RECORDER.Cell([{'name', 'onset', 'duration'} header_data], nline+2) % +2 : AddStart + AddEnd
            self.header_data = header_data;
            self.description = class(self);
        end

        %------------------------------------------------------------------
        function AddStim(self, name, onset, duration, data)
            if nargin < 5
                data = cell(size(self.header_data));
            end
            self.AddLine([{name, onset, duration} data])
        end % fcn

        %------------------------------------------------------------------
        function AddStart( self, starttime )
            if nargin < 2
                starttime = 0;
            end
            self.AddStim(self.label_start, starttime, 0);
        end % fcn

        %------------------------------------------------------------------
        function AddEnd( self, endtime )
            if nargin < 2
                endtime = 0;
            end
            self.AddStim(self.label_end, endtime, 0);
        end % fcn

        %------------------------------------------------------------------
        function ComputeDurations( self )

            % Compute durations for each onsets
            onsets               = cell2mat( self.data(:,self.icol_onset) ); % Get the times
            durations            = diff(onsets);                             % Compute the differences
            self.data(1:end-1,self.icol_duration) = num2cell( durations );   % Save durations

            % For the last event, usually `label_stop`, we need an exception.
            if strcmp( self.data{end,self.icol_name} , self.label_end )
                self.data{end,self.icol_duration} = 0;
            end

        end % fcn

        %------------------------------------------------------------------
        function ScaleTime( self, t0 )
            % Scale the time origin to the first entry in self.data
            if nargin < 2
                t0 = self.data( 1 , self.icol_onset );
            end
            time = cell2mat( self.data( : , self.icol_onset ) ); % Onsets of events
            if isempty(time)
                warning('no data ?')
                if self.count == 0
                    warning('no data : self.count=0')
                    return
                end
            end
            self.data( : , self.icol_onset ) = num2cell( time - t0 );
        end % fcn

        %------------------------------------------------------------------
        function BuildGraph( self )
            % Build curves for each events, ready to be plotted.

            % ===================== Regroup each event ====================

            % Check if not empty
            self.IsEmptyProp('data');

            [ event_name , ~ , idx_event2data ] = unique(self.data(:,self.icol_name), 'stable');

            self.graph_data = struct;

            for e = 1:length(event_name)
                self.graph_data(e).name     = event_name{e};
                self.graph_data(e).onset    = cell2mat ( self.data( idx_event2data == e , self.icol_onset    ) );
                self.graph_data(e).duration = cell2mat ( self.data( idx_event2data == e , self.icol_duration ) );
            end

            % ================= Build curves for each Event ===============

            for e = 1 : length(self.graph_data) % For each Event

                N   = length(self.graph_data(e).onset);
                pts = 5; % build : rectangle -> 4 corners + 1 invisible point between event
                data = nan(N*pts,2);

                for n = 1 : N

                    % 4 corner X
                    data(pts*n+0,1) = self.graph_data(e).onset(n);
                    data(pts*n+1,1) = self.graph_data(e).onset(n);
                    data(pts*n+2,1) = self.graph_data(e).onset(n) + self.graph_data(e).duration(n);
                    data(pts*n+3,1) = self.graph_data(e).onset(n) + self.graph_data(e).duration(n);

                    % 4 corners Y
                    data(pts*n+0,2) = 0;
                    data(pts*n+1,2) = 1;
                    data(pts*n+2,2) = 1;
                    data(pts*n+3,2) = 0;

                    % +1 invisible point between events
                    if n < N
                        data(pts*n+4,1) = self.graph_data(e).onset(n+1);
                        data(pts*n+4,1) = NaN;
                    end

                end

                % Store curves
                self.graph_data(e).x = data(:,1);
                self.graph_data(e).y = data(:,2);

            end % e

        end % fcn

        %------------------------------------------------------------------
        function Plot( self )
            % =============== BuildGraph if necessary =====================

            % Each subclass has its own BuildGraph() method because Data
            % properties are different. But each BuildGraph subclass method
            % converge to a uniform graph_data.

            if isempty(self.graph_data)
                self.BuildGraph();
            end

            % Figure
            figure('Name', [ inputname(1) ' : ' class(self) ], 'NumberTitle' ,'off')
            hold all

            % For each Event, plot the curve
            for e = 1 : length(self.graph_data)

                switch self.display_symbol
                    case '+'
                        plot( self.graph_data(e).x, self.graph_data(e).y + e )
                    case '*'
                        plot( self.graph_data(e).x , self.graph_data(e).y * e )
                    otherwise
                        error('Unknown display_symbol')
                end
            end

            % Legend
            lgd = legend( {self.graph_data.name} );
            set(lgd,'Interpreter','none','Location','Best')

            % ================ Adapt the graph axes limits ================

            % Change the limit of the graph so we can clearly see the
            % rectangles.

            UTILS.ScaleAxisLimits( gca , 1.1 )

            % ================ Change YTick and YTickLabel ================

            % Put 1 tick in the middle of each event
            switch self.display_symbol
                case '+'
                    set( gca , 'YTick' , (1:length(self.graph_data))+0.5 )
                case '*'
                    set( gca , 'YTick' , (1:length(self.graph_data))     )
            end

            % Set the tick label to the event name
            set(gca , 'YTickLabel' , {self.graph_data.name} )

            % Not all versions of MATLAB have this option
            set(gca, 'TickLabelInterpreter', 'none')

        end % fcn

        %------------------------------------------------------------------
        function PlotHRF( self, TR, nrVolumes )
            %PLOTHRF convolves the events with HRF, using SPM pipeline
            % TR is required to estimate the stimulus response function


            %=== Checks

            % SPM
            assert( ~isempty( which('spm_hrf') ) , 'SPM toolbox is required' )

            % Data
            assert( size(self.data,1)>1, 'Empty data' )

            % TR
            assert( nargin>=1, 'TR is required to estimate the stimulus response function' )
            assert( isnumeric(TR) && isscalar(TR) && TR>0, 'TR must be positive' )

            % nrVolumes
            if nargin < 3
                nrVolumes = ceil( self.data{end,2}/TR ) + 1;
            end
            assert( isnumeric(nrVolumes) && isscalar(nrVolumes) && nrVolumes>0 && nrVolumes==round(nrVolumes) , 'nrVolumes must be positive integer' )


            %=== Format self.data into names onsets durations

            [names,~,indC] = unique( self.data(:,1) , 'stable' );

            onsets    = cell(size(names));
            durations = cell(size(names));

            for n = 1 : length(names)
                onsets{n}    = cell2mat( self.data(indC==n,2) );
                durations{n} = cell2mat( self.data(indC==n,3) );
            end % names


            %=== Pipe my environement with SPM

            SPM.xY.RT = TR;
            SPM.nscan = nrVolumes;

            multicond           = struct;
            multicond.names     = names;
            multicond.onsets    = onsets;
            multicond.durations = durations;

            SPM.xBF.name = 'hrf'; % it means cannonical HRF
            SPM.xBF.UNITS = 'secs';


            %=== SPM : part 1

            %-Microtime onset and microtime resolution
            %--------------------------------------------------------------------------
            fMRI_T     = spm_get_defaults('stats.fmri.t');
            fMRI_T0    = spm_get_defaults('stats.fmri.t0');
            SPM.xBF.T  = fMRI_T;
            SPM.xBF.T0 = fMRI_T0;

            %-Time units, dt = time bin {secs}
            %--------------------------------------------------------------------------
            SPM.xBF.dt     = SPM.xY.RT/SPM.xBF.T;

            %-Get basis functions
            %--------------------------------------------------------------------------
            SPM.xBF        = spm_get_bf(SPM.xBF);


            %=== SPM : part 2

            i = 1;

            sess.cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});

            % %-Load MAT-file
            % %------------------------------------------------------------------
            % try
            %     multicond = load('/mnt/data/benoit/Protocol/NBI/fmri/behaviour_data/spmReady_MTMST_files/2016_04_29_NBI_Pilote01/MT_LEFT.mat');
            % catch
            %     error('Cannot load %s',sess.multi{1});
            % end

            %-Check structure content
            %------------------------------------------------------------------
            if ~all(isfield(multicond, {'names','onsets','durations'})) || ...
                    ~iscell(multicond.names) || ...
                    ~iscell(multicond.onsets) || ...
                    ~iscell(multicond.durations) || ...
                    ~isequal(numel(multicond.names), numel(multicond.onsets), ...
                    numel(multicond.durations))
                error(['Multiple conditions MAT-file ''%s'' is invalid:\n',...
                    'File must contain names, onsets, and durations '...
                    'cell arrays of equal length.\n'],sess.multi{1});
            end

            for j=1:numel(multicond.onsets)

                %-Mutiple Conditions: names, onsets and durations
                %--------------------------------------------------------------
                cond.name     = multicond.names{j};
                if isempty(cond.name)
                    error('MultiCond file: sess %d cond %d has no name.',i,j);
                end
                cond.onset    = multicond.onsets{j};
                if isempty(cond.onset)
                    error('MultiCond file: sess %d cond %d has no onset.',i,j);
                end
                cond.duration = multicond.durations{j};
                if isempty(cond.onset)
                    error('MultiCond file: sess %d cond %d has no duration.',i,j);
                end

                %-Mutiple Conditions: Time Modulation
                %--------------------------------------------------------------
                if ~isfield(multicond,'tmod'); %#ok<*NOSEL>
                    cond.tmod = 0;
                else
                    try
                        cond.tmod = multicond.tmod{j};
                    catch
                        error('Error specifying time modulation.');
                    end
                end

                %-Mutiple Conditions: Parametric Modulation
                %--------------------------------------------------------------
                cond.pmod = [];
                if isfield(multicond,'pmod')
                    try
                        %-Check if a PM is defined for that condition
                        if (j <= numel(multicond.pmod)) && ...
                                ~isempty(multicond.pmod(j).name)
                            for ii = 1:numel(multicond.pmod(j).name)
                                cond.pmod(ii).name  = multicond.pmod(j).name{ii};
                                cond.pmod(ii).param = multicond.pmod(j).param{ii};
                                cond.pmod(ii).poly  = multicond.pmod(j).poly{ii};
                            end
                        end
                    catch
                        warning('Error specifying parametric modulation.');
                        rethrow(lasterror); %#ok<*LERR>
                    end
                end

                %-Mutiple Conditions: Orthogonalisation of Modulations
                %--------------------------------------------------------------
                if isfield(multicond,'orth') && (j <= numel(multicond.orth))
                    cond.orth    = multicond.orth{j};
                else
                    cond.orth    = true;
                end

                %-Append to singly-specified conditions
                %--------------------------------------------------------------
                sess.cond(end+1) = cond;
            end


            %-Conditions
            %----------------------------------------------------------------------
            U = [];

            for j = 1:numel(sess.cond)

                %-Name, Onsets, Durations
                %------------------------------------------------------------------
                cond      = sess.cond(j);
                U(j).name = {cond.name}; %#ok<*AGROW>
                U(j).ons  = cond.onset(:);
                U(j).dur  = cond.duration(:);
                U(j).orth = cond.orth;
                if isempty(U(j).orth), U(j).orth = true; end
                if length(U(j).dur) == 1
                    U(j).dur = repmat(U(j).dur,size(U(j).ons));
                elseif numel(U(j).dur) ~= numel(U(j).ons)
                    error('Mismatch between number of onset and number of durations.');
                end

                %-Modulations
                %------------------------------------------------------------------
                P  = [];
                q1 = 0;
                %-Time Modulation
                %     switch job.timing.units
                %         case 'secs'
                sf    = 1 / 60;
                %         case 'scans'
                %             sf    = job.timing.RT / 60;
                %         otherwise
                %             error('Unknown unit "%s".',job.timing.units);
                %     end
                if cond.tmod > 0
                    P(1).name = 'time';
                    P(1).P    = U(j).ons * sf;
                    P(1).h    = cond.tmod;
                    q1        = 1;
                end
                %-Parametric Modulations
                if ~isempty(cond.pmod)
                    for q = 1:numel(cond.pmod)
                        q1 = q1 + 1;
                        P(q1).name = cond.pmod(q).name;
                        P(q1).P    = cond.pmod(q).param(:);
                        P(q1).h    = cond.pmod(q).poly;
                    end
                end
                %-None
                if isempty(P)
                    P.name = 'none';
                    P.h    = 0;
                end

                U(j).P = P;

            end

            SPM.Sess.U = U;


            %=== SPM : part 3

            s = 1;

            %-Number of scans for this session
            %----------------------------------------------------------------------
            k = SPM.nscan(s);

            %-Create convolved stimulus functions or inputs
            %======================================================================

            %-Get inputs, neuronal causes or stimulus functions U
            %----------------------------------------------------------------------
            U = spm_get_ons(SPM,s);

            %-Convolve stimulus functions with basis functions
            %----------------------------------------------------------------------
            SPM.xBF.Volterra = 1;
            % [X,Xn,Fc] = spm_Volterra(U, SPM.xBF.bf, SPM.xBF.Volterra);
            [X,~,~] = spm_Volterra(U, SPM.xBF.bf, SPM.xBF.Volterra);

            %-Resample regressors at acquisition times (32 bin offset)
            %----------------------------------------------------------------------
            if ~isempty(X)
                X_reg = X((0:(k - 1))*fMRI_T + fMRI_T0 + 32,:);
            end

            %=== Plot

            % Figure
            figure( ...
                'Name'        , [ inputname(1) ' : ' class(self) ] , ...
                'NumberTitle' , 'off'                                ...
                )
            hold all

            t = (0 : nrVolumes-1) * TR;

            for n = 1 : length(names)

                plot( t, X_reg(:,n), 'DisplayName',names{n} )

            end

            xlabel ('time (s)')
            ylabel ('hemodynamic response (A.U.)')

            legend('show')

        end % fcn

    end % meths

end % class
