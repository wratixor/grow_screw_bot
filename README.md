<H1>grow_screw_bot</H1>
<h2>Расти болты, ломай болты, точи болты, сражайся на болтах! Больше болтов для трона из болтов!
</h2>
<h2>Site: https://wratixor.ru/projects/grow_screw_bot</h2>
<h2>TG: https://t.me/grow_screw_bot</h2>

<h3>Requirements:</h3>
 - aiogram<br>
 - python-decouple<br>
 - asyncpg<br>

<h3>Install:</h3>
- <code>git clone https://github.com/wratixor/grow_screw_bot</code><br>
- <code>python3 -m venv .venv</code><br>
- <code>source .venv/bin/activate</code><br>
- <code>pip install -r requirements.txt</code><br>
- Edit template.env and rename to .env<br>
- Run <code>db_utils/reinit_db.sql</code> into PostgreSQL CLI<br>
- Edit screwbot.service<br>
- <code>ln -s /../screwbot.service /etc/systemd/system</code><br>
- <code>systemctl enable screwbot.service</code><br>
- <code>systemctl start screwbot.service</code><br>