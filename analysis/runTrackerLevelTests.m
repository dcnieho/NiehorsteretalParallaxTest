function trackerTests = runTrackerLevelTests(subjectRows, glassesStr)

    nTrackers = numel(glassesStr);

    trackerTests = table();

    for r = 1:nTrackers

        trackerName = glassesStr(r);

        idxRows = subjectRows.tracker == trackerName;
        T = subjectRows(idxRows, :);

        n = height(T);

        % Translation parameters
        transParams = [T.tx, T.ty];

        % Position-dependent affine parameters only
        linearParams = [T.a, T.b, T.c, T.d];

        transTest = hotellingT2Test(transParams);
        linearTest = hotellingT2Test(linearParams);

        newRow = table();

        newRow.tracker = trackerName;
        newRow.n = n;

        newRow.translation2D_T2 = transTest.T2;
        newRow.translation2D_F = transTest.F;
        newRow.translation2D_df1 = transTest.df1;
        newRow.translation2D_df2 = transTest.df2;
        newRow.translation2D_p = transTest.p;

        newRow.linearAffine4D_T2 = linearTest.T2;
        newRow.linearAffine4D_F = linearTest.F;
        newRow.linearAffine4D_df1 = linearTest.df1;
        newRow.linearAffine4D_df2 = linearTest.df2;
        newRow.linearAffine4D_p = linearTest.p;

        trackerTests = [trackerTests; newRow]; %#ok<AGROW>
    end
end
