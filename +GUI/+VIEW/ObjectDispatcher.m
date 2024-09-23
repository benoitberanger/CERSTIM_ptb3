classdef ObjectDispatcher < handle


    properties

        inputVect     (:,1) double
        interWidth    (1,1) double
        vectLength_x  (1,1) double
        vectTotal_x   (1,1) double
        unitWidth_x   (1,1) double
        x_offcet      (1,1) double = 1

        nObjPerRow    (1,1) double
        vectLength_y  (1,1) double
        vectTotal_y   (1,1) double
        unitWidth_y   (1,1) double
        y_offcet      (1,1) double = NaN

        count         (1,1) double = 0

    end % props


    methods

        %------------------------------------------------------------------
        %- Constructor
        function self = ObjectDispatcher(inputVect, nObjPerRow, interWidth)

            if nargin == 0
                return
            end

            if nargin < 2
                nObjPerRow = Inf;
            end

            if nargin < 3 || isempty(interWidth)
                interWidth = 0.05; % from 0 to 1
            end

            self.inputVect  = inputVect;
            self.interWidth = interWidth;
            self.nObjPerRow = nObjPerRow;
            self.interWidth = interWidth;

            if ~isfinite(nObjPerRow)
                self.vectLength_x = length(self.inputVect              );
                self.vectTotal_x  = sum   (self.inputVect              );
                self.vectLength_y = 1;
                self.vectTotal_y  = 1;
            else
                self.vectLength_x = length(self.inputVect(1:nObjPerRow));
                self.vectTotal_x  = sum   (self.inputVect(1:nObjPerRow));
                self.vectLength_y = ceil(length(self.inputVect)/nObjPerRow);
                self.vectTotal_y  = self.vectLength_y;

            end
            self.y_offcet     = self.vectLength_y;
            self.unitWidth_x  = ( 1 - (self.interWidth*(self.vectLength_x + 1)) ) / self.vectTotal_x ;
            self.unitWidth_y  = ( 1 - (self.interWidth*(self.vectLength_y + 1)) ) / self.vectTotal_y ;

        end % function

        %------------------------------------------------------------------
        function next(self, value)

            if nargin < 2
                value = +1;
            end
            self.count = self.count + value;
            self.x_offcet = self.count;

            if self.x_offcet > self.nObjPerRow
                self.count = 1;
                self.x_offcet = self.count;
                self.y_offcet = self.y_offcet - 1;
            end

        end

        %------------------------------------------------------------------
        function pos = xpos(self)
            pos = self.unitWidth_x*sum(self.inputVect(1:self.x_offcet-1)) + self.interWidth*self.x_offcet;
        end

        %------------------------------------------------------------------
        function width = xwidth(self)
            width = self.inputVect(self.x_offcet)*self.unitWidth_x;
        end

        %------------------------------------------------------------------
        function pos = ypos(self)
            pos = self.unitWidth_y*sum(self.inputVect(1:self.y_offcet-1)) + self.interWidth*self.y_offcet;
        end

        %------------------------------------------------------------------
        function width = yheight(self)
            width = self.inputVect(self.y_offcet)*self.unitWidth_y;
        end

        %------------------------------------------------------------------
        function p = pos(self)
            p = [self.xpos self.ypos self.xwidth self.yheight];
        end

    end % meths


end % class
