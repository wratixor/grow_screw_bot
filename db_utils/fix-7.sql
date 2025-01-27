ALTER TABLE screw.sc_screw ALTER COLUMN sizesm TYPE numeric(12,2);

DROP TYPE screw.t_status_all IF EXISTS CASCADE;
CREATE TYPE screw.t_status_all AS (
	username text,
	growe_size numeric(12,2),
	blade_size numeric(12,2),
	catch_size numeric(12,2));

DROP TYPE screw.t_status_my IF EXISTS CASCADE;
CREATE TYPE screw.t_status_my AS (
	username text,
	growe_size numeric(12,2),
	blade_size numeric(12,2),
	catch_size numeric(12,2),
	luck numeric(4,2),
	donat_luck numeric(4,2),
	donat text);

CREATE OR REPLACE FUNCTION screw.r_status_all(i_chat_id bigint)
 RETURNS SETOF screw.t_status_all
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER COST 1 ROWS 20
AS $function$
DECLARE

  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);

BEGIN
  IF l_chat_id <> 0 THEN
    RETURN QUERY
    select u.first_name::text                   as username
         , g.sizesm::numeric(12, 2)              as growe_size
         , coalesce(b.sizesm, 0)::numeric(12, 2) as blade_size
         , coalesce(c.sizesm, 0)::numeric(12, 2) as catch_size
      from screw.sc_user_chat as uc
      join screw.sc_user  as u on uc.user_id = u.user_id
      join screw.sc_screw as g on g.screw_id = u.growe_screw
 left join screw.sc_screw as b on b.screw_id = u.blade_screw
 left join screw.sc_screw as c on c.screw_id = u.catch_screw
     where uc.chat_id = l_chat_id
     order by g.sizesm desc
    FOR READ ONLY;
  END IF;
RETURN;
END
$function$
;


CREATE OR REPLACE FUNCTION screw.r_status_my(i_user_id bigint)
 RETURNS SETOF screw.t_status_my
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER COST 1 ROWS 20
AS $function$
DECLARE

  l_user_id bigint := coalesce(i_user_id, 0::bigint);

BEGIN
  IF l_user_id <> 0 THEN
    RETURN QUERY
    select u.username::text                           as username
         , coalesce(g.sizesm, 0)::numeric(12, 2)       as growe_size
         , coalesce(b.sizesm, 0)::numeric(12, 2)       as blade_size
         , coalesce(c.sizesm, 0)::numeric(12, 2)       as catch_size
         , coalesce(u.luck, 0)::numeric(4, 2)         as luck
         , coalesce(u.donat_luck, 0)::numeric(4, 2)   as donat_luck
         , ('Баланс: ' || u.donat_amount || '| Цена броска: ' || (3.0 ^ u.donat_luck)::numeric(6, 2))::text as donat
      from screw.sc_user  as u
      join screw.sc_screw as g on g.screw_id = u.growe_screw
 left join screw.sc_screw as b on b.screw_id = u.blade_screw
 left join screw.sc_screw as c on c.screw_id = u.catch_screw
     where u.user_id = l_user_id
    FOR READ ONLY;
  END IF;
RETURN;
END
$function$
;