classdef (Abstract) Base < handle
    % This is a very basic object, just a container of simple methods

    properties(GetAccess = public, SetAccess = public)
        header      (1,:) cell   = {''}                    % Description of each columns
        n_col       (1,1) double = 0
        n_lin       (1,1) double = 0
        count       (1,1) double = 0
        data        (:,:)
    end % props

    properties(GetAccess = public, SetAccess = protected)
        timestamp   (1,:) char   = datestr( now ) % creation of object
        description (1,:) char   = ''
        label_start (1,:) char   = 'START'
        label_end   (1,:) char   = 'END'
    end % props
    
    methods(Access = public)
        
        %---- Constructor -------------------------------------------------
        function self = Base()
            self.description = class(self);
        end

        %------------------------------------------------------------------
        function IncreaseCount(self, n)
            if nargin < 2
                n = +1;
            end
            self.count = self.count + n;
        end

        %------------------------------------------------------------------
        function AddLine(self, content)
            assert(isvector(content) && length(content)==self.n_col, 'wrong content')
            self.IncreaseCount();
            self.data(self.count, :) = content;
        end % fcn

        %------------------------------------------------------------------
        function ClearEmptyLines( self )
            self.data = self.data(1:self.count,:);
        end % fcn

        %------------------------------------------------------------------
        function newObject = CopyObject( self )
            % Deep copy of the object
            className = class( self );
            propOfClass = properties( self );
            newObject = eval(className);
            for p = 1 : length(propOfClass)
                newObject.(propOfClass{p}) = self.(propOfClass{p});
            end
        end % fcn

        %------------------------------------------------------------------
        function t = data2table( self )
            DATA = self.data; % make a copy so it can be modified if necessary

            if iscell(DATA)
                % remove StartTime & StopTime
                startstop = strcmp( DATA(:,1), 'StartTime' ) | strcmp( DATA(:,1), 'StopTime' );
                DATA( startstop , : ) = [];
                t = cell2table(DATA,'VariableName',matlab.lang.makeValidName(self.header));

            elseif isnumeric(DATA)
                t = array2table(DATA,'VariableName',matlab.lang.makeValidName(self.header));

            end
        end % fcn

        %------------------------------------------------------------------
        function ExportToCSV( self, filename, withHeader )
            if nargin < 3
                withHeader = 1;
            end
            self.ExportToTxt(filename,'csv',withHeader)
        end % fcn

        %------------------------------------------------------------------
        function savestruct = ExportToStructure( self )
            % StructureToSave = self.ExportToStructure()
            %
            % Export all proporties of the object into a structure, so it
            % can be saved.
            % WARNING : it does not save the methods, just transform the
            % object into a common structure.

            ListProperties = properties(self);

            savestruct = struct;
            for prop_number = 1:length(ListProperties)
                savestruct.(ListProperties{prop_number}) = self.(ListProperties{prop_number});
            end
        end % fcn

        %------------------------------------------------------------------
        function ExportToTSV( self, filename, withHeader )
            if nargin < 3
                withHeader = 1;
            end

            self.ExportToTxt(filename,'tsv',withHeader)
        end % fcn

        %------------------------------------------------------------------
        function ExportToTxt( self, filename, filetype, withHeader )
            %EXPORTTOTXT print the self.Header and self.Data in a text file
            % withHeader=1 prints header (default), withHeader=0 does not.

            switch filetype
                case 'csv'
                    ext = '.csv';
                    sep = ';';
                case 'tsv'
                    ext = '.tsv';
                    sep = sprintf('\t');
                otherwise
                    error('unmapped filetype')
            end

            % Open file in write mod
            fileID = fopen( [ filename ext ] , 'w' , 'n' , 'UTF-8' );
            if fileID < 0
                error('%d cannot be opened', filename)
            end

            % Fill the file
            % Print header
            if withHeader
                for h = 1 : length(self.header)
                    fprintf(fileID, '%s%s', self.header{h},sep);
                end
                fprintf(fileID, '\n'); % end of line
            end

            % Print data
            for i = 1 : size(self.Data,1)
                for j = 1 : size(self.Data,2)

                    % Apply conversion if necessary
                    switch class(self.Data)

                        case 'cell'

                            if ischar(self.Data{i,j})
                                toprint = self.Data{i,j};

                            elseif isnumeric(self.Data{i,j})
                                toprint = num2str(self.Data{i,j});

                            elseif islogical(self.Data{i,j})
                                switch self.Data{i,j}
                                    case true
                                        toprint = 'TRUE';
                                    case false
                                        toprint = 'FALSE';
                                end

                            end


                        case 'double'

                            if isnumeric(self.Data(i,j))
                                toprint = num2str(self.Data(i,j));

                            elseif islogical(self.Data(i,j))
                                switch self.Data(i,j)
                                    case true
                                        toprint = 'TRUE';
                                    case false
                                        toprint = 'FALSE';
                                end

                            end

                        otherwise
                            warning('unmapped input type')
                    end

                    fprintf(fileID, '%s%s', toprint,sep);

                    % End of line
                    if j == size(self.Data,2)
                        fprintf(fileID, '\n');
                    end

                end % j
            end % i

            % Close the file
            fclose( fileID );

        end % fcn

        %------------------------------------------------------------------
        function [ output ] = Get( self, str, evt )
            %GET is not a classc "get" method
            %
            % Here, this method is a way to fetch :
            % 1) a column number      in slef.data . Syntax : columnNumber = obj.Get('regex'            )
            % 2) an element contained in self.Data . Syntax : element      = obj.Get('regex', lineNumber)
            %    lineNumber=integer ... => 1 element // lineNumber=vector => N elements // lineNumber=[] => all the column
            %
            % The 'regex' is a regular expression that will be found in obj.Header
            %

            column = ~cellfun(@isempty,regexp(self.header,str,'once'));
            assert(any(column), 'Get method did not find ''%s'' in the Header', str)

            column = find(column);

            if nargin < 3
                output = column;
                return
            end

            assert( isnumeric(evt), 'evt, if is defined, mut be numeric' )

            if isempty(evt)
                output = self.Data(:,column);
                return
            end

            if isscalar(evt)
                switch class(self.Data)
                    case 'cell'
                        output = self.Data{evt,column};
                    case 'double'
                        output = self.Data(evt,column);
                    otherwise
                        output = self.Data{evt,column};
                end
                return
            end

            if isvector(evt)
                output = self.Data(evt,column);
                return
            end

            error('evt ?')
        end % fcn

        %------------------------------------------------------------------
        function IsEmptyProp( self , propertyname )
            % self.IsEmptyProperty( PropertyName )
            %
            % Raise an error if self.'PropertyName' is empty

            % Fetch caller object
            [~, objName, ~] = fileparts(self.description);

            if isempty(self.(propertyname))
                error('No data in %s.%s' , objName , propertyname )
            end
        end % fcn

    end % meths

end % classdef
