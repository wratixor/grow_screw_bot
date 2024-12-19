update screw.sc_message_pos set message_pos = 'веселит свой болт' where message_pos = 'вселит свой болт';

ALTER TABLE screw.sc_grow_log ADD modif numeric(6, 2) not null default 0.0;

drop SEQUENCE if exists screw.pay_sq cascade;
CREATE SEQUENCE screw.pay_sq
INCREMENT 1
START 100
MINVALUE 100
MAXVALUE 9223372036854775807
CACHE 1;

drop table if exists screw.sc_pay_log cascade;
CREATE TABLE screw.sc_pay_log (
    uid bigint NOT NULL DEFAULT nextval('screw.pay_sq'::regclass),
    user_id bigint references screw.sc_user(user_id),
    pay numeric(6, 2) not null default 0.0,
    update_date timestamptz not null default now(),
	CONSTRAINT "sc_pay_log$pk" PRIMARY KEY (uid)
);

ALTER TABLE screw.sc_user ADD luck numeric(4, 2) not null default 0.0;
ALTER TABLE screw.sc_user ADD donat_luck numeric(4, 2) not null default 0.0;
ALTER TABLE screw.sc_user ADD donat_amount numeric(8, 2) not null default 0.0;


DROP FUNCTION IF EXISTS screw.i_d20();
DROP FUNCTION IF EXISTS screw.i_d20(int8);
CREATE OR REPLACE FUNCTION screw.i_d20(i_user_id bigint)
 RETURNS numeric(4, 2)
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE

  l_luck numeric(4, 2) := (select luck from screw.sc_user where user_id = i_user_id);
  l_donat_luck numeric(4, 2) := (select donat_luck from screw.sc_user where user_id = i_user_id);
  l_donat_amount numeric(8, 2) := (select donat_amount from screw.sc_user where user_id = i_user_id);
  l_donat_mod numeric(6, 2) := 3 ^ l_donat_luck;
  l_d20 numeric(4, 2) := (((random() * 19.0) + 1.0) + l_luck)::numeric;

 BEGIN
  IF l_d20 < 10.0 THEN
    update screw.sc_user set luck = luck + 1.0 where user_id = i_user_id;
  END IF;

  IF l_donat_luck > 0.0 and l_donat_amount > l_donat_mod THEN
    update screw.sc_user set donat_amount = donat_amount - l_donat_mod where user_id = i_user_id;
    insert into screw.sc_pay_log (user_id, pay) values (i_user_id, (-1.0 * l_donat_mod));
    l_d20 := l_d20 + l_donat_luck;
  END IF;

  RETURN (l_d20);
 END
$function$
;


DROP FUNCTION IF EXISTS screw.s_set_donat_luck(int8, numeric);
CREATE OR REPLACE FUNCTION screw.s_set_donat_luck(i_user_id bigint, i_luck numeric)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_user boolean := false;

  l_user_id bigint := coalesce(i_user_id, 0::bigint);
  l_luck numeric(2, 2) := (select case when i_luck between 0.0 and 5.0 then i_luck else 0.0 end);

 BEGIN
  l_check_user := ((select count(1) from screw.sc_user as u where u.user_id = l_user_id) = 1);
  IF l_check_user and l_luck > 0.0 THEN
    update screw.sc_user set donat_luck = l_luck where user_id = l_user_id;
  ELSE
    update screw.sc_user set donat_luck = 0.0 where user_id = l_user_id;
  END IF;

  RETURN (
    SELECT
      case when l_luck = 0.0 then 'Позолота отключена.'
           when not l_check_user then 'Некорректный ID'
           else 'Установлена позолота: ' || l_luck end::text as status
    FOR READ ONLY
  );
 END
$function$
;


DROP FUNCTION IF EXISTS screw.s_user_pay(int8, numeric);
CREATE OR REPLACE FUNCTION screw.s_user_pay(i_user_id bigint, i_pay numeric)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_user boolean := false;

  l_user_id bigint := coalesce(i_user_id, 0::bigint);
  l_pay numeric(6, 2) := coalesce(i_pay, 0.0);

 BEGIN
  l_check_user := ((select count(1) from screw.sc_user as u where u.user_id = l_user_id) = 1);
  IF l_check_user and l_pay > 0.0 THEN
    update screw.sc_user set donat_amount = donat_amount + l_pay where user_id = l_user_id;
    insert into screw.sc_pay_log (user_id, pay) values (l_user_id, l_pay);
  END IF;

  RETURN (
    SELECT
      case when l_pay > 0.0 then 'Зачислено: ' || l_pay
           when not l_check_user then 'Некорректный ID'
           else 'Не выполнено' end::text as status
    FOR READ ONLY
  );
 END
$function$
;


DROP TYPE IF EXISTS screw.t_status_my CASCADE;
CREATE TYPE screw.t_status_my AS (
    username text,
    growe_size numeric(6, 2),
    blade_size numeric(6, 2),
    catch_size numeric(6, 2),
    luck       numeric(2, 2),
    donat_luck numeric(2, 2),
    donat text
);


DROP FUNCTION IF EXISTS screw.r_status_my(int8);
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
         , coalesce(u.luck, 0)::numeric(2, 2)         as luck
         , coalesce(u.donat_luck, 0)::numeric(2, 2)   as donat_luck
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



DROP FUNCTION IF EXISTS screw.r_status_all();
CREATE OR REPLACE FUNCTION screw.r_status_all()
 RETURNS SETOF screw.t_status_all
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER COST 1 ROWS 40
AS $function$
DECLARE


BEGIN
    RETURN QUERY
    select u.first_name::text                   as username
         , g.sizesm::numeric(6, 2)              as growe_size
         , coalesce(b.sizesm, 0)::numeric(6, 2) as blade_size
         , coalesce(c.sizesm, 0)::numeric(6, 2) as catch_size
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

DROP FUNCTION IF EXISTS screw.donat_rang(int8);
CREATE OR REPLACE FUNCTION screw.donat_rang(i_user_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE

  l_donat_luck numeric(4, 2) := (select donat_luck from screw.sc_user where user_id = i_user_id);
  l_donat_amount numeric(8, 2) := (select donat_amount from screw.sc_user where user_id = i_user_id);
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
  l_debuf_pre numeric := (select case when (now() - l_last_upd) < (interval '3 hour') then -100.0
                                      when (l_last_upd > (l_create_date + interval '10 second')) then ((extract(EPOCH from (now() -  l_last_upd)) / 3600.0) - 10.0)
                                      else 10.0 end);
  l_debuf numeric := (select case when l_debuf_pre > 10 then 10 else l_debuf_pre end);
  l_d20 numeric(4, 2) := screw.i_d20(i_user_id);

  l_modif numeric := ((((l_debuf + ((l_d20 ^ l_pow) * l_mul)) / l_di1) - l_sub) / l_di2);
  l_curr_size numeric(6, 2) := (select sizesm from screw.sc_screw where screw_id = i_screw_id);
  l_half_size numeric(6, 2) := l_curr_size / 2.0;
  l_double_size numeric(6, 2) := l_curr_size * 2.0;

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


DROP FUNCTION IF EXISTS screw.s_user_tig(int8);
CREATE OR REPLACE FUNCTION screw.s_user_tig(i_user_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
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
  l_blade_size numeric(6, 2) := 0.0;
 BEGIN
  l_check_user  := ((select count(1) from screw.sc_user as u where u.user_id = l_user_id) = 1);
  l_check_chat  := ((select count(1) from screw.sc_chat as c where c.chat_id = l_chat_id) = 1);

  IF l_check_user and l_check_chat THEN
    l_check_isset := ((select count(1) from screw.sc_user_chat as uc where uc.user_id = l_user_id and uc.chat_id = l_chat_id) = 1);
  END IF;

  IF l_check_isset THEN
    l_drop_screw := (select drop_screw from screw.sc_chat as c where c.chat_id = l_chat_id);
    l_blade_size := (select coalesce(b.sizesm, 0.0)::numeric(6, 2) from screw.sc_user as u left join screw.sc_screw as b on b.screw_id = u.blade_screw where u.user_id = l_user_id);
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

DROP FUNCTION IF EXISTS screw.s_screw_braeck(int8, int8, int8, int8, int8);
DROP FUNCTION IF EXISTS screw.s_screw_breack(int8, int8, int8, int8, int8);
CREATE OR REPLACE FUNCTION screw.s_screw_breack(i_chat_id bigint, i_user_id bigint, i_screw_id bigint, i_defuser_id bigint, i_defscrew_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE

  l_d20       numeric(4, 2) := screw.i_d20(i_defuser_id);
  l_d20_def   numeric(4, 2) := screw.i_d20(i_user_id);
  l_size      numeric(6, 2) := coalesce((select sizesm from screw.sc_screw where screw_id = i_screw_id), 0.0);
  l_size_def  numeric(6, 2) := coalesce((select sizesm from screw.sc_screw where screw_id = i_defscrew_id), 0.0);

  l_half_size numeric(6, 2) := 0.0;

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


DROP FUNCTION IF EXISTS screw.s_user_breack(int8, int8);
CREATE OR REPLACE FUNCTION screw.s_user_breack(i_chat_id bigint, i_user_id bigint)
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
  l_duser_id bigint := 0;

  l_growe_screw bigint := (select growe_screw from screw.sc_user as c where c.user_id = l_user_id);
  l_dgrowe_screw bigint := 0;
  l_screw_size numeric(6, 2) := (select sizesm from screw.sc_screw where screw_id = l_growe_screw);

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


DROP FUNCTION IF EXISTS screw.s_screw_attack(int8, int8, int8, int8, int8);
CREATE OR REPLACE FUNCTION screw.s_screw_attack(i_chat_id bigint, i_user_id bigint, i_screw_id bigint, i_defuser_id bigint, i_defscrew_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE

  l_d20       numeric(4, 2) := screw.i_d20(i_user_id);
  l_d20_def   numeric(4, 2) := screw.i_d20(i_defuser_id);
  l_size      numeric(6, 2) := coalesce((select sizesm from screw.sc_screw where screw_id = i_screw_id), 0.0);
  l_size_def  numeric(6, 2) := coalesce((select sizesm from screw.sc_screw where screw_id = i_defscrew_id), 0.0);

  l_half_size numeric(6, 2) := 0.0;

  l_win boolean := ((l_d20_def + l_size_def) < (l_d20 + l_size));

  l_catch_screw bigint := (select catch_screw from screw.sc_user as c where c.user_id = i_defuser_id);
  l_screw_size numeric(6, 2) := (select sizesm from screw.sc_screw where screw_id = l_catch_screw);

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


DROP FUNCTION IF EXISTS screw.s_user_attack(int8, int8);
CREATE OR REPLACE FUNCTION screw.s_user_attack(i_chat_id bigint, i_user_id bigint)
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
                    where abs(g.sizesm - l_screw_size) <= 17.0
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



DROP FUNCTION IF EXISTS screw.s_screw_cut(int8, int8, int8, int8, int8);
CREATE OR REPLACE FUNCTION screw.s_screw_cut(i_chat_id bigint, i_user_id bigint, i_screw_id bigint, i_defuser_id bigint, i_defscrew_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE

  l_d20       numeric(4, 2) := screw.i_d20(i_user_id);
  l_d20_def   numeric(4, 2) := screw.i_d20(i_defuser_id);
  l_size      numeric(6, 2) := coalesce((select sizesm from screw.sc_screw where screw_id = i_screw_id), 0.0);
  l_size_def  numeric(6, 2) := coalesce((select sizesm from screw.sc_screw where screw_id = i_defscrew_id), 0.0);

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

DROP FUNCTION IF EXISTS screw.s_user_cut(int8, int8);
CREATE OR REPLACE FUNCTION screw.s_user_cut(i_chat_id bigint, i_user_id bigint)
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

 BEGIN
  l_check_user  := ((select count(1) from screw.sc_user as u where u.user_id = l_user_id) = 1);
  l_check_chat  := ((select count(1) from screw.sc_chat as c where c.chat_id = l_chat_id) = 1);

  IF l_check_user and l_check_chat THEN
    l_check_isset := ((select count(1) from screw.sc_user_chat as uc where uc.user_id = l_user_id and uc.chat_id = l_chat_id) = 1);
  END IF;

  IF l_check_isset THEN
    RETURN (
      SELECT case when ds.sizesm is null then 'Тут все уже попрятали свои болты!'
                  else screw.s_screw_cut(uc.chat_id, u.user_id, u.blade_screw, du.user_id, du.growe_screw) end::text as res
        from screw.sc_user_chat as uc
        join screw.sc_user as u on u.user_id = uc.user_id and u.user_id = l_user_id
   left join screw.sc_grow_log as sg on sg.chat_id = uc.chat_id and (extract(EPOCH from (now() - sg.update_date)) < 66) and u.user_id <> sg.user_id
   left join screw.sc_user as du on du.user_id = sg.user_id
   left join screw.sc_screw as ds on ds.screw_id = du.growe_screw and ds.sizesm > 0
       where uc.chat_id = l_chat_id
       order by sg.update_date desc
       limit 1
      FOR READ ONLY
    );
  END IF;
 END
$function$
;

update screw.sc_screw set sizesm = sizesm + 2 + (random() * 2) where sizesm < 2.0;