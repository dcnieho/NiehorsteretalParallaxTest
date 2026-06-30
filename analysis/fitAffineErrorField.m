function out = fitAffineErrorField(x, y, ex, ey)
% fitAffineErrorField
%
% Fits:
%
%   ex = tx + a*x + b*y
%   ey = ty + c*x + d*y
%
% The affine displacement field is:
%
%   e(x,y) = t + A*[x;y]
%
% where:
%
%   t = [tx; ty]
%   A = [a b; c d]

    x  = x(:);
    y  = y(:);
    ex = ex(:);
    ey = ey(:);

    n = numel(x);

    if n < 3
        error('At least 3 non-collinear points are required.');
    end

    X_aff = [ones(n,1), x, y];
    X_trans = ones(n,1);

    % Translation-only model
    beta_x_trans = X_trans \ ex;
    beta_y_trans = X_trans \ ey;

    ex_hat_trans = X_trans * beta_x_trans;
    ey_hat_trans = X_trans * beta_y_trans;

    res_x_trans = ex - ex_hat_trans;
    res_y_trans = ey - ey_hat_trans;

    SSE_trans = sum(res_x_trans.^2 + res_y_trans.^2);

    % Affine model
    beta_x_aff = X_aff \ ex;
    beta_y_aff = X_aff \ ey;

    ex_hat_aff = X_aff * beta_x_aff;
    ey_hat_aff = X_aff * beta_y_aff;

    res_x_aff = ex - ex_hat_aff;
    res_y_aff = ey - ey_hat_aff;

    SSE_aff = sum(res_x_aff.^2 + res_y_aff.^2);

    % Zero-error reference
    SSE_zero = sum(ex.^2 + ey.^2);

    R2_aff_vs_zero = 1 - SSE_aff / SSE_zero;
    R2_trans_vs_zero = 1 - SSE_trans / SSE_zero;

    % How much of the remaining non-translational structure is explained
    if SSE_trans > 0
        R2_aff_vs_translation = 1 - SSE_aff / SSE_trans;
    else
        R2_aff_vs_translation = NaN;
    end

    tx = beta_x_aff(1);
    ty = beta_y_aff(1);

    a = beta_x_aff(2);
    b = beta_x_aff(3);
    c = beta_y_aff(2);
    d = beta_y_aff(3);

    A = [a b; c d];

    % Geometric decomposition of the affine matrix
    divergence = 0.5 * (a + d);
    anisotropic_scaling = 0.5 * (a - d);
    rotation_like = 0.5 * (c - b);
    shear_like = 0.5 * (b + c);

    out = struct();

    out.tx = tx;
    out.ty = ty;
    out.A = A;

    out.a = a;
    out.b = b;
    out.c = c;
    out.d = d;

    out.divergence = divergence;
    out.anisotropic_scaling = anisotropic_scaling;
    out.rotation_like = rotation_like;
    out.shear_like = shear_like;

    out.ex_hat_aff = ex_hat_aff;
    out.ey_hat_aff = ey_hat_aff;

    out.res_x_aff = res_x_aff;
    out.res_y_aff = res_y_aff;

    out.SSE_zero = SSE_zero;
    out.SSE_trans = SSE_trans;
    out.SSE_aff = SSE_aff;

    out.R2_aff_vs_zero = R2_aff_vs_zero;
    out.R2_trans_vs_zero = R2_trans_vs_zero;
    out.R2_aff_vs_translation = R2_aff_vs_translation;
end
