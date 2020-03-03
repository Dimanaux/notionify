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

id_to_rating = {}

def set_rating(row, sem):
    global id_to_rating
    sem.acquire()
    try:
        row.rating_num = id_to_rating[row.ID]
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
            id_to_rating[int(row['Id'])] = int(row['rating'] or '0')

    client = NotionClient(token_v2=args.token)
    cv = client.get_collection_view(args.view)
    rows = cv.build_query().execute()

    sem = Semaphore(10)
    for r in rows:
        t = Thread(target=set_rating, args=(r, sem))
        t.start()


if __name__ == '__main__':
    main()
