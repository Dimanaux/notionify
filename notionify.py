#!/usr/bin/env python3

import json
from subprocess import Popen, PIPE
from threading import (Thread, Semaphore)
from time import sleep
from argparse import ArgumentParser
import sys

from notion.client import NotionClient
from notion.block import BulletedListBlock
from notion.block import HeaderBlock


parser = ArgumentParser(description='Add comments, upload files in Notion table.')
parser.add_argument('--token', metavar='token_v2', help='token_v2 cookie from https://www.notion.so', required=True)
parser.add_argument('--view', metavar='URL', help='link to notion view', required=True)
# args = parser.parse_args(sys.argv[1:])

token_v2 = '17556e79b0773f875535054f318b8aa2524cb31269f3f3063ccfcae69c5e5e4db3e8c3a5a3bd3018e910b7aecaac862c86fad7025b32eb7dc494e3252aae76dd6c178470a0dafc60dc16161c04ba'
view_link = 'https://www.notion.so/flatstack/c8b0473836b94aee92263a660ed91c3f?v=5d3227b643424365a2875845ef2aa270'

client = NotionClient(token_v2=token_v2)
cv = client.get_collection_view(view_link)
rows = cv.build_query().execute()

semaphore = Semaphore(7)

def get_attachments(links_line):
    links = []
    if links_line not in ('', None):
        attachments = links_line.split(':')
        for a in attachments:
            link = upload(a)
            links.append(link)
    links = list(filter(lambda l: l != '', links))
    if len(links) > 0:
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
        row.attachments = get_attachments(row.RelPaths)
    except Exception as e:
        print('Error while setting attachments!', e)


def set_row_comments(row):
    try:
        if len(row.children) != 0 or row.commentsjson == '{"comments":[]}':
            return
        comments = json.loads(row.commentsjson)['comments']
        comments.sort(key=lambda d: d['date'])
        row.children.add_new(HeaderBlock, title='# Comments')
        parents = {}
        for comment in comments:
            text = format_comment(comment)
            if comment['parent_id'] not in (None, ''):
                parent_id = comment['parent_id']
                parents[parent_id].children.add_new(BulletedListBlock, title=text)
            else:
                parent = row.children.add_new(BulletedListBlock, title=text)
                parents[comment['id']] = parent
    except Exception as e:
        print(e)


def process_rows_parallel(task):
    global rows
    rows_iter = iter(rows)
    for r in rows_iter:
        t = Thread(target=task, args=(r,))
        semaphore.acquire()
        try:
            t.start()
        except Exception as e:
            print(e)
        finally:
            semaphore.release()


def main():
    process_rows_parallel(set_row_comments)
    process_rows_parallel(set_row_attachments)


if __name__ == '__main__':
    main()
