CREATE VIEW clients_crud_vw AS (
    SELECT account_id AS unique_identifier,
        client_number AS "Client number",
        first_name AS "First name",
        last_name AS "Last name",
        email AS "Email",
        telephone_numbers AS "Telephone numbers",
        address_line1 AS "Address line1",
        address_line2 AS "Address line2",
        city AS "City",
        postcode AS "Postcode",
        notes AS "Notes"
    FROM clients
    WHERE is_deleted IS FALSE
    ORDER BY client_number
);

CREATE VIEW teams_crud_vw AS (
    SELECT
        id_hash AS unique_identifier,
        name AS "Team name",
        notes AS "Notes"
    FROM teams
    WHERE is_deleted is FALSE
    ORDER BY name
);

CREATE VIEW team_members_crud_vw AS (
    SELECT
        TM.id_hash AS unique_identifier,
        TM.first_name AS "First name",
        TM.last_name AS "Last name",
        T.name AS "Team",
        TM.notes AS "Notes"
    FROM team_members TM
        LEFT JOIN teams T ON TM.team_id = T.id
    WHERE TM.is_deleted IS FALSE
    ORDER BY TM.first_name, TM.last_name
);

CREATE VIEW quote_types_crud_vw AS (
    SELECT
        id AS unique_identifier,
        name AS "Type"
    FROM quote_types
);

CREATE VIEW quotes_crud_vw AS (
    SELECT 
        Q.id_hash AS unique_identifier,
        Q.quote_number AS "Quote number",
        C.first_name || C.last_name || '(' || C.client_number || ')' AS "Client",
        QT.name AS "Type",
        Q.price AS "Price",
        Q.starts_at AS "Starts at",
        Q.finished_at AS "Finished at",
        QS.name AS "Status",
        T.name AS "Team",
        Q.notes AS "Notes",
        'quote-pdfs/' || Q.id_hash || '.pdf' AS "PDF_pdf_file"
    FROM quotes Q
        JOIN quote_types QT ON Q.type_id = QT.id
        JOIN quote_statuses QS ON Q.status_id = QS.id
        JOIN clients C ON Q.client_id = C.id
        JOIN teams T ON Q.team_id = T.id
);
