from notionify import *
from threading import Thread
from time import sleep

threads = []

def alive():
    global threads
    return len(list(filter(lambda t: t.is_alive(), threads)))


def comments(rows):
    rows_iter = iter(rows)
    for r in rows_iter:
        if len(r.children) > 0:
            continue
        t = Thread(target=set_row_comments, args=(r,), name=r.Name)
        threads.append(t)
        while alive() > 8:
            sleep(0.1)
        print(r.Name)
        t.start()


def attachments(rows):
    rows_iter = iter(rows)
    for r in rows_iter:
        t = Thread(target=set_row_attachments, args=(r,), name=r.Name)
        threads.append(t)
        while alive() > 8:
            sleep(0.1)
        print(r.Name)
        t.start()


ct = Thread(target=comments, args=(rows,))

(len(threads), alive())


def delete_comments(rows):
    rows_iter = iter(rows)
    for r in rows_iter:
        while len(r.children) > 0:
            r.children[0].remove()

