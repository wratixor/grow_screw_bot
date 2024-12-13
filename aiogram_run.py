import asyncio
import logging

from create_bot import bot, dp, admins
from handlers.admin_menu import admin_router
from handlers.group_command import start_router
from aiogram.types import BotCommand, BotCommandScopeAllPrivateChats


logger = logging.getLogger(__name__)

async def set_all_commands():
    commands = [BotCommand(command='/start', description='Инициализация'),
                BotCommand(command='/help', description='Помощь'),
                BotCommand(command='/stat', description='Статы участников в чате'),
                BotCommand(command='/bolt', description='Болт'),
                BotCommand(command='/cut', description='Срезать'),
                BotCommand(command='/breack', description='Сломать'),
                BotCommand(command='/catch', description='Забрать'),
                BotCommand(command='/sharp', description='Точить')
                ]
    await bot.set_my_commands(commands)

async def set_private_commands():
    commands = [BotCommand(command='/start', description='Запуск'),
                BotCommand(command='/help', description='Помощь'),
                ]
    await bot.set_my_commands(commands, BotCommandScopeAllPrivateChats())

async def start_bot():
    logger.warning('Bot running')
    bn = await bot.get_my_name()
    for admin_id in admins:
        try:
            await bot.send_message(admin_id, f'{bn.name} запущен! 🥳')
        except Exception as e:
            logger.error(f'start_bot(): {e}')

async def stop_bot():
    logger.warning('Bot stopping')
    bn = await bot.get_my_name()
    for admin_id in admins:
        try:
            await bot.send_message(admin_id, f'{bn.name} остановлен. За что? 😔')
        except Exception as e:
            logger.error(f'stop_bot(): {e}')

async def main():
    dp.include_router(start_router)
    dp.include_router(admin_router)
    dp.startup.register(set_all_commands)
    dp.startup.register(set_private_commands)

    dp.startup.register(start_bot)
    dp.shutdown.register(stop_bot)

    try:
        await bot.delete_webhook(drop_pending_updates=True)
        await dp.start_polling(bot, allowed_updates=dp.resolve_used_update_types())
    except Exception as e:
        logger.error(f'main(): {e}')
    finally:
        await bot.session.close()
        await exit(0)

if __name__ == "__main__":
    asyncio.run(main())
