classdef Double < UTILS.RECORDER.Base
    % This class is optimized to store numerical samples.

    properties(GetAccess = public, SetAccess = public)
    end % properties

    methods(Access = public)

        %---- Constructor -------------------------------------------------
        function self = Double( header , nline )
            % Usually, first column is the time, and other columns are samples type

            if nargin > 0

                % --- header ----
                if iscellstr( header ) && isvector( header ) && ~isempty( header )
                    self.header =  header;
                    self.n_col = length(header);
                else
                    error( 'Header should be a line cell of strings' )
                end

                % --- nline ---
                if isnumeric( nline ) && nline == round( nline ) && nline > 0
                    self.n_lin = nline;
                else
                    error( 'nline must be a positive integer' )
                end

            end

            self.description = class(self);
            self.data        = zeros( self.n_lin , self.n_col);

        end % ctor

        %------------------------------------------------------------------
        function Plot( self )
            % Check if not empty
            self.IsEmptyProperty('data');

            % Figure
            figure('Name',[ inputname(1) ' : ' class(self) ], 'NumberTitle' ,'off')
            hold all

            % For each Event, plot the curve
            % x = first column, y1 = col2, y2 = col3, ...
            for signal = 2 : size( self.data , 2 )
                plot(self.data(:,1),self.data(:,signal));
            end

            % Legend
            lgd = legend( self.header(2:end) );
            set(lgd,'Interpreter','none','Location','Best')

            xlabel(self.header{1})

            UTILS.ScaleAxisLimits( gca , 1.1 )
        end % fcn

        %------------------------------------------------------------------
        function PlotDiffTime( self )
            % Check if not empty
            self.IsEmptyProperty('data');

            % Figure
            figure('Name',[ inputname(1) ' : ' class(self) ], 'NumberTitle' ,'off')
            hold all

            plot(self.data(1:end-1,1),diff(self.data(:,1)));

            % Legend
            lgd = legend( 'diff(time)' );
            set(lgd,'Interpreter','none','Location','Best')

            xlabel(self.Header{1})

            UTILS.ScaleAxisLimits( gca , 1.1 )
        end % fcn

        %------------------------------------------------------------------
        function ScaleTime( self )
            % self.ScaleTime()
            %
            % Scale the time origin to the first entry in self.Data

            % Onsets of events
            time = self.data( : , 1 );

            % Write scaled time
            if ~isempty( time )
                self.data( : , 1 ) = time - time(1);
            else
                warning( 'No data in %s.data (%s)' , inputname(1) )
            end
        end % fcn

    end % methods

end % class
