function [E, targetOrder] = getParallaxField(T1, T2)
% Match rows by target and compute the parallax vector field.

    requiredVars = ["target", "median_acc_x", "median_acc_y"];

    for v = requiredVars
        if ~ismember(v, string(T1.Properties.VariableNames))
            error('First table is missing variable: %s', v);
        end
        if ~ismember(v, string(T2.Properties.VariableNames))
            error('Second table is missing variable: %s', v);
        end
    end

    T1s = sortrows(T1, 'target');
    T2s = sortrows(T2, 'target');

    if ~isequal(T1s.target, T2s.target)
        error('Target labels do not match between distance 1 and distance 2.');
    end

    targetOrder = T1s.target;

    E1 = [T1s.median_acc_x, T1s.median_acc_y];
    E2 = [T2s.median_acc_x, T2s.median_acc_y];

    E = E1 - E2;
end
