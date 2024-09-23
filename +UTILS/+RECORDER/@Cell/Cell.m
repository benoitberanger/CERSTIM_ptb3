classdef Cell < UTILS.RECORDER.Base
    % Data are stored in Cell.

    properties(GetAccess = public, SetAccess = public)
    end % properties

    methods(Access = public)

        %---- Constructor -------------------------------------------------
        function self = Cell(header, nline)

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
            self.data        = cell( self.n_lin , self.n_col);
        end

    end % meths

end % classdef
