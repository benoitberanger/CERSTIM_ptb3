classdef Logger < handle
    % Singleton class, only accessed using `logger = getLogger()`
    % the end user will only be interesed in the "public" part


    %% public

    methods(Static, Access = public)

        function self = getInstance()
            self = getLogger();
        end % fcn
        function self = get() % shortcur
            self = UTILS.Logger.instance;
        end % fcn

        % declare this function from external file as static method
        cprintf(style,format,varargin)

    end % meths

    properties(GetAccess = public, SetAccess = public)
        padding (1,1) double {mustBeInteger, mustBeNonnegative} = 0;
    end % props

    methods(Access = public)

        function log(self, formatted_char, varargin)
            fprintf('%s\n', self.FormatMessage(formatted_char, varargin{:}));
        end% fcn

        function ok(self, formatted_char, varargin)
            self.cprintf('Comments', '%s\n', self.FormatMessage(formatted_char, varargin{:}));
        end% fcn

        function warn(self, formatted_char, varargin)
            self.cprintf('Keywords', '%s\n', self.FormatMessage(formatted_char, varargin{:}));
        end% fcn
        function warning(self, formatted_char, varargin)
            warning(self.FormatMessage(formatted_char, varargin{:}));
        end% fcn

        function err(self, formatted_char, varargin)
            self.cprintf('Errors', '%s\n', self.FormatMessage(formatted_char, varargin{:}));
        end% fcn
        function error(self, formatted_char, varargin)
            error(self.FormatMessage(formatted_char, varargin{:}));
        end% fcn

        function assert(self, condition, formatted_char, varargin)
            assert(condition, self.FormatMessage(formatted_char, varargin{:}));
        end% fcn

    end % meths


    %% private

    properties(Constant, Access = private)
        instance (1,1) UTILS.Logger = UTILS.Logger()
    end % props

    properties(GetAccess = public, SetAccess = private)
        last_msg (1,:) char         = '';
    end % props

    properties(Constant, Access = public)
        creation (1,:) char         = datestr(now, 'yyyy-mm-dd HH:MM:ss')
    end % props

    methods (Access = private)

        function self = Logger() % constructor
            self.warn('Logger class MUST NOT be used for real time logging. Use `fprintf` instead.')
        end

        function str = FormatMessage(self, formatted_char, varargin)
            msg = sprintf(formatted_char, varargin{:});
            str = sprintf('[%s - %-*s] %s', self.getTimeStamp(), self.padding, self.getCaller(), msg);
            self.last_msg = str;
        end

    end % meths

    methods (Static, Access = private)

        function str = getCaller()
            stack = dbstack(3,'-completenames');
            if isempty(stack)
                str = '';
                return
            end

            % basic cleaning
            str = strrep(stack(1).file, UTILS.GET.RootDir(),'');
            str = str(2:end); % remove the first `filesep`
            str = strrep(str, '.m', ''); % remove .m extension

            % convert the package disk separator to the matlab script usage (easier copy-paste)
            str = strrep(str, [filesep '+'], '.');

            % if its a class method, show it
            idx = strfind(str, '@');
            if idx
                str = [str(1:idx)  stack(1).name];
            else
                idx = length(str);
            end

            str(1:idx) = strrep(str(1:idx), filesep, '.');
            str = strrep(str, '+', '');
        end

        function str = getTimeStamp()
            str = datestr(now, 'HH:MM:ss');
        end

    end % meths


end % class
