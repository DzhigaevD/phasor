% clc;
% clear;
% close all;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Adapted by D. Dzhigaev, Lund Univerity 2021

% Mapping Detector Conjugated Space to Sample Space
% Version 1.0
% July 2019
% Written By: David Yang
% University of Oxford, Dept. of Engineering Science
% 
% PURPOSE: To map an object in detector conjugated space (DCS) to sample space (SS) for the same object.
% 
% FILE INPUT: A reconstruction folder containing -AMP.mat and -PH.mat files
% 
% FILE OUTPUT: A file containing the calculated SS shape in a -SAM.mat file
% 
% USER-DEFINED SECTIONS:
% 1. Original reflection details
% - collects details about the reconstructed DCS shape to be translated
% 
% 2. Beamline selection
% - user specifies the beamline plugin to create specific rotation matrices
% 
% 3. Plot options
% - user can plot the calculated shape and configure parameters
% 
% 4. Save calculated shape
% - option to save the calculated SS shape or twin in a -SAM.mat file
% 
% 5. Test
% - to plot the calculated shape with a previous reconstruction for comparison
% 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clc;
% clear;
% close all;
fprintf('<>---<>---<>---<>---<>---<>---<>---<>---<>---<>---<>---<>---<>\n');
fprintf('       Mapping Detector Conjugated Space to Sample Space\n');
fprintf('                         Version 1.0\n');
fprintf('                          July 2019\n');
fprintf('                    Written By: David Yang\n');
fprintf('      University of Oxford, Dept. of Engineering Science\n');
fprintf('<>---<>---<>---<>---<>---<>---<>---<>---<>---<>---<>---<>---<>\n');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 1. Original reflection details
fprintf('\n...collecting original reflection details...');
% addpath(fullfile('functions','APS 34-ID-C angles'));
% addpath(fullfile('functions','NanoMAXangles'));
% addpath(fullfile('functions','P10 angles'));
% importing the -AMP.mat and -PH.mat files from reconstruction

O.DCS_shape_REC_AMP = abs(postPhasor.object);
O.DCS_shape_REC_PH = angle(postPhasor.object);

% generating the DCS shape
% O.DCS_shape_REC = abs(O.DCS_shape_REC_AMP.*exp(1i.*O.DCS_shape_REC_PH));
O.DCS_shape_REC = O.DCS_shape_REC_AMP.*exp(1j.*O.DCS_shape_REC_PH);
O.DCS_shape_REC = O.DCS_shape_REC./max(O.DCS_shape_REC(:));

% the old hkl reflection
O.hkl = [1; 1; 1];

% wavelength in m for original reflection
O.lambda = postPhasor.experiment.wavelength;

% get size of the original matrix
[O.Nv, O.Nh, O.Nr] = size(O.DCS_shape_REC);
O.p_sam = 1; % obtained from reconstruction, set to 1 if unknown

switch postPhasor.experiment.beamline
    % Unified coordinate transformation
    % coordinate system : x-outborad (horizontal axis), y-up (vertical
    % axis), z - along the incoming beam (bram axis)
    case '34idc'        
        % beamline detector motor angles in degrees
        O.detectorVerticalAxisRotation = postPhasor.experiment.delta+postPhasor.experiment.delta_correction;       
        O.detectorHorizontalAxisRotation = postPhasor.experiment.gamma+postPhasor.experiment.gamma_correction;
        % Final orientation in the laboratory frame
        % beamline sample motor angles in degrees (set to the motors' default angles for lab space)
        
        O.sampleVerticalAxisRotation = 0;
        O.sampleBeamAxisRotation = 90;
        O.sampleHorizontalAxisRotation = 0;     
    case 'nanomax'
        % beamline detector motor angles in degrees
        O.detectorVerticalAxisRotation = postPhasor.experiment.gamma+postPhasor.experiment.gamma_correction;
        O.detectorHorizontalAxisRotation = postPhasor.experiment.delta+postPhasor.experiment.delta_correction;

        O.sampleVerticalAxisRotation = 0;
        O.sampleBeamAxisRotation = 90;
        O.sampleHorizontalAxisRotation = 0;
        
%         DCS_to_SS_MAXIV_NanoMAX;    
    case 'p10'
        % beamline detector motor angles in degrees
        O.detectorVerticalAxisRotation = postPhasor.experiment.gamma+postPhasor.experiment.gamma_correction;
        O.detectorHorizontalAxisRotation = postPhasor.experiment.delta+postPhasor.experiment.delta_correction;

        O.sampleVerticalAxisRotation = 0;
        O.sampleBeamAxisRotation = 90;
        O.sampleHorizontalAxisRotation = 0;

end                               

% choose rocking angle and increment in degrees
O.rocking_angle = postPhasor.experiment.rocking_motor; % 'dphi' rotate around horizontal-axis, 'dtheta' rotate around vertical-axis for 34-ID-C
O.rocking_increment = postPhasor.experiment.angular_step; % rocking angle step size

% detector parameters in m
O.D = postPhasor.experiment.sample_detector_d; % detector distance in m, put absolute value if known
O.d = postPhasor.experiment.detector_pitch*postPhasor.plotting.binning(1); % detector pixel size in m--this is effective, becomes larger than actual if binning is used
O.N = size(postPhasor.object); % number of pixels along one dimension of square detector

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Beamline selection
% adding path to APS 34-ID-C angles folder

switch postPhasor.experiment.beamline
    % Unified coordinate transformation
    % beamline-specific plugin for O: [sampleVerticalAxisRotation, sampleBeamAxisRotation, sampleHorizontalAxisRotation, detectorVerticalAxisRotation, detectorHorizontalAxisRotation, rockingIncrement, rockingMotor]
    case '34idc'                
        [O.R_dqp_12, O.R_dqp_3, O.R_xyz, O.S_0lab_dir] = plugin_APS_34IDC(O.sampleVerticalAxisRotation, O.sampleBeamAxisRotation, O.sampleHorizontalAxisRotation, O.detectorVerticalAxisRotation, O.detectorHorizontalAxisRotation, O.rocking_increment, O.rocking_angle);

    case 'nanomax'
        [O.R_dqp_12, O.R_dqp_3, O.R_xyz, O.S_0lab_dir] = plugin_NanoMAX(O.sampleVerticalAxisRotation, O.sampleBeamAxisRotation, O.sampleHorizontalAxisRotation, O.detectorVerticalAxisRotation, O.detectorHorizontalAxisRotation, O.rocking_increment, O.rocking_angle);   
        
    case 'p10'
        [O.R_dqp_12, O.R_dqp_3, O.R_xyz, O.S_0lab_dir] = plugin_P10(O.sampleVerticalAxisRotation, O.sampleBeamAxisRotation, O.sampleHorizontalAxisRotation, O.detectorVerticalAxisRotation, O.detectorHorizontalAxisRotation, O.rocking_increment, O.rocking_angle);           
end    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3. Plot options
% plot the calculated DCS shape
plot_shape = 0; % 1 to plot calculated DCS shape

% toggle between viewing the thresholded amplitude or isosurface
amplitudes = 0; % 1 to plot amplitudes, 0 to plot isosurfaces
amplitude_threshold = 0.1; % 0.3 is a good starting point

% select viewpoint
viewpoint = [-180, -90]; % viewpoint = [az, el], x-y plane
% viewpoint = [-180, 0]; % viewpoint = [az, el], x-z plane
% viewpoint = [-90, 0]; % viewpoint = [az, el], y-z plane


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4. Save calculated shape
% choose to save the calculated SS shape
save_reflection = 0; % 1 to save, 0 to not save

% choose to take the twin of the new calculated SS shape
twin = 0; % 1 to take the conjugate reflection

% save directory
save_dir = 'lab_space'; 

% save name
save_name = 'phasing'; 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 5. Testing
 % 1 to test against a reconstructed shape, 0 to not test
test = 0;

% directory to the reconstruction folder
O.dir = 'Reconstruction Examples/Cylinder_(-120)_-36.0786_gamma_40.2954_delta_0.00274_dtheta';

% name of the reconstruction folder
O.file_name = 'Cylinder_(-120)_-36.0786_gamma_40.2954_delta_0.00274_dtheta-SAM';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% DON'T EDIT BELOW THIS SECTION %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Making grids assuming 34-ID-C coordinate frame (DO NOT TOUCH)
%% Making grids assuming 34-ID-C coordinate frame (DO NOT TOUCH)
fprintf('\n...making pixel grids...');
% make pixel coordinate grids for the 3D volume of the original DCS shape
[O.Nvgrid, O.Nhgrid, O.Nrgrid] = meshgrid(-(O.Nh-1)/2:(O.Nh-1)/2, -(O.Nv-1)/2:(O.Nv-1)/2, -(O.Nr-1)/2:(O.Nr-1)/2);

% calculating original voxel size if unknown
if O.p_sam == 1
%     O.p_sam = [O.lambda*O.D/(O.N(1)*O.d),O.lambda*O.D/(O.N(2)*O.d),abs(O.lambda/(O.N(3)*(O.rocking_increment*pi/180)))]; % this is just for detector plane
%     min_sampling = min([O.lambda*O.D/(O.N(1)*O.d),O.lambda*O.D/(O.N(2)*O.d),abs(O.lambda/(O.N(3)*(O.rocking_increment*pi/180)))]);
%     O.p_sam = [min_sampling, min_sampling, min_sampling]; % this is just for detector plane
    O.p_sam = [O.lambda*O.D/(O.N(1)*O.d),O.lambda*O.D/(O.N(2)*O.d),min(O.lambda*O.D/(O.N(1)*O.d),O.lambda*O.D/(O.N(2)*O.d))];
end

postPhasor.object_sampling = O.p_sam;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Make original (O) coordinates (DO NOT TOUCH)
fprintf('\n...making detector conjugated space coordinates...');

% making S_0lab, S_lab and Q_lab vectors for beamline
O.S_0lab = 2*pi/O.lambda*O.S_0lab_dir;
O.S_lab = O.R_dqp_12*O.S_0lab;
O.Q_lab = O.S_lab - O.S_0lab;

% making x_sam , y_sam , z_sam sample space vectors
O.x_sam = O.R_xyz*[1; 0; 0];
O.y_sam = O.R_xyz*[0; 1; 0];
O.z_sam = O.R_xyz*[0; 0; 1];

% making q_1', q_2', q_3' detector reciprocal space vectors: unitary
% vectors
O.q_1p = 2*pi/O.lambda*O.d/O.D*O.R_dqp_12*[1; 0; 0];
O.q_2p = 2*pi/O.lambda*O.d/O.D*O.R_dqp_12*[0; 1; 0];
O.q_3p = O.R_dqp_3*O.Q_lab-O.Q_lab;

% O.p_sam = 1;

% make x', y', and z' detector conjugated space basis vectors, adapted from Berenguer et al. PRB 88, 144101 (2013).
% O.V_DRS = dot(cross(O.q_3p, O.q_2p), O.q_1p)*O.Nv*O.p_sam(1)*O.Nh*O.p_sam(2)*O.Nr*O.p_sam(3);
O.V_DRS = dot(cross(O.q_1p, O.q_2p), O.q_3p)*O.Nv*O.p_sam(1)*O.Nh*O.p_sam(2)*O.Nr*O.p_sam(3);

O.xp = 2*pi*cross(O.Nh*O.p_sam(2)*O.q_2p, O.Nr*O.p_sam(3)*O.q_3p)./O.V_DRS;
O.yp = 2*pi*cross(O.Nr*O.p_sam(3)*O.q_3p, O.Nv*O.p_sam(1)*O.q_1p)./O.V_DRS;
O.zp = 2*pi*cross(O.Nv*O.p_sam(1)*O.q_1p, O.Nh*O.p_sam(2)*O.q_2p)./O.V_DRS;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Map from original DCS to new DCS (DO NOT TOUCH)
fprintf('\n...interpolating detector conjugated to sample space coordinates...');
% making the T_DCS_to_SS matrix for O
O.T_DCS_to_SS = [O.xp, O.yp, O.zp]\[O.x_sam, O.y_sam, O.z_sam]; % equivalent to [a_1, a_2, a_3]*inv(b_1, b_2, b_3])

% map original coordinates to non-orthogonal coordinates
O.N1gridp = O.T_DCS_to_SS(1,1)*O.Nvgrid + O.T_DCS_to_SS(1,2)*O.Nhgrid + O.T_DCS_to_SS(1,3)*O.Nrgrid;
O.N2gridp = O.T_DCS_to_SS(2,1)*O.Nvgrid + O.T_DCS_to_SS(2,2)*O.Nhgrid + O.T_DCS_to_SS(2,3)*O.Nrgrid;
O.N3gridp = O.T_DCS_to_SS(3,1)*O.Nvgrid + O.T_DCS_to_SS(3,2)*O.Nhgrid + O.T_DCS_to_SS(3,3)*O.Nrgrid;


% interpolate original reflection data in the detector conjugated frame to sample space frame
% O.SS_shape_CALC = flip(O.DCS_shape_REC,3);
O.SS_shape_CALC = interp3(O.Nvgrid, O.Nhgrid, O.Nrgrid, O.DCS_shape_REC, O.N1gridp, O.N2gridp, O.N3gridp, 'linear', 0); % make any values outside original data zero.
% O.SS_shape_CALC = flip(O.SS_shape_CALC,1);
% O.SS_shape_CALC = flip(O.SS_shape_CALC,2);


% taking the twin if necessary
if twin == 1
    F = ifftshift(fftn(fftshift(O.SS_shape_CALC)));
    O.SS_shape_CALC = fftshift(ifftn(ifftshift(conj(F))));
end

% centering about the centre of mass
O.SS_shape_CALC_MASK = single(abs(O.SS_shape_CALC) > amplitude_threshold);
structure_element = strel('sphere', 3);
O.SS_shape_CALC_MASK = imerode(imdilate(O.SS_shape_CALC_MASK, structure_element),structure_element); % takes care of dislocation cores
O.SS_shape_CALC_COM = ceil(centerOfMass(O.SS_shape_CALC_MASK));
O.SS_shape_CALC = circshift(O.SS_shape_CALC, round(size(O.SS_shape_CALC)/2)-O.SS_shape_CALC_COM);

% Output for phasor
postPhasor.object = O.SS_shape_CALC;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Saving new reflection shape (DO NOT TOUCH)
if save_reflection == 1
    fprintf('\n...saving new reflection shape...');
    mkdir(save_dir);
    array = O.SS_shape_CALC;
    save([save_dir, '/', save_name,'_(', num2str(O.hkl(1)), num2str(O.hkl(2)), num2str(O.hkl(3)),')_', num2str(O.gamma_bl),'_gamma_',num2str(O.delta_bl),'_delta_',num2str(O.rocking_increment),'_',O.rocking_angle, '-SAM.mat'], 'array');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Testing calculated shape with reconstructed shape (DO NOT TOUCH)
if plot_shape == 1
    if test == 1
        fprintf('\n...plotting reconstructed detector conjugated space shape from reconstruction to compare...');
        
        % importing the sample space files
        try
            O.SS_shape_REC = cell2mat(struct2cell(load([O.dir, '/', O.file_name, '.mat'])));
        catch
            fprintf('\n...the reconstruction folder and/or file is corrupt or cannot be found...');
            test = 0;
        end

        % centring about the centre of mass
        fprintf('\n...centring shapes...');
        O.SS_shape_REC_MASK = single(abs(O.SS_shape_REC) > amplitude_threshold); % binarizing
        structure_element = strel('sphere', 3);
        O.SS_shape_REC_MASK = imerode(imdilate(O.SS_shape_REC_MASK, structure_element),structure_element);   %takes care of dislocation cores
        O.SS_shape_REC_COM = ceil(centerOfMass(O.SS_shape_REC_MASK));
        O.SS_shape_REC = circshift(O.SS_shape_REC, size(O.SS_shape_REC)/2-O.SS_shape_REC_COM);
    end
    
    % creating a figure
    figure;
    hold on;
    
    if amplitudes == 1
        % plotting calculated shape amplitude
        O.plot = patch(isosurface(O.N1grid*O.p_sam(1), O.N2grid*O.p_sam(2), O.N3grid*O.p_sam(3), abs(O.SS_shape_CALC), amplitude_threshold));
        set(O.plot, 'FaceColor', 'red', 'EdgeColor', 'none', 'FaceAlpha', 0.3);
        if test == 1
            % plotting reconstructed shape amplitude
            O.plot_true = patch(isosurface(O.N1grid*O.p_sam(1), O.N2grid*O.p_sam(2), O.N3grid*O.p_sam(3), abs(O.SS_shape_REC), amplitude_threshold));
            set(O.plot_true, 'FaceColor', 'blue', 'EdgeColor', 'none', 'FaceAlpha', 0.3);
        end
    else
        % plotting calculated shape isosurface
        [faces,verts,colors] = isosurface(O.N1grid*O.p_sam(1), O.N2grid*O.p_sam(2), O.N3grid*O.p_sam(3), abs(O.SS_shape_CALC), amplitude_threshold, angle(O.SS_shape_CALC));
        O.plot = patch('Vertices', verts, 'Faces', faces, 'FaceVertexCData', colors, 'FaceColor', 'interp', 'edgecolor', 'none');
        if test == 1
            % plotting reconstructed shape isosurface
            [faces,verts,colors] = isosurface(O.N1grid*O.p_sam(1), O.N2grid*O.p_sam(2), O.N3grid*O.p_sam(3), abs(O.SS_shape_REC), amplitude_threshold, angle(O.SS_shape_REC));
            O.plot_true = patch('Vertices', verts, 'Faces', faces, 'FaceVertexCData', colors, 'FaceColor', 'interp', 'edgecolor', 'none');
        end
    end
    
    % plotting x, y and z axes
    x_axis = quiver3(0, 0, 0, 0.9*O.N1*O.p_sam(1)/2, 0, 0);
    set(x_axis, 'Color', 'black', 'Linewidth', 2, 'AutoScale', 'off');
    text(O.N1*O.p_sam(1)/2, 0, 0, 'x_{sam}', 'Color', 'black', 'FontSize', 14);
    y_axis = quiver3(0, 0, 0, 0, 0.9*O.N2*O.p_sam(2)/2, 0);
    set(y_axis, 'Color', 'black', 'Linewidth', 2, 'AutoScale', 'off');
    text(0, O.N2*O.p_sam(2)/2, 0, 'y_{sam}', 'Color', 'black', 'FontSize', 14);
    z_axis = quiver3(0, 0, 0, 0, 0, 0.9*O.N3*O.p_sam(3)/2);
    set(z_axis, 'Color', 'black', 'Linewidth', 2, 'AutoScale', 'off');
    text(0, 0, O.N3*O.p_sam(3)/2, 'z_{sam}', 'Color', 'black', 'FontSize', 14);
    
    % overlap textbox
    if test == 1
        % centring masks for overlap calculation
        O.SS_shape_CALC_MASK = circshift(O.SS_shape_CALC_MASK, size(O.SS_shape_CALC_MASK)/2-O.SS_shape_CALC_COM);
        O.SS_shape_REC_MASK = circshift(O.SS_shape_REC_MASK, size(O.SS_shape_REC_MASK)/2-O.SS_shape_REC_COM);
        % calculating overlap
        overlap = round(abs((1-abs(sum(sum(sum(O.SS_shape_CALC_MASK - O.SS_shape_REC_MASK))))/sum(sum(sum(O.SS_shape_REC_MASK))))*100), 2);
        annotation('textbox',[0.17, 0.1, .3, .3], 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle','String',['Overlap: ',num2str(overlap),'%'], 'BackgroundColor', 'white','FitBoxToText','on');
        legend([O.plot, O.plot_true], ['Calculated Sample Space Shape from (', num2str(O.hkl(1)),num2str(O.hkl(2)),num2str(O.hkl(3)),')'], ['Reconstructed Sample Space Shape from (', num2str(O.hkl(1)),num2str(O.hkl(2)),num2str(O.hkl(3)),')']);
    else
        legend([O.plot], ['Calculated Sample Space Shape from (', num2str(O.hkl(1)),num2str(O.hkl(2)),num2str(O.hkl(3)),')']);
    end
    
    % setting plot parameters
    title(['Calculated Sample Space Shape vs. Reconstructed Sample Space Shape for (', num2str(O.hkl(1)),num2str(O.hkl(2)),num2str(O.hkl(3)),')']);
    xlabel('x_{sam} (m)'); ylabel('y_{sam} (m)'); zlabel('z_{sam} (m)');
    set(gca,'XDir','normal');
    set(gca,'YDir','normal');
    daspect([1,1,1]);
    axis equal;
    axis vis3d xy;
    grid on;
    xlim([-O.N1*O.p_sam(1)/2, O.N1*O.p_sam(1)/2]); ylim([-O.N2*O.p_sam(2)/2, O.N2*O.p_sam(2)/2]); zlim([-O.N3*O.p_sam(3)/2, O.N3*O.p_sam(3)/2]);
    view(viewpoint(1), viewpoint(2));
    lighting gouraud;

    if test ~= 1
        camlight('headlight');
    end
    if amplitudes ~= 1
        c = colorbar;
        ylabel(c, 'Phase');
        caxis([-pi, pi]);
    end
end

fprintf('\n...done\n\n');
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = centerOfMass(A,varargin)
% CENTEROFMASS finds the center of mass of the N-dimensional input array
%
%   CENTEROFMASS(A) finds the gray-level-weighted center of mass of the
%   N-dimensional numerical array A. A must be real and finite. A warning
%   is issued if A contains any negative values. Any NaN elements of A will
%   automatically be ignored. CENTEROFMASS produces center of mass
%   coordinates in units of pixels. An empty array is returned if the
%   center of mass is undefined.
%
%   The center of mass is reported under the assumption that the first
%   pixel in each array dimension is centered at 1.
%
%   Also note that numerical arrays other than DOUBLE and SINGLE are
%   converted to SINGLE in order to prevent numerical roundoff error.
%
%   Examples:
%       A = rgb2gray(imread('saturn.png'));
%       C = centerOfMass(A);
%
%       figure; imagesc(A); colormap gray; axis image
%       hold on; plot(C(2),C(1),'rx')
%
%   See also: 
%
%

%
%   Jered R Wells
%   2013/05/07
%   jered [dot] wells [at] gmail [dot] com
%
%   v1.0
%
%   UPDATES
%       YYYY/MM/DD - jrw - v1.1
%
%

%% INPUT CHECK
narginchk(0,1);
nargoutchk(0,1);
fname = 'centerOfMass';

% Checked required inputs
validateattributes(A,{'numeric'},{'real','finite'},fname,'A',1);

%% INITIALIZE VARIABLES
A(isnan(A)) = 0;
if ~(strcmpi(class(A),'double') || strcmpi(class(A),'single'))
    A = single(A);
end
if any(A(:)<0)
    warning('MATLAB:centerOfMass:neg','Array A contains negative values.');
end

%% PROCESS
sz = size(A);
nd = ndims(A);
M = sum(A(:));
C = zeros(1,nd);
if M==0
    C = [];
else
    for ii = 1:nd
        shp = ones(1,nd);
        shp(ii) = sz(ii);
        rep = sz;
        rep(ii) = 1;
        ind = repmat(reshape(1:sz(ii),shp),rep);
        C(ii) = sum(ind(:).*A(:))./M;
    end
end

% Assemble the VARARGOUT cell array
varargout = {C};

end % MAIN