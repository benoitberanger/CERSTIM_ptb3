classdef Window < handle
    % Class to open PTB window, and set its parameters


    %% Public

    properties(GetAccess = public, SetAccess = public)
        % here is a list of "default" parameters :

        % user-depend settings
        bg_color          (1,3) uint8   = [128 128 128];    % [R G B]  , from 0 to 255
        text_font         (1,:) char    = 'arial'
        text_color        (1,4) uint8   = [200 200 200 255] % [R G B a], from 0 to 255
        text_size_ratio   (1,1) double  = 0.10              % text_size = text_size_ratio * window_size_y
        movie_filepath    (1,:) char    = ''

        % from the gui
        screen_id                double % mandatory, you need to be set by the user
        is_transparent    (1,1) logical = false;
        is_windowed       (1,1) logical = false;
        is_recorded       (1,1) logical = false;

        % my suggestion of useful settings
        anti_aliazing     (1,1) double  = 4; % number of samples for multi-sample anti-aliazing

        % for debugging
        debugOpaqueForHID (1,1) logical = false; % see PsychDebugWindowConfiguration
        debugOpacity      (1,1) double  = 0.5    % see PsychDebugWindowConfiguration
        debugFactor       (1,1) double  = 0.5    % windowed size shrinking factor
    end % props

    methods(Access = public)

        %------------------------------------------------------------------
        function Open(self)
            % paramters come from `global S` and default paramters (see above, in the Public)

            logger = getLogger();
            logger.log('Preparing PTB window')
            clear Screen % reset all cashed PTB screen settings
            
            % Call this function at the beginning of your experiment script before
            % calling *any* Psychtoolbox Screen() command, if you intend to use
            % low-level OpenGL drawing commands in your script as provided by
            % Richard Murrays moglcore extension.
            InitializeMatlabOpenGL();

            if isempty(self.screen_id)
                logger.err('screen_id not set, opening a window in debug mode : windowed & transparent ')
                self.screen_id = max(Screen('Screens'));
                self.is_transparent = true;
                self.is_windowed    = true;
            end

            % Transparent
            if self.is_transparent
                PsychDebugWindowConfiguration(self.debugOpaqueForHID, self.debugOpacity);
            end

            % Use GStreamer : for videos
            if self.is_recorded
                Screen('Preference', 'OverrideMultimediaEngine', 1);
            end

            % PTB opening screen will be empty = black screen
            Screen('Preference', 'VisualDebugLevel', 1);

            % Windowed
            if self.is_windowed
                [ScreenWidth, ScreenHeight]=Screen('WindowSize', self.screen_id);
                SmallWindow = ScaleRect( [0 0 ScreenWidth ScreenHeight] , self.debugFactor , self.debugFactor );
                WindowRect = CenterRectOnPoint( SmallWindow , ScreenWidth/2 , ScreenHeight/2 );
            else
                WindowRect = [];
            end

            % Open
            try
                [self.ptr,self.rect] = Screen('OpenWindow',self.screen_id,self.bg_color,WindowRect,[],[],[],self.anti_aliazing);
            catch err
                logger.err(err.message)
                Screen('Preference', 'SkipSyncTests', 1);
                [self.ptr,self.rect] = Screen('OpenWindow',self.screen_id,self.bg_color,WindowRect,[],[],[],self.anti_aliazing);
            end

            % Set up alpha-blending for smooth (anti-aliased) lines and alpha-blending
            % (transparent background textures)
            Screen('BlendFunction', self.ptr, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

            % Center, Width & Hight
            [self.  size_x, self.  size_y] = RectSize  (self.rect);
            [self.center_x, self.center_y] = RectCenter(self.rect);

            % Get refresh rate info
            self.ifi   = Screen('GetFlipInterval', self.ptr);
            self.slack = self.ifi/2;
            self.fps   = Screen('FrameRate'      , self.ptr);

            % Text
            Screen('Preference', 'TextRenderer', 1); % ? dont remeber why...
            Screen('TextFont' , self.ptr, self.text_font );
            Screen('TextColor', self.ptr, self.text_color);
            Screen('TextSize' , self.ptr, self.text_size_ratio * self.size_y);

            % Warmup
            Screen('Flip', self.ptr);

            logger.log('PTB window & rendering parameters set')

            if self.is_recorded
                self.CreateMovie()
                logger.log('Movie file opened : %s', self.movie_filepath)
            end
        end % fcn

        %------------------------------------------------------------------
        function Close(self)
            if self.is_recorded
                self.FinalizeMovie();
            end
            Screen('Close', self.ptr);
        end % fcn

        %------------------------------------------------------------------
        function real_onset = Flip(self,target_onset)
            if nargin < 2
                target_onset = [];
            end
            Screen('DrawingFinished', self.ptr);
            real_onset = Screen('Flip',self.ptr, target_onset);
        end % fcn

        %------------------------------------------------------------------
        function CreateMovie(self)
            self.movie_ptr = Screen('CreateMovie', self.ptr, self.movie_filepath, [], [], self.fps);
        end % fcn

        %------------------------------------------------------------------
        function FinalizeMovie(self)
            Screen('FinalizeMovie', self.movie_ptr);
        end % fcn

        %------------------------------------------------------------------
        function AddFrameToMovie(self, duration, buffer)
            if ~self.is_recorded
                return
            end

            if nargin < 2, duration = []           ; end
            if nargin < 3, buffer   = 'frontBuffer'; end

            if isempty(duration)
                nframe = [];
            else
                nframe = round(duration/self.ifi);
            end

            Screen('AddFrameToMovie', self.ptr, [], buffer, self.movie_ptr, nframe);
        end % fcn

    end % props


    %% Protected

    properties(GetAccess = public, SetAccess = protected)
        % paramters setted after Open()
        ptr           (1,1) double % window pointer : Screen('DoSomething', ptr)
        rect          (1,4) double % [0 0 size_x size_y], in pixel
        size_x        (1,1) double % in pixel
        size_y        (1,1) double % in pixel
        center_x      (1,1) double % in pixel
        center_y      (1,1) double % in pixel

        ifi           (1,1) double % inter-frame-interval, in seconds
        slack         (1,1) double % in seconds
        fps           (1,1) double % frames-per-seconds, in Hz

        movie_ptr     (1,1) double % movie pointer
    end % props

    methods(Access = protected)
    end % props


    %% Private

    properties(GetAccess = public, SetAccess = private)
    end % props

    methods(Access = private)
    end % props


end % class
