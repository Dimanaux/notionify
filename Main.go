package main

import (
    "github.com/kjk/notionapi"
    "os"
    "fmt"
)

func main() {
    token_v2 := os.Args[1]

    client := &notionapi.Client{}
    client.AuthToken = token_v2

    file, fileErr := os.Open(os.Args[2])
    if fileErr == nil {
        _, url, err := client.UploadFile(file)
        if err == nil {
            fmt.Println(url)
        }
        file.Close()        
    } else {
        fmt.Println("Error")
    }
}
