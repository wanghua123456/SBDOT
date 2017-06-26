function [] = Train( obj )
% TRAIN learn the statistical relationship of the data
%
% Syntax :
% []=obj.train();

% Superclass method
obj.Train@Metamodel();

if obj.prob.display, fprintf('\nTraining starting...');end

if isempty(obj.hyp_corr)
    
    % Default bounds
    if isempty( obj.lb_hyp_corr ) || isempty( obj.ub_hyp_corr )
        
        if xor( isempty(obj.lb_hyp_corr), isempty(obj.ub_hyp_corr) )
            warning('SBDOT:Kriging:HypBounds_miss','Both bounds lb_hyp_corr and ub_hyp_corr have to be defined ! Default values are applied')
        end
        
        % Bounds based on inter-distances of training points
        [ hyp_corr0_temp, lb_hyperp_temp, ub_hyperp_temp ] = Theta_bound( obj.x_train );
        obj.lb_hyp_corr = log10( ( 1./(2*ub_hyperp_temp) ).^2 ) * ones(1,obj.prob.m_x);
        obj.ub_hyp_corr = log10( ( 1./(2*lb_hyperp_temp) ).^2 ) * ones(1,obj.prob.m_x);
        obj.hyp_corr0 = log10( ( 1./(2*hyp_corr0_temp) ).^2 ) * ones(1,obj.prob.m_x);
    else
        
        assert( size(obj.lb_hyp_corr,2) == obj.prob.m_x ,...
            'SBDOT:Kriging:HypBounds_size',...
            'lb_hyp_corr must be of size 1-by-m_x');
        
        assert( size(obj.ub_hyp_corr,2) == obj.prob.m_x ,...
            'SBDOT:Kriging:HypBounds_size',...
            'ub_hyp_corr must be of size 1-by-m_x');
        
        assert( all( obj.lb_hyp_corr < obj.ub_hyp_corr , 2),...
            'SBDOT:Kriging:HypBounds',...
            'lb_hyp_corr must be lower than ub_hyp_corr');
        
        obj.ub_hyp_corr = log10( obj.ub_hyp_corr );
        obj.lb_hyp_corr = log10( obj.lb_hyp_corr );
        obj.hyp_corr0 = ( obj.lb_hyp_corr + obj.ub_hyp_corr ) ./ 2;
        
    end
    
else
    
    assert( size(obj.hyp_corr,2) == obj.prob.m_x ,...
            'SBDOT:Kriging:Hyp_val_size',...
            'hyp_corr0 must be of size 1-by-m_x');
        
    obj.hyp_corr0 = log10(obj.hyp_corr);
    obj.lb_hyp_corr = log10(obj.hyp_corr);
    obj.ub_hyp_corr = log10(obj.hyp_corr);
        
end

opts = ooDACE.Kriging.getDefaultOptions();
opts.regressionMaxLevelInteractions = obj.prob.m_x;

% Regression (if asked)
if obj.reg
    
    if obj.prob.display, fprintf('\nRegression activated\n');end
    
    if isempty(obj.hyp_reg)
        
        opts.lambda0 = 0;
        
        if isempty( obj.lb_hyp_reg ) || isempty( obj.ub_hyp_reg )
            
            if xor( isempty(obj.lb_hyp_reg), isempty(obj.ub_hyp_reg) )
                warning('SBDOT:Kriging:RegBounds_miss','Both bounds lb_reg and ub_reg have to be defined ! Default values are applied')
            end
            obj.lb_hyp_reg = 1e-8;
            obj.ub_hyp_reg = max( var(obj.f_train), 1e-7 );
            
        else
            
            assert( all( obj.lb_hyp_reg < obj.ub_hyp_reg , 2),...
                'SBDOT:Kriging:RegBounds',...
                'lb_hyp_reg must be lower than ub_hyp_reg');
            
        end
        
        opts.reinterpolation = true;
        
        
        opts.lambdaBounds = log10([obj.lb_hyp_reg ; obj.ub_hyp_reg]);
        
    else
        
        opts.lambda0 = log10( obj.hyp_reg );
        opts.lambdaBounds = log10( [obj.hyp_reg ; obj.hyp_reg] );
        
    end
end

opts.hpBounds = [obj.lb_hyp_corr ; obj.ub_hyp_corr];

obj.k_oodace = ooDACE.Kriging( opts, obj.hyp_corr0, obj.regpoly, obj.corr);
obj.k_oodace = obj.k_oodace.fit(obj.x_train,obj.f_train);

if obj.prob.display, corr_name=func2str(obj.corr); fprintf(['\nKriging with ',corr_name(22:end),' correlation function is created.\n\n']);end


obj.hyp_corr = 10.^obj.k_oodace.getHyperparameters;

hyp_reg_temp = obj.k_oodace.getSigma;
obj.hyp_reg = hyp_reg_temp(1,1);

obj.hyp_corr_bounds = 10.^[min(obj.lb_hyp_corr) , max(obj.ub_hyp_corr)];
obj.hyp_reg_bounds = [obj.lb_hyp_reg , obj.ub_hyp_reg];
obj.hyp_corr0 = 10.^ obj.hyp_corr0(1);

end
