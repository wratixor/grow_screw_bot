from typing import Callable, Dict, Any, Awaitable, Union

from aiogram import BaseMiddleware
from aiogram.types import Message, CallbackQuery


class QParamMiddleware(BaseMiddleware):
    def __init__(self):
        self.group_set: set = {'group', 'supergroup', 'channel'}

    async def __call__(
            self,
            handler: Callable[[Message, Dict[str, Any]], Awaitable[Any]],
            event: Union[Message, CallbackQuery],
            data: Dict[str, Any]
    ) -> Any:
        tmp_uname: str = event.from_user.username
        if tmp_uname is None:
            tmp_uname = f'{event.from_user.first_name}'
        else:
            tmp_uname = f'@{tmp_uname}'
        data['quname']: str = tmp_uname
        data['isgroup']: bool = event.chat.type in self.group_set
        return await handler(event, data)

class QParamMiddlewareCallback(BaseMiddleware):
    def __init__(self):
        pass

    async def __call__(
            self,
            handler: Callable[[Message, Dict[str, Any]], Awaitable[Any]],
            event: Union[Message, CallbackQuery],
            data: Dict[str, Any]
    ) -> Any:
        tmp_uname: str = event.from_user.username
        if tmp_uname is None:
            tmp_uname = f'{event.from_user.first_name}'
        else:
            tmp_uname = f'@{tmp_uname}'
        data['quname']: str = tmp_uname
        return await handler(event, data)
