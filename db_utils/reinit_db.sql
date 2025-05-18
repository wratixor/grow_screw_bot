DROP SCHEMA IF EXISTS screw CASCADE;
CREATE SCHEMA screw AUTHORIZATION rmaster;

-- DROP SEQUENCE screw.grow_sq;

CREATE SEQUENCE screw.grow_sq
    INCREMENT BY 1
    MINVALUE 100
    MAXVALUE 9223372036854775807
    START 100
    CACHE 1
    NO CYCLE;
-- DROP SEQUENCE screw.message_pos_sq;

CREATE SEQUENCE screw.message_pos_sq
    INCREMENT BY 1
    MINVALUE 100
    MAXVALUE 9223372036854775807
    START 100
    CACHE 1
    NO CYCLE;
-- DROP SEQUENCE screw.message_pre_sq;

CREATE SEQUENCE screw.message_pre_sq
    INCREMENT BY 1
    MINVALUE 100
    MAXVALUE 9223372036854775807
    START 100
    CACHE 1
    NO CYCLE;
-- DROP SEQUENCE screw.pay_sq;

CREATE SEQUENCE screw.pay_sq
    INCREMENT BY 1
    MINVALUE 100
    MAXVALUE 9223372036854775807
    START 100
    CACHE 1
    NO CYCLE;
-- DROP SEQUENCE screw.screw_sq;

CREATE SEQUENCE screw.screw_sq
    INCREMENT BY 1
    MINVALUE 100
    MAXVALUE 9223372036854775807
    START 100
    CACHE 1
    NO CYCLE;-- screw.sc_message_pos определение

-- Drop table

-- DROP TABLE screw.sc_message_pos;

CREATE TABLE screw.sc_message_pos (
    uid int8 DEFAULT nextval('screw.message_pos_sq'::regclass) NOT NULL,
    message_pos varchar(64) NOT NULL,
    CONSTRAINT "sc_message_pos$pk" PRIMARY KEY (uid)
);


-- screw.sc_message_pre определение

-- Drop table

-- DROP TABLE screw.sc_message_pre;

CREATE TABLE screw.sc_message_pre (
    uid int8 DEFAULT nextval('screw.message_pre_sq'::regclass) NOT NULL,
    message_pre varchar(32) NOT NULL,
    CONSTRAINT "sc_message_pre$pk" PRIMARY KEY (uid)
);


-- screw.sc_screw определение

-- Drop table

-- DROP TABLE screw.sc_screw;

CREATE TABLE screw.sc_screw (
    screw_id int8 DEFAULT nextval('screw.screw_sq'::regclass) NOT NULL,
    sizesm numeric(12, 2) DEFAULT 0.0 NOT NULL,
    create_date timestamptz DEFAULT now() NOT NULL,
    update_date timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT "sc_screw$pk" PRIMARY KEY (screw_id)
);


-- screw.sc_chat определение

-- Drop table

-- DROP TABLE screw.sc_chat;

CREATE TABLE screw.sc_chat (
    chat_id int8 NOT NULL,
    chat_type varchar(64) NOT NULL,
    chat_title varchar(64) NULL,
    drop_screw int8 NULL,
    CONSTRAINT "sc_chat$pk" PRIMARY KEY (chat_id),
    CONSTRAINT sc_chat_drop_screw_fkey FOREIGN KEY (drop_screw) REFERENCES screw.sc_screw(screw_id)
);


-- screw.sc_user определение

-- Drop table

-- DROP TABLE screw.sc_user;

CREATE TABLE screw.sc_user (
    user_id int8 NOT NULL,
    username varchar(64) NULL,
    first_name varchar(64) NULL,
    growe_screw int8 NULL,
    blade_screw int8 NULL,
    catch_screw int8 NULL,
    luck numeric(4, 2) DEFAULT 0.0 NOT NULL,
    donat_luck numeric(4, 2) DEFAULT 0.0 NOT NULL,
    donat_amount numeric(6, 2) DEFAULT 0.0 NOT NULL,
    CONSTRAINT "sc_user$pk" PRIMARY KEY (user_id),
    CONSTRAINT sc_user_blade_screw_fkey FOREIGN KEY (blade_screw) REFERENCES screw.sc_screw(screw_id),
    CONSTRAINT sc_user_catch_screw_fkey FOREIGN KEY (catch_screw) REFERENCES screw.sc_screw(screw_id),
    CONSTRAINT sc_user_growe_screw_fkey FOREIGN KEY (growe_screw) REFERENCES screw.sc_screw(screw_id)
);


-- screw.sc_user_chat определение

-- Drop table

-- DROP TABLE screw.sc_user_chat;

CREATE TABLE screw.sc_user_chat (
    user_id int8 NOT NULL,
    chat_id int8 NOT NULL,
    CONSTRAINT "sc_user_chat$pk" PRIMARY KEY (chat_id, user_id),
    CONSTRAINT sc_user_chat_chat_id_fkey FOREIGN KEY (chat_id) REFERENCES screw.sc_chat(chat_id),
    CONSTRAINT sc_user_chat_user_id_fkey FOREIGN KEY (user_id) REFERENCES screw.sc_user(user_id)
);


-- screw.sc_grow_log определение

-- Drop table

-- DROP TABLE screw.sc_grow_log;

CREATE TABLE screw.sc_grow_log (
    uid int8 DEFAULT nextval('screw.grow_sq'::regclass) NOT NULL,
    chat_id int8 NULL,
    user_id int8 NULL,
    screw_id int8 NULL,
    update_date timestamptz DEFAULT now() NOT NULL,
    modif numeric(6, 2) DEFAULT 0.0 NOT NULL,
    CONSTRAINT "sc_grow_log$pk" PRIMARY KEY (uid),
    CONSTRAINT sc_grow_log_chat_id_fkey FOREIGN KEY (chat_id) REFERENCES screw.sc_chat(chat_id),
    CONSTRAINT sc_grow_log_screw_id_fkey FOREIGN KEY (screw_id) REFERENCES screw.sc_screw(screw_id),
    CONSTRAINT sc_grow_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES screw.sc_user(user_id)
);


-- screw.sc_pay_log определение

-- Drop table

-- DROP TABLE screw.sc_pay_log;

CREATE TABLE screw.sc_pay_log (
    uid int8 DEFAULT nextval('screw.pay_sq'::regclass) NOT NULL,
    user_id int8 NULL,
    pay numeric(6, 2) DEFAULT 0.0 NOT NULL,
    update_date timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT "sc_pay_log$pk" PRIMARY KEY (uid),
    CONSTRAINT sc_pay_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES screw.sc_user(user_id)
);



-- DROP FUNCTION screw.donat_rang(int8);

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

-- DROP FUNCTION screw.i_d20(int8);

CREATE OR REPLACE FUNCTION screw.i_d20(i_user_id bigint)
 RETURNS numeric
 LANGUAGE plpgsql
 SECURITY DEFINER COST 1
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
  ELSE
    update screw.sc_user set luck = 0.0 where user_id = i_user_id;
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

-- DROP FUNCTION screw.i_new_screw();

CREATE OR REPLACE FUNCTION screw.i_new_screw()
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER COST 1
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

-- DROP FUNCTION screw.i_new_screw(numeric);

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

-- DROP FUNCTION screw.r_status_all();

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

-- DROP FUNCTION screw.r_status_all(int8);

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

-- DROP FUNCTION screw.r_status_my(int8);

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

-- DROP FUNCTION screw.s_aou_chat(int8, text, text);

CREATE OR REPLACE FUNCTION screw.s_aou_chat(i_chat_id bigint, i_chat_type text, i_chat_title text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER COST 1
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

-- DROP FUNCTION screw.s_aou_user(int8, text, text);

CREATE OR REPLACE FUNCTION screw.s_aou_user(i_user_id bigint, i_username text, i_first_name text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_user boolean := false;
  l_add_user boolean := false;
  l_update_user boolean := false;
  l_check boolean := false;

  l_user_id bigint := coalesce(i_user_id, 0::bigint);
  l_username text := coalesce(i_username, '');
  l_first_name text := coalesce(i_first_name, '');

 BEGIN
  l_check_user := ((select count(1) from screw.sc_user as u where u.user_id = l_user_id) = 1);
  IF not l_check_user THEN
    insert into screw.sc_user (user_id, username, first_name, growe_screw)
                       values (l_user_id, l_username, l_first_name, screw.i_new_screw());
    l_add_user := true;
  ELSE
    l_check := ((select username||first_name from screw.sc_user as u where u.user_id = l_user_id) = l_username||l_first_name);
    IF not l_check THEN
      update screw.sc_user set username = l_username, first_name = l_first_name where user_id = l_user_id;
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

-- DROP FUNCTION screw.s_gen_mid();

CREATE OR REPLACE FUNCTION screw.s_gen_mid()
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER COST 1
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

-- DROP FUNCTION screw.s_join(int8, int8);

CREATE OR REPLACE FUNCTION screw.s_join(i_user_id bigint, i_chat_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER COST 1
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

-- DROP FUNCTION screw.s_screw_attack(int8, int8, int8, int8, int8);

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

-- DROP FUNCTION screw.s_screw_breack(int8, int8, int8, int8, int8);

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

-- DROP FUNCTION screw.s_screw_cut(int8, int8, int8, int8, int8);

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

-- DROP FUNCTION screw.s_screw_grow(int8, int8, int8);

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

-- DROP FUNCTION screw.s_set_donat_luck(int8, numeric);

CREATE OR REPLACE FUNCTION screw.s_set_donat_luck(i_user_id bigint, i_luck numeric)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER COST 1
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

-- DROP FUNCTION screw.s_user_attack(int8, int8);

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

-- DROP FUNCTION screw.s_user_breack(int8, int8);

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

-- DROP FUNCTION screw.s_user_catch(int8, int8);

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

-- DROP FUNCTION screw.s_user_cut(int8, int8);

CREATE OR REPLACE FUNCTION screw.s_user_cut(i_chat_id bigint, i_user_id bigint)
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

-- DROP FUNCTION screw.s_user_grow(int8, int8);

CREATE OR REPLACE FUNCTION screw.s_user_grow(i_chat_id bigint, i_user_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_user boolean := false;
  l_check_chat boolean := false;
  l_check_isset boolean := false;
  l_check_query boolean := false;
  l_antispam boolean := false;

  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);
  l_user_id bigint := coalesce(i_user_id, 0::bigint);



 BEGIN
  l_check_user  := ((select count(1) from screw.sc_user as u where u.user_id = l_user_id) = 1);
  l_check_chat  := ((select count(1) from screw.sc_chat as c where c.chat_id = l_chat_id) = 1);

  IF l_check_user and l_check_chat THEN
    l_check_isset := ((select count(1) from screw.sc_user_chat as uc where uc.user_id = l_user_id and uc.chat_id = l_chat_id) = 1);
  END IF;

  IF l_check_isset THEN
   l_antispam := (
     select ((now() - max(update_date)) > (interval '15 minute') or max(update_date) is null)
       from screw.sc_grow_log as sg
      where sg.user_id = l_user_id
    );

    IF l_antispam THEN
      RETURN (
        SELECT u.username || screw.s_gen_mid() || screw.s_screw_grow(l_chat_id, u.user_id, u.growe_screw)
          from screw.sc_user as u
         where u.user_id = l_user_id
        FOR READ ONLY
      );
    ELSE
      RETURN (
        SELECT u.username || ', ХАРЭ ДРОЧИТЬ!'
          from screw.sc_user as u
         where u.user_id = l_user_id
        FOR READ ONLY
      );
    END IF;
  END IF;
 END
$function$
;

-- DROP FUNCTION screw.s_user_pay(int8, numeric);

CREATE OR REPLACE FUNCTION screw.s_user_pay(i_user_id bigint, i_pay numeric)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER COST 1
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

-- DROP FUNCTION screw.s_user_sharpen(int8);

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

-- DROP FUNCTION screw.s_user_tig(int8);

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
  l_screw_size numeric(12, 2) := 0.0;
  l_screw_modif numeric(12, 2) := 0.0;


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
('беседует со своим болтом'),
('благодарит свой болт'),
('благословляет свой болт'),
('боготворит свой болт'),
('бранится на свой болт'),
('бреет свой болт'),
('бренчит на своём болте'),
('будоражит свой болт'),
('вглядывается в свой болт'),
('вертит своим болтом'),
('веселит свой болт'),
('веселится со своим болтом'),
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
('вытаскивает на всеобщее обозрение свой болт'),
('гипнотизирует свой болт'),
('горланит о своём болте'),
('демонстрирует всем свой болт'),
('дергает свой болт'),
('деформирует свой болт'),
('душит свой болт'),
('изгибает свой болт'),
('кусает свой болт'),
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

