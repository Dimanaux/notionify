#!/usr/bin/env python3

import json
from subprocess import Popen, PIPE
from threading import (Thread, Semaphore)
from time import sleep
from argparse import ArgumentParser

from notion.client import NotionClient
from notion.block import BulletedListBlock
from notion.block import HeaderBlock


parser = ArgumentParser(description='Add comments, upload files in Notion table.')
parser.add_argument('--csv', metavar='file.csv', help='.csv file with applicants', required=True)
parser.add_argument('--token', metavar='token_v2', help='token_v2 cookie from https://www.notion.so', required=True)
parser.add_argument('--view', metavar='URL', help='link to notion view', required=True)
args = parser.parse_args(sys.argv[1:])

client = NotionClient(token_v2=args.token)
cv = client.get_collection_view(args.view)
rows = cv.build_query().execute()

threads = []


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
    process = Popen(["./Main", args.token, file], stdout=PIPE)
    (output, err) = process.communicate()
    exit_code = process.wait()
    return output.decode("utf-8").rstrip("\n")


def format_comment(comment):
    return '{text}\n__by {author} on {date}__'.format(**comment)


def set_row_attachments(row, sem):
    sem.acquire()
    try:
        row.attachments = get_attachments(row.relpaths)
    except Exception:
        pass
    finally:
        sem.release()


def set_row_comments(row, sem):
    sem.acquire()
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
                parent_id = int(comment['parent_id'])
                parents[parent_id].children.add_new(BulletedListBlock, title=text)
            else:
                parent = row.children.add_new(BulletedListBlock, title=text)
                parents[int(comment['id'])] = parent
    except Exception:
        pass
    finally:
        sem.release()


def comments():
    global threads
    global rows
    rows_iter = iter(rows)
    sem = Semaphore(10)
    for r in rows_iter:
        t = Thread(target=set_row_comments, args=(r,sem))
        threads.append(t)
        t.start()


def attachments():
    global threads
    global rows
    rows_iter = iter(rows)
    sem = Semaphore(10)
    for r in rows_iter:
        t = Thread(target=set_row_attachments, args=(r,sem))
        threads.append(t)
        while len(alive_threads()) > 10:
            sleep(0.1)
        t.start()


ct = Thread(target=comments, args=())
at = Thread(target=attachments, args=())


def main():
    ct.start()
    at.start()


if __name__ == '__main__':
    main()
