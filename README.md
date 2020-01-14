# notionify

## Dependencies:
- `ruby   >= 2.5`
    + httparty
- `python >= 3.3`
    + notion-api
- `go     >= 1.13 *`
    + notionapi

`*` - required if you have incompatible arch.\
You have to compile `Main.go` by yourself (use `install_go.sh` -
requires [go](https://golang.org/dl/)).\
Precompiled for Mac OS X.

## How to:
### 1. Export BambooHR data to CSV.
Replace `?` with your company domain in [main.rb](app/main.rb) on line 66.

Replace `?` with your BambooHR API key in [main.rb](app/main.rb) on line 67.

[This article](https://help.quantumworkplace.com/creating-a-bamboohr-api-key-for-integration)
explains how to get BambooHR API key.

For example my

- company domain was:
`neverg1veup`

- BambooHR API Key:
`7c0a82a3578120bd6ee1da05ca10a2aa9806ced1`

Run it! `ruby app/main.rb`

You get all files in [files directory](files).

### 2. Upload CSV to Notion.
In your Notion workspace click __add a new page__, click __import__ and then choose csv.

Upload file [applicant.csv](files/Applicant.csv).

Don't remove temporarily columns yet.

Set Attachments type to **Files & Media**.

### 3. Upload files and add comments to notes.
Replace `?` with your notion token (set by `token_v2` [cookie](https://www.notion.so))
in [notionify.py](notionify.py) on line 10.

Replace `?` with view link (copy by clicking 3 dots above the table created at step 2, copy link to view)
in [notionify.py](notionify.py) on line 11.

For example my

- Notion token was:
`758ab22a01b6472f841f4a8cfd08c7ea0058c341b6959154c2e6451a80e3ef7406a0c1aeeee313fd16346b42fb6c04c2dca27e2badc08ae46e50bb6b2371a67cb9ebe4b43cdd09dffe1d26ad1f5a`

- Link to view:
`https://www.notion.so/bamboohrcsvdemo/a4898a3b2e9b4faaba234553f34a8076?v=d17b517d1509ae068fcdff61380eec29`

Run it: `./notionify.py`

### 4. Prettify your table.
Now you can drop temporarily columns (CommentsJson, Links), give types to other columns.
