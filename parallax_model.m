close all

%% 1. 1D model: dependence on calibration distance and viewing distance

% Geometry:
%
%                        z (depth / eye axis)
%                        ^
%                        |
%                        |
%                        |
%                        -  * calibration point (y = 0, z = calibration distance)
%                        |
%                        |
%                        |
%                        |
%                        -  * viewing point     (y = 0, z = viewing distance)
%                        |
%                        |
%                        |
%                        |
%                        |
%                        |
% -----------------------o------------------o------------> y (vertical axis)
%                       Eye               Camera
%                      (0,0)              (+5, 0)
%
% The eye is at the origin and looks straight ahead along +z. The scene
% camera is offset vertically by camera_offset_y and points parallel to the
% eye's line of sight. In eye-centered coordinates, fixation points lie on
% the eye axis (y = 0) at different depths z. In camera-centered
% coordinates, those same points are shifted by -camera_offset_y in y.

% Vertical camera offset relative to the eye
camera_offset_y = 5;   % cm; e.g. camera is 5 cm above the eye

% Calibration distance and viewing distances (depth values along z)
viewing_distance_far = 100;              % cm
viewing_distances    = 20:600;           % cm

% World positions of fixation points relative to the eye.
% Because the eye is directed straight ahead, all fixation points have y=0
% and differ only in depth z.
world_pos_calibration = [0 viewing_distance_far];
world_pos_viewing     = [zeros(numel(viewing_distances),1) viewing_distances(:)];

% Express points in camera-centered coordinates.
% If the camera is shifted upward relative to the eye, world points
% appear shifted downward in the camera frame.
camera_pos_calibration      = world_pos_calibration;
camera_pos_viewing          = world_pos_viewing;
camera_pos_calibration(:,1) = camera_pos_calibration(:,1) - camera_offset_y;
camera_pos_viewing(:,1)     = camera_pos_viewing(:,1)     - camera_offset_y;

% Project to the camera's normalized image plane (i.e., the tangent plane
% at unit distance) by dividing vertical position by depth.
image_pos_calibration = camera_pos_calibration(:,1) ./ camera_pos_calibration(:,2);
image_pos_viewing     = camera_pos_viewing(:,1)     ./ camera_pos_viewing(:,2);

% Convert normalized image-plane positions to camera-relative visual
% directions. This is exact for the pinhole model used here.
direction_calibration = atand(image_pos_calibration);
direction_viewing     = atand(image_pos_viewing);

% Define gaze shift due to parallax as:
%     reported position - actual position
% in the scene camera.
% The reported position is the calibration-consistent direction, i.e. the
% direction associated with the eye orientation learned during calibration.
% The actual position is the camera-relative direction of the viewed point
% at the current viewing distance.
gaze_shift = direction_calibration - direction_viewing;

% The model can be written in a single expression as:
%   gaze_shift(z) = atand(-camera_offset_y / calibration_distance) ...
%                 - atand(-camera_offset_y / z)
%
% This makes three points explicit:
% 1. Normalized image-plane position is exactly proportional to 1/z.
% 2. Angular gaze shift is approximately proportional to 1/z for small
%    gaze shifts (small angle approximation).
% 3. Changing calibration distance adds a constant offset term; it does not
%    change the shape of the function over z.

plot([0 viewing_distances(end)],[0 0],'--','Color',[.6 .6 .6])
hold on
plot(viewing_distances, gaze_shift, 'LineWidth',1.2)
axis tight
xlabel('Viewing distance (cm)','FontSize',15,'FontWeight','bold')
ylabel('Gaze shift (deg)','FontSize',15,'FontWeight','bold')
ax = gca;
ax.XAxis.FontSize = 13;
ax.YAxis.FontSize = 13;
box off

f1=gcf;
f1.Position(3) = f1.Position(3)*1.65;
print('Figure_1B.png','-dpng','-r300')


%% 2. 2D model: dependence on viewing direction
viewing_directions = [0 0; -8 0; 8 0; 0 -8; 0 8];   % [H V] in deg

% distances from the "sitting" condition in the paper
viewing_distance_far = 200;   % cm
viewing_distance_near= 30;    % cm, 
camera_offset_xy     = [-5 3]; % cm; 5 cm left, 3 cm up

% World positions of fixation points relative to the eye
world_positions = cat(3, viewing_distance_far, viewing_distance_near) .* ...
                  [tand(viewing_directions) ones(size(viewing_directions,1),1)];

% Express points in camera-centered coordinates
camera_positions = world_positions;
camera_positions(:,1:2,:) = camera_positions(:,1:2,:) - camera_offset_xy;

% Project to tangent plane and convert to camera-relative directions (Fick
% order)
image_positions = camera_positions(:,1:2,:) ./ camera_positions(:,3,:);
fick_directions = zeros(size(camera_positions,1), 2, size(camera_positions,3));
fick_directions(:,1,:) = atan2d(image_positions(:,1,:), 1);
fick_directions(:,2,:) = atan2d(image_positions(:,2,:), sqrt(image_positions(:,1,:).^2 + 1));

% Compute gaze shift due to parallax for these two viewing distances,
% taking into account that angles are not commutative and thus cannot be
% directly subtracted
direction_fick_far = fick_directions(:,:,1);
direction_fick_near= fick_directions(:,:,2);

shift_fick = zeros(size(direction_fick_far));
for ii = 1:size(direction_fick_far,1)
    shift_fick(ii,:) = relativeFick(direction_fick_far(ii,:), direction_fick_near(ii,:));
end

figure
plot(viewing_directions(:,1),viewing_directions(:,2),'o',Color='b',MarkerFaceColor='b');
hold on
for v=1:size(shift_fick,1)
    hs = plot(viewing_directions(v,1)+[0 shift_fick(v,1)], viewing_directions(v,2)+[0 shift_fick(v,2)], '-',Color='r',LineWidth=2);
end
axis square
xlim([-16.3 8.3])
ylim([-9.9 14.7])
xlabel('Horizontal gaze position (deg)')
ylabel('Vertical gaze position (deg)')

f2=gcf;
f2.Position(4) = f2.Position(4)*.6;
print('Figure_1C.png','-dpng','-r300')




% helpers
function hv_err = relativeFick(hv_rep, hv_act)
R_rep = fickRotation(hv_rep(1), hv_rep(2));
R_act = fickRotation(hv_act(1), hv_act(2));
R_err = R_rep * R_act';
hv_err = rotationToFick(R_err);
end

function R = fickRotation(H, V)
R = Ry(H) * Rx(-V);
end

function hv = rotationToFick(R)
H = atan2d(R(1,3), R(3,3));
V = atan2d(R(2,3), sqrt(R(1,3)^2 + R(3,3)^2));
hv = [H V];
end

function R = Rx(angle_deg)
ca = cosd(angle_deg);
sa = sind(angle_deg);
R = [1  0   0;
     0  ca -sa;
     0  sa  ca];
end

function R = Ry(angle_deg)
ca = cosd(angle_deg);
sa = sind(angle_deg);
R = [ ca 0 sa;
       0 1  0;
     -sa 0 ca];
end
