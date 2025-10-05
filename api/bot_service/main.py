from fastapi import FastAPI
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="ChatAppointment Bot Service", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health_check():
    return JSONResponse(content={"status": "healthy", "service": "bot-service"}, status_code=200)

@app.get("/")
def read_root():
    return {"message": "ChatAppointment Bot Service", "version": "1.0.0"}

@app.post("/chat")
def chat_endpoint(message: dict):
    # TODO: Implement chatbot logic
    return {"response": "Hello! This is a placeholder response from the bot service."}
    # TODO: Add logic to process user messages and generate responses gfgfgfgfg jkjjhhjhjhjh kjkjk jkjkjkj

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)