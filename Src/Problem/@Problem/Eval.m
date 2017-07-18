function [ y_eval, g_eval, x_eval ] = Eval( obj, x_eval )
    % EVAL Evaluates the problem function at x_eval
    %   *x_eval is a n_eval by m_x matrix
    %   *y_eval is objectives evaluated at x_eval
    %   *g_eval is contraints evaluated at x_eval
    %
    % Syntax :
    % [ y_eval, g_eval ]=obj.Eval(x_eval);

    % Checks
    n_eval = obj.Input_assert( x_eval );

    % Evaluation
    if obj.round
        x_eval = Round_data( x_eval, obj.round_range ); %round x_eval
    end

    if obj.display, fprintf('Evaluation '); end

    if obj.parallel % Parallel evaluation is allowed

        if obj.display, fprintf('ongoing'); end

        try
            if obj.m_g > 0 % With constraints
                [ y_eval, g_eval ]=feval( obj.function_name,x_eval );
            else           % Unconstrained
                y_eval = feval( obj.function_name, x_eval );
                g_eval = [];
            end
        catch ME
            obj.Eval_error_handling( ME, 'unknow because parallel evaluation' )
        end
        
        if ~isempty(obj.save_file)
            
            save( obj.save_file, 'x_eval', 'y_eval', 'g_eval' )
            
        end

        if obj.display, fprintf( repmat('\b',1,7) ); end   

    else % Parallel evaluation is not allowed    

        if obj.display
            format_display = [ '%',num2str(length(num2str(n_eval))),...
                '.0d/%',num2str(length(num2str(n_eval))),'.0d' ];
            format_display2=repmat('\b',1,2*length(num2str(n_eval))+1); 
        end 

        for i=1:n_eval
            if obj.display, fprintf( format_display, i, n_eval ); end

            try
                if obj.m_g > 0 % With constraints
                    [ y_eval(i,:), g_eval(i,:) ] = feval( obj.function_name, x_eval(i,:) );

                else           % unconstraint
                    y_eval(i,:) = feval( obj.function_name, x_eval(i,:) );
                    g_eval = [] ;
                end
            catch ME
                obj.Eval_error_handling( ME, x_eval(i,:) )
            end 
            
            if ~isempty(obj.save_file)
                
                save( obj.save_file, 'x_eval', 'y_eval', 'g_eval' )
                
            end

            if obj.display,fprintf( format_display2 ); end         

        end

    end

    if obj.display, fprintf( 'completed.\n\n' ); end

    obj.Add_data( x_eval, y_eval, g_eval ); % add dataset to object

end

