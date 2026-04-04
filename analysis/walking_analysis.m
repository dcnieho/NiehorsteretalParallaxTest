close all
clear all

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

colors = ["F0A3FF","C20088","393939","9DCC00","0075DC","993F00","4C005C","005C31","2BCE48","FFCC99","94FFB5","8F7C00"];
colors = arrayfun(@(x) hex2dec(reshape(char(x),2,3).').'/255, colors,'UniformOutput',false);

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
            dist(p) = pose.pose_T_vec_z(pose.frame_idx==gazeData.frame_idx(p));
        end
        gazeData.dist = dist/1000;
        
        parallax{s,r} = gazeData;
    end
end

if true
    % get viewing distances
    dists = cell(1,numel(parallax));
    for p=1:numel(parallax)
        dists{p} = parallax{p}.dist;
    end
    dists = cat(1,dists{:});
    distLims = quantile(dists,[.025,0.975]);
end

% make into decile per participant
binedges = fliplr(1./linspace(1./sqrt(distLims(2)),1/sqrt(distLims(1)),21).^2);
binedges = max(0,min(1,(binedges-distLims(1))/diff(distLims)));
bincenters = conv(binedges,[.5 .5],'valid');

% plot
for x=1:2 % horizontal and vertical
    if x==1
        field = 'offset_x_target_1_pose_vidpos_ray';
        lbl = 'Horizontal gaze offset (deg)';
    else
        field = 'offset_y_target_1_pose_vidpos_ray';
        lbl = 'Vertical gaze offset (deg)';
    end
    f1 = figure;
    tl = tiledlayout(2,length(glasses)/2,'TileIndexing', 'rowmajor','Padding','tight','TileSpacing','compact');
    xlabel(tl, 'Viewing distance (m)', 'FontWeight', 'bold')
    ylabel(tl, lbl, 'FontWeight', 'bold')

    f1.Position(3) = f1.Position(3)*2.5;
    f1.Position(4) = f1.Position(4)*1.5;
    f1.Position(1:2) = 100;
    quantiles = cell(length(subs),length(glasses));
    yls = zeros(6,2);
    for r=1:length(glasses)
        ax=nexttile; hold on
        plot([0 6],[0 0],'--','Color',[.6 .6 .6])
        title(glassLbls{r},'FontSize',15)
        h = gobjects(1,length(subs));
        for s=1:length(subs)
            pd = parallax{s,r}.(field);
            pd(abs(pd)>20) = nan;
            pd = pd-mean(pd,'omitnan');
            [px,py] = quantile2D(parallax{s,r}.dist,pd,bincenters,binedges);
            h(s) = plot(px,py,'o-',Color=colors{s}, MarkerFaceColor=colors{s});
            quantiles{s,r} = [px; py];
        end
        axis tight
        xlim([0 6])
        yl = ylim;
        ylim(yl+(30-diff(yl))*.5*[-1 1]);
        if x==1 && r==1
            legend(h,arrayfun(@(x) sprintf('P%02d',x),1:length(subs),'uni',false),Location="southeast",NumColumns=3, Box="off");
        end
        yls(r,:) = yl;
        if x==2
            axis ij
        end
        ax.XRuler.FontSize=14;
        ax.YRuler.FontSize=14;
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
            yp = [yl2(1)+3 yl2(1)+13];
        else
            if x==1
                yp = [yl2(2)-11 yl2(2)-1];
            else
                yp = [yl2(2)-13 yl2(2)-3];
            end
        end
        xp = [2.8 5.8];
        yl = (yls(r,:)-mean(yls(r,:)))*1.1+mean(yls(r,:));
        iax = MagInset(f1,gca,[0 .5 yl], [xp yp],{'NE','NW';'SE','SW'});
        iax.XRuler.FontSize=12;
        iax.XTick = [0:.1:0.5];
        iax.YRuler.FontSize=12;
    end


    print(sprintf('a_walking\\quantile_%s.png',lower(lbl(1:3))),'-dpng','-r300');
end
