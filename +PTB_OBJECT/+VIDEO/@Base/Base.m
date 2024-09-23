classdef Base < handle
    % BASE is a 'virtual' class : all subclasses contain this virtual class methods and attributes

    properties(GetAccess = public, SetAccess = public)
        window PTB_ENGINE.VIDEO.Window
    end % props

    methods(Access = public)

        %------------------------------------------------------------------
        function self = Base()
            % pass
        end % fcn

        %------------------------------------------------------------------
        function newObject = CopyObject( self )
            className = class( self );
            propOfClass = properties( self );
            newObject = eval(className);
            for p = 1 : length(propOfClass)
                newObject.(propOfClass{p}) = self.(propOfClass{p});
            end
        end % fcn

        %------------------------------------------------------------------
        function AssertReady( self )
            props = properties(self);
            for p = 1: length(props)
                assert( ~isempty(self.(props{p})) , '%s is empty' , props{p} )
            end
        end % fcn

        %------------------------------------------------------------------
        function DrawFlip( self )
            self.Draw();
            self.Flip();
        end % fcn

        %------------------------------------------------------------------
        function Flip( self )
            Screen('Flip',self.window.ptr);
        end % fcn

    end % meths

end % class