update screw.sc_message_pos set message_pos = 'кусает свой болт' where message_pos = 'кусаает свой болт';

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
     l_dblade_screw := (select blade_screw from screw.sc_user as c where c.user_id = l_duser_id);
   END IF;

    RETURN (
      select case when l_screw_size < 1.0 then 'Ну куда ж ты с голыми руками то!'
                  when l_duser_id is null then 'Нет достойных тебя соперников или у них нечего отбирать...'
                  else screw.s_screw_attack(l_chat_id, l_user_id, l_blade_screw, l_duser_id, l_dblade_screw) end::text as res
    );
  END IF;
 END
$function$
;