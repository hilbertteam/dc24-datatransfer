CREATE ROLE person_viewer;
CREATE ROLE sales_admin;
GRANT USAGE on SCHEMA person to person_viewer;
GRANT SELECT ON ALL TABLES IN SCHEMA person to person_viewer;
GRANT ALL ON SCHEMA sales TO sales_admin;
CREATE USER mary WITH PASSWORD 'test123';
CREATE USER vasja WITH PASSWORD 'test456';
GRANT person_viewer TO mary;
GRANT person_viewer, sales_admin TO vasja;


