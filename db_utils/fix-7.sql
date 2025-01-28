ALTER TABLE screw.sc_screw ALTER COLUMN sizesm TYPE numeric(12,2);

DROP TYPE IF EXISTS screw.t_status_all CASCADE;
CREATE TYPE screw.t_status_all AS (
	username text,
	growe_size numeric(12,2),
	blade_size numeric(12,2),
	catch_size numeric(12,2));

DROP TYPE IF EXISTS screw.t_status_my CASCADE;
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

CREATE OR REPLACE FUNCTION screw.r_status_all()
 RETURNS SETOF screw.t_status_all
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER COST 1 ROWS 40
AS $function$
DECLARE


BEGIN
    RETURN QUERY
    select u.first_name::text                   as username
         , g.sizesm::numeric(12, 2)              as growe_size
         , coalesce(b.sizesm, 0)::numeric(12, 2) as blade_size
         , coalesce(c.sizesm, 0)::numeric(12, 2) as catch_size
      from screw.sc_user  as u
      join screw.sc_screw as g on g.screw_id = u.growe_screw
 left join screw.sc_screw as b on b.screw_id = u.blade_screw
 left join screw.sc_screw as c on c.screw_id = u.catch_screw
     order by g.sizesm desc
    FOR READ ONLY;
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

CREATE OR REPLACE FUNCTION screw.s_screw_grow(i_chat_id bigint, i_user_id bigint, i_screw_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER COST 1
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

  l_time_pice numeric := 1200.0;


  l_last_upd timestamptz := (select update_date from screw.sc_screw where screw_id = i_screw_id);
  l_create_date timestamptz := (select create_date from screw.sc_screw where screw_id = i_screw_id);
  l_debuf_pre numeric := (select case when (l_last_upd > (l_create_date + interval '10 second')) then ((extract(EPOCH from (now() -  l_last_upd)) / l_time_pice) - 10.0)
                                      else 10.0 end);
  l_debuf numeric := (select case when l_debuf_pre > 10 then 10 else l_debuf_pre end);
  l_d20 numeric(4, 2) := screw.i_d20(i_user_id);

  l_modif numeric := ((((l_debuf + ((l_d20 ^ l_pow) * l_mul)) / l_di1) - l_sub) / l_di2);
  l_curr_size numeric(12, 2) := (select sizesm from screw.sc_screw where screw_id = i_screw_id);
  l_half_size numeric(12, 2) := l_curr_size / 2.0;
  l_double_size numeric(12, 2) := l_curr_size * 2.0;

 BEGIN
  IF l_curr_size < 1 and l_modif < 0.0 THEN
    l_modif := 1.0 + random();
  END IF;
  IF l_curr_size < l_in1 and l_modif > l_max THEN
    l_modif := l_in2 + (random() * l_in1);
  END IF;

  IF l_modif < l_min THEN
    update screw.sc_chat set drop_screw = i_screw_id where chat_id = i_chat_id;
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
    l_curr_size := l_double_size;
  END IF;
  IF l_modif between l_div and l_max THEN
    l_curr_size := l_curr_size + l_modif;
    IF l_curr_size < 0.0 THEN l_curr_size := 0.0; END IF;
    update screw.sc_screw set sizesm = l_curr_size, update_date = now() where screw_id = i_screw_id;
  END IF;

  insert into screw.sc_grow_log (chat_id, user_id, screw_id, modif) values (i_chat_id, i_user_id, i_screw_id, l_modif);
  RETURN (
    SELECT (case when l_modif < l_min then ', и его(её)' || screw.donat_rang(i_user_id) || 'болт отваливается!!!'
                 when l_modif < l_div then ', и его(её)' || screw.donat_rang(i_user_id) || 'болт ломается пополам! Обломок можно забрать!'
                 when l_modif < l_su2 then ', и его(её)' || screw.donat_rang(i_user_id) || 'болт значительно уменьшается.'
                 when l_modif < l_su1 then ', и его(её)' || screw.donat_rang(i_user_id) || 'болт уменьшается в размерах'
                 when l_modif < 00.00 then ', и его(её)' || screw.donat_rang(i_user_id) || 'болт слегка уменьшается'
                 when l_modif > l_max then ', и его(её)' || screw.donat_rang(i_user_id) || 'болт увеличивается вдвое!!!'
                 when l_modif > l_in2 then ', и его(её)' || screw.donat_rang(i_user_id) || 'болт значительно увеличивается!'
                 when l_modif > l_in1 then ', и его(её)' || screw.donat_rang(i_user_id) || 'болт увеличивается в размерах'
                 when l_modif > 00.00 then ', и его(её)' || screw.donat_rang(i_user_id) || 'болт слегка увеличивается...'
                 else ', и его(её)' || screw.donat_rang(i_user_id) || 'болт остаётся неизменным.' end || ' Размер болта: ' || l_curr_size || 'см.' )::text as res
    );
 END
$function$
;

CREATE OR REPLACE FUNCTION screw.s_screw_cut(i_chat_id bigint, i_user_id bigint, i_screw_id bigint, i_defuser_id bigint, i_defscrew_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER COST 1
AS $function$
 DECLARE

  l_d20       numeric(4, 2) := screw.i_d20(i_user_id);
  l_d20_def   numeric(4, 2) := screw.i_d20(i_defuser_id);
  l_size      numeric(12, 2) := coalesce((select sizesm from screw.sc_screw where screw_id = i_screw_id), 0.0);
  l_size_def  numeric(12, 2) := coalesce((select sizesm from screw.sc_screw where screw_id = i_defscrew_id), 0.0);

  l_attack bool := ((l_d20_def + l_size_def) < (l_d20 + l_size));

 BEGIN
  IF l_attack THEN
    update screw.sc_chat  set drop_screw  = i_defscrew_id       where chat_id  = i_chat_id;
    update screw.sc_user  set growe_screw = screw.i_new_screw() where user_id  = i_defuser_id;
    update screw.sc_screw set update_date = now()               where screw_id = i_defscrew_id;
  END IF;

  RETURN (
    SELECT (u.username || ' засматривается на болт ' || ud.username || ' и решает его срезать! '
            || l_d20 || ' + ' || l_size || 'см. против ' || l_d20_def ||  ' + ' || l_size_def || 'см.! '
            || (case when l_attack then u.username || ' успешно срезает болт ' || ud.username || '! Быстрее хватай его в карман!'
                                   else ud.username || ' успешно защищается своим болтом!' end))::text as res
      from screw.sc_chat as c
      join screw.sc_user as u  on  u.user_id = i_user_id
      join screw.sc_user as ud on ud.user_id = i_defuser_id
     where c.chat_id = i_chat_id
     limit 1
    );
 END
$function$
;

CREATE OR REPLACE FUNCTION screw.s_screw_breack(i_chat_id bigint, i_user_id bigint, i_screw_id bigint, i_defuser_id bigint, i_defscrew_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER COST 1
AS $function$
 DECLARE

  l_d20       numeric(4, 2) := screw.i_d20(i_defuser_id);
  l_d20_def   numeric(4, 2) := screw.i_d20(i_user_id);
  l_size      numeric(12, 2) := (select sizesm from screw.sc_screw where screw_id = i_screw_id);
  l_size_def  numeric(12, 2) := (select sizesm from screw.sc_screw where screw_id = i_defscrew_id);

  l_half_size numeric(12, 2) := 0.0;

  l_looser       bigint     := 0;
  l_looser_screw bigint     := 0;

 BEGIN
  IF (l_d20_def + l_size_def) > (l_d20 + l_size) THEN
    l_looser := i_defuser_id;
    l_looser_screw := i_defscrew_id;
  ELSE
    l_looser := i_user_id;
    l_looser_screw := i_screw_id;
  END IF;

  l_half_size := (select sizesm / 2 from screw.sc_screw where screw_id = l_looser_screw);
  update screw.sc_chat set drop_screw = screw.i_new_screw(l_half_size) where chat_id = i_chat_id;
  update screw.sc_screw set sizesm = l_half_size, update_date = now() where screw_id = l_looser_screw;

  RETURN (
    SELECT 'На арене "' || c.chat_title || '" ' || u.username || ' решает смахнуться болтами с ' || ud.username
            || '! ' || l_d20 || ' + ' || l_size || 'см. против ' || l_d20_def ||  ' + ' || l_size_def
            || 'см.! Болт ' || ul.username || ' разлетается пополам! Обломок ' || l_half_size || 'см. можно забрать!'
      from screw.sc_chat as c
      join screw.sc_user as u  on  u.user_id = i_user_id
      join screw.sc_user as ud on ud.user_id = i_defuser_id
      join screw.sc_user as ul on ul.user_id = l_looser
     where c.chat_id = i_chat_id
     limit 1
    );
 END
$function$
;

CREATE OR REPLACE FUNCTION screw.s_screw_attack(i_chat_id bigint, i_user_id bigint, i_screw_id bigint, i_defuser_id bigint, i_defscrew_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER COST 1
AS $function$
 DECLARE

  l_d20       numeric(4, 2) := screw.i_d20(i_user_id);
  l_d20_def   numeric(4, 2) := screw.i_d20(i_defuser_id);
  l_size      numeric(12, 2) := (select sizesm from screw.sc_screw where screw_id = i_screw_id);
  l_size_def  numeric(12, 2) := (select sizesm from screw.sc_screw where screw_id = i_defscrew_id);

  l_half_size numeric(12, 2) := 0.0;

  l_win boolean := ((l_d20_def + l_size_def) < (l_d20 + l_size));

  l_catch_screw bigint := (select catch_screw from screw.sc_user as c where c.user_id = i_defuser_id);
  l_screw_size numeric(12, 2) := (select sizesm from screw.sc_screw where screw_id = l_catch_screw);

 BEGIN
  IF l_win THEN
    update screw.sc_user set catch_screw = l_catch_screw where user_id = i_user_id;
    update screw.sc_user set catch_screw = null          where user_id = i_defuser_id;
  END IF;


  RETURN (
    SELECT 'На арене "' || c.chat_title || '" ' || u.username || ' бессовестно нападает на ' || ud.username
            || '! ' || l_d20 || ' + ' || l_size || 'см. против ' || l_d20_def ||  ' + ' || l_size_def
            || 'см.! ' || u.username || (case when l_win then ' успешно отбирает ' else ' не удаётся отобрать ' end)
            || 'у ' || ud.username || ' обломок ' || l_screw_size || 'см.!'
      from screw.sc_chat as c
      join screw.sc_user as u  on  u.user_id = i_user_id
      join screw.sc_user as ud on ud.user_id = i_defuser_id
     where c.chat_id = i_chat_id
     limit 1
    );
 END
$function$
;

CREATE OR REPLACE FUNCTION screw.i_new_screw(i_size numeric)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_screw_id bigint := 0;
  l_size numeric(12, 2) := i_size;

 BEGIN

  l_screw_id := nextval('screw.screw_sq'::regclass);
  insert into screw.sc_screw(screw_id, sizesm) values (l_screw_id, l_size);

  RETURN (
    select l_screw_id
  );
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
  l_screw_size numeric(12, 2) := (select sizesm from screw.sc_screw where screw_id = l_blade_screw);

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
                  else screw.s_screw_attack(l_chat_id, l_user_id, l_blade_screw, l_duser_id, l_dblade_screw) end::text as res
    );
  END IF;
 END
$function$
;

CREATE OR REPLACE FUNCTION screw.s_user_breack(i_chat_id bigint, i_user_id bigint)
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

  l_growe_screw bigint := (select growe_screw from screw.sc_user as c where c.user_id = l_user_id);
  l_dgrowe_screw bigint := 0;
  l_screw_size numeric(12, 2) := (select sizesm from screw.sc_screw where screw_id = l_growe_screw);

 BEGIN
  l_check_user  := ((select count(1) from screw.sc_user as u where u.user_id = l_user_id) = 1);
  l_check_chat  := ((select count(1) from screw.sc_chat as c where c.chat_id = l_chat_id) = 1);

  IF l_check_user and l_check_chat THEN
    l_check_isset := ((select count(1) from screw.sc_user_chat as uc where uc.user_id = l_user_id and uc.chat_id = l_chat_id) = 1);
  END IF;

  IF l_check_isset THEN
    l_duser_id := (select u.user_id
                     from screw.sc_user as u
                     join screw.sc_screw as g on g.screw_id = u.growe_screw
                    where abs(g.sizesm - l_screw_size) <= 17.0
                      and u.user_id <> l_user_id
                      and g.sizesm > 2.0
                    order by random()
                    limit 1);
   IF l_duser_id is not null THEN
     l_dgrowe_screw := (select growe_screw from screw.sc_user as c where c.user_id = l_duser_id);
   END IF;

    RETURN (
      select case when l_screw_size < 2.0 then 'У тебя слишком короткий болт, отрасти хотябы 2.00см.!'
                  when l_duser_id is null then 'Нет достойных тебя соперников...'
                  else screw.s_screw_breack(l_chat_id, l_user_id, l_growe_screw, l_duser_id, l_dgrowe_screw) end::text as res
    );
  END IF;
 END
$function$
;

CREATE OR REPLACE FUNCTION screw.s_user_catch(i_chat_id bigint, i_user_id bigint)
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

  l_drop_screw bigint := null;
  l_screw_size numeric(12, 2) := 0.0;
  l_blade_size numeric(12, 2) := 0.0;
 BEGIN
  l_check_user  := ((select count(1) from screw.sc_user as u where u.user_id = l_user_id) = 1);
  l_check_chat  := ((select count(1) from screw.sc_chat as c where c.chat_id = l_chat_id) = 1);

  IF l_check_user and l_check_chat THEN
    l_check_isset := ((select count(1) from screw.sc_user_chat as uc where uc.user_id = l_user_id and uc.chat_id = l_chat_id) = 1);
  END IF;

  IF l_check_isset THEN
    l_drop_screw := (select drop_screw from screw.sc_chat as c where c.chat_id = l_chat_id);
    l_blade_size := (select coalesce(b.sizesm, 0.0)::numeric(12, 2) from screw.sc_user as u left join screw.sc_screw as b on b.screw_id = u.blade_screw where u.user_id = l_user_id);
    IF l_drop_screw is not null THEN
      update screw.sc_user set catch_screw = l_drop_screw where user_id = l_user_id;
      update screw.sc_chat set drop_screw = null where chat_id = l_chat_id;
      l_screw_size := (select sizesm from screw.sc_screw where screw_id = l_drop_screw);
    END IF;

    RETURN (
      SELECT (case when l_drop_screw is not null then u.username || ' забирает болт ' || l_screw_size || 'см. себе в карман.'
                   else u.username || ', тут уже нечего подбирать.' end) || ' Размер режека: ' || l_blade_size || 'см.'::text as res
        from screw.sc_user as u
       where u.user_id = l_user_id
      FOR READ ONLY
    );
  END IF;
 END
$function$
;


CREATE OR REPLACE FUNCTION screw.s_user_sharpen(i_user_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_user boolean := false;

  l_user_id bigint := coalesce(i_user_id, 0::bigint);
  l_catch_screw bigint := null;
  l_screw_size numeric(12, 2) := 0.0;


 BEGIN
  l_check_user := ((select count(1) from screw.sc_user as u where u.user_id = l_user_id) = 1);

  IF l_check_user THEN
    l_catch_screw := (select catch_screw from screw.sc_user as c where c.user_id = l_user_id);
    IF l_catch_screw is not null THEN
      update screw.sc_user set blade_screw = l_catch_screw, catch_screw = null where user_id = l_user_id;
      l_screw_size := (select sizesm from screw.sc_screw where screw_id = l_catch_screw);
    END IF;
    RETURN (
      SELECT case when l_catch_screw is not null then u.username || screw.s_gen_mid() || ' из кармана и превращает его в режек ' || l_screw_size || 'см.!'
                  else u.username || ', тебе нечего точить!' end::text as res
        from screw.sc_user as u
       where u.user_id = l_user_id
      FOR READ ONLY
    );
  END IF;
 END
$function$
;


CREATE OR REPLACE FUNCTION screw.s_user_tig(i_user_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_user boolean := false;

  l_user_id bigint := coalesce(i_user_id, 0::bigint);
  l_catch_screw bigint := null;
  l_growe_screw bigint := (select growe_screw from screw.sc_user as c where c.user_id = l_user_id);
  l_screw_size numeric(6, 2) := 0.0;
  l_screw_modif numeric(6, 2) := 0.0;


 BEGIN
  l_check_user := ((select count(1) from screw.sc_user as u where u.user_id = l_user_id) = 1);

  IF l_check_user THEN
    l_catch_screw := (select catch_screw from screw.sc_user as c where c.user_id = l_user_id);

    IF l_catch_screw is not null THEN
      l_screw_size := (select sizesm from screw.sc_screw where screw_id = l_catch_screw);
      l_screw_modif := (screw.i_d20(i_user_id) / 18.0) * l_screw_size;
      update screw.sc_user set catch_screw = null where user_id = l_user_id;
      update screw.sc_screw set sizesm = sizesm + l_screw_modif where screw_id = l_growe_screw;
      l_screw_size := (select sizesm from screw.sc_screw where screw_id = l_growe_screw);
    END IF;
    RETURN (
      SELECT case when l_catch_screw is not null then u.username || screw.s_gen_mid() || ' из кармана и приваривает ' || l_screw_modif
                                                      || 'см. к своему болту! Теперь его(её)' || screw.donat_rang(i_user_id) || 'болт ' || l_screw_size || 'см.!'
                  else u.username || ', тебе нечего приваривать!' end::text as res
        from screw.sc_user as u
       where u.user_id = l_user_id
      FOR READ ONLY
    );
  END IF;
 END
$function$
;