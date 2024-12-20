CREATE OR REPLACE FUNCTION screw.donat_rang(i_user_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER COST 1
AS $function$
 DECLARE

  l_donat_luck numeric(4, 2) := (select donat_luck from screw.sc_user where user_id = i_user_id);
  l_donat_amount numeric(6, 2) := (select donat_amount from screw.sc_user where user_id = i_user_id);
  l_donat_mod numeric(6, 2) := 3 ^ l_donat_luck;

 BEGIN

  RETURN (select case when l_donat_amount > l_donat_mod and l_donat_luck between 0.1 and 2.0 then ' золотистый '
                      when l_donat_amount > l_donat_mod and l_donat_luck between 2.0 and 4.0 then ' позолоченный '
                      when l_donat_amount > l_donat_mod and l_donat_luck > 4.0 then               ' золотой '
                      when l_donat_amount < l_donat_mod and l_donat_luck > 0.0 then               ' потускневший '
                      else ' ' end::text as status
  );
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
         , coalesce(g.sizesm, 0)::numeric(6, 2)       as growe_size
         , coalesce(b.sizesm, 0)::numeric(6, 2)       as blade_size
         , coalesce(c.sizesm, 0)::numeric(6, 2)       as catch_size
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

CREATE OR REPLACE FUNCTION screw.s_user_attack(i_chat_id bigint, i_user_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_user boolean := false;
  l_check_chat boolean := false;
  l_check_isset boolean := false;

  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);
  l_user_id bigint := coalesce(i_user_id, 0::bigint);
  l_duser_id bigint := 0;

  l_blade_screw bigint := (select blade_screw from screw.sc_user as c where c.user_id = l_user_id);
  l_dblade_screw bigint := 0;
  l_screw_size numeric(6, 2) := (select sizesm from screw.sc_screw where screw_id = l_blade_screw);

 BEGIN
  l_check_user  := ((select count(1) from screw.sc_user as u where u.user_id = l_user_id) = 1);
  l_check_chat  := ((select count(1) from screw.sc_chat as c where c.chat_id = l_chat_id) = 1);

  IF l_check_user and l_check_chat THEN
    l_check_isset := ((select count(1) from screw.sc_user_chat as uc where uc.user_id = l_user_id and uc.chat_id = l_chat_id) = 1);
  END IF;

  IF l_check_isset THEN
    l_duser_id := (select u.user_id
                     from screw.sc_user as u
                     join screw.sc_screw as b on b.screw_id = u.blade_screw
                    where abs(b.sizesm - l_screw_size) <= 17.0
                      and u.user_id <> l_user_id
                      and u.catch_screw is not null
                    order by random()
                    limit 1);
   IF l_duser_id is not null THEN
     l_dblade_screw := (select growe_screw from screw.sc_user as c where c.user_id = l_duser_id);
   END IF;

    RETURN (
      select case when l_screw_size < 1.0 then 'Ну куда ж ты с голыми руками то!'
                  when l_duser_id is null then 'Нет достойных тебя соперников или у них нечего отбирать...'
                  else screw.s_screw_breack(l_chat_id, l_user_id, l_blade_screw, l_duser_id, l_dblade_screw) end::text as res
    );
  END IF;
 END
$function$
;