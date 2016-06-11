GRANT ALL ON sys_users TO cleaningweb;
GRANT ALL ON sys_users_id_seq TO cleaningweb;
GRANT ALL ON sys_users_sessions TO cleaningweb;
GRANT ALL ON sys_users_sessions_id_seq TO cleaningweb;

GRANT ALL ON clients TO cleaningweb;
GRANT ALL ON clients_id_seq TO cleaningweb;
GRANT ALL ON clients_client_number_seq TO cleaningweb;
GRANT SELECT on clients_crud_vw TO cleaningweb;

GRANT ALL ON team_members TO cleaningweb;
GRANT ALL ON team_members_id_seq TO cleaningweb;
GRANT ALL ON teams TO cleaningweb;
GRANT ALL ON teams_id_seq TO cleaningweb;
GRANT SELECT ON team_members_crud_vw TO cleaningweb;
GRANT SELECT ON teams_crud_vw TO cleaningweb;

GRANT ALL ON quotes TO cleaningweb;
GRANT ALL ON quotes_quote_number_seq TO cleaningweb;
GRANT ALL ON quotes_id_seq TO cleaningweb;
GRANT ALL ON quote_types TO cleaningweb;
GRANT ALL ON quote_types_id_seq TO cleaningweb;
GRANT SELECT ON quote_statuses TO cleaningweb;
GRANT SELECT ON quotes_crud_vw TO cleaningweb;
GRANT SELECT ON quote_types_crud_vw TO cleaningweb;
