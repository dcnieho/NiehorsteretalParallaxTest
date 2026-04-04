function iaxes=MagInset(h, ax, ZoomArea, InsetPos, Lines)
    % ************ MagInset.m *************
    % * Created: January 1, 2015          *
    % * By: Damien Frost                  *
    % * Inspiration By: Robert Richardson *
    % *************************************
    % 
    % MagInset (Magnified Inset) places an axes inset into an existing 
    % figure with handle h. Re-size your figure and axes before running
    % MagInset.
    %
    % h - handle to a figure on which to place an inset
    %
    % ax - handle to an axes object. Set to -1 to use the default axes in the
    %      figure.
    %
    % ZoomArea - a 4x1 array which defines the zoom area that inset
    %            should have. It is of the form: 
    %                [xmin xmax ymin ymax]
    %            The values are NOT normalized values, but graph values. In
    %            this way, you can easily read off the zoom area you would like
    %            to specify.
    %
    % InsetPos - defines the position of the inset. It is of the form:
    %                [xmin xmax ymin ymax]
    %            The values are NOT normalized values, but graph values. In
    %            this way, you can easily read off the inset area you would
    %            like to specify
    %
    % Lines - defines a list of lines to connect the zoom area with the inset
    %         graph. It can be empty. It should be of the form:
    %             Lines = {'NW','SW'; 'NE','SE'};
    %         It can have as many rows as you wish
    %         The first column is the corner of the Zoom Area. The second column is the
    %         corner of the Inset Axes
    BadInput = 0;
    axesObjs = findobj(h,'Type','Axes');  %axes handles
    % Determine which axes the inset will be placed on:
    if(ax == -1)
        MainAx = axesObjs(end);
    else
        MainAx = -1;
        for ii=1:1:max(size(axesObjs))
            if(axesObjs(ii) == ax)
                MainAx = axesObjs(ii);
                break;
            end
        end
        if(MainAx == -1)
            % Could not find the desired axes:
            fprintf('\nMagInset Error: Could not find the desired axes in the figure.\n');
            BadInput = 1;
        end
    end
    if(BadInput == 0)
        % Get the plot data:
        dataObjs = get(MainAx, 'Children');
        % Annotation positions are of the form:
        % [x y length height]
        % And are normalized to the figure
        % Calculate the normalize rectangular coordinates for the zoom area:
        [zax, zay] = xy2norm(MainAx, ZoomArea(1:2), ZoomArea(3:4));
        [zaxl,zayl] = xy2norm(MainAx, MainAx.XLim, MainAx.YLim);
        zay = sort(zay);
        zayl= sort(zayl);
        zax = max(zaxl(1),min(zaxl(2),zax));
        zay = max(zayl(1),min(zayl(2),zay));
        % Create the rectangle around the area we are going to zoom into:
        annotation('rectangle',[zax(1) zay(1) (zax(2) - zax(1)) (zay(2) - zay(1))]);
        % Calculate the inset position in normalized coordinates;
        [ipx, ipy] = xy2norm(MainAx, InsetPos(1:2), InsetPos(3:4));
        ipy = sort(ipy);
        if(nargin > 4)
            % Add the lines from the zoom area to the inset:
            numLine = size(Lines,1);
            if((numLine>0) && (size(Lines,2) == 2))
                lx = zeros(2,1);
                ly = zeros(2,1);
                for ii=1:1:numLine
                    jj = 1;
                    % Find the co-ordinate in the zoom area:
                    % y co-ordinates:
                    if(Lines{ii,jj}(1) == 'S')
                        ly(jj) = zay(1);
                    else
                        ly(jj) = zay(2);
                    end
                    % x co-ordinates:
                    if(Lines{ii,jj}(2) == 'W')
                        lx(jj) = zax(1);
                    else
                        lx(jj) = zax(2);
                    end
                    jj = 2;
                    % Find the co-ordinate in the inset axes:
                    % y co-ordinates:
                    if(Lines{ii,jj}(1) == 'S')
                        ly(jj) = ipy(1);
                    else
                        ly(jj) = ipy(2);
                    end
                    % x co-ordinates:
                    if(Lines{ii,jj}(2) == 'W')
                        lx(jj) = ipx(1);
                    else
                        lx(jj) = ipx(2);
                    end
                    % Add the line:
                    annotation('line', lx,ly);
                end
            end
        end
        % Add the second set of axes on the same plot:
        iaxes = axes('position', [ipx(1) ipy(1) (ipx(2) - ipx(1)) (ipy(2) - ipy(1))]);
        hold on;
        box on;
        % Add the plots from the original axes onto the inset axes:
        copyobj(dataObjs,iaxes);
        % set the limits on the new axes:
        xlim(ZoomArea(1:2));
        ylim(ZoomArea(3:4));
        iaxes.YDir = MainAx.YDir;
        % Our work here is done.
    end
end

function [xn, yn] = xy2norm(axh, x, y)
%XY2NORM Convert data coordinates (x,y) to normalized figure coordinates (xn,yn).
%   Works with standard axes (axis xy) and axis ij (YDir='reverse').
%   Also respects XDir='reverse'. Optionally handles log scales.
%
%   Inputs:
%     axh - handle to axes
%     x,y - data coordinates (scalar or vectors of the same length)
%
%   Outputs:
%     xn, yn - normalized coordinates in figure space (0..1), aligned to axes Position.
%
%   Notes:
%   - (xn, yn) map the data (x,y) to the rectangle 'Position' of the axes,
%     measured in normalized units relative to the figure.
%   - Tick labels, titles, etc. are not considered (use InnerPosition if desired).
%   - If your axes Units aren’t 'normalized', we temporarily switch to ensure
%     consistent output and restore afterwards.

    % Backwards-compatible axes handle
    axh = handle(axh);

    % Preserve and use normalized units for Position
    oldUnits = axh.Units;
    axh.Units = 'normalized';
    axPos = axh.Position;  % [left bottom width height] in figure-normalized coords
    axh.Units = oldUnits;  % restore

    % Limits and directions
    xlims = axh.XLim;
    ylims = axh.YLim;
    xdir  = axh.XDir;      % 'normal' or 'reverse'
    ydir  = axh.YDir;      % 'normal' or 'reverse' (axis ij => 'reverse')
    xscale = axh.XScale;   % 'linear' or 'log'
    yscale = axh.YScale;   % 'linear' or 'log'

    % Compute fractional positions along each axis
    xfrac = fracAlongAxis(x, xlims, xdir, xscale);
    yfrac = fracAlongAxis(y, ylims, ydir, yscale);

    % Map to figure-normalized coordinates inside the axes rectangle
    xn = axPos(1) + axPos(3) .* xfrac;
    yn = axPos(2) + axPos(4) .* yfrac;
end

function f = fracAlongAxis(val, lims, dir, scale)
%FRACALONGAXIS Return fractional position in [0,1] along an axis
% respecting axis direction and (linear/log) scaling.
%
%   val  - data values (scalar or vector)
%   lims - [min max] axis limits
%   dir  - 'normal' or 'reverse'
%   scale- 'linear' or 'log'

    % Robust to vector inputs
    val = double(val);
    lims = double(lims);

    % Handle scale
    switch lower(scale)
        case 'linear'
            t = (val - lims(1)) ./ (lims(2) - lims(1));
        case 'log'
            % Use log10 mapping; assumes lims>0 and val>0 for log axes
            t = (log10(val) - log10(lims(1))) ./ (log10(lims(2)) - log10(lims(1)));
        otherwise
            error('Unsupported axis scale: %s', scale);
    end

    % Handle direction
    switch lower(dir)
        case 'normal'
            f = t;
        case 'reverse'
            f = 1 - t;
        otherwise
            error('Unsupported axis direction: %s', dir);
    end
end







function [pos_norm_inner, pos_norm_outer, pos_fig_px, outer_fig_px] = axesNormalizedInFigure(ax)
%AXESNORMALIZEDINFIGURE Axes position in figure-normalized coordinates.
% Robust with TILEDLAYOUT. Uses figure InnerPosition origin & size for exact match.
%
% [POS_NORM_INNER, POS_NORM_OUTER] = AXESNORMALIZEDINFIGURE(AX)
% [POS_NORM_INNER, POS_NORM_OUTER, POS_FIG_PX, OUTER_FIG_PX]
%
% POS_NORM_INNER : inner plotting box, figure-normalized
% POS_NORM_OUTER : bounding box incl. title/labels/ticks, figure-normalized
% POS_FIG_PX     : inner plotting box, in figure pixels (relative to interior)
% OUTER_FIG_PX   : outer bounding box, in figure pixels (relative to interior)
%
% Example:
%   figure; ax = gca;
%   [a,b] = axesNormalizedInFigure(ax);
%   % For axes whose parent is the figure and Units='normalized',
%   % 'a' should match ax.Position exactly (modulo rounding at pixel boundaries).
%   annotation('rectangle','Units','normalized','Position',b,'Color','r');

    % Validate
    if nargin < 1 || ~isa(ax,'matlab.graphics.axis.Axes')
        error('axesNormalizedInFigure:InvalidInput','Input must be an axes handle.');
    end
    fig = ancestor(ax,'figure');
    if isempty(fig) || ~ishandle(fig)
        error('axesNormalizedInFigure:NoFigure','Axes has no ancestor figure.');
    end

    % ---- Fast path: axes parent is the figure ----
    % When the axes live directly under the figure, MATLAB already stores
    % Position in figure-normalized units (if ax.Units='normalized').
    if isequal(ax.Parent, fig) && strcmpi(ax.Units,'normalized')
        pos_norm_inner = ax.Position;
        % Outer box via TightInset in normalized units
        oldUnits = ax.Units; ax.Units = 'pixels';
        ti_px = ax.TightInset; ax.Units = oldUnits;

        % Convert TightInset pixels to normalized using figure inner size
        oldFigUnits = fig.Units; fig.Units = 'pixels'; inner = fig.InnerPosition; fig.Units = oldFigUnits;
        ti_norm = [ti_px(1)/inner(3), ti_px(2)/inner(4), ti_px(3)/inner(3), ti_px(4)/inner(4)];

        pos_norm_outer = [ ...
            pos_norm_inner(1)-ti_norm(1), ...
            pos_norm_inner(2)-ti_norm(2), ...
            pos_norm_inner(3)+ti_norm(1)+ti_norm(3), ...
            pos_norm_inner(4)+ti_norm(2)+ti_norm(4) ];

        % Pixel outputs (relative to interior)
        oldAxUnits = ax.Units; ax.Units = 'pixels';
        pos_fig_px = ax.Position; ax.Units = oldAxUnits;
        outer_fig_px = [ ...
            pos_fig_px(1)-ti_px(1), pos_fig_px(2)-ti_px(2), ...
            pos_fig_px(3)+ti_px(1)+ti_px(3), pos_fig_px(4)+ti_px(2)+ti_px(4) ];
        return;
    end

    % ---- General path: nested parents (e.g., tiledlayout) ----
    % 1) Get axes rectangle in *figure* pixel coordinates:
    ax_fig_px_global = getpixelposition(ax, true);   % [x y w h], relative to figure outer frame

    % 2) Translate to figure *interior* origin:
    oldFigUnits = fig.Units; fig.Units = 'pixels';
    fig_inner = fig.InnerPosition;                   % [x y w h] in pixels, interior relative to figure outer
    fig.Units = oldFigUnits;

    pos_fig_px = [ ...
        ax_fig_px_global(1) - fig_inner(1), ...
        ax_fig_px_global(2) - fig_inner(2), ...
        ax_fig_px_global(3), ...
        ax_fig_px_global(4) ];

    % 3) TightInset in pixels
    oldAxUnits = ax.Units; ax.Units = 'pixels';
    ti_px = ax.TightInset;                           % [L B R T] in pixels
    ax.Units = oldAxUnits;

    outer_fig_px = [ ...
        pos_fig_px(1) - ti_px(1), ...
        pos_fig_px(2) - ti_px(2), ...
        pos_fig_px(3) + ti_px(1) + ti_px(3), ...
        pos_fig_px(4) + ti_px(2) + ti_px(4) ];

    % 4) Normalize by the figure *interior* size:
    W = fig_inner(3); H = fig_inner(4);
    if any([W H] <= 0)
        error('axesNormalizedInFigure:ZeroFigureSize','Figure inner width/height are zero.');
    end

    pos_norm_inner = [pos_fig_px(1)/W, pos_fig_px(2)/H, pos_fig_px(3)/W, pos_fig_px(4)/H];
    pos_norm_outer = [outer_fig_px(1)/W, outer_fig_px(2)/H, outer_fig_px(3)/W, outer_fig_px(4)/H];
end
