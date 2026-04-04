close all
clear all

datafile = "..\gazeMapper_project\data_quality_Dynamic validation (validate).tsv";
data = readtable(datafile,'FileType','delimitedtext');

val = groupsummary(data,'session',{'mean','median'},'acc');

ETs = split(val.session,'_');
val.ET = ETs(:,2);

valm = groupsummary(val,'ET',{'mean','min','max'},'mean_acc')
