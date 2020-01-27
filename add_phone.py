#!/usr/bin/env python3

import csv
import sys
from datetime import datetime
from threading import (Thread, Semaphore)
from time import sleep
from argparse import ArgumentParser

from notion.client import NotionClient
from notion.block import BulletedListBlock
from notion.block import HeaderBlock

date_added_to_phones = {}

def csv_key(row):
    return row['Name'] + ';' + row['Role'] + ';' + datetime.fromisoformat(row['Added']).strftime('%Y.%m.%d %H:%M')


def notion_key(Name, Role, Added):
    return Name + ';' + Role + ';' + Added.start.strftime('%Y.%m.%d %H:%M')


def set_phone(row, sem):
    global date_added_to_phones
    sem.acquire()
    try:
        phone = date_added_to_phones[notion_key(row.Name, row.Role, row.Added)]
        row.Phone = phone
    except KeyError:
        phone = date_added_to_phones[notion_key(row.Name.replace('_', '*'), row.Role, row.Added)]
        row.Phone = phone
    finally:
        sem.release()


def main():
    parser = ArgumentParser(description='Add phone numbers to existing applicant table in Notion.')
    parser.add_argument('--csv', metavar='file.csv', help='.csv file with applicants', required=True)
    parser.add_argument('--token', metavar='token_v2', help='token_v2 cookie from https://www.notion.so', required=True)
    parser.add_argument('--view', metavar='URL', help='link to notion view', required=True)
    args = parser.parse_args(sys.argv[1:])

    with open(args.csv, newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            date_added_to_phones[csv_key(row)] = row['phoneNumber']

    client = NotionClient(token_v2=args.token)
    cv = client.get_collection_view(args.view)
    rows = cv.build_query().execute()

    sem = Semaphore(10)
    for r in rows:
        t = Thread(target=set_phone, args=(r, sem))
        t.start()


if __name__ == '__main__':
    main()
