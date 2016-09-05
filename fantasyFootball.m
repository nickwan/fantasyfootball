%% Fantasy Football stats from 2015
% This is really just a thrown-together analysis -- really basic statistics
% Everything is MATLAB code, but for my blog post I use gramm for
% visualization, so if you are seeking to run the visualizations from this
% post then you'll also need gramm!
%
% You'll find this code broken up from a "top-down" manner: starting with
% broad strokes of overall rankings and variance, diving into each position
% rankings and variance, with a final analysis of comparisons between
% positions and variance.
%
% I sort of cheat on the CSV load and used the Import Data - Generate
% Script method. It's lazy, but whatevs. 
% 
% Data is pulled from Pro Football Reference (http://www.pro-football-reference.com/years/2015/fantasy.htm). 
% You can most likely use this code for previous years if you'd like (may
% take some messing with, particularly with your "startRow" variable)

%% User-defined variables
% Clear the workspace
clear all

% Raw CSV from Pro Football Reference (I used 2015 season)
RawData = '/Users/leapnirs/Desktop/football/fantasy/years_2015_fantasy_fantasy.csv';

%% Import data
% Import data from text file.

% Initialize variables.
filename = RawData;
delimiter = ',';
startRow = 2;

% Read columns of data as strings:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%[^\n\r]';

% Open the text file.
fileID = fopen(filename,'r');

% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'HeaderLines' ,startRow-1, 'ReturnOnError', false);

% Close the text file.
fclose(fileID);

% Convert the contents of columns containing numeric strings to numbers.
% Replace non-numeric strings with NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = dataArray{col};
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27]
    % Converts strings in the input cell array to numbers. Replaced non-numeric
    % strings with NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1);
        % Create a regular expression to detect and remove non-numeric prefixes and
        % suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData{row}, regexstr, 'names');
            numbers = result.numbers;
            
            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if any(numbers==',');
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(thousandsRegExp, ',', 'once'));
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric strings to numbers.
            if ~invalidThousandsSeparator;
                numbers = textscan(strrep(numbers, ',', ''), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch me
        end
    end
end

% Split data into numeric and cell columns.
rawNumericColumns = raw(:, [1,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27]);
rawCellColumns = raw(:, [2,3,4]);

% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
rawNumericColumns(R) = {NaN}; % Replace non-numeric cells

% Allocate imported array to column variable names
% NOTE: I personally restructured this into one giant structure, as opposed
% to column vectors per variable. 
fb.Rk = cell2mat(rawNumericColumns(:, 1)); % You can treat Rk as a unique ID key
fb.Name = rawCellColumns(:, 1);
fb.Tm = rawCellColumns(:, 2);
fb.FantPos = rawCellColumns(:, 3);
fb.Age = cell2mat(rawNumericColumns(:, 2));
fb.G = cell2mat(rawNumericColumns(:, 3));
fb.GS = cell2mat(rawNumericColumns(:, 4));
fb.PassCmp = cell2mat(rawNumericColumns(:, 5));
fb.PassAtt = cell2mat(rawNumericColumns(:, 6));
fb.PassYds = cell2mat(rawNumericColumns(:, 7));
fb.PassTD = cell2mat(rawNumericColumns(:, 8));
fb.PassInt = cell2mat(rawNumericColumns(:, 9));
fb.RushAtt = cell2mat(rawNumericColumns(:, 10));
fb.RushYds = cell2mat(rawNumericColumns(:, 11));
fb.RushYA = cell2mat(rawNumericColumns(:, 12));
fb.RushTD = cell2mat(rawNumericColumns(:, 13));
fb.ReceiveTgt = cell2mat(rawNumericColumns(:, 14));
fb.ReceiveRec = cell2mat(rawNumericColumns(:, 15));
fb.ReceiveYds = cell2mat(rawNumericColumns(:, 16));
fb.ReceiveYR = cell2mat(rawNumericColumns(:, 17));
fb.ReceiveTD = cell2mat(rawNumericColumns(:, 18));
fb.FantPt = cell2mat(rawNumericColumns(:, 19));
fb.DKPt = cell2mat(rawNumericColumns(:, 20));
fb.FDPt = cell2mat(rawNumericColumns(:, 21));
fb.VBD = cell2mat(rawNumericColumns(:, 22));
fb.PosRank = cell2mat(rawNumericColumns(:, 23));
fb.OvRank = cell2mat(rawNumericColumns(:, 24));

% Clear temporary variables
clearvars filename delimiter startRow formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp me rawNumericColumns rawCellColumns R;

%% Overall stats

% Create a points per game field in fb for all players who played a game
% (fb.G) and also generated fantasy points (fb.FantPt)
fb.ppg = []; 
for x = 1:length(fb.Rk);
   if isnan(fb.FantPt(x)) == 1 || isnan(fb.G(x)) == 1;
       fb.ppg = [fb.ppg; NaN];
   else
       fb.ppg = [fb.ppg; fb.FantPt(x)/fb.G(x)];
   end
end

% Creates jittered scatter and box plot for each position
g(1,1) = gramm('x',fb.FantPos,'y',fb.ppg,'color',fb.FantPos);
g(1,1).geom_jitter();
g(1,1).no_legend();
g(1,1).set_names('x', ' ', 'y', 'Fantasy Points (per game)');
g(1,1).set_color_options('map','brewer1');

g(1,2) = gramm('x',fb.FantPos,'y',fb.ppg,'color',fb.FantPos);
g(1,2).stat_boxplot();
g(1,2).set_names('x', ' ', 'y', ' ','color','Position');
g(1,2).set_color_options('map','brewer1');

g.set_title('Fantasy Points per Game (all players, each position)');
figure('Position',[100 100 900 550]);
g.draw();

% Create "tiers" based on standard deviation for each position based on
% standard deviation

% I'm copying out of fb so I don't overwrite raw data
temp.FP = fb.FantPos;
temp.PPG = fb.ppg;
temp.FP(isnan(fb.FantPt)) = [];
temp.PPG(isnan(fb.FantPt)) = [];

% This gets all of the descriptive stats per position into one structure
FFds.QB = [mean([fb.ppg(strcmp(temp.FP,'QB'))]) std([fb.ppg(strcmp(temp.FP,'QB'))])];
FFds.RB = [mean([fb.ppg(strcmp(temp.FP,'RB'))]) std([fb.ppg(strcmp(temp.FP,'RB'))])];
FFds.WR = [mean([fb.ppg(strcmp(temp.FP,'WR'))]) std([fb.ppg(strcmp(temp.FP,'WR'))])];
FFds.TE = [mean([fb.ppg(strcmp(temp.FP,'TE'))]) std([fb.ppg(strcmp(temp.FP,'TE'))])];

% we can clear the temp stuff now
clear temp

% puts each player in a tier for their position (1 = highest, 4 = lowest);
fb.tier = [];
for x = 1:length(fb.Rk);
    if strcmp(fb.FantPos(x),'');
        fb.tier = [fb.tier; NaN]; 
    elseif fb.ppg(x) >= FFds.(fb.FantPos{x})(1)+FFds.(fb.FantPos{x})(2);
        fb.tier = [fb.tier; 1];
    elseif fb.ppg(x) >= FFds.(fb.FantPos{x})(1) & fb.ppg(x)<FFds.(fb.FantPos{x})(1)+FFds.(fb.FantPos{x})(2);
        fb.tier = [fb.tier; 2];
    elseif fb.ppg(x) >= FFds.(fb.FantPos{x})(1)-FFds.(fb.FantPos{x})(2) & fb.ppg(x)<FFds.(fb.FantPos{x})(1);
        fb.tier = [fb.tier; 3];
    elseif fb.ppg(x) < FFds.(fb.FantPos{x})(1)-FFds.(fb.FantPos{x})(2);
        fb.tier = [fb.tier; 4];
    else
        fb.tier = [fb.tier; NaN]; % still keeping in NaNs for data posterity, will copy out of raw data into a temp structure if necessary
    end
end

% Creates a jittered scatter and box plot for each position, colored by tier
g(1,1) = gramm('x',fb.FantPos,'y',fb.ppg,'color',fb.tier);
g(1,1).geom_jitter();
g(1,1).no_legend();
g(1,1).set_names('x', ' ', 'y', 'Fantasy Points (per game)');
g(1,1).set_color_options('map','brewer1');

g(1,2) = gramm('x',fb.FantPos,'y',fb.ppg,'color',fb.tier);
g(1,2).stat_boxplot();
g(1,2).set_names('x', ' ', 'y', ' ','color','Tier');
g(1,2).set_color_options('map','brewer1');

g.set_title('Fantasy Points per Game (ranked in tiers)');
figure('Position',[100 100 900 550]);
g.draw();

%% QB specific stats

% Create completion percentage (fb.CompPct), yards per game (fb.ypg), TDs
% per game (fb.tdpg), and interceptions per game (fb.intpg)

fb.CompPct = fb.PassCmp./fb.PassAtt; % Completion percent
fb.ypg = fb.PassYds./fb.G; % Yards per game
fb.tdpg = fb.PassTD./fb.G; % TDs per game
fb.intpg = fb.PassInt./fb.G; % Interceptions per game
fb.y2pg = fb.RushYds./fb.G; % QB rush yards per game
fb.td2pg = fb.RushTD./fb.G; % QB rush TDs per game

% Create scatters against points per game for each stat
% This is out of order because I went back to set the order to how I wanted
% it after I coded it. Really lazy, I know, but it works. It gets less
% messy in the subsequent sections!

% Completion percentage (the comments here follow the same logic for each
% subsequent graph)
temp.ppg = fb.ppg(strcmp(fb.FantPos,'QB') & isnan(fb.CompPct)==0 & isnan(fb.ppg)==0); % copying from the raw data, clearing out non-QB data
temp.CompPct = fb.CompPct(strcmp(fb.FantPos,'QB') & isnan(fb.CompPct)==0 & isnan(fb.ppg)==0); 
temp.tier = fb.tier(strcmp(fb.FantPos,'QB') & isnan(fb.CompPct)==0 & isnan(fb.ppg)==0); 
p = polyfit(temp.ppg,temp.CompPct,1); % gets slope/intercept info; I went this route versus the GLM because the error bars didn't really tell any better of a story for my blog post; you can switch out abline for glm if you want (when you're overlapping, remember to use g.update() )
clear g % this is messy, but this clears the previous gramm object
g(3,2) = gramm('x',temp.ppg,'y',temp.CompPct,'color',temp.tier);
g(3,2).geom_abline('slope',p(1),'intercept',p(2),'style','k'); % you can alternatively use the stat_glm() function if you want error bars
g(3,2).geom_point(); % makes the scatter
g(3,2).set_color_options('map','brewer1'); % brewer 1 is my go-to for this blog post
g(3,2).set_names('x','Points per game','y','Completions (%)', 'color', 'Tier'); 
% the legend ends up going here, which slightly messes with the sizing of
% this graph versus the others... but I guess I really don't care.
% Alternatively, you can no_legend() all of these graphs since the tier
% legend appeared previously, but you know... shrugs dot gif

% Yards per game
temp.ppg = fb.ppg(strcmp(fb.FantPos,'QB') & fb.ypg~=0 & isnan(fb.ppg)==0);
temp.ypg = fb.ypg(strcmp(fb.FantPos,'QB') & fb.ypg~=0 & isnan(fb.ppg)==0);
temp.tier = fb.tier(strcmp(fb.FantPos,'QB') & fb.ypg~=0 & isnan(fb.ppg)==0);
p = polyfit(temp.ppg,temp.ypg,1);
g(2,1) = gramm('x',temp.ppg,'y',temp.ypg,'color',temp.tier);
g(2,1).geom_abline('slope',p(1),'intercept',p(2),'style','k');
g(2,1).geom_point();
g(2,1).set_color_options('map','brewer1');
g(2,1).set_names('x','Points per game','y','Pass Yards per game');
g(2,1).no_legend();


% Touchdowns per game
temp.ppg = fb.ppg(strcmp(fb.FantPos,'QB') & fb.tdpg~=0 & isnan(fb.ppg)==0);
temp.tdpg = fb.tdpg(strcmp(fb.FantPos,'QB') & fb.tdpg~=0 & isnan(fb.ppg)==0);
temp.tier = fb.tier(strcmp(fb.FantPos,'QB') & fb.tdpg~=0 & isnan(fb.ppg)==0);
p = polyfit(temp.ppg,temp.tdpg,1);
g(1,1) = gramm('x',temp.ppg,'y',temp.tdpg,'color',temp.tier);
g(1,1).geom_abline('slope',p(1),'intercept',p(2),'style','k');
g(1,1).geom_point();
g(1,1).set_color_options('map','brewer1');
g(1,1).set_names('x','Points per game','y','Passing TDs per game');
g(1,1).no_legend();

% Interceptions per game
temp.ppg = fb.ppg(strcmp(fb.FantPos,'QB') & fb.intpg~=0 & isnan(fb.ppg)==0);
temp.intpg = fb.intpg(strcmp(fb.FantPos,'QB') & fb.intpg~=0 & isnan(fb.ppg)==0);
temp.tier = fb.tier(strcmp(fb.FantPos,'QB') & fb.intpg~=0 & isnan(fb.ppg)==0);
p = polyfit(temp.ppg,temp.intpg,1);
g(3,1) = gramm('x',temp.ppg,'y',temp.intpg,'color',temp.tier);
g(3,1).geom_abline('slope',p(1),'intercept',p(2),'style','k');
g(3,1).geom_point();
g(3,1).set_color_options('map','brewer1');
g(3,1).set_names('x','Points per game','y','Interceptions per game');
g(3,1).no_legend();

% Rushing touchdowns per game
temp.ppg = fb.ppg(strcmp(fb.FantPos,'QB') & fb.td2pg~=0 & isnan(fb.ppg)==0);
temp.td2pg = fb.td2pg(strcmp(fb.FantPos,'QB') & fb.td2pg~=0 & isnan(fb.ppg)==0);
temp.tier = fb.tier(strcmp(fb.FantPos,'QB') & fb.td2pg~=0 & isnan(fb.ppg)==0);
p = polyfit(temp.ppg,temp.td2pg,1);
g(1,2) = gramm('x',temp.ppg,'y',temp.td2pg,'color',temp.tier);
g(1,2).geom_abline('slope',p(1),'intercept',p(2),'style','k');
g(1,2).geom_point();
g(1,2).set_color_options('map','brewer1');
g(1,2).set_names('x','Points per game','y','Rush TDs per game');
g(1,2).no_legend();

% Rushing yards per game
temp.ppg = fb.ppg(strcmp(fb.FantPos,'QB') & fb.y2pg~=0 & isnan(fb.ppg)==0);
temp.y2pg = fb.y2pg(strcmp(fb.FantPos,'QB') & fb.y2pg~=0 & isnan(fb.ppg)==0);
temp.tier = fb.tier(strcmp(fb.FantPos,'QB') & fb.y2pg~=0 & isnan(fb.ppg)==0);
p = polyfit(temp.ppg,temp.y2pg,1);
g(2,2) = gramm('x',temp.ppg,'y',temp.y2pg,'color',temp.tier);
g(2,2).geom_abline('slope',p(1),'intercept',p(2),'style','k');
g(2,2).geom_point();
g(2,2).set_color_options('map','brewer1');
g(2,2).set_names('x','Points per game','y','Rush yards per game', 'color', 'Tier');
g(2,2).no_legend();

g.set_title('Quarterback Stats vs Points per Game');
figure('Position',[100 100 900 550]);
g.draw();

clear temp g % from here on out, you'll see this clear versus the previous clear

%% RB specific stats

% rush yards and rush TDs were made in the previous screen
% rush yards per game are fb.y2pg
% rush TDs per game are fb.td2pg
fb.rpg = fb.RushAtt./fb.G; % rushes per game
fb.recpg = fb.ReceiveRec./fb.G; % receptions per game
fb.y3pg = fb.ReceiveYds./fb.G; % receiving yards per game
fb.td3pg = fb.ReceiveTD./fb.G; %receiving TDs per game


% Create scatters against points per game for each stat

% Rush TDs (the comments here follow the same logic for each
% subsequent graph)
temp.ppg = fb.ppg(strcmp(fb.FantPos,'RB') & fb.td2pg~=0 & isnan(fb.ppg)==0); % copying from the raw data, clearing out non-QB data
temp.td2pg = fb.td2pg(strcmp(fb.FantPos,'RB') & fb.td2pg~=0 & isnan(fb.ppg)==0); 
temp.tier = fb.tier(strcmp(fb.FantPos,'RB') & fb.td2pg~=0 & isnan(fb.ppg)==0); 
p = polyfit(temp.ppg,temp.td2pg,1); % gets slope/intercept info; I went this route versus the GLM because the error bars didn't really tell any better of a story for my blog post; you can switch out abline for glm if you want (when you're overlapping, remember to use g.update() )
g(1,1) = gramm('x',temp.ppg,'y',temp.td2pg,'color',temp.tier);
g(1,1).geom_abline('slope',p(1),'intercept',p(2),'style','k'); % you can alternatively use the stat_glm() function if you want error bars
g(1,1).geom_point(); % makes the scatter
g(1,1).set_color_options('map','brewer1'); % brewer 1 is my go-to for this blog post
g(1,1).set_names('x','Points per game','y','Rush TDs per game'); 
g(1,1).no_legend();

% Rush yards
temp.ppg = fb.ppg(strcmp(fb.FantPos,'RB') & fb.y2pg~=0 & isnan(fb.ppg)==0); 
temp.y2pg = fb.y2pg(strcmp(fb.FantPos,'RB') & fb.y2pg~=0 & isnan(fb.ppg)==0); 
temp.tier = fb.tier(strcmp(fb.FantPos,'RB') & fb.y2pg~=0 & isnan(fb.ppg)==0); 
p = polyfit(temp.ppg,temp.y2pg,1); 
g(2,1) = gramm('x',temp.ppg,'y',temp.y2pg,'color',temp.tier);
g(2,1).geom_abline('slope',p(1),'intercept',p(2),'style','k'); 
g(2,1).geom_point(); 
g(2,1).set_color_options('map','brewer1'); 
g(2,1).set_names('x','Points per game','y','Rush yards per game'); 
g(2,1).no_legend();

% Rush attempts
temp.ppg = fb.ppg(strcmp(fb.FantPos,'RB') & fb.rpg~=0 & isnan(fb.ppg)==0); 
temp.rpg = fb.rpg(strcmp(fb.FantPos,'RB') & fb.rpg~=0 & isnan(fb.ppg)==0); 
temp.tier = fb.tier(strcmp(fb.FantPos,'RB') & fb.rpg~=0 & isnan(fb.ppg)==0); 
p = polyfit(temp.ppg,temp.rpg,1); 
g(3,1) = gramm('x',temp.ppg,'y',temp.rpg,'color',temp.tier);
g(3,1).geom_abline('slope',p(1),'intercept',p(2),'style','k'); 
g(3,1).geom_point(); 
g(3,1).set_color_options('map','brewer1'); 
g(3,1).set_names('x','Points per game','y','Rush attempts per game'); 
g(3,1).no_legend();

% Receiving TDs
temp.ppg = fb.ppg(strcmp(fb.FantPos,'RB') & fb.td3pg~=0 & isnan(fb.ppg)==0); 
temp.td3pg = fb.td3pg(strcmp(fb.FantPos,'RB') & fb.td3pg~=0 & isnan(fb.ppg)==0); 
temp.tier = fb.tier(strcmp(fb.FantPos,'RB') & fb.td3pg~=0 & isnan(fb.ppg)==0); 
p = polyfit(temp.ppg,temp.td3pg,1); 
g(1,2) = gramm('x',temp.ppg,'y',temp.td3pg,'color',temp.tier);
g(1,2).geom_abline('slope',p(1),'intercept',p(2),'style','k'); 
g(1,2).geom_point(); 
g(1,2).set_color_options('map','brewer1'); 
g(1,2).set_names('x','Points per game','y','Receiving TDs per game'); 
g(1,2).no_legend();

% Receiving yards
temp.ppg = fb.ppg(strcmp(fb.FantPos,'RB') & fb.y3pg~=0 & isnan(fb.ppg)==0); 
temp.y3pg = fb.y3pg(strcmp(fb.FantPos,'RB') & fb.y3pg~=0 & isnan(fb.ppg)==0); 
temp.tier = fb.tier(strcmp(fb.FantPos,'RB') & fb.y3pg~=0 & isnan(fb.ppg)==0); 
p = polyfit(temp.ppg,temp.y3pg,1); 
g(2,2) = gramm('x',temp.ppg,'y',temp.y3pg,'color',temp.tier);
g(2,2).geom_abline('slope',p(1),'intercept',p(2),'style','k'); 
g(2,2).geom_point(); 
g(2,2).set_color_options('map','brewer1'); 
g(2,2).set_names('x','Points per game','y','Receiving yards per game'); 
g(2,2).no_legend();

% Receptions
temp.ppg = fb.ppg(strcmp(fb.FantPos,'RB') & fb.recpg~=0 & isnan(fb.ppg)==0); 
temp.recpg = fb.recpg(strcmp(fb.FantPos,'RB') & fb.recpg~=0 & isnan(fb.ppg)==0); 
temp.tier = fb.tier(strcmp(fb.FantPos,'RB') & fb.recpg~=0 & isnan(fb.ppg)==0); 
p = polyfit(temp.ppg,temp.recpg,1); 
g(3,2) = gramm('x',temp.ppg,'y',temp.recpg,'color',temp.tier);
g(3,2).geom_abline('slope',p(1),'intercept',p(2),'style','k'); 
g(3,2).geom_point(); 
g(3,2).set_color_options('map','brewer1'); 
g(3,2).set_names('x','Points per game','y','Receptions per game', 'color', 'Tier'); 

g.set_title('Running Back Stats vs Points per Game');
figure('Position',[100 100 900 550]);
g.draw();

clear temp g % from here on out, you'll see this clear versus the previous clear

%% WR specific stats
% this should run as-is; literally only changed the position and copied the
% RB code

% Receiving TDs
temp.ppg = fb.ppg(strcmp(fb.FantPos,'WR') & fb.td3pg~=0 & isnan(fb.ppg)==0); 
temp.td3pg = fb.td3pg(strcmp(fb.FantPos,'WR') & fb.td3pg~=0 & isnan(fb.ppg)==0); 
temp.tier = fb.tier(strcmp(fb.FantPos,'WR') & fb.td3pg~=0 & isnan(fb.ppg)==0); 
p = polyfit(temp.ppg,temp.td3pg,1); 
g(1,1) = gramm('x',temp.ppg,'y',temp.td3pg,'color',temp.tier);
g(1,1).geom_abline('slope',p(1),'intercept',p(2),'style','k'); 
g(1,1).geom_point(); 
g(1,1).set_color_options('map','brewer1'); 
g(1,1).set_names('x','Points per game','y','Receiving TDs per game'); 
g(1,1).no_legend();

% Receiving yards
temp.ppg = fb.ppg(strcmp(fb.FantPos,'WR') & fb.y3pg~=0 & isnan(fb.ppg)==0); 
temp.y3pg = fb.y3pg(strcmp(fb.FantPos,'WR') & fb.y3pg~=0 & isnan(fb.ppg)==0); 
temp.tier = fb.tier(strcmp(fb.FantPos,'WR') & fb.y3pg~=0 & isnan(fb.ppg)==0); 
p = polyfit(temp.ppg,temp.y3pg,1); 
g(2,1) = gramm('x',temp.ppg,'y',temp.y3pg,'color',temp.tier);
g(2,1).geom_abline('slope',p(1),'intercept',p(2),'style','k'); 
g(2,1).geom_point(); 
g(2,1).set_color_options('map','brewer1'); 
g(2,1).set_names('x','Points per game','y','Receiving yards per game'); 
g(2,1).no_legend();

% Receptions
temp.ppg = fb.ppg(strcmp(fb.FantPos,'WR') & fb.recpg~=0 & isnan(fb.ppg)==0); 
temp.recpg = fb.recpg(strcmp(fb.FantPos,'WR') & fb.recpg~=0 & isnan(fb.ppg)==0); 
temp.tier = fb.tier(strcmp(fb.FantPos,'WR') & fb.recpg~=0 & isnan(fb.ppg)==0); 
p = polyfit(temp.ppg,temp.recpg,1); 
g(3,1) = gramm('x',temp.ppg,'y',temp.recpg,'color',temp.tier);
g(3,1).geom_abline('slope',p(1),'intercept',p(2),'style','k'); 
g(3,1).geom_point(); 
g(3,1).set_color_options('map','brewer1'); 
g(3,1).set_names('x','Points per game','y','Receptions per game', 'color', 'Tier'); 

g.set_title('Wide Receiver Stats vs Points per Game');
figure('Position',[100 100 900 550]);
g.draw();

clear temp g 

%% TE specific stats
% This is literally the WR code, but with TE in there for position.

% Receiving TDs
temp.ppg = fb.ppg(strcmp(fb.FantPos,'TE') & fb.td3pg~=0 & isnan(fb.ppg)==0); 
temp.td3pg = fb.td3pg(strcmp(fb.FantPos,'TE') & fb.td3pg~=0 & isnan(fb.ppg)==0); 
temp.tier = fb.tier(strcmp(fb.FantPos,'TE') & fb.td3pg~=0 & isnan(fb.ppg)==0); 
p = polyfit(temp.ppg,temp.td3pg,1); 
g(1,1) = gramm('x',temp.ppg,'y',temp.td3pg,'color',temp.tier);
g(1,1).geom_abline('slope',p(1),'intercept',p(2),'style','k'); 
g(1,1).geom_point(); 
g(1,1).set_color_options('map','brewer1'); 
g(1,1).set_names('x','Points per game','y','Receiving TDs per game'); 
g(1,1).no_legend();

% Receiving yards
temp.ppg = fb.ppg(strcmp(fb.FantPos,'TE') & fb.y3pg~=0 & isnan(fb.ppg)==0); 
temp.y3pg = fb.y3pg(strcmp(fb.FantPos,'TE') & fb.y3pg~=0 & isnan(fb.ppg)==0); 
temp.tier = fb.tier(strcmp(fb.FantPos,'TE') & fb.y3pg~=0 & isnan(fb.ppg)==0); 
p = polyfit(temp.ppg,temp.y3pg,1); 
g(2,1) = gramm('x',temp.ppg,'y',temp.y3pg,'color',temp.tier);
g(2,1).geom_abline('slope',p(1),'intercept',p(2),'style','k'); 
g(2,1).geom_point(); 
g(2,1).set_color_options('map','brewer1'); 
g(2,1).set_names('x','Points per game','y','Receiving yards per game'); 
g(2,1).no_legend();

% Receptions
temp.ppg = fb.ppg(strcmp(fb.FantPos,'TE') & fb.recpg~=0 & isnan(fb.ppg)==0); 
temp.recpg = fb.recpg(strcmp(fb.FantPos,'TE') & fb.recpg~=0 & isnan(fb.ppg)==0); 
temp.tier = fb.tier(strcmp(fb.FantPos,'TE') & fb.recpg~=0 & isnan(fb.ppg)==0); 
p = polyfit(temp.ppg,temp.recpg,1); 
g(3,1) = gramm('x',temp.ppg,'y',temp.recpg,'color',temp.tier);
g(3,1).geom_abline('slope',p(1),'intercept',p(2),'style','k'); 
g(3,1).geom_point(); 
g(3,1).set_color_options('map','brewer1'); 
g(3,1).set_names('x','Points per game','y','Receptions per game', 'color', 'Tier'); 

g.set_title('Tight End Stats vs Points per Game');
figure('Position',[100 100 900 550]);
g.draw();

clear temp g 
