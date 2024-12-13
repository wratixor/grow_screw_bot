DROP SCHEMA IF EXISTS screw CASCADE;
CREATE SCHEMA screw AUTHORIZATION rmaster;

drop SEQUENCE if exists screw.screw_sq cascade;
CREATE SEQUENCE screw.screw_sq
INCREMENT 1
START 100
MINVALUE 100
MAXVALUE 9223372036854775807
CACHE 1;

drop table if exists screw.sc_screw cascade;
CREATE TABLE screw.sc_screw (
    screw_id bigint NOT NULL DEFAULT nextval('screw.screw_sq'::regclass),
    sizesm numeric(6, 2) not null default 0.0,
    create_date timestamptz not null default now(),
    update_date timestamptz not null default now(),
	CONSTRAINT "sc_screw$pk" PRIMARY KEY (screw_id)
);

drop table if exists screw.sc_user cascade;
CREATE TABLE screw.sc_user (
    user_id bigint NOT NULL,
    username varchar(64) null,
    growe_screw bigint references screw.sc_screw(screw_id),
    blade_screw bigint references screw.sc_screw(screw_id),
    catch_screw bigint references screw.sc_screw(screw_id),
	CONSTRAINT "sc_user$pk" PRIMARY KEY (user_id)
);

drop table if exists screw.sc_chat cascade;
CREATE TABLE screw.sc_chat (
    chat_id bigint NOT NULL,
    chat_type varchar(64) not null,
    chat_title varchar(64) null,
    drop_screw bigint references screw.sc_screw(screw_id) default null,
	CONSTRAINT "sc_chat$pk" PRIMARY KEY (chat_id)
);

drop table if exists screw.sc_user_chat cascade;
CREATE TABLE screw.sc_user_chat (
    user_id bigint references screw.sc_user(user_id),
    chat_id bigint references screw.sc_chat(chat_id),
	CONSTRAINT "sc_user_chat$pk" PRIMARY KEY (chat_id, user_id)
);

drop SEQUENCE if exists screw.grow_sq cascade;
CREATE SEQUENCE screw.grow_sq
INCREMENT 1
START 100
MINVALUE 100
MAXVALUE 9223372036854775807
CACHE 1;

drop table if exists screw.sc_grow_log cascade;
CREATE TABLE screw.sc_grow_log (
    uid bigint NOT NULL DEFAULT nextval('screw.grow_sq'::regclass),
    chat_id bigint references screw.sc_chat(chat_id),
    user_id bigint references screw.sc_user(user_id),
    screw_id bigint references screw.sc_screw(screw_id),
    update_date timestamptz not null default now(),
	CONSTRAINT "sc_grow_log$pk" PRIMARY KEY (uid)
);


drop SEQUENCE if exists screw.message_pre_sq cascade;
CREATE SEQUENCE screw.message_pre_sq
INCREMENT 1
START 100
MINVALUE 100
MAXVALUE 9223372036854775807
CACHE 1;

drop table if exists screw.sc_message_pre cascade;
CREATE TABLE screw.sc_message_pre (
    uid bigint NOT NULL DEFAULT nextval('screw.message_pre_sq'::regclass),
    message_pre varchar(32) not null,
	CONSTRAINT "sc_message_pre$pk" PRIMARY KEY (uid)
);


drop SEQUENCE if exists screw.message_pos_sq cascade;
CREATE SEQUENCE screw.message_pos_sq
INCREMENT 1
START 100
MINVALUE 100
MAXVALUE 9223372036854775807
CACHE 1;

drop table if exists screw.sc_message_pos cascade;
CREATE TABLE screw.sc_message_pos (
    uid bigint NOT NULL DEFAULT nextval('screw.message_pos_sq'::regclass),
    message_pos varchar(64) not null,
	CONSTRAINT "sc_message_pos$pk" PRIMARY KEY (uid)
);

DROP FUNCTION IF EXISTS screw.i_new_screw();
CREATE OR REPLACE FUNCTION screw.i_new_screw()
 RETURNS bigint
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_screw_id bigint := 0;

 BEGIN

  l_screw_id := nextval('screw.screw_sq'::regclass);
  insert into screw.sc_screw(screw_id) values (l_screw_id);

  RETURN (
    select l_screw_id
  );
 END
$function$
;

DROP FUNCTION IF EXISTS screw.i_new_screw(numeric);
CREATE OR REPLACE FUNCTION screw.i_new_screw(i_size numeric)
 RETURNS bigint
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_screw_id bigint := 0;
  l_size numeric(6, 2) := i_size;

 BEGIN

  l_screw_id := nextval('screw.screw_sq'::regclass);
  insert into screw.sc_screw(screw_id, sizesm) values (l_screw_id, l_size);

  RETURN (
    select l_screw_id
  );
 END
$function$
;

DROP FUNCTION IF EXISTS screw.s_aou_user(int8, text);
CREATE OR REPLACE FUNCTION screw.s_aou_user(i_user_id bigint, i_username text)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_user boolean := false;
  l_add_user boolean := false;
  l_update_user boolean := false;
  l_check boolean := false;

  l_user_id bigint := coalesce(i_user_id, 0::bigint);
  l_username text := coalesce(i_username, '');

 BEGIN
  l_check_user := ((select count(1) from screw.sc_user as u where u.user_id = l_user_id) = 1);
  IF not l_check_user THEN
    insert into screw.sc_user (user_id, username, growe_screw)
                       values (l_user_id, l_username, screw.i_new_screw());
    l_add_user := true;
  ELSE
    l_check := ((select username from screw.sc_user as u where u.user_id = l_user_id) = l_username);
    IF not l_check THEN
      update screw.sc_user set username = l_username where user_id = l_user_id;
      l_update_user := true;
    END IF;
  END IF;

  RETURN (
    SELECT
      case when l_update_user then 'Успешно обновлено'
           when l_add_user then 'Пользователь добавлен'
           when l_check_user and l_check then 'Обновление не требуется'
           else 'Не выполнено' end::text as status
    FOR READ ONLY
  );
 END
$function$
;


DROP FUNCTION IF EXISTS screw.s_aou_chat(int8, text, text);
CREATE OR REPLACE FUNCTION screw.s_aou_chat(i_chat_id bigint, i_chat_type text, i_chat_title text)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_chat boolean := false;
  l_add_chat boolean := false;
  l_update_chat boolean := false;
  l_check_hash boolean := false;

  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);
  l_chat_type text := coalesce(i_chat_type, '');
  l_chat_title text := coalesce(i_chat_title, '');

  l_hash text := l_chat_type||l_chat_title;

 BEGIN
  l_check_chat := ((select count(1) from screw.sc_chat as c where c.chat_id = l_chat_id) = 1);
  IF not l_check_chat THEN
    insert into screw.sc_chat (chat_id, chat_type, chat_title)
                       values (l_chat_id, l_chat_type, l_chat_title);
    l_add_chat := true;
  ELSE
    l_check_hash := ((select chat_type||chat_title as hash from screw.sc_chat as c where c.chat_id = l_chat_id) = l_hash);
    IF not l_check_hash THEN
      update screw.sc_chat set chat_type = l_chat_type, chat_title = l_chat_title, update_date = now() where chat_id = l_chat_id;
      l_update_chat := true;
    END IF;
  END IF;

  RETURN (
    SELECT
      case when l_update_chat then 'Успешно обновлено'
           when l_add_chat then 'Группа добавлена'
           when l_check_chat and l_check_hash then 'Обновление не требуется'
           else 'Не выполнено' end::text as status
    FOR READ ONLY
  );
 END
$function$
;

DROP FUNCTION IF EXISTS screw.s_join(int8, int8);
CREATE OR REPLACE FUNCTION screw.s_join(i_user_id bigint, i_chat_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_user boolean := false;
  l_check_chat boolean := false;
  l_check_isset boolean := false;
  l_check_query boolean := false;

  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);
  l_user_id bigint := coalesce(i_user_id, 0::bigint);

 BEGIN
  l_check_user  := ((select count(1) from screw.sc_user      as u  where u.user_id = l_user_id) = 1);
  l_check_chat  := ((select count(1) from screw.sc_chat      as c  where c.chat_id = l_chat_id) = 1);
  l_check_isset := ((select count(1) from screw.sc_user_chat as uc where uc.user_id = l_user_id and uc.chat_id = l_chat_id) = 1);

  IF l_check_user and l_check_chat THEN
    IF not l_check_isset THEN
      insert into screw.sc_user_chat (user_id, chat_id) values (l_user_id, l_chat_id);
      l_check_query := true;
    END IF;
  END IF;

  RETURN (
    SELECT
      case when     l_check_query then 'Успешно присоединился к группе'
           when     l_check_isset then 'Уже есть в группе'
           when not  l_check_user then 'Неизвестный пользователь'
           when not  l_check_chat then 'Неизвестная группа'
           else 'Не выполнено' end::text as status
    FOR READ ONLY
  );
 END
$function$
;

DROP TYPE IF EXISTS screw.t_status_all CASCADE;
CREATE TYPE screw.t_status_all AS (
    username text,
    growe_size numeric(6, 2),
    blade_size numeric(6, 2),
    catch_size numeric(6, 2)
);


DROP FUNCTION IF EXISTS screw.r_status_all(int8);
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
    select u.username::text                     as username
         , g.sizesm::numeric(6, 2)              as growe_size
         , coalesce(b.sizesm, 0)::numeric(6, 2) as blade_size
         , coalesce(c.sizesm, 0)::numeric(6, 2) as catch_size
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


DROP FUNCTION IF EXISTS screw.s_gen_mid();
CREATE OR REPLACE FUNCTION screw.s_gen_mid()
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_message_pre text := (select message_pre from screw.sc_message_pre order by random() limit 1);
  l_message_pos text := (select message_pos from screw.sc_message_pos order by random() limit 1);

 BEGIN

  RETURN (
    select ' ' || l_message_pre || ' ' || l_message_pos
  );
 END
$function$
;

DROP FUNCTION IF EXISTS screw.i_d20();
CREATE OR REPLACE FUNCTION screw.i_d20()
 RETURNS numeric(2, 2)
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE

 BEGIN

  RETURN (
    select ((random() * 19.0) + 1)
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
  l_debuf_pre numeric(4, 2) := (select case when l_last_upd > l_create_date then ((extract(EPOCH from (now() -  l_last_upd)) / 3600.0) - 10.0) else 10.0 end);
  l_debuf numeric(4, 2) := (select case when l_debuf_pre > 10 then 10 else l_debuf_pre end);
  l_d20 numeric(4, 2) := screw.i_d20();

  l_modif numeric(4, 2) := ((((l_debuf + ((l_d20 ^ l_pow) * l_mul)) / l_di1) - l_sub) / l_di2);

  l_half_size numeric(6, 2) := (select sizesm / 2 from screw.sc_screw where screw_id = i_screw_id);

 BEGIN
  IF l_modif < l_min THEN
    update screw.sc_chat set drop_screw = i_screw_id, update_date = now() where chat_id = i_chat_id;
    update screw.sc_user set growe_screw = screw.i_new_screw() where user_id = i_user_id;
    update screw.sc_screw set update_date = now() where screw_id = i_screw_id;
  END IF;
  IF l_modif between l_min and l_div THEN
    update screw.sc_chat set drop_screw = screw.i_new_screw(l_half_size) where chat_id = i_chat_id;
    update screw.sc_screw set sizesm = l_half_size, update_date = now() where screw_id = i_screw_id;
  END IF;
  IF l_modif > l_max THEN
    update screw.sc_screw set sizesm = (sizesm * 2), update_date = now() where screw_id = i_screw_id;
  END IF;
  IF l_modif between l_div and l_max THEN
    update screw.sc_screw set sizesm = sizesm + l_modif, update_date = now() where screw_id = i_screw_id;
  END IF;

  insert into screw.sc_grow_log (chat_id, user_id, screw_id) values (i_chat_id, i_user_id, i_screw_id);
  RETURN (
    SELECT case when l_modif < l_min then ', и его болт отваливается!!!'
                when l_modif < l_div then ', и его болт ломается пополам!'
                when l_modif < l_su2 then ', и его болт значительно уменьшается.'
                when l_modif < l_su1 then ', и его болт уменьшается в размерах'
                when l_modif < 00.00 then ', и его болт слегка уменьшается'
                when l_modif > l_max then ', и его болт увеличивается вдвое!!!'
                when l_modif > l_in2 then ', и его болт значительно увеличивается!'
                when l_modif > l_in1 then ', и его болт увеличивается в размерах'
                when l_modif > 00.00 then ', и его болт слегка увеличивается...'
                else 'остаётся неизменным' end::text as res
    );
 END
$function$
;

DROP FUNCTION IF EXISTS screw.s_user_grow(int8, int8);
CREATE OR REPLACE FUNCTION screw.s_user_grow(i_chat_id bigint, i_user_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_user boolean := false;
  l_check_chat boolean := false;
  l_check_isset boolean := false;
  l_check_query boolean := false;

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
      SELECT u.username || screw.s_gen_mid() || screw.s_screw_grow(l_chat_id, u.user_id, u.growe_screw)
        from screw.sc_user as u
       where u.user_id = l_user_id
      FOR READ ONLY
    );
  END IF;
 END
$function$
;


DROP FUNCTION IF EXISTS screw.s_user_sharpen(int8);
CREATE OR REPLACE FUNCTION screw.s_user_sharpen(i_user_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_user boolean := false;

  l_user_id bigint := coalesce(i_user_id, 0::bigint);
  l_catch_screw bigint := null;

 BEGIN
  l_check_user := ((select count(1) from screw.sc_user as u where u.user_id = l_user_id) = 1);

  IF l_check_user THEN
    l_catch_screw := (select catch_screw from screw.sc_user as c where c.user_id = l_user_id);
    IF l_catch_screw is not null THEN
      update screw.sc_user set blade_screw = l_catch_screw, catch_screw = null where user_id = l_user_id;
    END IF;
    RETURN (
      SELECT case when l_catch_screw is not null then u.username || screw.s_gen_mid() || ' из кармана и превращает его в режек!'
                  else u.username || ', тебе нечего точить!' end::text as res
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
    END IF;

    RETURN (
      SELECT case when l_drop_screw is not null then u.username || ' забирает болт себе в карман.'
                  else u.username || ' не успевает забрать болт.' end::text as res
        from screw.sc_user as u
       where u.user_id = l_user_id
      FOR READ ONLY
    );
  END IF;
 END
$function$
;


DROP FUNCTION IF EXISTS screw.s_screw_braeck(int8, int8, int8, int8, int8);
CREATE OR REPLACE FUNCTION screw.s_screw_braeck(i_chat_id bigint, i_user_id bigint, i_screw_id bigint, i_defuser_id bigint, i_defscrew_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE

  l_d20       numeric(4, 2) := screw.i_d20();
  l_d20_def   numeric(4, 2) := screw.i_d20();
  l_size      numeric(6, 2) := (select sizesm from screw.sc_screw where screw_id = i_screw_id);
  l_size_def  numeric(6, 2) := (select sizesm from screw.sc_screw where screw_id = i_defscrew_id);

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
    SELECT 'На арене "' || c.title || '" ' || u.username || ' решает смахнуться болтами с ' || ud.username || '! Болт ' || ul.username || ' разлетается пополам!'
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

 BEGIN
  l_check_user  := ((select count(1) from screw.sc_user as u where u.user_id = l_user_id) = 1);
  l_check_chat  := ((select count(1) from screw.sc_chat as c where c.chat_id = l_chat_id) = 1);

  IF l_check_user and l_check_chat THEN
    l_check_isset := ((select count(1) from screw.sc_user_chat as uc where uc.user_id = l_user_id and uc.chat_id = l_chat_id) = 1);
  END IF;

  IF l_check_isset THEN
    RETURN (
      SELECT screw.s_screw_braeck(uc.chat_id, u.user_id, u.growe_screw, du.user_id, du.growe_screw) as res
        from screw.sc_user_chat as uc
        join screw.sc_user as u on u.user_id = uc.user_id and u.user_id = l_user_id
        join screw.sc_grow_log as sg on sg.chat_id = uc.chat_id
        join screw.sc_user as du on u.user_id = sg.user_id and u.user_id <> sg.user_id
       where uc.chat_id = l_chat_id
       order by sg.update_date desc
       limit 1
      FOR READ ONLY
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

  l_d20       numeric(4, 2) := screw.i_d20();
  l_d20_def   numeric(4, 2) := screw.i_d20();
  l_size      numeric(6, 2) := (select sizesm from screw.sc_screw where screw_id = i_screw_id);
  l_size_def  numeric(6, 2) := (select sizesm from screw.sc_screw where screw_id = i_defscrew_id);

  l_attack bool := ((l_d20_def + l_size_def) < (l_d20 + l_size));

 BEGIN
  IF l_attack THEN
    update screw.sc_chat  set drop_screw  = i_defscrew_id       where chat_id  = i_chat_id;
    update screw.sc_user  set growe_screw = screw.i_new_screw() where user_id  = i_defuser_id;
    update screw.sc_screw set update_date = now()               where screw_id = i_defscrew_id;
  END IF;

  RETURN (
    SELECT case when l_attack then u.username || ' успешно срезает болт ' || ud.username || '! Быстрее хватай его в карман!'
           else 'На арене "' || c.title || '" ' || u.username || ' решает срезать болт ' || ud.username || ', но тот успешно защищается своим болтом!'
           end::text as res
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
      SELECT case when sg.user_id is null then 'Тут все уже попрятали свои болты!'
                  else screw.s_screw_cut(uc.chat_id, u.user_id, u.blade_screw, du.user_id, du.growe_screw) end::text as res
        from screw.sc_user_chat as uc
        join screw.sc_user as u on u.user_id = uc.user_id and u.user_id = l_user_id
   left join screw.sc_grow_log as sg on sg.chat_id = uc.chat_id and (extract(EPOCH from (now() - sg.update_date)) < 66)
   left join screw.sc_user as du on u.user_id = sg.user_id and u.user_id <> sg.user_id
       where uc.chat_id = l_chat_id
       order by sg.update_date desc
       limit 1
      FOR READ ONLY
    );
  END IF;
 END
$function$
;

insert into screw.sc_message_pre(message_pre) values
('азартно'),
('аккуратно'),
('активно'),
('бегло'),
('беззаботно'),
('беззвучно'),
('безразлично'),
('безумно'),
('бережно'),
('беспокойно'),
('беспомощно'),
('беспощадно'),
('беспрепятственно'),
('бессильно'),
('бессмысленно'),
('бессовестно'),
('бессознательно'),
('бесшумно'),
('бешено'),
('блаженно'),
('бодро'),
('болезненно'),
('бурно'),
('быстро'),
('вежливо'),
('вероломно'),
('весело'),
('взволнованно'),
('виновато'),
('властно'),
('внезапно'),
('внимательно'),
('вовсю'),
('возбужденно'),
('возмущенно'),
('вопросительно'),
('восторженно'),
('впустую'),
('всерьез'),
('всячески'),
('втайне'),
('вызывающе'),
('вяло'),
('гневно'),
('гордо'),
('горестно'),
('горячо'),
('грамотно'),
('грозно'),
('грубо'),
('грустно'),
('деликатно'),
('демонстративно'),
('детально'),
('дико'),
('динамично'),
('добровольно'),
('добродушно'),
('добросовестно'),
('доверчиво'),
('долго'),
('достойно'),
('дружески'),
('духовно'),
('душевно'),
('ежедневно'),
('ежемесячно'),
('еле-еле'),
('ехидно'),
('жадно'),
('жалобно'),
('жарко'),
('жестко'),
('жестоко'),
('живо'),
('жутко'),
('забавно'),
('заботливо'),
('загадочно'),
('задумчиво'),
('заискивающе'),
('застенчиво'),
('злобно'),
('изумленно'),
('изящно'),
('инстинктивно'),
('интенсивно'),
('искренне'),
('искусно'),
('к своему стыду'),
('качественно'),
('красиво'),
('крепко'),
('круглосуточно'),
('культурно'),
('ласково'),
('легко'),
('лениво'),
('лихо'),
('лихорадочно'),
('ловко'),
('лукаво'),
('любезно'),
('любовно'),
('любопытно'),
('мало-помалу'),
('мастерски'),
('медленно'),
('методично'),
('механически'),
('мило'),
('мимоходом'),
('мирно'),
('многозначительно'),
('многократно'),
('молниеносно'),
('молча'),
('моментально'),
('мощно'),
('мрачно'),
('мужественно'),
('мучительно'),
('мягко'),
('нагло'),
('наглядно'),
('надежно'),
('наивно'),
('намертво'),
('наперебой'),
('напоказ'),
('напряжённо'),
('нарочито'),
('насмешливо'),
('наспех'),
('настойчиво'),
('настороженно'),
('настоятельно'),
('небрежно'),
('невзначай'),
('невозмутимо'),
('невольно'),
('недоверчиво'),
('недовольно'),
('недоуменно'),
('нежно'),
('незамедлительно'),
('незаметно'),
('нелепо'),
('неловко'),
('ненароком'),
('неожиданно'),
('неохотно'),
('нервно'),
('неспешно'),
('нетерпеливо'),
('неторопливо'),
('неуверенно'),
('неудачно'),
('неудержимо'),
('неуклюже'),
('неумело'),
('неумолимо'),
('нехотя'),
('нещадно'),
('обиженно'),
('облегчённо'),
('обречённо'),
('обстоятельно'),
('одиноко'),
('одобрительно'),
('оживленно'),
('озабоченно'),
('оперативно'),
('органично'),
('ослепительно'),
('основательно'),
('осторожно'),
('откровенно'),
('открыто'),
('отчаянно'),
('охотно'),
('периодически'),
('печально'),
('плавно'),
('по-разному'),
('подозрительно'),
('покорно'),
('поневоле'),
('понимающе'),
('поразительно'),
('послушно'),
('поспешно'),
('постепенно'),
('постоянно'),
('потрясающе'),
('похотливо'),
('почтительно'),
('превозмогая усталость'),
('презрительно'),
('приветливо'),
('привычно'),
('прилично'),
('принципиально'),
('приободряюще'),
('пристально'),
('простодушно'),
('профессионально'),
('прочно'),
('публично'),
('равнодушно'),
('равномерно'),
('радикально'),
('радостно'),
('раздражённо'),
('разочарованно'),
('рассеянно'),
('расслабленно'),
('растерянно'),
('ревниво'),
('регулярно'),
('решительно'),
('робко'),
('свободно'),
('своевременно'),
('сдержанно'),
('сдуру'),
('секретно'),
('сердечно'),
('сердито'),
('серьезно'),
('систематически'),
('скептически'),
('скромно'),
('скупо'),
('сладко'),
('смело'),
('смертельно'),
('смешно'),
('смиренно'),
('смущенно'),
('снисходительно'),
('сознательно'),
('сокрушенно'),
('солидно'),
('сонно'),
('сосредоточенно'),
('сочувственно'),
('спешно'),
('спокойно'),
('справедливо'),
('срочно'),
('стабильно'),
('странно'),
('страстно'),
('стремительно'),
('строго'),
('стыдливо'),
('судорожно'),
('сурово'),
('счастливо'),
('таинственно'),
('тайно'),
('творчески'),
('терпеливо'),
('технично'),
('торжественно'),
('торопливо'),
('тоскливо'),
('тревожно'),
('тщательно'),
('убедительно'),
('уверенно'),
('увлечённо'),
('угрожающе'),
('угрюмо'),
('украдкой'),
('умело'),
('уничижительно'),
('уныло'),
('упорно'),
('упрямо'),
('усердно'),
('усиленно'),
('устало'),
('хитро'),
('хладнокровно'),
('хмуро'),
('хорошенько'),
('чинно'),
('чудесно'),
('чудовищно'),
('чутко'),
('шумно'),
('шутливо'),
('элегантно'),
('энергично'),
('эротично'),
('эффектно'),
('яростно');

insert into screw.sc_message_pos(message_pos) values
('бередит свой болт'),
('беседует со свим болтом'),
('благодарит свой болт'),
('благословляет свой болт'),
('боготворит свой болт'),
('бранится на свой болт'),
('бреет свой болт'),
('бренчит на своём болте'),
('будоражит свой болт'),
('вглядывается в свой болт'),
('вертит своим болтом'),
('веселится со свим болтом'),
('вещает истину своему болту'),
('взбивает свой болт'),
('взвешивает свой болт'),
('вздергивает свой болт'),
('взмахивает своим болтом'),
('взъерошивает свой болт'),
('вибрирует своим болтом'),
('возбуждает свой болт'),
('воодушевляет свой болт'),
('воспевает свой болт'),
('восхваляет свой болт'),
('вселит свой болт'),
('вытаскивает на всеобщее обозрение свой болт'),
('гипнотизирует свой болт'),
('горланит о свём болте'),
('демонстрирует всем свой болт'),
('дергает свой болт'),
('деформирует свой болт'),
('душит свой болт'),
('изгибает свой болт'),
('кусаает свой болт'),
('ласкает свой болт'),
('материт свой болт'),
('машет своим болтом'),
('мельтешит у всех перед глазами своим болтом'),
('моет свой болт'),
('мылит свой болт'),
('намывает свой болт'),
('напевает своему болту'),
('натирает свой болт'),
('начинает размахивать своим болтом'),
('наяривает свой болт'),
('облизывает свой болт'),
('оскабливает свой болт'),
('оскаливается на свой болт'),
('оскорбляет свой болт'),
('оценивает свой болт'),
('ощупывает свой болт'),
('поглаживает свой болт'),
('поднимает свой болт'),
('покрывает смазкой свой болт'),
('покрывает эмалью свой болт'),
('посасывает свой болт'),
('пытается растянуть свой болт'),
('раскачивает своим болтом'),
('сжимает свой болт'),
('слюнявит свой болт'),
('смазывает свой болт'),
('смотрит на свой болт'),
('убаюкивает свой болт'),
('хвастается своим болтом');
