function [P_out, mesh_data_out] = mesh_transform(P_in, varargin)
% MESH_TRANSFORM Unified 3D mesh transformation (Scale -> Rotate -> Translate)
%
% [Inputs]
%   P_in          : Node coordinates matrix (N x 3) or mesh_data struct
%
% [Optional Name-Value Parameters]
%   'Scale'       : Scale factor (scalar or [sx, sy, sz], default: 1.0)
%   'Rotate'      : Euler angles [roll, pitch, yaw], Z-Y-X Tait-Bryan (default: [0 0 0])
%   'Translate'   : Displacement [dx, dy, dz] (default: [0 0 0])
%   'Center'      : Pivot for scale & rotation ([cx cy cz] or 'centroid', default: [0 0 0])
%   'AngleUnit'   : 'deg' (default) or 'rad'
%
% [Outputs]
%   P_out         : Transformed node coordinates (N x 3)
%   mesh_data_out : Updated mesh structure with recalculated geometry

    %% 1. Input Parsing & Validation
    is_struct_input = isstruct(P_in);
    if is_struct_input
        mesh_data_out = P_in;
        if isfield(P_in, 'P'),         P = P_in.P;
        elseif isfield(P_in, 'nodes'), P = P_in.nodes;
        else, error('mesh_transform:badStruct', 'Input struct must contain "P" or "nodes".');
        end
    else
        P = P_in;
        mesh_data_out = struct();
    end
    validateattributes(P, {'numeric'}, {'2d', 'ncols', 3, 'finite'}, mfilename, 'P');

    p = inputParser;
    addParameter(p, 'Scale', 1.0, ...
        @(v) isnumeric(v) && (isscalar(v) || numel(v) == 3) && all(isfinite(v(:))));
    addParameter(p, 'Rotate', [0, 0, 0], ...
        @(v) isnumeric(v) && numel(v) == 3 && all(isfinite(v(:))));
    addParameter(p, 'Translate', [0, 0, 0], ...
        @(v) isnumeric(v) && numel(v) == 3 && all(isfinite(v(:))));
    addParameter(p, 'Center', [0, 0, 0]);
    addParameter(p, 'AngleUnit', 'deg');
    parse(p, varargin{:});

    scale_val  = p.Results.Scale;
    rot_val    = p.Results.Rotate;
    trans_val  = reshape(p.Results.Translate, 1, 3);
    center_val = p.Results.Center;
    angle_unit = validatestring(p.Results.AngleUnit, {'deg', 'rad'}, mfilename, 'AngleUnit');

    %% 2. Pivot Center
    if ischar(center_val) || isstring(center_val)
        % 'centroid'/'center' both mean nodal centroid; any other string errors
        validatestring(center_val, {'centroid', 'center'}, mfilename, 'Center');
        center_pt = mean(P, 1);
    else
        validateattributes(center_val, {'numeric'}, {'numel', 3, 'finite'}, mfilename, 'Center');
        center_pt = reshape(center_val, 1, 3);
    end

    %% 3. Scale Vector
    if isscalar(scale_val)
        S = scale_val * [1, 1, 1];
    else
        S = reshape(scale_val, 1, 3);
    end

    %% 4. Rotation Matrix (Z-Y-X Tait-Bryan: R = Rz * Ry * Rx)
    if strcmp(angle_unit, 'deg')
        ang = deg2rad(rot_val);
    else
        ang = rot_val;
    end
    rx = ang(1); ry = ang(2); rz = ang(3);

    Rx = [1, 0, 0; 0, cos(rx), -sin(rx); 0, sin(rx), cos(rx)];
    Ry = [cos(ry), 0, sin(ry); 0, 1, 0; -sin(ry), 0, cos(ry)];
    Rz = [cos(rz), -sin(rz), 0; sin(rz), cos(rz), 0; 0, 0, 1];
    R  = Rz * Ry * Rx;

    %% 5. Unified Transformation (implicit expansion, R2016b+)
    % P' = ((P - C) .* S) * R.' + C + T
    P_out = ((P - center_pt) .* S) * R.' + (center_pt + trans_val);

    %% 6. Geometric Properties Update
    if ~is_struct_input
        mesh_data_out.P = P_out;   % never return an empty struct
        return;
    end

    if isfield(mesh_data_out, 'P'),     mesh_data_out.P = P_out;     end
    if isfield(mesh_data_out, 'nodes'), mesh_data_out.nodes = P_out; end

    if isfield(mesh_data_out, 't'),             t = mesh_data_out.t;
    elseif isfield(mesh_data_out, 'triangles'), t = mesh_data_out.triangles;
    else, t = [];
    end

    if ~isempty(t)
        % Degenerate-triangle fallback: +Z rotated by R (physically consistent
        % after transformation, unlike a fixed [0 0 1]).
        fallback_n = ([0, 0, 1] * R.');
        props = tri_mesh_props(P_out, t, fallback_n);

        mesh_data_out.centroids = props.centroids;
        mesh_data_out.areas     = props.areas;
        mesh_data_out.normals   = props.normals;
        if isfield(mesh_data_out, 'total_area')
            mesh_data_out.total_area = props.total_area;
        end
    end
end
