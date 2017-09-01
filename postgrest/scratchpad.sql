/*set role anon;

set request.jwt.claim.uid = 'e6cc76db-1caf-49f0-b80b-968687e09040';
UPDATE public.files
   SET updated_on= '2018-01-01 00:00:00'
 WHERE file_id=2;

set role postgres;*/

--select current_setting('request.jwt.claim.uid'::text);
--set role postgres;
--select * from files;
--select * from pg_policies;
--"(creator_id = current_setting('request.jwt.claim.uid'::text))"
--alter table files enable row level security;
--GRANT SELECT ON files to anon;



--IMPORTANT
--CREATE POLICY file_select_all ON files FOR SELECT USING (true)
--CREATE POLICY file_insert ON files FOR INSERT TO anon WITH CHECK (true)

--IMPORTANT
--CREATE POLICY file_update ON files FOR UPDATE 
--USING (current_setting('request.jwt.claim.uid'::text) = creator_id)  
--WITH CHECK (current_setting('request.jwt.claim.uid'::text) = creator_id);

--DROP POLICY file_insert on FILES;
--CREATE POLICY file_update ON files FOR UPDATE 
--USING (current_setting('request.jwt.claim.uid'::text) = creator_id)  
--WITH CHECK (current_setting('request.jwt.claim.uid'::text) = creator_id);
--CREATE POLICY file_update ON files FOR INSERT 
--USING (current_setting('request.jwt.claim.uid'::text) = creator_id)  
--WITH CHECK (current_setting('request.jwt.claim.uid'::text) = creator_id);

--select * from pg_policies;
--DROP POLICY files_read on files;
--CREATE POLICY files_read on files for SELECT to PUBLIC;
--DROP POLICY file_update on files;
--DROP POLICY file_delete on files;
--CREATE POLICY file_update on files for UPDATE WITH CHECK(creator_id = current_setting('request.jwt.claim.uid'::text))
--CREATE POLICY file_delete on files for DELETE USING(creator_id = current_setting('request.jwt.claim.uid'::text))
--CREATE POLICY policy_employee_user ON tbl_Employees FOR ALL TO PUBLIC USING (pgUser = current_user);