%%% CreateOpticFlowGIF: Generate GIF illustrating optic flow
%%% Written by Nicole Peltier (July 5, 2020)
%%%
%%% Input variables:
%%%   Required:
%%%     - trans_vel: t*3 array; translational self-velocity in U (lateral),
%%%       V (vertical), W (fore/aft) dimensions for each of t trials
%%%     - rot_vel: t*3 array; rotational self-velocity in A (pitch),
%%%       B (yaw), C (roll) dimensions for each of t trials
%%%   Optional:
%%%     - filepath: string; directory to save GIF; if not entered, user 
%%%       prompted to select directory to save gif
%%%     - filename: string; file name to save GIF; (default: 
%%%       'OpticFlow.gif')
%%%
%%% Output: GIF illustrating optic flow with self-motion specified by user.
%%% Multiple trials strung together with blank screen between trials.

function CreateOpticFlowGIF(trans_vel, rot_vel, filepath, filename)

if nargin<3
    filepath = uigetdir;
end
if nargin<4
    filename = 'OpticFlow.gif';
end

savename = [filepath '\' filename];

% Translational self-motion components
U = trans_vel(:,1);
V = trans_vel(:,2);
W = trans_vel(:,3);

% Rotational self-motion components
A = rot_vel(:,1);
B = rot_vel(:,2);
C = rot_vel(:,3);

% Flag for stereo depth cues
stereo = 0;

% Basic stimulus/video parameters
stim_dur = 3;% seconds
num_frames = 150;
frame_dur = stim_dur/num_frames;
IOD = 0.035;% interocular distance in meters
num_OFdots = 4000;
max_val = 1.0;
min_val = -max_val;
clip_near = 0.05;% meters
clip_far = 1.50;
view_dist = 0.33;
star_size = 8;

% Self motion parameters
num_sigmas = 6;
x_gauss = 1:num_frames;
velocity_profile = normpdf(x_gauss, num_frames/2, num_frames/num_sigmas);


% Initialize figure
motion_stim = cell(1, num_frames);
fig = figure();
set(fig, 'Units', 'centimeters', 'Position', [0, 0, 24, 24]);

% Black screen
clf;
axes('box','off','xtick',[],'ytick',[],'ztick',[],'xcolor',[0 0 0],'ycolor',[0 0 0]);
set(gca,'position',[0 0 1 1],'units','normalized');
set(gca,'xticklabel',[]);
set(gca,'yticklabel',[]);
xlim([-0.3, 0.3]);
ylim([-0.3, 0.3]);
set(gca,'Color','k');
set(get(gca,'title'),'Position', [0, 0.85*max(get(gca,'ylim')), 0.5]);
drawnow;
frame = getframe;
black_screen = frame2im(frame);

% Fixation point
clf;
axes('box','off','xtick',[],'ytick',[],'ztick',[],'xcolor',[0 0 0],'ycolor',[0 0 0]);
set(gca,'position',[0 0 1 1],'units','normalized');
fp_size = 0.006;
fp_loc = [0-fp_size/2, fp_size/2, fp_size, fp_size];
rectangle('Position', fp_loc, 'FaceColor', 'y');
set(gca,'xticklabel',[]);
set(gca,'yticklabel',[]);
xlim([-0.3, 0.3]);
ylim([-0.3, 0.3]);
set(gca,'Color','k');
set(get(gca,'title'),'Position', [0, 0.85*max(get(gca,'ylim')), 0.5]);
drawnow;
frame = getframe;
fixation_point = frame2im(frame);

%%% LOOP FOR EACH TRIAL %%%
for t=1:length(W)
    % Compute planar projection of each OF and obj dot
    % Starting point of each optic flow dot
    OF_x = min_val+(max_val-min_val)*rand(1, num_OFdots);
    OF_y = min_val+(max_val-min_val)*rand(1, num_OFdots);
    OF_z = clip_near+(clip_far-clip_near)*rand(1, num_OFdots);

    % Velocity profile for each translation/rotation dimension
    u_vel = U(t)/sum(velocity_profile).*velocity_profile;
    v_vel = V(t)/sum(velocity_profile).*velocity_profile;
    w_vel = W(t)/sum(velocity_profile).*velocity_profile;
    a_vel = A(t)/sum(velocity_profile).*velocity_profile;
    b_vel = B(t)/sum(velocity_profile).*velocity_profile;
    c_vel = C(t)/sum(velocity_profile).*velocity_profile;

    for idx=1:num_frames
        clf;

        % Compute change in each dimension
        dXdT = -u_vel(idx) - b_vel(idx).*OF_z + c_vel(idx).*OF_y;
        dYdT = -v_vel(idx) - c_vel(idx).*OF_x + a_vel(idx).*OF_z;
        dZdT = -w_vel(idx) - a_vel(idx).*OF_y + b_vel(idx).*OF_x;

        % Compute new (X, Y, Z) of each optic flow point
        OF_x = OF_x + dXdT;
        OF_y = OF_y + dYdT;
        OF_z = OF_z + dZdT;

        % If OF star outside of projection, reposition
        % First, reposition if outside clipping window
        OF_z(OF_z>clip_far) = clip_near;
        OF_z(OF_z<clip_near) = clip_far;

        OF_outsideview = abs(OF_x)>OF_z | abs(OF_y)>OF_z;
        num_redrawn = sum(OF_outsideview);
        OF_x(OF_outsideview) = min_val+(max_val-min_val)*rand(1, num_redrawn);
        OF_y(OF_outsideview) = min_val+(max_val-min_val)*rand(1, num_redrawn);
        if W>=0
            OF_z(OF_outsideview) = repmat(clip_far, 1, num_redrawn);
        else
            OF_z(OF_outsideview) = repmat(clip_near, 1, num_redrawn);
        end

        % Compute optic flow star projection size
        dot_size = (star_size.*view_dist./OF_z).^2;

        % Retinal projection (x, y)
        x = OF_x./OF_z;
        y = OF_y./OF_z;

        axes('box','off','xtick',[],'ytick',[],'ztick',[],'xcolor',[0 0 0],'ycolor',[0 0 0]);
        set(gca,'position',[0 0 1 1],'units','normalized');

        % Plot optic flow dots
        scatter(x, y, dot_size, '^', 'filled', 'MarkerFaceColor','y', 'MarkerFaceAlpha', 1);
        hold on;

        % Plot fixation point
        rectangle('Position', fp_loc, 'FaceColor', 'y');

        set(gca,'xticklabel',[]);
        set(gca,'yticklabel',[]);
        xlim([-0.3, 0.3]);
        ylim([-0.3, 0.3]);

        set(gca,'Color','k');

        drawnow;
        frame = getframe;
        motion_stim{idx} = frame2im(frame);
    end

    % Write frames to gif
    [~,map] = rgb2ind(motion_stim{1},256);

    % % Black screen
    % [A, map] = rgb2ind(black_screen,256);
    % imwrite(A,map,filename,'gif','LoopCount',Inf,'DelayTime',1);

    % Fixation point
    [a,map] = rgb2ind(fixation_point,256);
    if t==1
        imwrite(a,map,savename,'gif','LoopCount',Inf,'DelayTime',0.25);
    else
        imwrite(a,map,savename,'gif','WriteMode','append','DelayTime',0.25);
    end

    % Motion stimulus
    for idx = 1:num_frames
        [a,map] = rgb2ind(motion_stim{idx},256);
        imwrite(a,map,savename,'gif','WriteMode','append','DelayTime',frame_dur);
    end
end

close;
