CREATE TABLE quote_types (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

CREATE TABLE quote_statuses (
    id INT PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

INSERT INTO quote_statuses VALUES(100, 'Pending'), (200, 'Completed'), (300, 'Rejected');

CREATE SEQUENCE quotes_quote_number_seq INCREMENT BY 1 MINVALUE 1000000;

CREATE TABLE quotes (
    id SERIAL PRIMARY KEY,
    id_hash TEXT UNIQUE NOT NULL DEFAULT md5(random()::text || now()::text || random()::text),
    quote_number INTEGER UNIQUE NOT NULL DEFAULT nextval('quotes_quote_number_seq'::regclass),
    starts_at TIMESTAMP NOT NULL,
    finished_at TIMESTAMP,
    price NUMERIC(10,2) NOT NULL,
    type_id INT NOT NULL REFERENCES quote_types(id),
    status_id INT NOT NULL REFERENCES quote_statuses(id) DEFAULT 100,
    client_id INT NOT NULL REFERENCES clients(id),
    team_id INT NOT NULL REFERENCES teams(id),
    notes TEXT,
    inserted_at TIMESTAMP NOT NULL DEFAULT now(),
    inserted_by TEXT NOT NULL DEFAULT 'SYSTEM',
    updated_at  TIMESTAMP NOT NULL DEFAULT now(),
    updated_by  TEXT NOT NULL DEFAULT 'SYSTEM'
);
