import logging
from aiogram import Router
from aiogram.filters import Command, CommandObject
from aiogram.types import Message

from create_bot import admins, dp, bot
from filters.is_admin import IsAdmin

logger = logging.getLogger(__name__)
admin_router = Router()

@admin_router.message(Command(commands=['stop', 'stat', 'log']), IsAdmin(admins))
async def admin_menu(message: Message, command: CommandObject):
    if command.text == '/stop':
        logger.warning('/stop')
        try:
            await message.reply('Бот выключается...')
            await dp.stop_polling()
            await bot.session.close()
            await bot.close()
        except Exception as e:
            logger.error(f'/stop: {e}')
    elif command.text == '/stat':
        logger.warning('/stat')
    elif command.text == '/log':
        logger.warning('/log')
    else:
        logger.error('missed command')

