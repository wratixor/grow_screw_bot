import datetime
import logging
import asyncpg
from asyncpg import Record

logger = logging.getLogger(__name__)

async def s_join(pool: asyncpg.pool.Pool, user_id: int, group_id: int) -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from screw.s_join($1::bigint, $2::bigint)"
                                         , user_id, group_id)
        except Exception as e:
            result = f"Exception s_join({user_id}, {group_id}): {e}"
            logger.error(result)
    return result

async def s_aou_user(pool: asyncpg.pool.Pool, user_id: int, username: str, first_name: str) -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from screw.s_aou_user($1::bigint, $2::text, $3::text)"
                                         , user_id, username, first_name)
        except Exception as e:
            result = f"Exception s_aou_user({user_id}, {username}, {first_name}): {e}"
            logger.error(result)
    return result

async def s_aou_chat(pool: asyncpg.pool.Pool, group_id: int, group_type: str, group_title: str) -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from screw.s_aou_chat($1::bigint, $2::text, $3::text)"
                                         , group_id, group_type, group_title)
        except Exception as e:
            result = f"Exception s_aou_chat({group_id}, {group_type}, {group_title}): {e}"
            logger.error(result)
    return result

async def r_status(pool: asyncpg.pool.Pool, group_id: int = None) -> list[Record]:
    result: list[Record]
    async with pool.acquire() as conn:
        try:
            result = await conn.fetch("select * from screw.r_status_all($1::bigint)", group_id)
        except Exception as e:
            logger.error(f"Exception r_status({group_id}): {e}")
    return result


async def s_user_grow(pool: asyncpg.pool.Pool, group_id: int, user_id: int):
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from screw.s_user_grow($1::bigint, $2::bigint)"
                                         , group_id, user_id)
        except Exception as e:
            result = f"Exception s_user_grow({group_id}, {user_id}): {e}"
            logger.error(result)
    return result

async def s_user_cut(pool: asyncpg.pool.Pool, group_id: int, user_id: int):
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from screw.s_user_cut($1::bigint, $2::bigint)"
                                         , group_id, user_id)
        except Exception as e:
            result = f"Exception s_user_cut({group_id}, {user_id}): {e}"
            logger.error(result)
    return result

async def s_user_breack(pool: asyncpg.pool.Pool, group_id: int, user_id: int):
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from screw.s_user_breack($1::bigint, $2::bigint)"
                                         , group_id, user_id)
        except Exception as e:
            result = f"Exception s_user_breack({group_id}, {user_id}): {e}"
            logger.error(result)
    return result

async def s_user_catch(pool: asyncpg.pool.Pool, group_id: int, user_id: int):
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from screw.s_user_catch($1::bigint, $2::bigint)"
                                         , group_id, user_id)
        except Exception as e:
            result = f"Exception s_user_catch({group_id}, {user_id}): {e}"
            logger.error(result)
    return result

async def s_user_sharpen(pool: asyncpg.pool.Pool, user_id: int):
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from screw.s_user_sharpen($1::bigint)", user_id)
        except Exception as e:
            result = f"Exception s_user_sharpen({user_id}): {e}"
            logger.error(result)
    return result