import logging

import asyncpg
from aiogram import Router, F
from aiogram.filters import CommandStart, Command, CommandObject
from aiogram.types import Message
from asyncpg import Record

from middlewares.db_middleware import DatabaseMiddleware
from middlewares.qparam_middleware import QParamMiddleware
import db_utils.db_request as r

start_router = Router()
start_router.message.middleware(DatabaseMiddleware())
start_router.message.middleware(QParamMiddleware())
logger = logging.getLogger(__name__)

helpstr: str = (f'Доброго времени суток!'
                f'\n/start - Активация бота'
                f'\n/help или Помоги - Справка по командам'
                f'\nКоманды доступные только в чате:'
                f'\n/bolt или <code>Болт</code> - Растить свой болт'
                f'\n/cut или <code>Срезать</code> - Попытаться срезать режеком чужой болт'
                f' (Доступно 1 мин. после того, как кто-то другой выращивал свой болт, ничем не рискуешь'
                f', но нужно быть быстрым и иметь хороший режек)'
                f'\n/breack или <code>Сломать</code> - Попытаться сломать своим болтом чужой болт пополам'
                f' (Доступно всегда после того, как кто-то другой выращивал свой болт, но есть риск сломать свой)'
                f'\n/catch или <code>Забрать</code> - Подобрать последний срезанный/сломанный/отвалившийся болт'
                f' (Заменяет предыдущий подобранный болт)'
                f'\n/sharp или <code>Точить</code> - Заточить последний подобранный болт и превратить его в режек'
                f' (Заменяет предыдущий режек)'
                f'\n/stat или <code>Статы</code> - Cтаты участников чата'
                f'\nНе забудь выдать боту права админа, чтобы он видел русские команды без "/"!')


@start_router.message(CommandStart())
async def cmd_start(message: Message, db: asyncpg.pool.Pool, quname: str, isgroup: bool):
    await r.s_aou_user(db, message.from_user.id, quname, message.from_user.first_name)
    if isgroup:
        await r.s_aou_chat(db, message.chat.id, message.chat.type, message.chat.title)
        await r.s_join(db, message.from_user.id, message.chat.id)

    await message.answer(f'Доброго времени суток!'
                         f'\nПомощь доступна по команде /help'
                         f'\nРасти болты, ломай болты, точи болты, сражайся на болтах! Больше болтов для трона из болтов!'
                         f'\nНе забудь выдать боту права админа, чтобы он видел русские команды без "/"!')

@start_router.message(Command('test'))
async def test(message: Message, command: CommandObject, quname: str, isgroup: bool):
    command_args: str = command.args
    text: str = (f'test: {command_args}'
                 f'\nquname: {quname}'
                 f'\nisgroup: {isgroup}')
    await message.reply(text)
    logger.info(command_args)

@start_router.message(Command('developer_info'))
async def developer_info(message: Message):
    text: str = (f'Developer: @wratixor @tanatovich'
                 f'\nSite: https://wratixor.ru'
                 f'\nProject: https://wratixor.ru/projects/grow_screw_bot'
                 f'\nDonations: https://yoomoney.ru/to/4100118849397169'
                 f'\nGithub: https://github.com/wratixor/grow_screw_bot')
    await message.answer(text)

@start_router.message(Command('help'))
async def helper(message: Message, db: asyncpg.pool.Pool, quname: str, isgroup: bool):
    await r.s_aou_user(db, message.from_user.id, quname, message.from_user.first_name)
    if isgroup:
        await r.s_aou_chat(db, message.chat.id, message.chat.type, message.chat.title)
        await r.s_join(db, message.from_user.id, message.chat.id)
    await message.answer(helpstr)

@start_router.message(F.text.lower() == 'помоги')
async def status(message: Message, db: asyncpg.pool.Pool, quname: str, isgroup: bool):
    await r.s_aou_user(db, message.from_user.id, quname, message.from_user.first_name)
    if isgroup:
        await r.s_aou_chat(db, message.chat.id, message.chat.type, message.chat.title)
        await r.s_join(db, message.from_user.id, message.chat.id)
    await message.answer(helpstr)

@start_router.message(Command('stat'))
async def status(message: Message, db: asyncpg.pool.Pool, quname: str, isgroup: bool):
    await r.s_aou_user(db, message.from_user.id, quname, message.from_user.first_name)
    res: list[Record]
    answer: str = f'Болты в вашем чатике:\n'
    if isgroup:
        await r.s_aou_chat(db, message.chat.id, message.chat.type, message.chat.title)
        await r.s_join(db, message.from_user.id, message.chat.id)
        res = await r.r_status(db, message.chat.id)
        for row in res:
            answer += (f"{row['username']} - Болт: {row['growe_size']}| Режек: {row['blade_size']}"
                       f"| В кармане: {row['catch_size']}\n")
    else:
        answer = 'Команда доступна только в группе!'
    await message.answer(answer)

@start_router.message(F.text.lower() == 'статы')
async def status(message: Message, db: asyncpg.pool.Pool, quname: str, isgroup: bool):
    await r.s_aou_user(db, message.from_user.id, quname, message.from_user.first_name)
    res: list[Record]
    answer: str = f'Болты в вашем чатике:\n'
    if isgroup:
        await r.s_aou_chat(db, message.chat.id, message.chat.type, message.chat.title)
        await r.s_join(db, message.from_user.id, message.chat.id)
        res = await r.r_status(db, message.chat.id)
        for row in res:
            answer += (f"{row['username']} - Болт: {row['growe_size']}| Режек: {row['blade_size']}"
                       f"| В кармане: {row['catch_size']}\n")
    else:
        answer = 'Команда доступна только в группе!'
    await message.answer(answer)

@start_router.message(F.text.lower() == 'болт')
async def status(message: Message, db: asyncpg.pool.Pool, quname: str, isgroup: bool):
    await r.s_aou_user(db, message.from_user.id, quname, message.from_user.first_name)
    answer: str
    if isgroup:
        await r.s_aou_chat(db, message.chat.id, message.chat.type, message.chat.title)
        await r.s_join(db, message.from_user.id, message.chat.id)
        answer = await r.s_user_grow(db, message.chat.id, message.from_user.id)
    else:
        answer = 'Команда доступна только в группе!'
    await message.answer(answer)

@start_router.message(F.text.lower() == 'срезать')
async def status(message: Message, db: asyncpg.pool.Pool, isgroup: bool):
    answer: str
    if isgroup:
        answer = await r.s_user_cut(db, message.chat.id, message.from_user.id)
    else:
        answer = 'Команда доступна только в группе!'
    await message.answer(answer)

@start_router.message(F.text.lower() == 'сломать')
async def status(message: Message, db: asyncpg.pool.Pool, isgroup: bool):
    answer: str
    if isgroup:
        answer = await r.s_user_breack(db, message.chat.id, message.from_user.id)
    else:
        answer = 'Команда доступна только в группе!'
    await message.answer(answer)

@start_router.message(F.text.lower() == 'забрать')
async def status(message: Message, db: asyncpg.pool.Pool, isgroup: bool):
    answer: str
    if isgroup:
        answer = await r.s_user_catch(db, message.chat.id, message.from_user.id)
    else:
        answer = 'Команда доступна только в группе!'
    await message.answer(answer)

@start_router.message(F.text.lower() == 'точить')
async def status(message: Message, db: asyncpg.pool.Pool, isgroup: bool):
    answer: str
    if isgroup:
        answer = await r.s_user_sharpen(db, message.from_user.id)
    else:
        answer = 'Команда доступна только в группе!'
    await message.answer(answer)

@start_router.message(Command('bolt'))
async def status(message: Message, db: asyncpg.pool.Pool, quname: str, isgroup: bool):
    await r.s_aou_user(db, message.from_user.id, quname, message.from_user.first_name)
    answer: str
    if isgroup:
        await r.s_aou_chat(db, message.chat.id, message.chat.type, message.chat.title)
        await r.s_join(db, message.from_user.id, message.chat.id)
        answer = await r.s_user_grow(db, message.chat.id, message.from_user.id)
    else:
        answer = 'Команда доступна только в группе!'
    await message.answer(answer)

@start_router.message(Command('cut'))
async def status(message: Message, db: asyncpg.pool.Pool, isgroup: bool):
    answer: str
    if isgroup:
        answer = await r.s_user_cut(db, message.chat.id, message.from_user.id)
    else:
        answer = 'Команда доступна только в группе!'
    await message.answer(answer)

@start_router.message(Command('breack'))
async def status(message: Message, db: asyncpg.pool.Pool, isgroup: bool):
    answer: str
    if isgroup:
        answer = await r.s_user_breack(db, message.chat.id, message.from_user.id)
    else:
        answer = 'Команда доступна только в группе!'
    await message.answer(answer)

@start_router.message(Command('catch'))
async def status(message: Message, db: asyncpg.pool.Pool, isgroup: bool):
    answer: str
    if isgroup:
        answer = await r.s_user_catch(db, message.chat.id, message.from_user.id)
    else:
        answer = 'Команда доступна только в группе!'
    await message.answer(answer)

@start_router.message(Command('sharp'))
async def status(message: Message, db: asyncpg.pool.Pool, isgroup: bool):
    answer: str
    if isgroup:
        answer = await r.s_user_sharpen(db, message.from_user.id)
    else:
        answer = 'Команда доступна только в группе!'
    await message.answer(answer)

