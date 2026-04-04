function [xdata,ydata] = quantile2D(xdatain,ydatain,bincenters,binedges)
xdata       = quantile(xdatain,bincenters);

edges       = quantile(xdatain,binedges);
[~,ind]     = histc(xdatain,edges);
qUse        = ind>0 & ind<length(binedges);

ydata       = accumarray(ind(qUse),ydatain(qUse),[],@(x) median(x,'omitnan'));
ydata       = ydata';
