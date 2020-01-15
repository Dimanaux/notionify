#!/usr/bin/env python3

import json
from subprocess import Popen, PIPE
import asyncio
from concurrent.futures import ThreadPoolExecutor

from notion.client import NotionClient
from notion.block import BulletedListBlock
from notion.block import HeaderBlock

token_v2 = '?'
view_link = '?'


def get_attachments(links_line):
    links = []
    if links_line not in ('', None):
        attachments = links_line.split(':')
        for a in attachments:
            link = upload(a)
            links.append(link)
    if links:
        links.append('pull me if access error')
    return links


def upload(file):
    process = Popen(["./Main", token_v2, file], stdout=PIPE)
    (output, err) = process.communicate()
    exit_code = process.wait()
    return output.decode("utf-8").rstrip("\n")


def format_comment(comment):
    return '{text}\n__by {author} on {date}__'.format(**comment)


def set_row_attachments(row):
    try:
        row.attachments = get_attachments(row.relpaths)
    except Exception:
        pass


def set_row_comments(row):
    try:
        comments = json.loads(row.commentsjson)['comments']
        comments.sort(key=lambda d: d['date'])

        row.children.add_new(HeaderBlock, title='# Comments')
        parents = {}
        for comment in comments:
            text = format_comment(comment)
            if comment['parent_id'] not in (None, ''):
                parent_id = int(comment['parent_id'])
                parents[parent_id].children.add_new(BulletedListBlock, title=text)
            else:
                parent = row.children.add_new(BulletedListBlock, title=text)
                parents[int(comment['id'])] = parent
    except Exception:
        pass


async def process_rows_async():
    client = NotionClient(token_v2=token_v2)
    cv = client.get_collection_view(view_link)
    rows = cv.build_query().execute()

    with ThreadPoolExecutor(max_workers=8) as executor:
        loop = asyncio.get_event_loop()
        comments_tasks = [loop.run_in_executor(executor, set_row_comments, r) for r in rows]
        attachments_tasks = [loop.run_in_executor(executor, set_row_attachments, r) for r in rows]

        for r in await asyncio.gather(*comments_tasks):
            pass
        for r in await asyncio.gather(*attachments_tasks):
            pass


def main():
    loop = asyncio.get_event_loop()
    future = asyncio.ensure_future(process_rows_async())
    loop.run_until_complete(future)

main()
