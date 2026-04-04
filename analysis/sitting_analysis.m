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

distances = [30 200];
lims = [-16.2 16.2];

colors = ["F0A3FF","C20088","393939","9DCC00","0075DC","993F00","4C005C","005C31","2BCE48","FFCC99","94FFB5","8F7C00"];
colors = arrayfun(@(x) hex2dec(reshape(char(x),2,3).').'/255, colors,'UniformOutput',false);

parallax = cell(length(subs),length(glasses),length(distances));

% first read config, so we know where the targets are
tarPos = cell(1,length(distances));
for d=1:length(distances)
    fl = fullfile(gaze_folder, 'config',sprintf('parallax_%d',distances(d)),'targetPositions_converted.csv');
    targets = readtable(fl);
    tarPos{d} = [atand((targets.x-targets.x(1))/distances(d)) atand((targets.y-targets.y(1))/distances(d))];
end
assert(all(all(isapprox(tarPos{:})))) % check angles equal for the two viewing distances
tarPos = tarPos{1};

% read all data
for s=1:length(subs)
    for r=1:length(glasses)
        qRec = strcmp({recordings.subj},subs{s}) & strcmp({recordings.glasses},glasses{r});
        for d=1:length(distances)
            % read gaze data
            valData = readtable(fullfile(gaze_folder, recordings(qRec).name, 'et', sprintf('validate_Dynamic validation (parallax_%d)_data_quality.tsv',distances(d))),'FileType','delimitedtext');
            parallax{s,r,d} = groupsummary(valData,'target','median',["acc_x","acc_y"]);
        end
    end
end

% plot offsets per distance
for d=1:length(distances)
    f1 = figure;
    tl = tiledlayout(2,length(glasses)/2,'TileIndexing', 'rowmajor','Padding','tight','TileSpacing','compact');
    for r=1:length(glasses)
        nexttile, hold on
        title(glassLbls{r})
        h = gobjects(1,length(subs));
        for s=1:length(subs)
            dat = [parallax{s,r,d}.median_acc_x parallax{s,r,d}.median_acc_y]+tarPos;
            for p=1:size(dat,1)
                hp = plot([tarPos(p,1) dat(p,1)],[tarPos(p,2) dat(p,2)],'-',Color=colors{s});
                if p==1
                    h(s) = hp;
                end
            end
        end
        plot(tarPos(:,1),tarPos(:,2),'o',Color='b',MarkerFaceColor='b');
        xlim(lims)
        ylim(lims)
        axis ij
        axis square
    end

    xlabel(tl, 'Horizontal gaze position (deg)')
    ylabel(tl, 'Vertical gaze position (deg)')
    title(tl, sprintf('Distance %d cm',distances(d)))

    f1.Position(3) = f1.Position(3)*1.6;
    f1.Position(4) = f1.Position(4)*1.5;
    f1.Position(1:2) = 100;
    print(sprintf('a_sitting\\distance_%d.png',distances(d)),'-dpng','-r300');
end


% plot parallax error
f1 = figure;
tl = tiledlayout(2,length(glasses)/2,'TileIndexing', 'rowmajor','Padding','tight','TileSpacing','compact');
for r=1:length(glasses)
    nexttile, hold on
    title(glassLbls{r})
    h = gobjects(1,length(subs)+1);
    offs = nan(length(subs),5,2);
    for s=1:length(subs)
        off = [parallax{s,r,1}.median_acc_x parallax{s,r,1}.median_acc_y]-[parallax{s,r,2}.median_acc_x parallax{s,r,2}.median_acc_y];
        offs(s,:,:) = off;
        dat = off+tarPos;
        for p=1:size(dat,1)
            hp = plot([tarPos(p,1) dat(p,1)],[tarPos(p,2) dat(p,2)],'-',Color=colors{s});
            if p==1
                h(s) = hp;
            end
        end
    end
    plot(tarPos(:,1),tarPos(:,2),'o',Color='b',MarkerFaceColor='b');
    med_off = squeeze(median(offs));
    for p=1:size(med_off,1)
        hs = plot(tarPos(p,1)+[0 med_off(p,1)], tarPos(p,2)+[0 med_off(p,2)], '-',Color='r',LineWidth=2);
        if p==1
            h(end)=hs;
        end
    end
    xlim(lims)
    ylim(lims)
    axis ij
    axis square
    % xlim([0 6])
    % yl = ylim;
    % ylim(yl+(30-diff(yl))*.5*[-1 1]);
    if r==4
        hl=legend(h,[arrayfun(@(x) sprintf('P%02d',x),1:length(subs),'uni',false) {'median'}],Location="southwest",Box="off",IconColumnWidth=12);
    end
end

xlabel(tl, 'Horizontal gaze position (deg)')
ylabel(tl, 'Vertical gaze position (deg)')

f1.Position(3) = f1.Position(3)*1.6;
f1.Position(4) = f1.Position(4)*1.5;
f1.Position(1:2) = 100;
drawnow
hl.Position(1:2) = [0.058 0.072];
print('a_sitting\\parallax.png','-dpng','-r300');
