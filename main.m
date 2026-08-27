% =========================================================================
% 6-Panel 3D CAD Mesh Studio with Dual Slider-Input Controls (Revised)
% =========================================================================
function main()
    close all;   % NOTE: 'clear' removed — meaningless inside a function workspace

    %% 1. 기본 원본 형상 파라미터 초기화
    init_Lx = 1.0; init_Ly = 0.8; init_m = 8; init_n = 6;
    [P_plate_orig, t_plate_orig, plate_base] = generate_plate(init_Lx, init_Ly, init_m, init_n, '/');

    init_radius = 0.5; init_nth = 10; init_nph = 18;
    [P_sphere_orig, t_sphere_orig, sphere_base] = generate_sphere(init_radius, init_nth, init_nph);

    %% 2. Figure 및 6개 서브플롯 레이아웃 구성
    hFig = figure('Name', 'BRL 3D CAD Mesh Studio (6-Panel Interactive)', ...
                  'Color', 'w', 'Position', [30, 30, 1600, 940]);

    ax = gobjects(2, 3);
    h_plots = struct();

    titles_all = {'1. Plate Grid (Wireframe)',   '2. Plate Shaded Surface',  '3. Plate Outward Normals'; ...
                  '4. Sphere Grid (Wireframe)',  '5. Sphere Shaded Surface', '6. Sphere Outward Normals'};

    for row = 1:2
        for col = 1:3
            y_pos = 0.66 - (row - 1) * 0.33;
            x_pos = 0.05 + (col - 1) * 0.32;
            ax(row, col) = axes('Parent', hFig, 'Position', [x_pos, y_pos, 0.27, 0.27]);
            axis(ax(row, col), 'equal');
            axis(ax(row, col), 'vis3d');   % 회전/이동 시 3D 종횡비 고정 (뷰 튐 방지)
            grid(ax(row, col), 'on');
            box(ax(row, col), 'on');
            view(ax(row, col), 35, 25);
            hold(ax(row, col), 'on');

            set(ax(row, col), 'FontSize', 12, 'FontWeight', 'bold');
            xlabel(ax(row, col), 'X (m)', 'FontSize', 13, 'FontWeight', 'bold');
            ylabel(ax(row, col), 'Y (m)', 'FontSize', 13, 'FontWeight', 'bold');
            zlabel(ax(row, col), 'Z (m)', 'FontSize', 13, 'FontWeight', 'bold');
            title(ax(row, col), titles_all{row, col}, 'FontSize', 14, 'FontWeight', 'bold');
        end
    end

    % 2-1. 평판 서브플롯 초기화 (Row 1)
    plate_color = [0.85, 0.92, 0.98];
    h_plots.plate_wire  = patch('Parent', ax(1, 1), 'Faces', t_plate_orig, 'Vertices', P_plate_orig, ...
                                'FaceColor', plate_color, 'EdgeColor', 'k', 'LineWidth', 0.8);
    h_plots.plate_shade = patch('Parent', ax(1, 2), 'Faces', t_plate_orig, 'Vertices', P_plate_orig, ...
                                'FaceColor', plate_color, 'EdgeColor', 'none', 'FaceAlpha', 1.0);
    light(ax(1, 2), 'Position', [1, 3, 2]);
    lighting(ax(1, 2), 'gouraud'); material(ax(1, 2), 'shiny');

    h_plots.plate_norm_surf = patch('Parent', ax(1, 3), 'Faces', t_plate_orig, 'Vertices', P_plate_orig, ...
                                    'FaceColor', plate_color, 'EdgeColor', 'none', 'FaceAlpha', 0.8);
    h_plots.plate_quiver = quiver3(ax(1, 3), ...
        plate_base.centroids(:,1), plate_base.centroids(:,2), plate_base.centroids(:,3), ...
        plate_base.normals(:,1),   plate_base.normals(:,2),   plate_base.normals(:,3), 0.3, ...
        'Color', 'r', 'LineWidth', 1.2);
    light(ax(1, 3), 'Position', [1, 3, 2]); lighting(ax(1, 3), 'gouraud'); material(ax(1, 3), 'shiny');

    % 2-2. 구 서브플롯 초기화 (Row 2)
    sphere_color = [1.0, 0.78, 0.65];
    h_plots.sphere_wire  = patch('Parent', ax(2, 1), 'Faces', t_sphere_orig, 'Vertices', P_sphere_orig, ...
                                 'FaceColor', sphere_color, 'EdgeColor', 'k', 'LineWidth', 0.8);
    h_plots.sphere_shade = patch('Parent', ax(2, 2), 'Faces', t_sphere_orig, 'Vertices', P_sphere_orig, ...
                                 'FaceColor', sphere_color, 'EdgeColor', 'none', 'FaceAlpha', 1.0);
    light(ax(2, 2), 'Position', [2, 1, 3]); light(ax(2, 2), 'Position', [-2, -1, 3]);
    lighting(ax(2, 2), 'gouraud'); material(ax(2, 2), 'shiny');

    h_plots.sphere_norm_surf = patch('Parent', ax(2, 3), 'Faces', t_sphere_orig, 'Vertices', P_sphere_orig, ...
                                     'FaceColor', sphere_color, 'EdgeColor', 'none', 'FaceAlpha', 0.8);
    h_plots.sphere_quiver = quiver3(ax(2, 3), ...
        sphere_base.centroids(:,1), sphere_base.centroids(:,2), sphere_base.centroids(:,3), ...
        sphere_base.normals(:,1),   sphere_base.normals(:,2),   sphere_base.normals(:,3), 0.3, ...
        'Color', 'r', 'LineWidth', 1.2);
    light(ax(2, 3), 'Position', [2, 1, 3]); lighting(ax(2, 3), 'gouraud'); material(ax(2, 3), 'shiny');

    %% 3. 하단 컴팩트 듀얼 컨트롤러 패널 (슬라이더 + 입력창 동시 배치)
    ui_panel = uipanel('Parent', hFig, 'Title', ' 3D CAD Geometry & Transformation Controller ', ...
                       'FontSize', 12, 'FontWeight', 'bold', 'ForegroundColor', [0.1, 0.2, 0.5], ...
                       'Position', [0.02, 0.01, 0.96, 0.26], 'BackgroundColor', [0.95, 0.95, 0.97]);

    ctrls = struct();
    lbl_fnt = 11;
    edt_fnt = 11;

    function item = create_control_row(parent, x, y, w, h, lbl_text, min_v, max_v, init_v, is_int)
        uicontrol('Parent', parent, 'Style', 'text', 'String', lbl_text, ...
                  'Units', 'normalized', 'Position', [x, y, w*0.30, h], ...
                  'FontSize', lbl_fnt, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.95, 0.95, 0.97]);

        sld = uicontrol('Parent', parent, 'Style', 'slider', 'Min', min_v, 'Max', max_v, 'Value', init_v, ...
                        'Units', 'normalized', 'Position', [x + w*0.30, y, w*0.48, h]);

        % 정수 파라미터: 화살표 클릭 시 정확히 1씩 증감하도록 SliderStep 지정
        if is_int
            rng_span = max_v - min_v;
            set(sld, 'SliderStep', [1, min(5, rng_span)] / rng_span);
        end

        edt = uicontrol('Parent', parent, 'Style', 'edit', 'String', fmt_val(init_v, is_int), ...
                        'Units', 'normalized', 'Position', [x + w*0.80, y, w*0.20, h], ...
                        'FontSize', edt_fnt, 'FontWeight', 'bold', 'BackgroundColor', 'w');

        item.slider = sld;
        item.edit = edt;
        item.is_int = is_int;
        item.default = init_v;
    end

    % ---------------- Column 1: Plate Geometry ----------------
    make_header(ui_panel, [0.01, 0.82, 0.17, 0.14], '[ Plate Geometry ]', [0.1, 0.3, 0.6]);
    ctrls.Lx = create_control_row(ui_panel, 0.01, 0.62, 0.17, 0.16, 'Lx (m):', 0.1, 20.0, init_Lx, false);
    ctrls.Ly = create_control_row(ui_panel, 0.01, 0.42, 0.17, 0.16, 'Ly (m):', 0.1, 20.0, init_Ly, false);
    ctrls.m  = create_control_row(ui_panel, 0.01, 0.22, 0.17, 0.16, 'm (div):', 1, 50, init_m, true);
    ctrls.n  = create_control_row(ui_panel, 0.01, 0.02, 0.17, 0.16, 'n (div):', 1, 50, init_n, true);

    % ---------------- Column 2: Sphere Geometry ----------------
    make_header(ui_panel, [0.20, 0.82, 0.17, 0.14], '[ Sphere Geometry ]', [0.7, 0.2, 0.0]);
    ctrls.Radius = create_control_row(ui_panel, 0.20, 0.62, 0.17, 0.16, 'Radius:', 0.1, 5.0, init_radius, false);
    ctrls.nth    = create_control_row(ui_panel, 0.20, 0.42, 0.17, 0.16, 'n_th:',   2, 50, init_nth, true);
    ctrls.nph    = create_control_row(ui_panel, 0.20, 0.22, 0.17, 0.16, 'n_ph:',   3, 50, init_nph, true);

    % ---------------- Column 3: Scale & Rotation ----------------
    make_header(ui_panel, [0.39, 0.82, 0.20, 0.14], '[ Scale & Rotation ]', [0, 0, 0]);
    ctrls.Scale = create_control_row(ui_panel, 0.39, 0.62, 0.20, 0.16, 'Scale:',    0.1, 3.0, 1.0, false);
    ctrls.Roll  = create_control_row(ui_panel, 0.39, 0.42, 0.20, 0.16, 'Roll(X°):', -180, 180, 0.0, false);
    ctrls.Pitch = create_control_row(ui_panel, 0.39, 0.22, 0.20, 0.16, 'Pitch(Y°):', -180, 180, 0.0, false);
    ctrls.Yaw   = create_control_row(ui_panel, 0.39, 0.02, 0.20, 0.16, 'Yaw(Z°):',   -180, 180, 0.0, false);

    % ---------------- Column 4: Translation ----------------
    make_header(ui_panel, [0.61, 0.82, 0.19, 0.14], '[ Translation (m) ]', [0, 0, 0]);
    ctrls.TransX = create_control_row(ui_panel, 0.61, 0.62, 0.19, 0.16, 'Trans X:', -10.0, 10.0, 0.0, false);
    ctrls.TransY = create_control_row(ui_panel, 0.61, 0.42, 0.19, 0.16, 'Trans Y:', -10.0, 10.0, 0.0, false);
    ctrls.TransZ = create_control_row(ui_panel, 0.61, 0.22, 0.19, 0.16, 'Trans Z:', -10.0, 10.0, 0.0, false);

    % ---------------- Column 5: Target & Actions ----------------
    make_header(ui_panel, [0.82, 0.82, 0.17, 0.14], '[ Target & Actions ]', [0, 0, 0]);
    ctrls.Target = uicontrol('Parent', ui_panel, 'Style', 'popupmenu', ...
                             'String', {'Both Models', 'Plate Only', 'Sphere Only'}, ...
                             'Units', 'normalized', 'Position', [0.82, 0.60, 0.17, 0.18], ...
                             'FontSize', 11, 'FontWeight', 'bold');

    ctrls.btn_apply = uicontrol('Parent', ui_panel, 'Style', 'pushbutton', 'String', '메시 생성 및 적용 (Apply)', ...
                                'Units', 'normalized', 'Position', [0.82, 0.32, 0.17, 0.24], ...
                                'FontSize', 11, 'FontWeight', 'bold', ...
                                'BackgroundColor', [0.15, 0.55, 0.25], 'ForegroundColor', 'w');

    ctrls.btn_reset = uicontrol('Parent', ui_panel, 'Style', 'pushbutton', 'String', '기본값 초기화 (Reset)', ...
                                'Units', 'normalized', 'Position', [0.82, 0.04, 0.17, 0.24], ...
                                'FontSize', 11, 'FontWeight', 'bold', ...
                                'BackgroundColor', [0.88, 0.90, 0.95], 'ForegroundColor', [0.15, 0.2, 0.4]);

    function make_header(parent, pos, str, fg)
        uicontrol('Parent', parent, 'Style', 'text', 'String', str, ...
                  'Units', 'normalized', 'Position', pos, ...
                  'FontSize', lbl_fnt+1, 'FontWeight', 'bold', 'ForegroundColor', fg, ...
                  'HorizontalAlignment', 'left', 'BackgroundColor', [0.95, 0.95, 0.97]);
    end

    %% 4. 슬라이더-에디트 박스 양방향 동기화 및 콜백 바인딩
    % ContinuousValueChange 리스너: 드래그 중 실시간 갱신 (Callback은 릴리즈 시에만 발화)
    fn_list = fieldnames(ctrls);
    for idx = 1:numel(fn_list)
        fn = fn_list{idx};
        if isstruct(ctrls.(fn)) && isfield(ctrls.(fn), 'slider')
            c_item = ctrls.(fn);
            addlistener(c_item.slider, 'ContinuousValueChange', ...
                        @(src, ~) sync_slider(src, c_item.edit, c_item.is_int));
            set(c_item.edit, 'Callback', @(src, ~) sync_edit(src, c_item.slider, c_item.is_int));
        end
    end

    set(ctrls.Target,    'Callback', @apply_callback);
    set(ctrls.btn_apply, 'Callback', @apply_callback);
    set(ctrls.btn_reset, 'Callback', @reset_callback);

    function s = fmt_val(val, is_int)
        if is_int, s = sprintf('%d', round(val));
        else,      s = sprintf('%.2f', val);
        end
    end

    function sync_slider(sld_src, edt_dest, is_int)
        val = get(sld_src, 'Value');
        if is_int
            val = round(val);
            set(sld_src, 'Value', val);
        end
        set(edt_dest, 'String', fmt_val(val, is_int));
        apply_callback([], []);
    end

    function sync_edit(edt_src, sld_dest, is_int)
        val = str2double(get(edt_src, 'String'));
        min_v = get(sld_dest, 'Min');
        max_v = get(sld_dest, 'Max');
        if isnan(val), val = get(sld_dest, 'Value'); end   % 잘못된 입력 시 직전 값 유지
        val = min(max(val, min_v), max_v);
        if is_int, val = round(val); end
        set(sld_dest, 'Value', val);
        set(edt_src, 'String', fmt_val(val, is_int));
        apply_callback([], []);
    end

    % NaN-safe 파라미터 판독: edit 문자열 -> 슬라이더 범위로 클램프
    function val = get_val(item)
        val = str2double(get(item.edit, 'String'));
        if isnan(val), val = get(item.slider, 'Value'); end
        val = min(max(val, get(item.slider, 'Min')), get(item.slider, 'Max'));
        if item.is_int, val = round(val); end
    end

    %% 5. 변환 실행 및 실시간 렌더링 갱신
    function apply_callback(~, ~)
        Lx_val  = get_val(ctrls.Lx);   Ly_val  = get_val(ctrls.Ly);
        m_val   = get_val(ctrls.m);    n_val   = get_val(ctrls.n);
        rad_val = get_val(ctrls.Radius);
        nth_val = get_val(ctrls.nth);  nph_val = get_val(ctrls.nph);

        s_val  = get_val(ctrls.Scale);
        rot    = [get_val(ctrls.Roll), get_val(ctrls.Pitch), get_val(ctrls.Yaw)];
        trans  = [get_val(ctrls.TransX), get_val(ctrls.TransY), get_val(ctrls.TransZ)];
        target_idx = get(ctrls.Target, 'Value');

        % 1) 평판 재생성 및 변환
        [~, ~, p_base] = generate_plate(Lx_val, Ly_val, m_val, n_val, '/');
        if target_idx == 1 || target_idx == 2
            [~, p_mod] = mesh_transform(p_base, 'Scale', s_val, 'Rotate', rot, ...
                                        'Translate', trans, 'Center', 'centroid');
        else
            p_mod = p_base;
        end

        % 2) 구 재생성 및 변환
        [~, ~, s_base] = generate_sphere(rad_val, nth_val, nph_val);
        if target_idx == 1 || target_idx == 3
            [~, s_mod] = mesh_transform(s_base, 'Scale', s_val, 'Rotate', rot, ...
                                        'Translate', trans, 'Center', 'centroid');
        else
            s_mod = s_base;
        end

        % 3) 패치 갱신 (핸들 재사용)
        set(h_plots.plate_wire,      'Faces', p_mod.t, 'Vertices', p_mod.P);
        set(h_plots.plate_shade,     'Faces', p_mod.t, 'Vertices', p_mod.P);
        set(h_plots.plate_norm_surf, 'Faces', p_mod.t, 'Vertices', p_mod.P);
        set(h_plots.sphere_wire,      'Faces', s_mod.t, 'Vertices', s_mod.P);
        set(h_plots.sphere_shade,     'Faces', s_mod.t, 'Vertices', s_mod.P);
        set(h_plots.sphere_norm_surf, 'Faces', s_mod.t, 'Vertices', s_mod.P);

        % 4) Quiver 갱신: delete/재생성 대신 데이터만 교체 (핸들·조명 상태 보존)
        update_quiver(h_plots.plate_quiver,  p_mod);
        update_quiver(h_plots.sphere_quiver, s_mod);

        drawnow limitrate;   % 드래그 중 이벤트 폭주 시 렌더링 부하 제한
    end

    function update_quiver(hq, md)
        set(hq, 'XData', md.centroids(:,1), 'YData', md.centroids(:,2), 'ZData', md.centroids(:,3), ...
                'UData', md.normals(:,1),   'VData', md.normals(:,2),   'WData', md.normals(:,3));
    end

    function reset_callback(~, ~)
        fields = fieldnames(ctrls);
        for i = 1:numel(fields)
            fn_name = fields{i};
            if isstruct(ctrls.(fn_name)) && isfield(ctrls.(fn_name), 'default')
                def = ctrls.(fn_name).default;
                set(ctrls.(fn_name).slider, 'Value', def);
                set(ctrls.(fn_name).edit, 'String', fmt_val(def, ctrls.(fn_name).is_int));
            end
        end
        set(ctrls.Target, 'Value', 1);
        apply_callback([], []);
    end
end
