classdef vec3 < handle
    %vec3 Class to symplify syntax of X Y Z coordinates

    properties(GetAccess = public, SetAccess = public)
        x (1,1) double
        y (1,1) double
        z (1,1) double
    end % props

    properties(GetAccess = public, SetAccess = public, Dependent)
        xyz % column vector
    end % props

    methods % set/get

        function set.xyz(self, xyz)
            self.x = xyz(1);
            self.y = xyz(2);
            self.z = xyz(3);
        end

        function xyz = get.xyz(self)
            xyz = [self.x ; self.y ; self.z];
        end

    end

    methods(Access = public)

        %--- constructor --------------------------------------------------
        function self = vec3(varargin)

            if nargin < 1
                return
            end

            msg = 'Point accepts 1 vector [x y z], or 3 elements for x,y and z';

            dim = length(varargin);
            switch dim
                case 3
                    self.x = varargin{1};
                    self.y = varargin{2};
                    self.z = varargin{3};
                case 1
                    assert(isnumeric(varargin{1}) && isvector(varargin{1}) && length(varargin{1})==3, msg)
                    self.xyz = varargin{1};
                otherwise
                    error(msg)
            end

        end % ctor

        % -----------------------------------------------------------------
        %                           operators
        % -----------------------------------------------------------------

        function new = plus(obj1, obj2)
            class_name = class(obj1);
            new = feval(class_name, obj1.xyz + obj2.xyz);
        end

        function new = minus(obj1, obj2)
            class_name = class(obj1);
            new = feval(class_name, obj1.xyz - obj2.xyz);
        end

    end % meths

end % class
