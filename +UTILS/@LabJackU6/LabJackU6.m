classdef LabJackU6 < handle

    properties(GetAccess = public, SetAccess = public)
    end % props

    properties(GetAccess = public, SetAccess = protected)
        asm                 NET.Assembly
        udObj               % LabJack.LabJackUD.LJUD
        driverVersion (1,1) double
        error               % LabJack.LabJackUD.LJUD+LJUDERROR
        handle        (1,1) int32
        range         (1,2) double % [minVolt, maxVolt]
        value         (1,1) double % Volt
    end % props

    properties(GetAccess = public, SetAccess = public, Dependent)
    end % props

    methods % set/get
    end

    methods(Access = public)

        %--- constructor --------------------------------------------------
        function self = LabJackU6(varargin)
            % pass
        end % ctor

        %------------------------------------------------------------------
        function Open(self)
            % Make the UD .NET assembly visible in MATLAB.
            self.asm = NET.addAssembly('LJUDDotNet');
            self.udObj = LabJack.LabJackUD.LJUD;

            % Read and display the UD version.
            self.driverVersion = self.udObj.GetDriverVersion();
            fprintf('[LabJack] UD Driver Version = %g \n', self.driverVersion)

            % Open the first found LabJack U6.
            [self.error, self.handle] = self.udObj.OpenLabJackS('LJ_dtU6', 'LJ_ctUSB', '0', true, 0);
            switch char(self.error)
                case 'NOERROR'
                    % fprintf('[LabJack] OpenLabJackS OK \n')
                otherwise
                    fprintf('[LabJack] OpenLabJackS ERROR : %S \n', self.error)
            end

        end% fcn

        %------------------------------------------------------------------
        function Configure(self)
            % Configure the resolution of the analog inputs (pass a non-zero value for
            % quick sampling). See section 2.6 / 3.1 for more information.
            % LJ_chAIN_RESOLUTION //0=default, 1-8=high-speed ADC, 9-12=high-res ADC
            self.udObj.ePutSS(self.handle, 'LJ_ioPUT_CONFIG', 'LJ_chAIN_RESOLUTION', 0, 0);

            channelAIN0 = 0;

            % Configure the analog input range on channels 2 and 3 for
            % bipolar 10v (LJ_rgBIP10V = 2).
            % LJ_rgBIP10V // +/- 10V, i.e. Gain=x1
            % LJ_rgBIP1V // +/- 1V, i.e. Gain=x10
            % LJ_rgBIPP1V // +/- 0.1V, i.e. Gain=x100
            % LJ_rgBIPP01V // +/- 0.01V, i.e. Gain=x1000
            LJ_rgBIP10V = self.udObj.StringToConstant('LJ_rgBIP10V');
            self.udObj.ePutS(self.handle, 'LJ_ioPUT_AIN_RANGE', channelAIN0, LJ_rgBIP10V, 0);
            self.range = [-10 +10];
            % fprintf('[LabJack] LJ_ioPUT_AIN_RANGE \n')

            % Now we add requests to write and read I/O.  These requests
            % will be processed repeatedly by go/get statements in every
            % iteration of the while loop below.

            % Request AIN0.
            self.udObj.AddRequestS(self.handle, 'LJ_ioGET_AIN', channelAIN0, 0, 0, 0);
            % fprintf('[LabJack] AddRequestS : LJ_ioGET_AIN \n')

            % Constant values used in the loop.
            % LJ_ioGET_AIN = self.udObj.StringToConstant('LJ_ioGET_AIN');

            fprintf('[LabJack] Ready for Analog INput on channel %d \n', channelAIN0)
        end % fcn

        %------------------------------------------------------------------
        function value = GetValue(self)
            self.udObj.GoOne(self.handle);
            [self.error, ioType, channel, dblValue] = self.udObj.GetFirstResult(self.handle, 0, 0, 0, 0, 0);
            self.value = dblValue;
            value = self.value;
        end % fcn

    end % meths

    methods(Static)

        function Test()
            self = UTILS.LabJackU6();
            self.Open()
            self.Configure()

            fig = figure('Name', 'LabJackU6_AIN0', 'NumberTitle','off');
            window_size = 2000;
            time   = nan(1,window_size);
            sensor = nan(1,window_size);
            p = plot(time,sensor);

            t0 = GetSecs();
            fprintf('Press any key to stop \n')
            while ~KbCheck()
                time   = circshift(time  , 1);
                sensor = circshift(sensor, 1);

                value = self.GetValue();
                onset = GetSecs() - t0;
                time(1) = onset;
                sensor(1) = value;

                set(p, 'XData', time, 'YData', sensor);
                ylim([-1 5]);
                fprintf('%g \n', value);

                drawnow();
            end

            close(fig)
        end % fcn

    end % meths

end % class
