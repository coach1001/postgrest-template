--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.8
-- Dumped by pg_dump version 9.6.4

-- Started on 2017-09-01 14:47:16 SAST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

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

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 186 (class 1259 OID 96385)
-- Name: files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE files (
    file_id integer NOT NULL,
    creator_id text DEFAULT current_setting('request.jwt.claim.uid'::text) NOT NULL,
    created_on timestamp without time zone NOT NULL,
    updated_on timestamp without time zone
);


ALTER TABLE files OWNER TO postgres;

--
-- TOC entry 2073 (class 2606 OID 96393)
-- Name: files pk_files; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY files
    ADD CONSTRAINT pk_files PRIMARY KEY (file_id);


--
-- TOC entry 2189 (class 3256 OID 96397)
-- Name: files file_select_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY file_select_all ON files FOR SELECT TO PUBLIC USING (true);


--
-- TOC entry 2190 (class 3256 OID 96402)
-- Name: files file_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY file_update ON files FOR UPDATE TO PUBLIC USING ((current_setting('request.jwt.claim.uid'::text) = creator_id)) WITH CHECK ((current_setting('request.jwt.claim.uid'::text) = creator_id));


--
-- TOC entry 2188 (class 0 OID 96385)
-- Name: files; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE files ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 2196 (class 0 OID 0)
-- Dependencies: 9
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;
GRANT USAGE ON SCHEMA public TO anon;


--
-- TOC entry 2197 (class 0 OID 0)
-- Dependencies: 243
-- Name: login(text, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION login(email text, password text) FROM PUBLIC;
REVOKE ALL ON FUNCTION login(email text, password text) FROM postgres;
GRANT ALL ON FUNCTION login(email text, password text) TO postgres;
GRANT ALL ON FUNCTION login(email text, password text) TO PUBLIC;
GRANT ALL ON FUNCTION login(email text, password text) TO anon;


--
-- TOC entry 2198 (class 0 OID 0)
-- Dependencies: 186
-- Name: files; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE files FROM PUBLIC;
REVOKE ALL ON TABLE files FROM postgres;
GRANT ALL ON TABLE files TO postgres;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE files TO anon;


-- Completed on 2017-09-01 14:47:16 SAST

--
-- PostgreSQL database dump complete
--

