function props = tri_mesh_props(P, t, fallback_normal)
% TRI_MESH_PROPS Vectorized triangle-mesh geometric properties & edge topology
%
% [Inputs]
%   P               : Node coordinates (N x 3)
%   t               : Triangle connectivity (M x 3)
%   fallback_normal : Normal to assign to degenerate (zero-area) triangles.
%                     Either a 1x3 vector, or 'radial' (use centroid direction).
%
% [Outputs] props struct:
%   .centroids (M x 3), .areas (M x 1), .normals (M x 3, unit)
%   .edges (E x 2, sorted), .num_interior_edges, .num_boundary_edges
%   .total_area

    if nargin < 3, fallback_normal = [0, 0, 1]; end

    r1 = P(t(:, 1), :);
    r2 = P(t(:, 2), :);
    r3 = P(t(:, 3), :);

    props.centroids = (r1 + r2 + r3) / 3;

    cp = cross(r2 - r1, r3 - r1, 2);          % M x 3
    nv = sqrt(sum(cp.^2, 2));                  % M x 1
    props.areas = 0.5 * nv;

    normals = cp ./ max(nv, eps);              % implicit expansion
    bad = nv <= eps;                           % degenerate triangles
    if any(bad)
        if ischar(fallback_normal) && strcmpi(fallback_normal, 'radial')
            c  = props.centroids(bad, :);
            cn = sqrt(sum(c.^2, 2));
            normals(bad, :) = c ./ max(cn, eps);
        else
            normals(bad, :) = repmat(reshape(fallback_normal, 1, 3), nnz(bad), 1);
        end
    end
    props.normals = normals;
    props.total_area = sum(props.areas);

    % Edge topology (MoM RWG basis bookkeeping)
    all_edges = sort([t(:, [1, 2]); t(:, [2, 3]); t(:, [3, 1])], 2);
    [unique_edges, ~, edge_map] = unique(all_edges, 'rows');
    edge_counts = accumarray(edge_map, 1);

    props.edges = unique_edges;
    props.num_interior_edges = sum(edge_counts == 2);
    props.num_boundary_edges = sum(edge_counts == 1);
end
