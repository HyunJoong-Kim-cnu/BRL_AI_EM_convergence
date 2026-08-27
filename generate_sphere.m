function [P, t, mesh_data] = generate_sphere(radius, n_theta, n_phi)
% GENERATE_SPHERE Generates a triangular surface mesh for a sphere
%
% [Inputs]
%   radius  : Radius of the sphere (meters, default: 0.5)
%   n_theta : Divisions along polar angle theta in [0, pi]   (default: 12, min 2)
%   n_phi   : Divisions along azimuth angle phi in [0, 2pi)  (default: 24, min 3)
%
% [Outputs]
%   P         : Node coordinates matrix (N x 3) [x, y, z]
%   t         : Triangle connectivity matrix (M x 3), CCW -> outward normals
%   mesh_data : Structure with geometric properties and MoM edge topology

    %% 1. Default Parameter Handling & Validation
    if nargin < 3, n_phi = 24; end
    if nargin < 2, n_theta = 12; end
    if nargin < 1, radius = 0.5; end

    validateattributes(radius,  {'numeric'}, {'scalar', 'positive', 'finite'}, mfilename, 'radius');
    validateattributes(n_theta, {'numeric'}, {'scalar', 'integer', '>=', 2},  mfilename, 'n_theta');
    validateattributes(n_phi,   {'numeric'}, {'scalar', 'integer', '>=', 3},  mfilename, 'n_phi');

    %% 2. Node Generation (vectorized, ring-major ordering preserved)
    theta_vec = linspace(0, pi, n_theta + 1);
    theta_mid = theta_vec(2:end-1);            % exclude poles
    phi_vec   = linspace(0, 2*pi, n_phi + 1);
    phi_mid   = phi_vec(1:end-1);              % drop duplicated 2*pi

    num_mid_rings = numel(theta_mid);

    % ndgrid then transpose so linear indexing runs phi-fastest (ring-major)
    [TH, PH] = ndgrid(theta_mid, phi_mid);
    TH = TH.'; PH = PH.';                      % n_phi x num_mid_rings

    mid_nodes = radius * [sin(TH(:)).*cos(PH(:)), ...
                          sin(TH(:)).*sin(PH(:)), ...
                          cos(TH(:))];

    north_pole = [0, 0,  radius];
    south_pole = [0, 0, -radius];

    P = [north_pole; mid_nodes; south_pole];
    south_pole_idx = size(P, 1);

    %% 3. Triangle Connectivity (preallocated, CCW for outward normals)
    get_node_idx = @(ring_idx, phi_idx) 1 + (ring_idx - 1) * n_phi + phi_idx;

    num_triangles = 2 * n_phi * num_mid_rings;   % n_phi + 2*n_phi*(rings-1) + n_phi
    t = zeros(num_triangles, 3);
    k = 0;

    % 3-1. North cap (fan)
    for i = 1:n_phi
        next_i = mod(i, n_phi) + 1;
        k = k + 1;
        t(k, :) = [1, get_node_idx(1, i), get_node_idx(1, next_i)];
    end

    % 3-2. Mid-latitude bands (quad -> 2 triangles)
    for j = 1:(num_mid_rings - 1)
        for i = 1:n_phi
            next_i = mod(i, n_phi) + 1;
            n_tl = get_node_idx(j,     i);
            n_tr = get_node_idx(j,     next_i);
            n_bl = get_node_idx(j + 1, i);
            n_br = get_node_idx(j + 1, next_i);
            t(k + 1, :) = [n_tl, n_bl, n_tr];
            t(k + 2, :) = [n_tr, n_bl, n_br];
            k = k + 2;
        end
    end

    % 3-3. South cap (fan)
    for i = 1:n_phi
        next_i = mod(i, n_phi) + 1;
        k = k + 1;
        t(k, :) = [get_node_idx(num_mid_rings, i), south_pole_idx, ...
                   get_node_idx(num_mid_rings, next_i)];
    end

    %% 4. Geometric Properties (vectorized) + Outward-Normal Verification
    props = tri_mesh_props(P, t, 'radial');

    % Defensive check: for a sphere centered at origin, dot(n, c) must be > 0.
    % Any inward-facing triangle is flipped (critical for MoM sign consistency).
    inward = sum(props.normals .* props.centroids, 2) < 0;
    if any(inward)
        t(inward, [2, 3]) = t(inward, [3, 2]);
        props = tri_mesh_props(P, t, 'radial');
        warning('generate_sphere:flippedNormals', ...
                '%d triangle(s) had inward normals and were re-oriented.', nnz(inward));
    end

    %% 5. Output Packaging
    mesh_data.radius  = radius;
    mesh_data.n_theta = n_theta;
    mesh_data.n_phi   = n_phi;
    mesh_data.P = P;
    mesh_data.t = t;
    mesh_data.centroids = props.centroids;
    mesh_data.areas     = props.areas;
    mesh_data.normals   = props.normals;
    mesh_data.edges     = props.edges;
    mesh_data.num_interior_edges = props.num_interior_edges;
    mesh_data.num_boundary_edges = props.num_boundary_edges;  % closed surface -> 0
    mesh_data.total_area       = props.total_area;
    mesh_data.theoretical_area = 4 * pi * radius^2;
    mesh_data.area_error_pct   = 100 * (mesh_data.theoretical_area - mesh_data.total_area) ...
                                     / mesh_data.theoretical_area;
end
