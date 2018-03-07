--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.8
-- Dumped by pg_dump version 9.5.8

-- Started on 2017-06-17 23:54:01 SAST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 10 (class 2615 OID 16441)
-- Name: basic_authentication; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA basic_authentication;


ALTER SCHEMA basic_authentication OWNER TO postgres;

--
-- TOC entry 1 (class 3079 OID 12393)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2215 (class 0 OID 0)
-- Dependencies: 1
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- TOC entry 3 (class 3079 OID 16442)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 2216 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 2 (class 3079 OID 16479)
-- Name: pgjwt; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS pgjwt WITH SCHEMA public;


--
-- TOC entry 2217 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgjwt; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION pgjwt IS 'JSON Web Token API for Postgresql';


SET search_path = basic_authentication, pg_catalog;

--
-- TOC entry 598 (class 1247 OID 16487)
-- Name: jwt_token; Type: TYPE; Schema: basic_authentication; Owner: postgres
--

CREATE TYPE jwt_token AS (
	token text
);


ALTER TYPE jwt_token OWNER TO postgres;

--
-- TOC entry 240 (class 1255 OID 16488)
-- Name: check_role_exists(); Type: FUNCTION; Schema: basic_authentication; Owner: postgres
--

CREATE FUNCTION check_role_exists() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if not exists (select 1 from pg_roles as r where r.rolname = new.role) then
    raise foreign_key_violation using message =
      'unknown database role: ' || new.role;
    return null;
  end if;
  return new;
end
$$;


ALTER FUNCTION basic_authentication.check_role_exists() OWNER TO postgres;

--
-- TOC entry 241 (class 1255 OID 16489)
-- Name: encrypt_password(); Type: FUNCTION; Schema: basic_authentication; Owner: postgres
--

CREATE FUNCTION encrypt_password() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if tg_op = 'INSERT' or new.password <> old.password then
    new.password = crypt(new.password, gen_salt('bf'));
  end if;
  return new;
end
$$;


ALTER FUNCTION basic_authentication.encrypt_password() OWNER TO postgres;

--
-- TOC entry 242 (class 1255 OID 16490)
-- Name: user_role(text, text); Type: FUNCTION; Schema: basic_authentication; Owner: postgres
--

CREATE FUNCTION user_role(email text, password text) RETURNS name
    LANGUAGE plpgsql
    AS $$
begin
  return (
  select role from basic_authentication.users
   where users.email = user_role.email
     and users.password = crypt(user_role.password, users.password)
  );
end;
$$;


ALTER FUNCTION basic_authentication.user_role(email text, password text) OWNER TO postgres;

SET search_path = public, pg_catalog;

--
-- TOC entry 243 (class 1255 OID 16491)
-- Name: login(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION login(email text, password text) RETURNS basic_authentication.jwt_token
    LANGUAGE plpgsql
    AS $$declare
  _role name;
  _verified boolean;
  _uid text;
  result basic_authentication.jwt_token;
begin
  -- check email and password
  select basic_authentication.user_role(login.email, login.password) into _role;
  if _role is null then
    raise invalid_password using message = 'Invalid Email Or Password';
  end if;

  select basic_authentication.users.uid, basic_authentication.users.verified into _uid,_verified
  from basic_authentication.users
  where basic_authentication.users.email = login.email limit 1;

  if _verified = false then
   raise insufficient_privilege using message= 'User not Verified';
  end if;

  select sign(
      row_to_json(r), '.Y|E%BEl{>TfcLsY@NF9#XfK&SX.ge4>7V{T&KxH6OX<dxomk84hf*ZDgFULw1%'
    ) as token
    from (
      select _role as role, login.email as email, _uid as uid,
         extract(epoch from now())::integer + 1000*60*24*365 as exp
    ) r
    into result;
  return result;
end;
$$;


ALTER FUNCTION public.login(email text, password text) OWNER TO postgres;

SET search_path = basic_authentication, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 185 (class 1259 OID 16492)
-- Name: users; Type: TABLE; Schema: basic_authentication; Owner: postgres
--

CREATE TABLE users (
    uid uuid DEFAULT public.gen_random_uuid() NOT NULL,
    email text,
    password text NOT NULL,
    role name NOT NULL,
    verified boolean DEFAULT true,
    CONSTRAINT users_email_check CHECK ((email ~* '^.+@.+\..+$'::text)),
    CONSTRAINT users_password_check CHECK ((length(password) < 512)),
    CONSTRAINT users_role_check CHECK ((length((role)::text) < 512))
);


ALTER TABLE users OWNER TO postgres;

SET search_path = public, pg_catalog;

--
-- TOC entry 186 (class 1259 OID 16503)
-- Name: files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE files (
    file_id integer NOT NULL,
    creator_id text DEFAULT current_setting('request.jwt.claim.uid'::text) NOT NULL,
    created_on timestamp without time zone NOT NULL,
    updated_on timestamp without time zone
);


ALTER TABLE files OWNER TO postgres;

SET search_path = basic_authentication, pg_catalog;

--
-- TOC entry 2205 (class 0 OID 16492)
-- Dependencies: 185
-- Data for Name: users; Type: TABLE DATA; Schema: basic_authentication; Owner: postgres
--

COPY users (uid, email, password, role, verified) FROM stdin;
a38f5cc6-dc03-4108-83cb-8a0fe92c12cd	fweber@fhr.org.za	$2a$06$bSuVcCRmmndYMrJ92l8MhuLFxGMRts2ID3CvfQLm16mCnTrgQVO1W	user	t
51a4c9e4-406d-4ba2-80e1-0a5d4240f352	coach1001@gmail.com	$2a$06$OowzkVuJSt0pPwYV91OQ9OkbAKmrQR1PmrfeBni94GH/BSFY0gpTS	user	t
\.


SET search_path = public, pg_catalog;

--
-- TOC entry 2206 (class 0 OID 16503)
-- Dependencies: 186
-- Data for Name: files; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY files (file_id, creator_id, created_on, updated_on) FROM stdin;
4	51a4c9e4-406d-4ba2-80e1-0a5d4240f352	2017-06-16 21:09:18.777	2017-12-01 00:00:00
13	51a4c9e4-406d-4ba2-80e1-0a5d4240f352	2017-06-17 21:29:02.43	\N
14	51a4c9e4-406d-4ba2-80e1-0a5d4240f352	2017-06-17 21:33:36.961	\N
\.


SET search_path = basic_authentication, pg_catalog;

--
-- TOC entry 2080 (class 2606 OID 16510)
-- Name: pk_users_uid; Type: CONSTRAINT; Schema: basic_authentication; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT pk_users_uid PRIMARY KEY (uid);


--
-- TOC entry 2082 (class 2606 OID 32769)
-- Name: uq_users_email; Type: CONSTRAINT; Schema: basic_authentication; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT uq_users_email UNIQUE (email);


SET search_path = public, pg_catalog;

--
-- TOC entry 2084 (class 2606 OID 16512)
-- Name: pk_files; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY files
    ADD CONSTRAINT pk_files PRIMARY KEY (file_id);


SET search_path = basic_authentication, pg_catalog;

--
-- TOC entry 2085 (class 2620 OID 16513)
-- Name: encrypt_password; Type: TRIGGER; Schema: basic_authentication; Owner: postgres
--

CREATE TRIGGER encrypt_password BEFORE INSERT OR UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE encrypt_password();


--
-- TOC entry 2086 (class 2620 OID 16515)
-- Name: ensure_user_role_exists; Type: TRIGGER; Schema: basic_authentication; Owner: postgres
--

CREATE CONSTRAINT TRIGGER ensure_user_role_exists AFTER INSERT OR UPDATE ON users NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE PROCEDURE check_role_exists();


SET search_path = public, pg_catalog;

--
-- TOC entry 2204 (class 3256 OID 24578)
-- Name: file_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY file_insert ON files FOR INSERT TO file_uploader WITH CHECK (true);


--
-- TOC entry 2202 (class 3256 OID 24576)
-- Name: file_select_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY file_select_all ON files FOR SELECT TO PUBLIC USING (true);


--
-- TOC entry 2203 (class 3256 OID 24577)
-- Name: file_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY file_update ON files FOR UPDATE TO PUBLIC USING ((current_setting('request.jwt.claim.uid'::text) = creator_id)) WITH CHECK ((current_setting('request.jwt.claim.uid'::text) = creator_id));


--
-- TOC entry 2201 (class 0 OID 16503)
-- Name: files; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE files ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 2212 (class 0 OID 0)
-- Dependencies: 10
-- Name: basic_authentication; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA basic_authentication FROM PUBLIC;
REVOKE ALL ON SCHEMA basic_authentication FROM postgres;
GRANT ALL ON SCHEMA basic_authentication TO postgres;
GRANT USAGE ON SCHEMA basic_authentication TO file_uploader;


--
-- TOC entry 2214 (class 0 OID 0)
-- Dependencies: 9
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;
GRANT USAGE ON SCHEMA public TO file_uploader;


--
-- TOC entry 2218 (class 0 OID 0)
-- Dependencies: 243
-- Name: login(text, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION login(email text, password text) FROM PUBLIC;
REVOKE ALL ON FUNCTION login(email text, password text) FROM postgres;
GRANT ALL ON FUNCTION login(email text, password text) TO postgres;
GRANT ALL ON FUNCTION login(email text, password text) TO PUBLIC;
GRANT ALL ON FUNCTION login(email text, password text) TO file_uploader;


SET search_path = basic_authentication, pg_catalog;

--
-- TOC entry 2219 (class 0 OID 0)
-- Dependencies: 185
-- Name: users; Type: ACL; Schema: basic_authentication; Owner: postgres
--

REVOKE ALL ON TABLE users FROM PUBLIC;
REVOKE ALL ON TABLE users FROM postgres;
GRANT ALL ON TABLE users TO postgres;
GRANT SELECT ON TABLE users TO file_uploader;


SET search_path = public, pg_catalog;

--
-- TOC entry 2220 (class 0 OID 0)
-- Dependencies: 186
-- Name: files; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE files FROM PUBLIC;
REVOKE ALL ON TABLE files FROM postgres;
GRANT ALL ON TABLE files TO postgres;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE files TO file_uploader;


-- Completed on 2017-06-17 23:54:01 SAST

--
-- PostgreSQL database dump complete
--
