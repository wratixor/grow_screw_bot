from typing import Callable, Dict, Any, Awaitable, Union

import asyncpg
from aiogram import BaseMiddleware
from aiogram.types import Message, CallbackQuery
from create_bot import pg_link


class DatabaseMiddleware(BaseMiddleware):
    def __init__(self):
        self.pool = None

    async def __call__(
            self,
            handler: Callable[[Message, Dict[str, Any]], Awaitable[Any]],
            event: Union[Message, CallbackQuery],
            data: Dict[str, Any]
    ) -> Any:
        if not self.pool:
            self.pool = await asyncpg.create_pool(dsn=pg_link)
        data['db'] = self.pool
        return await handler(event, data)

