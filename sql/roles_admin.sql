-- script for creating roles on the database
-- supercedes the R sulution used originally in the file users.R

-- create maintainer role and grant to me
CREATE ROLE maintainer ;
GRANT ALL PRIVILEGES ON DATABASE test TO maintainer;
ALTER ROLE maintainer CREATEROLE CREATEDB;
GRANT maintainer TO majaz;

-- create reader role and grant to everyone.
CREATE ROLE reader;
GRANT CONNECT ON DATABASE test TO reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO reader;

REVOKE ALL ON DATABASE test FROM janez;
REVOKE ALL ON DATABASE test FROM mojca;
REVOKE ALL ON DATABASE test FROM andrej;
REVOKE ALL ON DATABASE test FROM maja;
GRANT reader TO andrej, janez, maja, mojca;

-- new users are added so:
CREATE USER <new user> WITH PASSWORD '<new password>';
REVOKE ALL ON DATABASE test FROM  <new user>;
GRANT reader to <new user>;
