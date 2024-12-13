import logging
from aiogram import Bot, Dispatcher
from aiogram.client.default import DefaultBotProperties
from aiogram.enums import ParseMode
from aiogram.fsm.storage.memory import MemoryStorage
from decouple import config

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
storage: MemoryStorage = MemoryStorage()

admins: set = set(int(admin_id) for admin_id in config('ADMINS').split(','))
pg_link: str = config('PG_LINK')

bot: Bot = Bot(token=config('BOT_TOKEN'), default=DefaultBotProperties(parse_mode=ParseMode.HTML))
bot_url: str = config('BOT_URL')
dp: Dispatcher = Dispatcher(storage=storage)

