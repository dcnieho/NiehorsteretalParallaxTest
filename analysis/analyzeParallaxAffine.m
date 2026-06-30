function results = analyzeParallaxAffine(parallax, tarPos, subs, glasses)
% analyzeParallaxAffine
%
% Analyze 2D parallax error fields arranged over five target locations.
%
% Inputs
% ------
% parallax : cell array, size nSubjects x nTrackers x 2
%     Each cell contains a table with columns:
%       target, GroupCount, median_acc_x, median_acc_y
%
% tarPos : 5 x 2 matrix
%     Target positions. Example:
%       [0 0;
%        -7.9494 0;
%         7.9494 0;
%         0 7.9494;
%         0 -7.9494]
%
% subs : subject labels
%     Numeric, string, char array, or cellstr.
%
% glasses : tracker labels
%     Numeric, string, char array, or cellstr.
%
% Output
% ------
% results : struct with fields
%     subjectFits       - one row per subject x tracker
%     trackerTests      - one row per tracker
%     componentTests    - component-wise t-tests per tracker

    nSubs = size(parallax, 1);
    nTrackers = size(parallax, 2);

    if size(parallax, 3) ~= 2
        error('Expected parallax to be nSubjects x nTrackers x 2.');
    end

    if size(tarPos, 1) ~= 5 || size(tarPos, 2) ~= 2
        error('Expected tarPos to be 5 x 2.');
    end

    subsStr = labelsToString(subs, nSubs, "S");
    glassesStr = labelsToString(glasses, nTrackers, "Tracker");

    x = tarPos(:,1);
    y = tarPos(:,2);

    subjectRows = table();

    % Store full fields: subject x tracker x target x component
    observedField = nan(nSubs, nTrackers, 5, 2);
    fittedField   = nan(nSubs, nTrackers, 5, 2);
    residualField = nan(nSubs, nTrackers, 5, 2);

    for s = 1:nSubs
        for r = 1:nTrackers

            T1 = parallax{s,r,1};
            T2 = parallax{s,r,2};

            if isempty(T1) || isempty(T2)
                warning('Empty table for subject %d, tracker %d. Skipping.', s, r);
                continue
            end

            [E, targetOrder] = getParallaxField(T1, T2);

            if numel(targetOrder) ~= 5
                warning('Expected 5 targets for subject %d, tracker %d. Skipping.', s, r);
                continue
            end

            % Reorder tarPos according to the target labels in the table.
            % This assumes target labels are 1:5 and correspond to tarPos rows.
            thisTarPos = tarPos(targetOrder, :);
            thisX = thisTarPos(:,1);
            thisY = thisTarPos(:,2);

            ex = E(:,1);
            ey = E(:,2);

            fit = fitAffineErrorField(thisX, thisY, ex, ey);

            observedField(s,r,:,:) = E;
            fittedField(s,r,:,1) = fit.ex_hat_aff;
            fittedField(s,r,:,2) = fit.ey_hat_aff;
            residualField(s,r,:,1) = fit.res_x_aff;
            residualField(s,r,:,2) = fit.res_y_aff;

            newRow = table();

            newRow.subject = subsStr(s);
            newRow.tracker = glassesStr(r);

            newRow.tx = fit.tx;
            newRow.ty = fit.ty;

            newRow.a = fit.a;
            newRow.b = fit.b;
            newRow.c = fit.c;
            newRow.d = fit.d;

            newRow.divergence = fit.divergence;
            newRow.anisotropic_scaling = fit.anisotropic_scaling;
            newRow.rotation_like = fit.rotation_like;
            newRow.shear_like = fit.shear_like;

            newRow.R2_aff_vs_zero = fit.R2_aff_vs_zero;
            newRow.R2_trans_vs_zero = fit.R2_trans_vs_zero;
            newRow.R2_aff_vs_translation = fit.R2_aff_vs_translation;

            newRow.SSE_zero = fit.SSE_zero;
            newRow.SSE_trans = fit.SSE_trans;
            newRow.SSE_aff = fit.SSE_aff;

            subjectRows = [subjectRows; newRow]; %#ok<AGROW>
        end
    end

    trackerTests = runTrackerLevelTests(subjectRows, glassesStr);
    componentTests = runComponentTests(subjectRows, glassesStr);

    results = struct();
    results.subjectFits = subjectRows;
    results.trackerTests = trackerTests;
    results.componentTests = componentTests;

    disp('Tracker-level tests:')
    disp(trackerTests)

    disp('Component-wise tests:')
    disp(componentTests)
end
