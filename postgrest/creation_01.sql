--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.8
-- Dumped by pg_dump version 9.6.4

-- Started on 2017-09-01 12:00:09 SAST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 10 (class 2615 OID 96269)
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
-- TOC entry 2206 (class 0 OID 0)
-- Dependencies: 1
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- TOC entry 3 (class 3079 OID 96270)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 2207 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 2 (class 3079 OID 96333)
-- Name: pgjwt; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pgjwt WITH SCHEMA public;


--
-- TOC entry 2208 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgjwt; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgjwt IS 'JSON Web Token API for Postgresql';


SET search_path = basic_authentication, pg_catalog;

--
-- TOC entry 598 (class 1247 OID 96309)
-- Name: jwt_token; Type: TYPE; Schema: basic_authentication; Owner: postgres
--

CREATE TYPE jwt_token AS (
	token text
);


ALTER TYPE jwt_token OWNER TO postgres;

--
-- TOC entry 235 (class 1255 OID 96327)
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
-- TOC entry 241 (class 1255 OID 96330)
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
-- TOC entry 236 (class 1255 OID 96332)
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
-- TOC entry 243 (class 1255 OID 96340)
-- Name: login(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION login(email text, password text) RETURNS basic_authentication.jwt_token
    LANGUAGE plpgsql
    AS $$
declare
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
         extract(epoch from now())::integer + 60*60*365 as exp
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
-- TOC entry 185 (class 1259 OID 96315)
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
-- TOC entry 186 (class 1259 OID 96349)
-- Name: files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE files (
    file_id integer NOT NULL,
    creator_id text NOT NULL,
    created_on timestamp without time zone NOT NULL,
    updated_on timestamp without time zone
);


ALTER TABLE files OWNER TO postgres;

SET search_path = basic_authentication, pg_catalog;

--
-- TOC entry 2079 (class 2606 OID 96326)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: basic_authentication; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (uid);


SET search_path = public, pg_catalog;

--
-- TOC entry 2081 (class 2606 OID 96356)
-- Name: files pk_files; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY files
    ADD CONSTRAINT pk_files PRIMARY KEY (file_id);


SET search_path = basic_authentication, pg_catalog;

--
-- TOC entry 2083 (class 2620 OID 96331)
-- Name: users encrypt_password; Type: TRIGGER; Schema: basic_authentication; Owner: postgres
--

CREATE TRIGGER encrypt_password BEFORE INSERT OR UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE encrypt_password();


--
-- TOC entry 2082 (class 2620 OID 96329)
-- Name: users ensure_user_role_exists; Type: TRIGGER; Schema: basic_authentication; Owner: postgres
--

CREATE CONSTRAINT TRIGGER ensure_user_role_exists AFTER INSERT OR UPDATE ON users NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE PROCEDURE check_role_exists();


--
-- TOC entry 2203 (class 0 OID 0)
-- Dependencies: 10
-- Name: basic_authentication; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA basic_authentication FROM PUBLIC;
REVOKE ALL ON SCHEMA basic_authentication FROM postgres;
GRANT ALL ON SCHEMA basic_authentication TO postgres;
GRANT USAGE ON SCHEMA basic_authentication TO anon;


--
-- TOC entry 2205 (class 0 OID 0)
-- Dependencies: 9
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;
GRANT USAGE ON SCHEMA public TO anon;


SET search_path = public, pg_catalog;

--
-- TOC entry 2209 (class 0 OID 0)
-- Dependencies: 243
-- Name: login(text, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION login(email text, password text) FROM PUBLIC;
REVOKE ALL ON FUNCTION login(email text, password text) FROM postgres;
GRANT ALL ON FUNCTION login(email text, password text) TO postgres;
GRANT ALL ON FUNCTION login(email text, password text) TO PUBLIC;
GRANT ALL ON FUNCTION login(email text, password text) TO anon;


SET search_path = basic_authentication, pg_catalog;

--
-- TOC entry 2210 (class 0 OID 0)
-- Dependencies: 185
-- Name: users; Type: ACL; Schema: basic_authentication; Owner: postgres
--

REVOKE ALL ON TABLE users FROM PUBLIC;
REVOKE ALL ON TABLE users FROM postgres;
GRANT ALL ON TABLE users TO postgres;
GRANT SELECT ON TABLE users TO anon;


-- Completed on 2017-09-01 12:00:09 SAST

--
-- PostgreSQL database dump complete
--

