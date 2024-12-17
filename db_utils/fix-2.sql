DROP FUNCTION IF EXISTS screw.s_user_catch(int8, int8);
CREATE OR REPLACE FUNCTION screw.s_user_catch(i_chat_id bigint, i_user_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_user boolean := false;
  l_check_chat boolean := false;
  l_check_isset boolean := false;

  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);
  l_user_id bigint := coalesce(i_user_id, 0::bigint);

  l_drop_screw bigint := null;
  l_screw_size numeric(6, 2) := 0.0;
 BEGIN
  l_check_user  := ((select count(1) from screw.sc_user as u where u.user_id = l_user_id) = 1);
  l_check_chat  := ((select count(1) from screw.sc_chat as c where c.chat_id = l_chat_id) = 1);

  IF l_check_user and l_check_chat THEN
    l_check_isset := ((select count(1) from screw.sc_user_chat as uc where uc.user_id = l_user_id and uc.chat_id = l_chat_id) = 1);
  END IF;

  IF l_check_isset THEN
    l_drop_screw := (select drop_screw from screw.sc_chat as c where c.chat_id = l_chat_id);
    IF l_drop_screw is not null THEN
      update screw.sc_user set catch_screw = l_drop_screw where user_id = l_user_id;
      update screw.sc_chat set drop_screw = null where chat_id = l_chat_id;
      l_screw_size := (select sizesm from screw.sc_screw where screw_id = l_drop_screw);
    END IF;

    RETURN (
      SELECT case when l_drop_screw is not null then u.username || ' забирает болт ' || l_screw_size || 'см. себе в карман.'
                  else u.username || ' не успевает забрать болт.' end::text as res
        from screw.sc_user as u
       where u.user_id = l_user_id
      FOR READ ONLY
    );
  END IF;
 END
$function$
;

DROP FUNCTION IF EXISTS screw.s_screw_grow(int8, int8, int8);
CREATE OR REPLACE FUNCTION screw.s_screw_grow(i_chat_id bigint, i_user_id bigint, i_screw_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_pow numeric(4, 2) :=   1.08;
  l_mul numeric(4, 2) :=   6.80;
  l_di1 numeric(4, 2) :=   2.00;
  l_sub numeric(4, 2) :=  42.00;
  l_di2 numeric(4, 2) :=   2.00;

  l_min numeric(4, 2) := -16.66;
  l_div numeric(4, 2) := -12.70;
  l_su2 numeric(4, 2) := -10.00;
  l_su1 numeric(4, 2) :=  -5.00;
  l_in1 numeric(4, 2) :=   5.00;
  l_in2 numeric(4, 2) :=  10.00;
  l_max numeric(4, 2) :=  19.70;


  l_last_upd timestamptz := (select update_date from screw.sc_screw where screw_id = i_screw_id);
  l_create_date timestamptz := (select create_date from screw.sc_screw where screw_id = i_screw_id);
  l_debuf_pre numeric(4, 2) := (select case when (now() - l_last_upd) < (interval '3 hour') then -100.0
                                            when (l_last_upd > (l_create_date + interval '10 second')) then ((extract(EPOCH from (now() -  l_last_upd)) / 3600.0) - 10.0)
                                            else 10.0 end);
  l_debuf numeric(4, 2) := (select case when l_debuf_pre > 10 then 10 else l_debuf_pre end);
  l_d20 numeric(4, 2) := screw.i_d20();

  l_modif numeric(4, 2) := ((((l_debuf + ((l_d20 ^ l_pow) * l_mul)) / l_di1) - l_sub) / l_di2);
  l_curr_size numeric(6, 2) := (select sizesm from screw.sc_screw where screw_id = i_screw_id);
  l_half_size numeric(6, 2) := l_curr_size / 2.0;
  l_double_size numeric(6, 2) := l_curr_size / 2.0;

 BEGIN
  IF l_modif < l_min THEN
    update screw.sc_chat set drop_screw = i_screw_id, update_date = now() where chat_id = i_chat_id;
    update screw.sc_user set growe_screw = screw.i_new_screw() where user_id = i_user_id;
    update screw.sc_screw set update_date = now() where screw_id = i_screw_id;
    l_curr_size := 0.0;
  END IF;
  IF l_modif between l_min and l_div THEN
    update screw.sc_chat set drop_screw = screw.i_new_screw(l_half_size) where chat_id = i_chat_id;
    update screw.sc_screw set sizesm = l_half_size, update_date = now() where screw_id = i_screw_id;
    l_curr_size := l_half_size;
  END IF;
  IF l_modif > l_max THEN
    update screw.sc_screw set sizesm = l_double_size, update_date = now() where screw_id = i_screw_id;
    l_half_size := l_double_size;
  END IF;
  IF l_modif between l_div and l_max THEN
    l_curr_size := l_curr_size + l_modif;
    IF l_curr_size < 0.0 THEN l_curr_size := 0.0; END IF;
    update screw.sc_screw set sizesm = l_curr_size, update_date = now() where screw_id = i_screw_id;
  END IF;

  insert into screw.sc_grow_log (chat_id, user_id, screw_id) values (i_chat_id, i_user_id, i_screw_id);
  RETURN (
    SELECT (case when l_modif < l_min then ', и тот отваливается!!!'
                 when l_modif < l_div then ', и тот ломается пополам! Обломок можно забрать!'
                 when l_modif < l_su2 then ', и тот значительно уменьшается.'
                 when l_modif < l_su1 then ', и тот уменьшается в размерах'
                 when l_modif < 00.00 then ', и тот слегка уменьшается'
                 when l_modif > l_max then ', и тот увеличивается вдвое!!!'
                 when l_modif > l_in2 then ', и тот значительно увеличивается!'
                 when l_modif > l_in1 then ', и тот увеличивается в размерах'
                 when l_modif > 00.00 then ', и тот слегка увеличивается...'
                 else 'остаётся неизменным.' end || ' Размер болта: ' || l_curr_size || 'см.' )::text as res
    );
 END
$function$
;
