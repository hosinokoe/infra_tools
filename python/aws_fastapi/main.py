#!/usr/bin/python3

import uvicorn
from fastapi import FastAPI

app = FastAPI()


@app.get("/")
async def root():
  return {"message": "Hello World"}

@app.get("/items/{item_id}")
async def read_item(item_id: int):
  return {"item_id": item_id}


 # at last, the bottom of the file/module
if __name__ == "__main__":
  uvicorn.run(app, host="127.0.0.1", port=5049)