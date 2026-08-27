function [P, t, mesh_data] = generate_plate(Lx, Ly, m, n, diag_pattern)
% GENERATE_PLATE Generates a triangular mesh for a rectangular plate (Lx x Ly)
%
% [Inputs]
%   Lx, Ly       : Plate length along X and Y axes (meters)
%   m, n         : Number of divisions along X and Y axes
%   diag_pattern : Diagonal split mode ('/' or '\', default: '/')
%
% [Outputs]
%   P         : Node coordinates matrix (N x 3) [x, y, z]
%   t         : Triangle connectivity matrix (M x 3), CCW -> +Z normals
%   mesh_data : Structure with geometric properties and MoM edge topology

    %% 1. Default Parameter Handling & Validation
    if nargin < 5, diag_pattern = '/'; end
    if nargin < 4, n = 8; end
    if nargin < 3, m = 10; end
    if nargin < 2, Ly = 0.8; end
    if nargin < 1, Lx = 1.0; end

    validateattributes(Lx, {'numeric'}, {'scalar', 'positive', 'finite'}, mfilename, 'Lx');
    validateattributes(Ly, {'numeric'}, {'scalar', 'positive', 'finite'}, mfilename, 'Ly');
    validateattributes(m,  {'numeric'}, {'scalar', 'integer', '>=', 1},  mfilename, 'm');
    validateattributes(n,  {'numeric'}, {'scalar', 'integer', '>=', 1},  mfilename, 'n');
    if ~any(strcmp(diag_pattern, {'/', '\'}))
        error('generate_plate:badPattern', 'diag_pattern must be ''/'' or ''\\''.');
    end

    %% 2. Node Generation (ndgrid: X-fastest linear indexing)
    x_vec = linspace(0, Lx, m + 1);
    y_vec = linspace(0, Ly, n + 1);
    [X, Y] = ndgrid(x_vec, y_vec);
    P = [X(:), Y(:), zeros(numel(X), 1)];

    %% 3. Triangle Connectivity (fully vectorized)
    % Cell (i, j), i = 1..m, j = 1..n; node_id(i, j) = (j-1)*(m+1) + i
    [I, J] = ndgrid(1:m, 1:n);
    I = I(:); J = J(:);

    n_bl = (J - 1) * (m + 1) + I;        % Bottom-Left
    n_br = n_bl + 1;                     % Bottom-Right
    n_tl = n_bl + (m + 1);               % Top-Left
    n_tr = n_tl + 1;                     % Top-Right

    if strcmp(diag_pattern, '/')
        % BL <-> TR diagonal, CCW (+Z normal)
        t = [n_bl, n_br, n_tr;
             n_bl, n_tr, n_tl];
    else
        % TL <-> BR diagonal, CCW (+Z normal)
        t = [n_bl, n_br, n_tl;
             n_br, n_tr, n_tl];
    end
    % Interleave the two triangles per cell to preserve original ordering
    num_cells = m * n;
    order = reshape([1:num_cells; num_cells+1:2*num_cells], [], 1);
    t = t(order, :);

    %% 4. Geometric Properties (vectorized shared helper)
    props = tri_mesh_props(P, t, [0, 0, 1]);

    %% 5. Output Packaging (schema-consistent with generate_sphere)
    mesh_data.Lx = Lx;
    mesh_data.Ly = Ly;
    mesh_data.m  = m;
    mesh_data.n  = n;
    mesh_data.P = P;
    mesh_data.t = t;
    mesh_data.centroids = props.centroids;
    mesh_data.areas     = props.areas;
    mesh_data.normals   = props.normals;
    mesh_data.edges     = props.edges;
    mesh_data.num_interior_edges = props.num_interior_edges;
    mesh_data.num_boundary_edges = props.num_boundary_edges;
    mesh_data.total_area       = props.total_area;
    mesh_data.theoretical_area = Lx * Ly;
end
