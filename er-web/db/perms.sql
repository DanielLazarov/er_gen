GRANT SELECT, UPDATE, INSERT ON sys_users TO er_diagweb;
GRANT USAGE ON sys_users_id_seq TO er_diagweb;

GRANT SELECT, UPDATE, INSERT ON sys_users_sessions TO er_diagweb;
GRANT USAGE ON sys_users_sessions_id_seq TO er_diagweb;

GRANT SELECT, UPDATE, INSERT ON diagrams TO er_diagweb;
GRANT USAGE ON diagrams_id_seq TO er_diagweb;

GRANT SELECT, UPDATE, INSERT ON last_diagram_by_session TO er_diagweb;
GRANT USAGE ON last_diagram_by_session_id_seq TO er_diagweb;
