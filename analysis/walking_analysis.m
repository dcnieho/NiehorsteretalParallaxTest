close all
clear all

if true
    % Use included data
    [walkQuant, subs, glasses] = loadWalkingQuantilesTxt('walking\data.tsv');
    glassLbls = {'Pupil Invisible','Pupil Neon','SMI ETG 2','Tobii Glasses 2','Tobii Glasses 3','VPS Lite'};
else
    % use data collected by user and processed using the provided
    % gazeMapper project
    gaze_folder  = '..\gazeMapper_project';

    recordings = FolderFromFolder(gaze_folder);
    recordings(strcmp({recordings.name},'config')) = [];
    [~,i] = natsort({recordings.name});
    recordings = recordings(i);
    
    inf = split({recordings.name},'_');
    [recordings.subj] = inf{:,:,1};
    [recordings.glasses] = inf{:,:,2};
    
    subs    = natsort(unique(inf(:,:,1)));
    glasses = unique(inf(:,:,2));
    glassLbls = {'Tobii Glasses 2','Tobii Glasses 3','Pupil Invisible','Pupil Neon', 'SMI ETG 2', 'VPS Lite'};
    [glassLbls,i] = sort(glassLbls);
    glasses = glasses(i);

    % read in data
    parallax = cell(length(subs),length(glasses));
    for s=1:length(subs)
        for r=1:length(glasses)
            qRec = strcmp({recordings.subj},subs{s}) & strcmp({recordings.glasses},glasses{r});
            % read gaze data
            gazeData = readtable(fullfile(gaze_folder, recordings(qRec).name, 'et', 'gazeOffset_parallax_walk.tsv'),'FileType','delimitedtext');
            if any(contains(gazeData.Properties.VariableNames,'timestamp_VOR'))
                gazeData.timestamp_VOR = gazeData.timestamp_VOR/1000;
                gazeData.frame_idx = gazeData.frame_idx_VOR;
            else
                gazeData.timestamp = gazeData.timestamp/1000;
            end
            st_fr = gazeData.frame_idx(1);
            en_fr = gazeData.frame_idx(end);
    
            % read plane pose to get distance
            pose = readtable(fullfile(gaze_folder, recordings(qRec).name, 'et', 'planePose_parallax_walk.tsv'),'FileType','delimitedtext');
            qPose = pose.frame_idx>=st_fr & pose.frame_idx<=en_fr;
            pose(~qPose,:) = [];
    
            % get distance for each gaze sample
            ns = size(gazeData,1);
            dist = nan(ns,1);
            for p=1:ns
                qFrame = pose.frame_idx==gazeData.frame_idx(p);
                if ~any(qFrame)
                    continue
                end
                dist(p) = pose.pose_T_vec_z(qFrame);
            end
            gazeData.dist = dist/1000;
            
            parallax{s,r} = gazeData;
        end
    end
    
    % get viewing distances
    dists = cell(1,numel(parallax));
    for p=1:numel(parallax)
        dists{p} = parallax{p}.dist;
    end
    dists = cat(1,dists{:});
    distLims = quantile(dists,[.025,0.975]);
    
    % make into decile per participant
    binedges = fliplr(1./linspace(1./sqrt(distLims(2)),1/sqrt(distLims(1)),21).^2);
    binedges = max(0,min(1,(binedges-distLims(1))/diff(distLims)));
    bincenters = conv(binedges,[.5 .5],'valid');

    % determine gaze shift per bin
    components = ["horizontal", "vertical"];
    fields = ["offset_x_target_1_pose_vidpos_ray", ...
              "offset_y_target_1_pose_vidpos_ray"];

    walkQuant = table();
    for s = 1:numel(subs)
        for r = 1:numel(glasses)
            for c = 1:numel(components)
                field = fields(c);

                pd = parallax{s,r}.(field);
                pd(abs(pd) > 20) = nan;

                % Match plotting code: remove participant mean
                pd = pd - mean(pd, 'omitnan');

                [px, py] = quantile2D(parallax{s,r}.dist, pd, bincenters, binedges);

                T = table();
                T.subject = repmat(string(subs(s)), numel(px), 1);
                T.glasses = repmat(string(glasses(r)), numel(px), 1);
                T.component = repmat(components(c), numel(px), 1);
                T.bin = (1:numel(px))';
                T.distance = px(:);
                T.offset = py(:);

                walkQuant = [walkQuant; T]; %#ok<AGROW>
            end
        end
    end
end

colors = ["F0A3FF","C20088","393939","9DCC00","0075DC","993F00","4C005C","005C31","2BCE48","FFCC99","94FFB5","8F7C00"];
colors = arrayfun(@(x) hex2dec(reshape(char(x),2,3).').'/255, colors,'UniformOutput',false);



% plot
for x=1:2 % horizontal and vertical
    if x==1
        component = 'horizontal';
        lbl = 'Horizontal gaze offset (deg)';
    else
        component = 'vertical';
        lbl = 'Vertical gaze offset (deg)';
    end
    f1 = figure;
    tl = tiledlayout(3,length(glasses)/3,'TileIndexing', 'rowmajor','Padding','tight','TileSpacing','compact');

    f1.Position(3) = f1.Position(3)*1.8;
    f1.Position(4) = f1.Position(4)*2.5;
    f1.Position(1:2) = 100;
    yls = zeros(6,2);
    for r=1:length(glasses)
        ax=nexttile; hold on
        if r>4
            xlabel(ax, 'Viewing distance (m)', 'FontWeight', 'bold')
        end
        if ismember(r,[1 3 5])
            ylabel(ax, lbl, 'FontWeight', 'bold')
        end
        plot([0 6],[0 0],'--','Color',[.6 .6 .6])
        title(glassLbls{r},'FontSize',16)
        h = gobjects(1,length(subs));
        for s = 1:numel(subs)
            idx = strcmp(walkQuant.subject, subs{s}) & ...
                strcmp(walkQuant.glasses, glasses{r}) & ...
                strcmp(walkQuant.component, component);

            T = walkQuant(idx, :);
            T = sortrows(T, 'bin');

            h(s) = plot(T.distance, T.offset, 'o-', ...
                Color = colors{s}, ...
                MarkerFaceColor = colors{s});
        end
        axis tight
        xlim([0 6])

        yl = ylim;
        ylim(yl+(30-diff(yl))*.5*[-1 1]);

        if x==1 && r==1
            hl = legend(h,arrayfun(@(x) sprintf('P%02d',x),1:length(subs),'uni',false),Location="southeast",NumColumns=3, Box="off");
        end

        yls(r,:) = yl;
        if x==2
            axis ij
        end
        ax.XRuler.FontSize=14;
        ax.YRuler.FontSize=14;
    end
    drawnow
    if x==1
        hl.Position(2) = hl.Position(2)-.01;
    end

    axObj = tl.Children;
    for r=1:length(glasses)
        % find axis
        for r2=1:length(axObj)
            if strcmp(axObj(r2).Title.String,glassLbls{r})
                break
            end
        end
        axes(axObj(r2)) %#ok<LAXES>
        yl2 = ylim();
        if x==1 && r==1
            yp = [-11 -1];
        elseif mean(yl2)<0
            if x==1
                yp = [yl2(1)+5 yl2(1)+15];
            else
                yp = [yl2(1)+3 yl2(1)+13];
            end
        else
            if x==1
                yp = [yl2(2)-11 yl2(2)-1];
            else
                yp = [yl2(2)-15 yl2(2)-5];
            end
        end
        xp = [2.8 5.8];
        yl = (yls(r,:)-mean(yls(r,:)))*1.1+mean(yls(r,:));
        iax = MagInset(f1,gca,[0 .5 yl], [xp yp],{'NE','NW';'SE','SW'});
        iax.XRuler.FontSize=12;
        iax.XTick = [0:.1:0.5];
        iax.YRuler.FontSize=12;
    end

    print(sprintf('walking\\quantile_%s.png',lower(lbl(1:3))),'-dpng','-r300');
end
